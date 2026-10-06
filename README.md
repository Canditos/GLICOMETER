# GLICOMETER — Sinalizador de Glucose (bedside)

Dispositivo bedside que mostra **relógio + tempo + glucose** (Dexcom G7) num
ecrã TFT **2.8" retrato**, com caixa 3D impressa (OpenSCAD).

> **ACESSÓRIO INFORMATIVO — NÃO é um dispositivo médico.**
> Mostra leituras do seu CGM; confirme sempre na app/receptor prescrito antes de tratar.

## Funcionalidades
- **Dois cartões** no ecrã retrato 240×320: relógio + tempo (localização WiFi automática) e glucose
- Valor **gigante**, delta numérico (polling real G7 = 5 min), seta de tendência
- **Fundo = cor da zona** (verde/laranja/amarelo/vermelho) + **piscar 1 Hz** em hipo/hiper grave
- Localização por IP (`ip-api`) e tempo (`open-meteo`) — **sem chaves**, sem contas
- Modo noturno (backlight reduzido) e silenciamento por botão

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `firmware/` | ESP32 (PlatformIO): `src/main.cpp`, `src/config.h`, README (comissionamento) |
| `modelo-3d/` | Caixa OpenSCAD + STL (corpo, placa traseira) para o ecrã 2.8" |
| `docs/` | BOM (preços), simulador do ecrã, mockup, previews 3D |
| `ANALISE-SINALIZADOR-GLUCOSE.md` | Spec do projeto |

## Começar (comissionamento — ~15 min, ver `firmware/README.md`)

1. Imprimir `modelo-3d/corpo.stl` + `modelo-3d/placa_traseira.stl` (PLA/PETG).
2. Montar: ESP32-WROOM + display TFT 2.8" ILI9341 (SPI) + buzzer + botões MUTE/NIGHT.
3. Criar app em https://developer.dexcom.com → **Client ID**; obter **refresh token** no fluxo OAuth.
4. Configurar `firmware/src/config.h` — `WIFI_SSID`, `WIFI_PASS`, `DEXCOM_CLIENT_ID`, `DEXCOM_REFRESH_TOKEN`.
5. Gravar: `pio run -u -d firmware\` (USB).
6. Colocar na cabeceira — relógio + tempo + glucose a funcionar.

## Custo estimado

~36–45 € em material (ver `docs/BOM.md`). Sensor Dexcom G7: ~60–90 €/mês (subscrição).
Comparação: CYGM open-source ~$40 · Glucose Display comercial $129.99.

---

MIT · #WeAreNotWaiting · independente (não afiliado à Dexcom/Abbott)