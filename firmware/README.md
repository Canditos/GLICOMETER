# Sinalizador de Glucose — Firmware (ESP32)

Aviso importante: este acessório é **INFORMATIVO** e **NÃO é um dispositivo médico certificado**.
Não usar para decisões clínicas. Consulte sempre um profissional de saúde.

## Comissionamento (checklist — ~15 min)

1. **Imprimir** as 2 peças 3D (`modelo-3d\corpo.stl` + `placa_traseira.stl`, PLA/PETG).
2. **Montar** — ESP32-WROOM + display TFT 2.8" (ILI9341 SPI) + buzzer + botões MUTE/NIGHT (ver pinos abaixo).
3. **Criar app Dexcom** em https://developer.dexcom.com → copiar o **Client ID**.
4. **Obter o refresh token** no 1.º fluxo OAuth (autorizar com o `DEXCOM_REDIRECT_URI` registado).
5. **Configurar** `src/config.h` — `WIFI_SSID`, `WIFI_PASS`, `DEXCOM_CLIENT_ID`, `DEXCOM_REFRESH_TOKEN`.
6. **Gravar** — `pio run -u -d firmware\` (USB) · ver serial a 115200 baud.
7. **Ligar** — no arranque: WiFi → localização (ip-api) → tempo (open-meteo) → token Dexcom → leituras.
8. **Verificar** — relógio + 18°C + glucose colorida; "há X min" atualiza a cada 60 s; ícone WiFi aceso.
9. **Cabeceira** — colocar na mesa; funciona dia/noite (modo noturno reduz brilho).

> Se o ecrã ficar "sem dados recentes" e o WiFi estiver ligado, ver o Serial para o erro
> (token inválido, sandbox vs produção, rede 2.4 GHz necessária).

## Requisitos

- ESP32 (env `esp32dev`, framework Arduino)
- Ecrã TFT (ILI9341 240×320 por omissão; ST7789 compatível — ver «Alternar para ST7789»)
- PlatformIO CLI

Binário `pio` usado nesta máquina:

```
C:\Users\marco\AppData\Local\Programs\Python\Python312\Scripts\pio.exe
```

## Estrutura

```
firmware/
├── platformio.ini      # env, libs, build_flags (pinos TFT)
├── src/
│   ├── main.cpp        # lógica principal
│   └── config.h        # WI-FI, Dexcom, alertas, pinos — editar aqui
└── README.md
```

## Compilar

```powershell
cd D:\FATURAÇÃO\firmware
& "C:\Users\marco\AppData\Local\Programs\Python\Python312\Scripts\pio.exe" run
```

Build actual: **verde** (EXITCODE=0). Log de referência:
`C:\Users\marco\AppData\Local\Temp\opencode\pio_build.log`

Carregar no equipamento:

```powershell
& "C:\Users\marco\AppData\Local\Programs\Python\Python312\Scripts\pio.exe" run -t upload
```

Monitor série (115200 baud):

```powershell
& "C:\Users\marco\AppData\Local\Programs\Python\Python312\Scripts\pio.exe" device monitor
```

## Configuração — `src/config.h`

Editar **apenas** `src/config.h` (não editar `platformio.ini` nem reescrever ficheiros de origem).

### Wi-Fi

| Constante | Valor por omissão | Notas |
|---|---|---|
| `WIFI_SSID` | `"SSID_AQUI"` | substituir |
| `WIFI_PASS` | `"PASSWORD_AQUI"` | substituir |
| `WIFI_TIMEOUT_MS` | `15000` | falha → tenta de novo no ciclo seguinte |

### Dexcom (OAuth v3)

| Constante | Valor por omissão | Notas |
|---|---|---|
| `DEXCOM_BASE_URL` | `"https://api.dexcom.com"` | produção; sandbox: `https://sandbox-api.dexcom.com` |
| `DEXCOM_CLIENT_ID` | `"CLIENT_ID_AQUI"` | obter em https://developer.dexcom.com |
| `DEXCOM_REFRESH_TOKEN` | `"REFRESH_TOKEN_AQUI"` | obtido no 1.º fluxo OAuth |
| `DEXCOM_REDIRECT_URI` | `"https://localhost"` | **tem de coincidir** com o registo da app |
| `DEXCOM_WINDOW_HOURS` (`EGVS_WINDOW_HOURS`) | `2` | janela de leituras |

