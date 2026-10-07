// Sinalizador de Glucose (bedside) — ESP32-WROOM + TFT 2.4" + Dexcom G7
// Acesso informativo. NAO e um dispositivo medico certificado.
//
// Fluxo: WiFi -> OAuth2 (refresh token persistido em NVS) -> EGVs (v3) ->
//        render (cor + seta de tendencia) + alarmes sonoros.
// A backing e sempre controlada com analogWrite (compativel cores 2.x e 3.x).

#include <Arduino.h>
#include <TFT_eSPI.h>
#include <Adafruit_NeoPixel.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <Preferences.h>
#include <ArduinoJson.h>
#include <time.h>

#include "config.h"

// ---------------------------------------------------------------------------
// Estado global
// ---------------------------------------------------------------------------
static TFT_eSPI tft;
static Preferences prefs;
Adafruit_NeoPixel glowStrip(1, PIN_GLOW, NEO_GRB + NEO_KHZ800);

static String accessToken;       // curto prazo (~2h), renovado via refresh token
static bool wifiOk = false;

static int  egvValue = -1;       // mg/dL, -1 = sem dados
static float egvTrendRate = NAN; // mg/dL/min
static String egvTrendStr;       // string do Dexcom (fallback)
static String egvSystemTime;     // systemTime do registo actual (ISO8601, UTC)
static long  egvAgeMin = -1;     // idade em minutos (calculada por render)
static bool  egvStale = true;    // sem dados recentes

static bool muted = false;       // MUTE silencia TODOS os beeps
static bool nightMode = false;   // so reduz backlight; alarmes continuam ativos

static bool btnMutePrev = HIGH;
static bool btnNightPrev = HIGH;
static unsigned long btnMuteLast = 0;
static unsigned long btnNightLast = 0;

static unsigned long lastFetchMs = 0;
static unsigned long lastStaleBeepMs = 0;
static bool blinkOn = false;          // piscar em hipo/hiper graves
static unsigned long lastBlinkMs = 0;
static int egvHist[48];               // ultimas leituras p/ delta (<=48)
static long egvHistT[48];             // timestamps (epoch) das leituras
static int egvHistLen = 0;
static double gLat = 0, gLon = 0;     // localizacao (ip-api, sem chave)
static bool hasGeo = false;
static bool hasWeather = false;
static float weatherTemp = NAN;       // graus C
static int weatherCode = -1;          // WMO code
static unsigned long lastWeatherMs = 0;

// ---------------------------------------------------------------------------
// Tempo: ISO8601 (UTC, sem sufixo Z) -> epoch via days_from_civil
// (algoritmo de Howard Hinnant; nao depende de strptime/timegm)
// ---------------------------------------------------------------------------
static long daysFromCivil(int y, int m, int d)
{
  y -= (m <= 2);
  const long era = (y >= 0 ? y : y - 399) / 400;
  const unsigned yoe = (unsigned)(y - era * 400);
  const unsigned doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1;
  const unsigned doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
  return era * 146097L + (long)doe - 719468L;
}

// "2026-10-03T12:34:56" -> epoch seconds (0 se invalido)
static long isoToEpoch(const String &iso)
{
  if (iso.length() < 19) return 0;
  int y = iso.substring(0, 4).toInt();
  int mo = iso.substring(5, 7).toInt();
  int d = iso.substring(8, 10).toInt();
  int h = iso.substring(11, 13).toInt();
  int mi = iso.substring(14, 16).toInt();
  int s = iso.substring(17, 19).toInt();
  if (y < 2000 || mo < 1 || mo > 12 || d < 1 || d > 31) return 0;
  return daysFromCivil(y, mo, d) * 86400L + h * 3600L + mi * 60L + s;
}

// epoch -> "YYYY-MM-DDTHH:MM:SS" (UTC)
static String epochToIso(long t)
{
  time_t tt = (time_t)t;
  struct tm tmv;
  gmtime_r(&tt, &tmv);
  char buf[24];
  snprintf(buf, sizeof(buf), "%04d-%02d-%02dT%02d:%02d:%02d",
           tmv.tm_year + 1900, tmv.tm_mon + 1, tmv.tm_mday,
           tmv.tm_hour, tmv.tm_min, tmv.tm_sec);
  return String(buf);
}

