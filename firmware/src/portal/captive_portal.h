// =============================================================================
// GLICOMETER — captive_portal.h
// Portal de Configuração Wi-Fi e Parâmetros Médicos IoT sem compilação.
// =============================================================================

#pragma once

#include <WiFi.h>
#include <WebServer.h>
#include <DNSServer.h>
#include <Preferences.h>
#include <ArduinoJson.h>

class GlicometerPortal {
private:
    WebServer server;
    DNSServer dnsServer;
    Preferences prefs;
    const byte DNS_PORT = 53;
    bool portalRunning = false;

    // Configurações persistidas
    struct Config {
        String wifiSSID = "";
        String wifiPass = "";
        String serviceType = "dexcom"; // "dexcom", "nightscout", "libre"
        String apiUrl = "https://api.dexcom.com";
        String apiToken = "";
        String clientId = "";
        int alertLow = 70;
        int alertHigh = 250;
        bool nightMode = true;
        int nightHourStart = 23;
        int nightHourEnd = 7;
        bool soundAlerts = true;
    } currentConfig;

    String getHtmlPage() {
        return R"rawliteral(
<!DOCTYPE html>
<html lang="pt-PT">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>GLICOMETER • Configuração Rápida</title>
  <style>
    :root {
      --bg: #0b0f17;
      --card: #161f36;
      --text: #f1f5f9;
      --sub: #94a3b8;
      --accent: #22c55e;
      --border: rgba(255,255,255,0.08);
    }
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
    body { background: var(--bg); color: var(--text); padding: 20px 16px; line-height: 1.5; }
    .container { max-width: 440px; margin: 0 auto; }
    .header { text-align: center; margin-bottom: 24px; }
    .logo { display: inline-flex; width: 48px; height: 48px; border-radius: 14px; background: linear-gradient(135deg, #22c55e, #06b6d4); align-items: center; justify-content: center; font-size: 24px; font-weight: bold; color: white; margin-bottom: 12px; }
    h1 { font-size: 22px; font-weight: 700; margin-bottom: 4px; }
    p.subtitle { font-size: 13px; color: var(--sub); }
    .card { background: var(--card); border: 1px solid var(--border); border-radius: 16px; padding: 20px; margin-bottom: 16px; }
    .card-title { font-size: 13px; text-transform: uppercase; font-weight: 700; color: var(--accent); letter-spacing: 0.05em; margin-bottom: 14px; display: flex; align-items: center; gap: 8px; }
    .form-group { margin-bottom: 14px; }
    .form-group:last-child { margin-bottom: 0; }
    label { display: block; font-size: 13px; font-weight: 600; color: var(--text); margin-bottom: 6px; }
    input, select { width: 100%; background: #0b0f17; border: 1px solid rgba(255,255,255,0.15); border-radius: 10px; color: white; padding: 12px; font-size: 14px; outline: none; transition: border-color 0.2s; }
    input:focus, select:focus { border-color: var(--accent); }
    .row { display: flex; gap: 12px; }
    .row .form-group { flex: 1; }
    .btn { display: block; width: 100%; background: var(--accent); color: #0b0f17; font-weight: 700; font-size: 15px; border: none; border-radius: 12px; padding: 14px; cursor: pointer; text-align: center; margin-top: 24px; box-shadow: 0 4px 15px rgba(34,197,94,0.3); }
    .btn:active { transform: scale(0.98); }
    .footer { text-align: center; font-size: 11px; color: var(--sub); margin-top: 24px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">G</div>
      <h1>GLICOMETER</h1>
      <p class="subtitle">Configuração do Dispositivo de Cabeceira</p>
    </div>

    <form method="POST" action="/save">
      <!-- WI-FI -->
      <div class="card">
        <div class="card-title">📡 Ligação Wi-Fi de Casa</div>
        <div class="form-group">
          <label>Nome da Rede (SSID)</label>
          <input type="text" name="ssid" required placeholder="Ex: MinhaCasa_WiFi">
        </div>
        <div class="form-group">
          <label>Password da Rede</label>
          <input type="password" name="password" placeholder="Password da rede Wi-Fi">
        </div>
      </div>

      <!-- FONTE DE DADOS -->
      <div class="card">
        <div class="card-title">🩺 Fonte de Glicemia CGM</div>
        <div class="form-group">
          <label>Serviço</label>
          <select name="service" id="serviceSelect" onchange="updateServiceFields()">
            <option value="dexcom">Dexcom Share / API Oficial</option>
            <option value="nightscout">Nightscout (Personal URL)</option>
            <option value="libre">FreeStyle LibreLinkUp</option>
          </select>
        </div>
        <div class="form-group">
          <label id="urlLabel">URL do Servidor / Base API</label>
          <input type="text" name="apiUrl" id="apiUrl" value="https://api.dexcom.com">
        </div>
        <div class="form-group">
          <label id="tokenLabel">Token de Acesso / API Secret</label>
          <input type="text" name="apiToken" placeholder="Insira o seu token ou API Secret">
        </div>
      </div>

      <!-- ALARMES & LIMITES -->
      <div class="card">
        <div class="card-title">🔔 Limites de Alarme (mg/dL)</div>
        <div class="row">
          <div class="form-group">
            <label>Alerta Hipo (&lt;)</label>
            <input type="number" name="alertLow" value="70" min="50" max="100">
          </div>
          <div class="form-group">
            <label>Alerta Hiper (&gt;)</label>
            <input type="number" name="alertHigh" value="250" min="140" max="400">
          </div>
        </div>
        <div class="form-group" style="margin-top: 10px;">
          <label>
            <input type="checkbox" name="soundAlerts" checked style="width: auto; margin-right: 8px;">
            Ativar Alarme Sonoro no Buzzer
          </label>
        </div>
      </div>

      <button type="submit" class="btn">Guardar e Reiniciar Monitor</button>
    </form>

    <div class="footer">
      GLICOMETER • Companion Monitor v2.1<br>Não substitui equipamento médico de diagnóstico.
    </div>
  </div>

  <script>
    function updateServiceFields() {
      var s = document.getElementById("serviceSelect").value;
      var ul = document.getElementById("urlLabel");
      var tl = document.getElementById("tokenLabel");
      var urlInput = document.getElementById("apiUrl");

      if (s === "nightscout") {
        ul.innerText = "URL do teu Nightscout (ex: https://meucgm.herokuapp.com)";
        tl.innerText = "API_SECRET (Token de Acesso)";
        urlInput.value = "";
      } else if (s === "dexcom") {
        ul.innerText = "Base API Dexcom";
        tl.innerText = "OAuth Refresh Token / Client ID";
        urlInput.value = "https://api.dexcom.com";
      } else if (s === "libre") {
        ul.innerText = "Região LibreLinkUp";
        tl.innerText = "Email / Password de Utilizador";
        urlInput.value = "EU";
      }
    }
  </script>
</body>
</html>
)rawliteral";
    }

    String getSuccessPage() {
        return R"rawliteral(
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>A Guardar...</title>
  <style>
    body { background: #0b0f17; color: white; font-family: sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; text-align: center; margin: 0; }
    .box { background: #161f36; padding: 30px; border-radius: 16px; border: 1px solid rgba(255,255,255,0.1); max-width: 320px; }
    h2 { color: #22c55e; margin-bottom: 12px; }
    p { font-size: 14px; color: #94a3b8; }
  </style>
</head>
<body>
  <div class="box">
    <h2>✓ Configuração Guardada!</h2>
    <p>O GLICOMETER vai reiniciar e ligar-se à tua rede Wi-Fi agora.</p>
    <p style="margin-top: 15px; font-size: 12px;">Podes fechar esta janela.</p>
  </div>
</body>
</html>
)rawliteral";
    }

public:
    GlicometerPortal() : server(80) {}

    void loadConfiguration() {
        prefs.begin("glicometer", true);
        currentConfig.wifiSSID = prefs.getString("ssid", "");
        currentConfig.wifiPass = prefs.getString("pass", "");
        currentConfig.serviceType = prefs.getString("srv", "dexcom");
        currentConfig.apiUrl = prefs.getString("url", "https://api.dexcom.com");
        currentConfig.apiToken = prefs.getString("token", "");
        currentConfig.alertLow = prefs.getInt("low", 70);
        currentConfig.alertHigh = prefs.getInt("high", 250);
        currentConfig.soundAlerts = prefs.getBool("snd", true);
        prefs.end();
    }

    bool hasValidCredentials() {
        return currentConfig.wifiSSID.length() > 0;
    }

    void startHotspot() {
        WiFi.disconnect();
        WiFi.mode(WIFI_AP);
        String apName = "GLICOMETER-SETUP";
        WiFi.softAP(apName.c_str());

        dnsServer.start(DNS_PORT, "*", WiFi.softAPIP());

        // Captive Portal Handlers
        server.on("/", HTTP_GET, [this]() {
            server.send(200, "text/html", getHtmlPage());
        });

        server.on("/save", HTTP_POST, [this]() {
            prefs.begin("glicometer", false);
            if (server.hasArg("ssid")) prefs.putString("ssid", server.arg("ssid"));
            if (server.hasArg("password")) prefs.putString("pass", server.arg("password"));
            if (server.hasArg("service")) prefs.putString("srv", server.arg("service"));
            if (server.hasArg("apiUrl")) prefs.putString("url", server.arg("apiUrl"));
            if (server.hasArg("apiToken")) prefs.putString("token", server.arg("apiToken"));
            if (server.hasArg("alertLow")) prefs.putInt("low", server.arg("alertLow").toInt());
            if (server.hasArg("alertHigh")) prefs.putInt("high", server.arg("alertHigh").toInt());
            prefs.putBool("snd", server.hasArg("soundAlerts"));
            prefs.end();

            server.send(200, "text/html", getSuccessPage());
            delay(1500);
            ESP.restart();
        });

        // Redirects para forçar Captive Portal no iOS / Android
        server.on("/generate_204", HTTP_GET, [this]() { server.send(200, "text/html", getHtmlPage()); });
        server.on("/hotspot-detect.html", HTTP_GET, [this]() { server.send(200, "text/html", getHtmlPage()); });
        server.onNotFound([this]() { server.send(200, "text/html", getHtmlPage()); });

        server.begin();
        portalRunning = true;
    }

    void handle() {
        if (portalRunning) {
            dnsServer.processNextRequest();
            server.handleClient();
        }
    }

    const Config& getConfig() const { return currentConfig; }
};
