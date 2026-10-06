# BOM — Sinalizador de Glucose

Lista de materiais para montar o sinalizador de glucose bedside
(Dexcom G7 → ESP32-WROOM → TFT 2.4").

> **ACESSÓRIO INFORMATIVO — NÃO é um dispositivo médico.**
> Preços estimados em EUR (mercado PT/EU, 2026) — variam com o fornecedor
> (AliExpress mais barato; loja local mais caro).

## 1. Peças impressas (3D)

| # | Peça | Ficheiro STL | Material | Qtd | Preço est. |
|---|------|--------------|----------|-----|------------|
| 1 | Corpo (caixa retrato) | `modelo-3d\corpo.stl` | PLA (protótipo) / PETG (final) | 1 | ~2–3 € |
| 2 | Placa traseira | `modelo-3d\placa_traseira.stl` | PLA / PETG | 1 | ~1 € |

## 2. Eletrónica

| # | Componente | Especificação | Qtd | Preço est. | Notas / pinos |
|---|------------|---------------|-----|------------|---------------|
| 1 | Microcontrolador | ESP32-WROOM (DevKit 30 pinos) | 1 | ~8–12 € | WiFi + BLE; alimentação 5V USB |
| 2 | Display TFT | ILI9341 240×320 (2.4") SPI | 1 | ~6–9 € | MOSI=23, SCLK=18, CS=15, DC=2, RST=4 |
| 3 | Backlight (PWM) | controlado por GPIO | — | incluído | PIN_BACKLIGHT=32 (brilho dia/noite) |
| 4 | Buzzer piezo | 5V, passivo (tone) | 1 | ~1 € | PIN_BUZZER=27 |
| 5 | Botão MUTE | push momentâneo | 1 | ~0,5 € | PIN_MUTE=13 (INPUT_PULLUP) |
| 6 | Botão NIGHT | push momentâneo | 1 | ~0,5 € | PIN_NIGHT=14 (INPUT_PULLUP) |
| 7 | Cabo USB | USB-A → micro-USB / USB-C | 1 | ~2 € | alimentação + saída traseira |
| 8 | Fonte 5V | carregador USB | 1 | ~5 € | ≥ 500 mA |

## 3. Fixação

| # | Componente | Especificação | Qtd | Preço est. | Notas |
|---|------------|---------------|-----|------------|-------|
| 1 | Parafuso M2 | cabeça chata, 6–8 mm | 4 | ~1 € | fixa o display (furos `furos_frente`) |
| 2 | Parafuso M2 | cabeça chata, 6–8 mm | 4 | ~1 € | fixa a placa traseira (postos internos) |
| 3 | Insert roscado M2 (opcional) | heat-set | 4 | ~2 € | reforço dos postos (PETG) |

## 4. Externo

| # | Componente | Especificação | Qtd | Preço est. | Notas |
|---|------------|---------------|-----|------------|-------|
| 1 | Sensor Dexcom G7 | CGM (Continuous Glucose Monitor) | 1 | ~60–90 €/mês | subscrição recorrente; dados via API Dexcom (WiFi) |
| 2 | App Dexcom | smartphone | 1 | grátis | necessário para obter o refresh token OAuth |

## 5. Consumíveis / ferramentas

- Fio de solda e jumpers (buzzer, botões, display): ~3 €
- Fita dupla-face ou cola (fixar o display, opcional): ~2 €
- Chave de fendas pequena (parafusos M2): ~3 €
- Filamento PLA/PETG (já incluído no custo das peças impressas)

---

## Total estimado

| Cenário | Total |
|---------|-------|
| **Hardware + impressão + fixação** (sem sensor) | **~25–35 €** |
| **Com sensor Dexcom G7** | **+60–90 €/mês** (subscrição) |

---

## Notas de montagem

- **Display:** ligar por SPI (ver pinos acima); o driver TFT_eSPI é configurado
  via `build_flags` no `platformio.ini`.
- **Buzzer:** piezo passivo ligado diretamente ao GPIO 27 (o firmware usa
  `tone()`); se usar buzzer ativo de maior corrente, adicionar transistor NPN.
- **Botões:** com `INPUT_PULLUP` — ligar entre o GPIO e GND (sem resistências externas).
- **Alimentação:** 5V pelo cabo USB (saída traseira da caixa); o ESP32 DevKit
  regula para 3.3V internamente.
- **Parafusos:** 4× M2 para o display + 4× M2 para a placa traseira (total 8).
- **Dexcom:** configurar `WIFI_SSID`, `WIFI_PASS`, `DEXCOM_CLIENT_ID` e
  `DEXCOM_REFRESH_TOKEN` em `firmware\src\config.h` (ver `firmware\README.md`).