// ---------------------------------------------------------------------------
// Alarmes (so com leitura NOVA ou stale periodico; NUNCA silenciados a noite)
// ---------------------------------------------------------------------------
static void beep(unsigned int freq, unsigned int ms)
{
  if (muted) return;
  tone(PIN_BUZZER, freq, ms);
}

static void alarmForNewReading(int value)
{
  if (value < ALERT_LOW)
  {
    // Hipoglicemia: 3 beeps de 150 ms
    beep(2000, 150); delay(220);
    beep(2000, 150); delay(220);
    beep(2000, 150);
  }
  else if (value > ALERT_HIGH)
  {
    // Hiperglicemia: 2 beeps
    beep(1000, 200); delay(260);
    beep(1000, 200);
  }
}

// ---------------------------------------------------------------------------
// Backlight (duty 0..255) — modo nocturno so aqui afecta
// ---------------------------------------------------------------------------
static void applyBacklight()
{
  int duty = nightMode ? BACKLIGHT_NIGHT : BACKLIGHT_BRIGHT;
  analogWrite(PIN_BACKLIGHT, duty);
}

// ---------------------------------------------------------------------------
// HTTP: refresh token (POST /v3/oauth2/token) + EGVs (GET v3)
// ---------------------------------------------------------------------------
static bool refreshAccessToken(bool force)
{
  if (!force && accessToken.length() > 0) return true;

  WiFiClientSecure client;
  client.setInsecure();

  HTTPClient http;

  if (!http.begin(client, String(DEXCOM_BASE_URL) + "/v3/oauth2/token")) return false;

  String refreshTok = prefs.getString("refresh_token", DEXCOM_REFRESH_TOKEN);
  if (refreshTok.length() == 0)
  {
    http.end();
    return false;
  }

  http.addHeader("Content-Type", "application/x-www-form-urlencoded");
  String body = "client_id=" + String(DEXCOM_CLIENT_ID) +
                "&refresh_token=" + refreshTok +
                "&grant_type=refresh_token" +
                "&redirect_uri=" + String(DEXCOM_REDIRECT_URI);
  int code = http.POST(body);
  if (code != 200)
  {
    http.end();
    return false;
  }

  DynamicJsonDocument doc(2048);
  DeserializationError err = deserializeJson(doc, http.getStream());
  http.end();
  if (err) return false;

  const char *at = doc["access_token"];
  const char *rt = doc["refresh_token"];
  if (!at || !at[0]) return false;
  accessToken = String(at);
  if (rt && rt[0])
  {
    // o refresh token ROTACIONA: persistir sempre
    prefs.putString("refresh_token", String(rt));
  }
  return true;
}

