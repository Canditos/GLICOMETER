// =============================================================================
// sinalizador-glucose — config.h
// Credenciais e parâmetros de configuracao.
//
// NOTA: Este e um acessorio INFORMATIVO para uso pessoal.
//       NAO e um dispositivo medico certificado (ver README.md).
// =============================================================================

#pragma once

// ---------------------------------------------------------------------------
// WiFi
// ---------------------------------------------------------------------------
#define WIFI_SSID "SSID_AQUI"
#define WIFI_PASS "PASSWORD_AQUI"
#define WIFI_TIMEOUT_MS 15000  // tempo maximo a tentar ligar ao WiFi

// ---------------------------------------------------------------------------
// Dexcom API v3 (OAuth2)
// ---------------------------------------------------------------------------
// Crie uma app em https://developer.dexcom.com e copie o Client ID.
// O Refresh Token e obtido no primeiro fluxo OAuth (ver README.md).
//
// PRODUCAO:   https://api.dexcom.com
// SANDBOX:    https://sandbox-api.dexcom.com  (para testes, dados simulados)
#define DEXCOM_BASE_URL "https://api.dexcom.com"
#define DEXCOM_CLIENT_ID "CLIENT_ID_AQUI"
#define DEXCOM_REFRESH_TOKEN "REFRESH_TOKEN_AQUI"
#define DEXCOM_REDIRECT_URI "https://localhost" // obrigatorio no form do token

// ---------------------------------------------------------------------------
// Intervalos e limiares (minutos / ms)
// ---------------------------------------------------------------------------
#define FETCH_INTERVAL_MS 60000    // busca a cada 60 s
#define STALE_MINUTES 10           // a partir de 10 min sem dados → stale
#define STALE_BEEP_MS 300000       // beep periodico de stale (5 min)
#define EGVS_WINDOW_HOURS 2        // janela pedida à API (2 h)

// ---------------------------------------------------------------------------
// Pinos (ESP32-WROOM)
// ---------------------------------------------------------------------------
// TFT (ver platformio.ini para build_flags do driver)
#define PIN_TFT_MOSI 23
#define PIN_TFT_SCLK 18
#define PIN_TFT_CS 15
#define PIN_TFT_DC 2
#define PIN_TFT_RST 4

// Backlight (PWM)
#define PIN_BACKLIGHT 32
#define BACKLIGHT_BRIGHT 255    // modo normal (0..255)
#define BACKLIGHT_NIGHT 64      // modo noturno ≈25 %

// Buzzer + controlos
#define PIN_BUZZER 27
#define PIN_MUTE 13   // botao: silencia TODOS os beeps (INPUT_PULLUP)
#define PIN_NIGHT 14  // botao: backlight reduzido (INPUT_PULLUP)
#define BUTTON_DEBOUNCE_MS 50

// ---------------------------------------------------------------------------
// Limites de alarme (mg/dL) — ver sec5.1 da spec
// ---------------------------------------------------------------------------
#define ALERT_LOW 70
#define ALERT_HIGH 250

// ---------------------------------------------------------------------------
// Slideshow (relogio <-> glucose) e tempo (localizacao via WiFi, sem chave)
// ---------------------------------------------------------------------------
#define VIEW_SECONDS 10            // intervalo do slideshow (s)
#define WEATHER_INTERVAL_MS 1800000 // atualizar tempo a cada 30 min
#define IPAPI_URL "http://ip-api.com/json/?fields=lat,lon,city"
#define WM_URL "http://api.open-meteo.com/v1/forecast?current=temperature_2m,weather_code"