Endpoint de leituras (v3):

```
GET https://api.dexcom.com/v3/users/self/egvs?startDate=...&endDate=...
```

Renovação de token (form-urlencoded):

```
POST https://api.dexcom.com/v3/oauth2/token
redirect_uri=https://localhost
```

### Cadência e stale

| Constante | Valor | Notas |
|---|---|---|
| `FETCH_INTERVAL_MS` | `60000` (1 min) | entre pedidos |
| `STALE_MINUTES` | `10` | leitura velha → oculta número + seta (spec §4.4) |
| `STALE_BEEP_MS` | `300000` (5 min) | beep curto `beep(1500, 120)` enquanto stale |

### Alarmes (mg/dL, spec §5.1)

| Constante | Valor |
|---|---|
| `ALERT_LOW` | `70` |
| `ALERT_HIGH` | `250` |

`alarmForNewReading(egvValue)` só dispara em **leitura nova** (não a cada ciclo).

### Pinos — TFT (também em `platformio.ini` `build_flags`)

| Sinal | GPIO |
|---|---|
| `PIN_TFT_MOSI` / `TFT_MOSI` | 23 |
| `PIN_TFT_SCLK` / `TFT_SCLK` | 18 |
| `PIN_TFT_CS` / `TFT_CS` | 15 |
| `PIN_TFT_DC` / `TFT_DC` | 2 |
| `PIN_TFT_RST` / `TFT_RST` | 4 |

### Pinos — periféricos

| Constante | GPIO | Função |
|---|---|
| `PIN_BACKLIGHT` | 32 | PWM: `BACKLIGHT_BRIGHT=255`, `BACKLIGHT_NIGHT=64` (≈25 %) |
| `PIN_BUZZER` | 27 | alarmes + stale beep |
| `PIN_MUTE` | 13 | `INPUT_PULLUP` — mute total (spec §4.3) |
| `PIN_NIGHT` | 14 | `INPUT_PULLUP` — modo noite: só backlight a 64 (spec §4.3) |
| — | — | `BUTTON_DEBOUNCE_MS=50` |

## Alternar para ST7789

Em `platformio.ini` → `build_flags`:

1. Trocar `ST7789_DRIVER=1` por `ILI9341_DRIVER=1` (ILI9341 = default actual)
2. Se usar ST7789 a sério: manter `ST7789_DRIVER=1` e `TFT_WIDTH=240` / `TFT_HEIGHT=320`
3. Reposicionar `USER_SETUP_LOADED=1` (tem de ser o 1.º flag)

Depois: `pio run` para validar.

## Cores do ecrã (RGB565, spec §4.1)

| Estado | Cor | Valor |
|---|---|---|
| Baixo | vermelho | `0xF800` |
| Alerta | laranja | `0xFD20` |
| Normal | verde | `0x07E0` |
| Alta | amarelo | `0xFFE0` |

Setas de tendência (`trendRate`, §4.2) são desenhadas sobre o fundo de cor.

## Troubleshooting

| Sintoma | Causa provável | Acção |
|---|---|---|
| `src/main.cpp:129` (ou 184/198/414/451) | já resolvido | build actual está verde — não reaplicar patches |
| Wi-Fi não liga | `WIFI_SSID`/`WIFI_PASS` por preencher | editar `config.h` |
| 401/403 Dexcom | token expirado ou `redirect_uri` divergente | renovar refresh token; confirmar registo em developer.dexcom.com |
| Ecrã preto | pino RST/DC errado ou driver errado | conferir tabela de pinos; ILI9341 vs ST7789 |
| Beep constante | leitura > `STALE_MINUTES` | esperar leitura nova; `PIN_MUTE` para silenciar |
| Sem leituras | `DEXCOM_BASE_URL` em sandbox vs produção | alinhar URL com o tipo de app |

## Notas de manutenção

- **Não reescrever** `platformio.ini` nem `config.h` a partir de zero — só edição pontual.
- `main.cpp`: corrigir apenas por **patch** (não reescrever o ficheiro).
- Verificar sempre o resultado em disco com caminho absoluto:
  `Get-Item "D:\FATURAÇÃO\firmware\README.md"`
- Caminho correcto: `D:\FATURAÇÃO\firmware\...` (Ç-Ã). **Nunca** `D:\FATURAÇÂO\`.