// Busca EGVs das ultimas EGVS_WINDOW_HOURS e guarda o registo mais recente.
// Devolve true se chegou um registo NOVO (systemTime diferente).
static bool fetchEgvs()
{
  if (WiFi.status() != WL_CONNECTED) { wifiOk = false; return false; }
  wifiOk = true;

  if (!refreshAccessToken(false)) return false;

  long now = (long)time(nullptr);
  if (now < 1000000000L) now = (long)millis() / 1000 + 1700000000L; // NTP ainda nao sinc.
  String start = epochToIso(now - EGVS_WINDOW_HOURS * 3600L);
  String end = epochToIso(now);

  WiFiClientSecure client;
  client.setInsecure();
  HTTPClient http;
  http.setTimeout(15000);
  String url = String(DEXCOM_BASE_URL) + "/v3/users/self/egvs?startDate=" + start +
               "&endDate=" + end;
  if (!http.begin(client, url)) return false;
  http.addHeader("Authorization", "Bearer " + accessToken);

  int code = http.GET();
  if (code == 401)
  {
    // token expirado: refresh forcado + 1 retry
    http.end();
    if (!refreshAccessToken(true)) return false;
  HTTPClient http2;
  http2.setTimeout(15000);
  if (!http2.begin(client, url)) return false;
    http2.addHeader("Authorization", "Bearer " + accessToken);
    code = http2.GET();
    if (code != 200) { http2.end(); return false; }
    DynamicJsonDocument doc(8192);
    DeserializationError err = deserializeJson(doc, http2.getStream());
    http2.end();
    if (err) return false;

    JsonArray recs = doc["records"].as<JsonArray>();
    String bestTime;
    int bestVal = -1;
    float bestRate = NAN;
    String bestTrend;
    long hT[48]; int hV[48]; int hN = 0;
    for (JsonObject r : recs)
    {
      const char *st = r["systemTime"];
      if (!st) continue;
      String s(st);
      long tt = isoToEpoch(s);
      int vv = r["value"] | -1;
      if (tt > 0 && vv >= 0 && hN < 48) { hT[hN] = tt; hV[hN] = vv; hN++; }
      if (bestTime.length() == 0 || s > bestTime)
      {
        bestTime = s;
        bestVal = r["value"] | -1;
        if (r["trendRate"].is<float>()) bestRate = r["trendRate"].as<float>();
        const char *tr = r["trend"];
        bestTrend = tr ? String(tr) : "";
      }
    }
    if (bestVal < 0) return false;
    bool isNew = (bestTime != egvSystemTime);
    egvSystemTime = bestTime;
    egvValue = bestVal;
    egvTrendRate = bestRate;
    egvTrendStr = bestTrend;
    egvHistLen = hN;
    for (int i = 0; i < hN; i++) { egvHist[i] = hV[i]; egvHistT[i] = hT[i]; }
    return isNew;
  }
  if (code != 200) { http.end(); return false; }

  DynamicJsonDocument doc(8192);
  DeserializationError err = deserializeJson(doc, http.getStream());
  http.end();
  if (err) return false;

  JsonArray recs = doc["records"].as<JsonArray>();
  String bestTime;
  int bestVal = -1;
  float bestRate = NAN;
  String bestTrend;
  long hT[48]; int hV[48]; int hN = 0;
  for (JsonObject r : recs)
  {
    const char *st = r["systemTime"];
    if (!st) continue;
    String s(st);
    long tt = isoToEpoch(s);
    int vv = r["value"] | -1;
    if (tt > 0 && vv >= 0 && hN < 48) { hT[hN] = tt; hV[hN] = vv; hN++; }
    if (bestTime.length() == 0 || s > bestTime)
    {
      bestTime = s;
      bestVal = r["value"] | -1;
      if (r["trendRate"].is<float>()) bestRate = r["trendRate"].as<float>();
      const char *tr = r["trend"];
      bestTrend = tr ? String(tr) : "";
    }
  }
  if (bestVal < 0) return false;

  bool isNew = (bestTime != egvSystemTime);
  egvSystemTime = bestTime;
  egvValue = bestVal;
  egvTrendRate = bestRate;
  egvTrendStr = bestTrend;
  egvHistLen = hN;
  for (int i = 0; i < hN; i++) { egvHist[i] = hV[i]; egvHistT[i] = hT[i]; }
  return isNew;
}

// ---------------------------------------------------------------------------
// Tendencia: preferir trendRate (§4.2); fallback para a string
// rate>2 ↑↑ | rate>1 ↑ | rate>=-1 → | rate>=-2 ↓ | senão ↓↓
// ---------------------------------------------------------------------------
static int arrowForTrend()
{
  // 0=none, 1=up, 2=upup, 3=flat, 4=down, 5=downup(down2)
  if (!isnan(egvTrendRate))
  {
    if (egvTrendRate > 2.0f) return 2;
    if (egvTrendRate > 1.0f) return 1;
    if (egvTrendRate >= -1.0f) return 3;
    if (egvTrendRate >= -2.0f) return 4;
    return 5;
  }
  if (egvTrendStr.length() == 0) return 0;
  if (egvTrendStr == "doubleUp") return 2;
  if (egvTrendStr == "singleUp" || egvTrendStr == "fortyFiveUp") return 1;
  if (egvTrendStr == "flat") return 3;
  if (egvTrendStr == "fortyFiveDown" || egvTrendStr == "singleDown") return 4;
  if (egvTrendStr == "doubleDown") return 5;
  return 0; // notComputable / desconhecido: sem seta
}

