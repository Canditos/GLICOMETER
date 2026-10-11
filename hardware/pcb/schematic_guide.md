# GLICOMETER Pro v2.0 - Schematic & PCB Architecture Guide

Este documento contém o esquema elétrico completo e as ligações pista a pista (Netlist) para o desenho da PCB no **KiCad** ou **EasyEDA**.

---

## 1. Bloco de Gestão de Energia (Power & Battery Management)

```
                       +5V_USB (VBUS)
                            │
               ┌────────────┴────────────┐
               │                         │
               ▼                         ▼
         [ R1, R2 5.1k ]            [ D1 (SS34) ]
       (CC1 & CC2 para GND)              │
                                         ▼
                                   [ Q2 (AO3401A P-MOSFET) ]
                                         ▲
                                         │ Porta controlada por VBUS
                                         │
        [ J2 Bateria LiPo ] ───► [ TP4056 Charger ] ───► VBAT
                                  (R_PROG = 2.4k -> 500mA)  │
                                                            │
                                  ┌─────────────────────────┘
                                  ▼
                             [ AP2112K-3.3V ]
                                  │
                                  ▼
                              +3.3V_SYSTEM (Para ESP32 e LCD)
```

### Regras de Pistas de Alimentação:
- Linhas de alimentação `+5V_USB`, `VBAT` e `+3.3V`: **Largura mínima de 0.6 mm (24 mil)** para suportar picos de transmissão Wi-Fi até 500 mA sem queda de tensão.
- O pino `GND` deve ser conectado diretamente a um **plano de terra contínuo na camada inferior (Bottom Copper Plane)** através de vias térmicas.

---

## 2. Pinagem do ESP32-S3-WROOM-1 e Ligações

| Pino ESP32-S3 | Nome no Módulo | Ligação / Função | Notas Técnicas |
| :---: | :---: | :---: | :--- |
| **GND** | GND (Múltiplos) | Plano de Terra | Conectar todos os pads de terra ao plano inferior |
| **3V3** | 3V3 | +3.3V_SYSTEM | Capacitor de desacoplamento 10uF + 100nF próximo |
| **EN / CHIP_PU** | EN | R8 (10k ao 3.3V) + C6 (1uF ao GND) + SW1 (Reset) | Circuito RC de inicialização automática |
| **IO0** | GPIO 0 | SW2 (Boot / Snooze) + R9 (10k ao 3.3V) | Botão frontal multifunções e modo bootloader |
| **IO1** | GPIO 1 (ADC1) | Divisor LDR1 (Sensor de Luz) + R7 (10k ao GND) | Leitura analógica de luminosidade (0..4095) |
| **IO2** | GPIO 2 (ADC1) | Divisor R10/R11 (Medição Bateria) | Lê VBAT/2 (escala 0..2.1V compatível com ADC) |
| **IO4** | GPIO 4 | R6 (1k) -> Base de Q1 (S8050) | Acionamento do Buzzer de Alarme |
| **IO15**| GPIO 15 | LCD_CS (Chip Select) | Linha ativa baixa (SPI Display) |
| **IO16**| GPIO 16 | LCD_DC (Data / Command) | Seleção Comando/Dados |
| **IO17**| GPIO 17 | LCD_RST (Reset) | Hardware Reset do Ecrã |
| **IO18**| GPIO 18 | LCD_SCLK (SPI Clock) | Barramento SPI a 40 MHz |
| **IO19**| GPIO 19 | USB_D- (Pino A7/B7 da porta USB-C) | Comunicação e gravação USB nativa direta |
| **IO20**| GPIO 20 | USB_D+ (Pino A6/B6 da porta USB-C) | Comunicação e gravação USB nativa direta |
| **IO21**| GPIO 21 | LCD_BL_PWM (Controlo de Brilho) | Saída PWM para o pino LED do ecrã |
| **IO23**| GPIO 23 | LCD_MOSI (SPI Data Out) | Barramento SPI a 40 MHz |
| **IO38**| GPIO 38 | LED1 DIN (WS2812B NeoPixel) | Sinal de controlo de cor ambiente |

---

## 3. Conector do Display MSP3520 (Header Fêmea 14 Pinos na Borda Superior)

O ecrã MSP3520 encaixa diretamente por trás da moldura sobre estes 14 pinos alinhados:
```
Pino 1:  VCC    -> Liga a +5V_USB / VBAT (o ecrã tem o seu próprio LDO interno de 3.3V)
Pino 2:  GND    -> Liga ao Plano de Terra
Pino 3:  CS     -> Liga ao GPIO 15 do ESP32
Pino 4:  RESET  -> Liga ao GPIO 17 do ESP32
Pino 5:  DC/RS  -> Liga ao GPIO 16 do ESP32
Pino 6:  MOSI   -> Liga ao GPIO 23 do ESP32
Pino 7:  SCK    -> Liga ao GPIO 18 do ESP32
Pino 8:  LED/BL -> Liga ao GPIO 21 (PWM)
Pino 9:  MISO   -> (Opcional) Liga ao GPIO 19 se leitura de toque/SD for usada
Pinos 10..14:   -> Pinos do Controlador Touch XPT2046
```

---

## 4. Regras Críticas de Roteamento de Pistas (Layout PCB)

1. **Antena Wi-Fi (ESP32)**:
   - A extremidade da antena do módulo ESP32 **deve ficar saliente da borda da placa**, ou a área de cobre (todas as camadas) por baixo da antena tem de ser **completamente removida (Keepout Zone)**.
   - NUNCA colocar pistas de cobre, componentes ou planos de massa por baixo da área da antena PCB.
2. **Pistas SPI de Alta Velocidade (SCK e MOSI)**:
   - Roteadas o mais curtas e diretas possível.
   - Manter com comprimento equivalente e com plano de massa contínuo imediatamente por baixo (evita reflexões a 40 MHz).
3. **USB-C Diferencial (D+ e D-)**:
   - As pistas de D+ e D- devem correr em **par diferencial paralelo (comprimento idêntico)**, impedância aproximada de 90 Ω.
4. **Alimentação e Bateria**:
   - Colocar o conector JST e o circuito TP4056 na parte inferior da placa, deixando o centro livre para a bateria LiPo ficar acomodada entre a PCB e a parede traseira da caixa.
