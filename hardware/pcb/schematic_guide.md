# GLICOMETER Pro v2.1 Dual-Band • Schematic & PCB Architecture Guide

Projeto com **ESP32-C5-WROOM-1**: Primeiro microcontrolador com suporte nativo a **Wi-Fi 6 Dual-Band (2.4 GHz e 5.0 GHz)**, eliminando falhas de conexão em routers modernos de operadoras (MEO, NOS, Vodafone, etc.).

---

## 1. Porquê o ESP32-C5 Dual-Band?
Nos dispositivos IoT convencionais (que apenas suportam 2.4 GHz), os clientes finais sofrem com:
- Redes Wi-Fi com "Smart Wi-Fi / Band Steering" que forçam clientes para 5 GHz, impedindo a ligação do dispositivo.
- Congestionamento severo da banda de 2.4 GHz em prédios de apartamentos.
- Necessidade de aceder à página de configuração do router para separar as redes em dois nomes diferentes (o que a maioria dos utilizadores não sabe fazer).

Com o **ESP32-C5 Dual-Band**, o GLICOMETER liga-se de imediato tanto a redes de 2.4 GHz como de 5 GHz sem qualquer configuração adicional no router.

---

## 2. Diagrama de Blocos de Hardware

```
                       [ PORTA USB-C (16-Pin) ]
                                  │
         ┌────────────────────────┼────────────────────────┐
         │ D+ / D-                │ VBUS (+5V)             │ CC1/CC2
         ▼                        ▼                        ▼
 [ USB Nativo no C5 ]      [ D1 SS34 ]              [ 2x 5.1k Resistors ]
 (GPIO 13 & GPIO 14)              │
                                  ▼
                         [ Q2 P-MOSFET AO3401A ] ◄── (Auto Power Path)
                                  ▲
                                  │
[ J2 Conector LiPo ] ──► [ TP4056 Carregador ] ──► VBAT
                          (R_PROG = 2.4k -> 500mA)    │
                                                      │
                                                      ▼
                                              [ AP2112K-3.3V ] (LDO 600mA)
                                                      │
                                                      ▼
                                           +3.3V_SYSTEM (Alimentação Principal)
                                                      │
    ┌─────────────────────────┬───────────────────────┼──────────────────────┐
    ▼                         ▼                       ▼                      ▼
[ ESP32-C5-WROOM-1 ]   [ Header MSP3520 ]    [ Buzzer Ativo ]      [ LDR Sensor ]
(2.4GHz + 5GHz Wi-Fi)  (Ecrã TFT 3.5" SPI)    (Alarme Noturno)     (Auto-Dimming)
```

---

## 3. Mapeamento de Pinos do ESP32-C5 (Pinout Matrix)

| Pino ESP32-C5 | Sinal de Circuito | Função no Sistema |
| :---: | :---: | :--- |
| **GND** | Plano GND | Plano de terra contínuo inferior |
| **3V3** | +3.3V_SYSTEM | Alimentação desacoplada com 10uF + 100nF |
| **EN / CHIP_PU**| EN | Circuito RC (R8 10k ao 3.3V + C6 1uF ao GND) + SW1 (Reset) |
| **IO0** | GPIO 0 | SW2 (Boot / Snooze / Mute) |
| **IO1** | GPIO 1 (ADC) | Sensor de Luz LDR (GL5528) para brilho adaptativo |
| **IO2** | GPIO 2 (ADC) | Medição de Voltagem da Bateria (Divisor R10/R11 100k) |
| **IO3** | GPIO 3 | Acionamento do Buzzer de Alarme (via Transistor Q1 S8050) |
| **IO4** | GPIO 4 | LCD_CS (Chip Select do Ecrã) |
| **IO5** | GPIO 5 | LCD_DC (Data / Command) |
| **IO6** | GPIO 6 | LCD_RST (Hardware Reset do Ecrã) |
| **IO7** | GPIO 7 | LCD_MOSI (SPI Data Out a 40 MHz) |
| **IO8** | GPIO 8 | LCD_SCLK (SPI Clock a 40 MHz) |
| **IO9** | GPIO 9 | LCD_BL_PWM (Controlo de Retroiluminação do Ecrã) |
| **IO10**| GPIO 10 | LED1 DIN (Controlo do NeoPixel WS2812B) |
| **IO13**| USB_D- | Linha de Dados USB Nativa (D-) ligada diretamente à porta USB-C |
| **IO14**| USB_D+ | Linha de Dados USB Nativa (D+) ligada diretamente à porta USB-C |

---

## 4. Regras Críticas de RF Dual-Band (2.4 GHz & 5.0 GHz)
A transmissão em 5 GHz é mais sensível a atenuações e descontinuidades dielétricas do que a 2.4 GHz:
1. **Zona de Exclusão da Antena (RF Keepout Zone)**:
   - A ponta da antena PCB do módulo ESP32-C5 **tem de ficar 100% fora do plano de terra e da placa**, ou a área do substrato FR4 por baixo da antena tem de ter **zero cobre em todas as camadas (Top, Bottom e planos internos)**.
   - NUNCA passar pistas de sinal ou de alimentação a menos de 4 mm da área da antena.
2. **Pistas de Dados USB**:
   - As linhas `USB_D+` e `USB_D-` devem ter traçado diferencial paralelo estrito de 90 Ω de impedância com o plano de terra inferior contínuo como referência.
3. **Plano de Terra Contínuo (Solid Ground Plane)**:
   - A camada inferior da placa (Bottom Layer) deve ser preenchida a 100% com plano de terra GND, unida por múltiplas vias de terra ao redor do módulo ESP32-C5 para dissipação térmica e blindagem de ruído.