// §4.1: <70 vermelho | 70-90 laranja | 91-180 verde | 181-250 amarelo | >250 vermelho
static uint16_t colorForValue(int v)
{
  if (v < ALERT_LOW) return 0xF800;
  if (v <= 90) return 0xFD20;
  if (v <= 180) return 0x07E0;
  if (v <= ALERT_HIGH) return 0xFFE0;
  return 0xF800;
}

// ---------------------------------------------------------------------------
// Render — setRotation(1) => 320x240
// ---------------------------------------------------------------------------
static void drawArrow(int kind, int cx, int cy, uint16_t fg, uint16_t bg)
{
  // Seta (escala ~0.6 da original): cabe entre o valor e o grafico.
  if (kind == 0) return;
  tft.fillTriangle(cx - 10, cy + 5, cx + 10, cy + 5, cx, cy - 12, fg); // base ↑
  if (kind == 1)
  {
    // ↑ simples: nada mais (triangulo ja e ↑)
  }
  else if (kind == 2)
  {
    // ↑↑: triangulo duplo
    tft.fillTriangle(cx - 10, cy + 20, cx + 10, cy + 20, cx, cy + 4, fg);
  }
  else if (kind == 3)
  {
    // → : limpar ↑ e desenhar horizontal
    tft.fillTriangle(cx - 10, cy + 5, cx + 10, cy + 5, cx, cy - 12, bg);
    tft.fillTriangle(cx - 5, cy - 14, cx - 5, cy + 14, cx + 14, cy, fg);
  }
  else if (kind == 4)
  {
    // ↓: espelhar
    tft.fillTriangle(cx - 10, cy + 5, cx + 10, cy + 5, cx, cy - 12, bg);
    tft.fillTriangle(cx - 10, cy - 5, cx + 10, cy - 5, cx, cy + 12, fg);
  }
  else if (kind == 5)
  {
    // ↓↓
    tft.fillTriangle(cx - 10, cy - 5, cx + 10, cy - 5, cx, cy + 12, bg);
    tft.fillTriangle(cx - 10, cy + 11, cx + 10, cy + 11, cx, cy + 28, fg);
    tft.fillTriangle(cx - 10, cy - 5, cx + 10, cy - 5, cx, cy + 12, fg);
  }
}

static void drawWifiIcon(int x, int y, bool ok, uint16_t fg, uint16_t bg)
{
  uint16_t c = ok ? fg : 0x8410; // cinza escuro quando sem WiFi
  tft.drawArc(x, y, 8, 6, 210, 330, c, bg);
  tft.drawArc(x, y, 5, 3, 210, 330, c, bg);
  tft.drawArc(x, y, 2, 1, 210, 330, c, bg);
  tft.fillCircle(x, y, 1, c);
}

static void drawClock(int x, int y, uint16_t fg, uint16_t bg)
{
  time_t nowt = time(nullptr);
  struct tm *ti = localtime(&nowt);
  if (!ti) return;
  char buf[6];
  snprintf(buf, sizeof(buf), "%02d:%02d", ti->tm_hour, ti->tm_min);
  tft.setTextSize(1);
  tft.setTextColor(fg, bg);
  tft.setCursor(x - tft.textWidth(buf), y);
  tft.print(buf);
}

// Icone de tempo simples (WMO code -> sol/nuvem/nevoeiro/chuva/trovoada)
static void drawWeatherIcon(int code, int x, int y, uint16_t c)
{
  int kind = 0; // sol
  if (code <= 3) kind = 1;                    // nublado
  else if (code == 45 || code == 48) kind = 2; // nevoeiro
  else if (code <= 77) kind = 3;              // chuva/neve
  else kind = 4;                              // aguaceiros/trovoada
  if (kind == 0)
  {
    tft.fillCircle(x, y, 8, c);
    for (int a = 0; a < 8; a++)
    {
      float ang = a * 0.785398f;
      tft.drawLine(x + (int)(11 * cos(ang)), y + (int)(11 * sin(ang)),
                   x + (int)(15 * cos(ang)), y + (int)(15 * sin(ang)), c);
    }
  }
  else
  {
    tft.fillCircle(x - 9, y + 2, 6, c);
    tft.fillCircle(x, y - 5, 7, c);
    tft.fillCircle(x + 9, y + 2, 6, c);
    tft.fillRect(x - 9, y, 18, 9, c);
    if (kind == 2)
    {
      tft.fillRect(x - 16, y + 14, 32, 2, c);
      tft.fillRect(x - 12, y + 18, 24, 2, c);
    }
    else if (kind == 3)
    {
      for (int i = -1; i <= 1; i++)
        tft.drawLine(x + i * 8, y + 16, x + i * 8 - 4, y + 22, c);
    }
    else if (kind == 4)
    {
      tft.fillTriangle(x - 3, y + 12, x + 6, y + 12, x, y + 21, c);
    }
  }
}

static void drawHeader(uint16_t fg, uint16_t bg)
{
  drawWifiIcon(20, 10, wifiOk, fg, bg);
  if (muted)
  {
    tft.setTextSize(1);
    tft.setTextColor(TFT_CYAN, bg);
    tft.setCursor(70, 4);
    tft.print("MUTE");
  }
  if (nightMode)
  {
    tft.setTextSize(1);
    tft.setTextColor(0x8410, bg);
    tft.setCursor(120, 4);
    tft.print("NIGHT");
  }
}

static void updateStale()
{
  long ageMin = -1;
  if (egvSystemTime.length() > 0)
  {
    long t = isoToEpoch(egvSystemTime);
    long now = (long)time(nullptr);
    if (t > 0 && now > t) ageMin = (now - t) / 60;
  }
  egvAgeMin = ageMin;
  egvStale = (egvValue < 0) || (ageMin < 0) || (ageMin > STALE_MINUTES);
}

// Localizacao via IP do WiFi (ip-api.com, sem chave): lat/lon
static bool geoLocate(double &lat, double &lon)
{
  WiFiClient client;
  HTTPClient http;
  if (!http.begin(client, IPAPI_URL)) return false;
  int code = http.GET();
  if (code != 200) { http.end(); return false; }
  DynamicJsonDocument doc(1024);
  DeserializationError err = deserializeJson(doc, http.getString());
  http.end();
  if (err) return false;
  if (!doc["lat"].is<double>() || !doc["lon"].is<double>()) return false;
  lat = doc["lat"].as<double>();
  lon = doc["lon"].as<double>();
  return true;
}

// Tempo por lat/lon (open-meteo, sem chave)
static void fetchWeather(double lat, double lon)
{
  char url[180];
  snprintf(url, sizeof(url), "%s&latitude=%.4f&longitude=%.4f", WM_URL, lat, lon);
  WiFiClient client;
  HTTPClient http;
  if (!http.begin(client, url)) return;
  int code = http.GET();
  if (code != 200) { http.end(); return; }
  DynamicJsonDocument doc(1024);
  DeserializationError err = deserializeJson(doc, http.getString());
  http.end();
  if (err) return;
  JsonObject cur = doc["current"].as<JsonObject>();
  if (cur.isNull()) return;
  if (cur["temperature_2m"].is<float>()) weatherTemp = cur["temperature_2m"].as<float>();
  weatherCode = cur["weather_code"] | -1;
  hasWeather = (weatherCode >= 0);
}

// Glow ambiente na base (NeoPixel): cor = zona; pulsa em hipo/hiper (usa blinkOn)
static void setGlowByZone()
{
  uint32_t c = glowStrip.Color(50, 50, 50);          // STALE: cinza suave
  if (!egvStale)
  {
    bool severe = (egvValue < ALERT_LOW || egvValue > ALERT_HIGH);
    if (egvValue < ALERT_LOW || egvValue > ALERT_HIGH) c = glowStrip.Color(255, 0, 0);
    else if (egvValue <= 90) c = glowStrip.Color(255, 110, 0);
    else if (egvValue <= 180) c = glowStrip.Color(0, 190, 60);
    else c = glowStrip.Color(255, 190, 0);
    if (severe && blinkOn) c = glowStrip.Color(0, 0, 0);   // pulsa: apaga entre ciclos
  }
  glowStrip.setPixelColor(0, c);
  glowStrip.show();
}

static void render()
{
  updateStale();

  uint16_t bg, fg;
  if (egvStale)
  {
    bg = 0x4208;                 // cinza escuro
    fg = TFT_WHITE;
  }
  else
  {
    bg = colorForValue(egvValue);
    bool severe = (egvValue < ALERT_LOW || egvValue > ALERT_HIGH);
    if (severe && blinkOn) bg = TFT_BLACK;   // piscar: alterna com preto
    fg = (bg == TFT_BLACK) ? 0xF800 : TFT_BLACK;
  }
  tft.fillScreen(bg);
  drawHeader(fg, bg);

  if (egvStale)
  {
    tft.setTextSize(3);
    tft.setTextColor(0xFFE0, bg);
    String msg = "sem dados recentes";
    int w = tft.textWidth(msg);
    tft.setCursor((480 - w) / 2, 150);
    tft.print(msg);
    setGlowByZone();
    return;
  }

  // Cartao esquerdo: relogio + tempo
  time_t nowt = time(nullptr);
  struct tm *ti = localtime(&nowt);
  char hh[3], mm[3];
  if (ti) { snprintf(hh, sizeof(hh), "%02d", ti->tm_hour); snprintf(mm, sizeof(mm), "%02d", ti->tm_min); }
  else { strcpy(hh, "--"); strcpy(mm, "--"); }
  tft.setTextSize(7);
  tft.setTextColor(fg, bg);
  int w8 = tft.textWidth(hh);
  int xc = (200 - (w8 * 2 + 12)) / 2;
  tft.setCursor(xc, 92);
  tft.print(hh);
  tft.fillRect(xc + w8 + 3, 114, 5, 5, fg);
  tft.fillRect(xc + w8 + 3, 130, 5, 5, fg);
  tft.setCursor(xc + w8 + 12, 92);
  tft.print(mm);

  if (hasWeather)
  {
    char tbuf[16];
    snprintf(tbuf, sizeof(tbuf), "%.0fC", weatherTemp);
    tft.setTextSize(3);
    tft.setTextColor(fg, bg);
    int tw = tft.textWidth(tbuf);
    tft.setCursor((200 - tw) / 2 - 16, 178);
    tft.print(tbuf);
    drawWeatherIcon(weatherCode, 152, 194, fg);
  }
  else
  {
    tft.setTextSize(2);
    tft.setTextColor(0x8410, bg);
    String m = "--C";
    int mw = tft.textWidth(m);
    tft.setCursor((200 - mw) / 2, 180);
    tft.print(m);
  }

  // divisor vertical entre os dois cartoes
  tft.drawLine(200, 24, 200, 296, fg);

  // Cartao direito: glucose — valor gigante (textSize 15)
  tft.setTextSize(15);
  tft.setTextColor(fg, bg);
  String s = String(egvValue);
  int wv = tft.textWidth(s);
  tft.setCursor(200 + (280 - wv) / 2, 66);
  tft.print(s);

  // delta (intervalo real de polling) + seta
  int delta = 0;
  long dtSec = 0;
  if (egvHistLen >= 2)
  {
    delta = egvHist[egvHistLen - 1] - egvHist[egvHistLen - 2];
    dtSec = egvHistT[egvHistLen - 1] - egvHistT[egvHistLen - 2];
  }
  tft.setTextSize(5);
  tft.setTextColor(fg, bg);
  char dbuf[12];
  snprintf(dbuf, sizeof(dbuf), "%+d", delta);
  int dw = tft.textWidth(dbuf);
  int mins = (dtSec >= 60) ? (int)(dtSec / 60) : 1;
  int dx = 200 + (280 - (dw + 64)) / 2;
  tft.setCursor(dx, 226);
  tft.print(dbuf);
  tft.setTextSize(2);
  char lbl[16];
  snprintf(lbl, sizeof(lbl), "%dmin", mins);
  tft.setCursor(dx + dw + 6, 236);
  tft.print(lbl);
  drawArrow(arrowForTrend(), 452, 240, fg, bg);

  // idade
  tft.setTextSize(2);
  tft.setTextColor(fg, bg);
  String age = "ha " + String(egvAgeMin) + " min";
  int aw = tft.textWidth(age);
  tft.setCursor(200 + (280 - aw) / 2, 292);
  tft.print(age);
  setGlowByZone();
}

// ---------------------------------------------------------------------------
// Botoes: debounce 50 ms (MUTE inverte mute; NIGHT inverte night mode)
// ---------------------------------------------------------------------------
static void handleButtons()
{
  unsigned long now = millis();
  bool m = digitalRead(PIN_MUTE);
  bool n = digitalRead(PIN_NIGHT);

  if (m == LOW && btnMutePrev == HIGH && now - btnMuteLast > BUTTON_DEBOUNCE_MS)
  {
    muted = !muted;
    btnMuteLast = now;
  }
  if (n == LOW && btnNightPrev == HIGH && now - btnNightLast > BUTTON_DEBOUNCE_MS)
  {
    nightMode = !nightMode;
    applyBacklight();
    btnNightLast = now;
  }
  btnMutePrev = m;
  btnNightPrev = n;
}

// ---------------------------------------------------------------------------
// Setup / Loop
// ---------------------------------------------------------------------------
void setup()
{
  Serial.begin(115200);
  pinMode(PIN_MUTE, INPUT_PULLUP);
  pinMode(PIN_NIGHT, INPUT_PULLUP);
  pinMode(PIN_BUZZER, OUTPUT);
  pinMode(PIN_BACKLIGHT, OUTPUT);
  analogWriteResolution(PIN_BACKLIGHT);

  prefs.begin("glucose", false); // NVS: refresh_token persistido

  tft.init();
  tft.setRotation(1); // 480x320 horizontal (ecra 3.5")
  tft.fillScreen(TFT_BLACK);
  applyBacklight();
  glowStrip.begin();
  glowStrip.setBrightness(70);
  glowStrip.show();
  tft.setTextSize(2);
  tft.setTextColor(TFT_WHITE, TFT_BLACK);
  tft.setCursor(20, 100);
  tft.print("A ligar WiFi...");

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  unsigned long t0 = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - t0 < WIFI_TIMEOUT_MS)
  {
    delay(200);
  }
  wifiOk = (WiFi.status() == WL_CONNECTED);

  // NTP (epoch para idade das leituras)
  configTime(0, 0, "pool.ntp.org", "time.nist.gov");

  if (wifiOk)
  {
    refreshAccessToken(true);
    fetchEgvs();
    hasGeo = geoLocate(gLat, gLon);
    if (hasGeo) fetchWeather(gLat, gLon);
    lastWeatherMs = millis();
  }
  render();
  lastFetchMs = millis();
}

void loop()
{
  handleButtons();

  // Piscar em hipo/hiper graves (<70 ou >250): alternar fundo a cada 500 ms
  bool severe = (egvValue >= 0) && !egvStale && (egvValue < ALERT_LOW || egvValue > ALERT_HIGH);
  if (severe)
  {
    if (millis() - lastBlinkMs >= 500)
    {
      lastBlinkMs = millis();
      blinkOn = !blinkOn;
      render();
    }
  }
  else
  {
    blinkOn = false;
  }

  // Tempo: atualizar periodicamente
  if (hasGeo && millis() - lastWeatherMs >= WEATHER_INTERVAL_MS)
  {
    lastWeatherMs = millis();
    fetchWeather(gLat, gLon);
  }

  if (millis() - lastFetchMs >= FETCH_INTERVAL_MS)
  {
    lastFetchMs = millis();
    bool isNew = fetchEgvs();
    if (isNew && egvValue >= 0)
    {
      alarmForNewReading(egvValue); // alarme SO em leitura nova
    }
    render();
  }

  // Stale periodico (5 min): beep unico, a menos que MUTE
  if (egvStale && millis() - lastStaleBeepMs >= STALE_BEEP_MS)
  {
    lastStaleBeepMs = millis();
    beep(1500, 120);
  }

  delay(50);
}
