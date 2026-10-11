# GLICOMETER Pro v2.2 Dual-Band & Voice-Ready • Schematic & PCB Guide

Placa com **ESP32-C5 Dual-Band (2.4 GHz + 5 GHz Wi-Fi 6)** com subsistema de **Áudio Digital I2S Integrado (Microfone MEMS + Amplificador Classe D de 3.2W)**.

---

## 1. Conceito Comercial de "Hardware-Ready, Software-Enabled"
A PCB inclui o circuito físico de voz e áudio desde o dia zero, o que permite:
- **Custos de Fabrico Mínimos**: Adicionar as pegadas e peças de áudio SMT acrescenta apenas ~1.10 € à placa.
- **Evolução Contínua via OTA**: Podes lançar o produto no mercado inicialmente como monitor visual e alarme sonoro por buzzer; mais tarde, ativas por atualização de firmware over-the-air (OTA) o controlo de voz, leitura falada de glicemia e integração com assistentes virtuais, sem nunca ter de alterar o hardware!

---

## 2. Subsistema de Áudio Digital I2S (Zero Ruído Analógico)

```
                     ┌────────────────────────┐
                     │     ESP32-C5 MCU       │
                     └────┬──────────────┬────┘
                          │              │
       Barramento I2S     │              │ Barramento I2S
       Entrada (Voz)      │              │ Saída (Fala / Alertas)
                          ▼              ▼
                   ┌──────────────┐┌──────────────┐
                   │  MSM261S4030 ││  MAX98357A   │ (Amplificador 3.2W)
                   │  Microfone   ││  Classe-D    │
                   │  MEMS I2S    │└──────┬───────┘
                   └──────────────┘       │
                                          ▼
                                   [ Mini Altifalante ]
                                   (1W 8Ω - 20mm Traseiro)
```

---

## 3. Mapeamento de Pinos Completo (Pinout Matrix Atualizado)

| Pino ESP32-C5 | Sinal de Circuito | Função no Sistema | Notas de Hardware |
| :---: | :---: | :--- | :--- |
| **GND** | Plano GND | Plano de terra contínuo inferior | Conectar todos os pads térmicos |
| **3V3** | +3.3V_SYSTEM | Alimentação desacoplada | 10uF + 100nF |
| **EN / CHIP_PU**| EN | Reset / Boot RC | R8 10k ao 3.3V + C8 1uF ao GND + SW1 |
| **IO0** | GPIO 0 | SW2 (Boot / Snooze / Mute) | Botão tátil multifunções |
| **IO1** | GPIO 1 (ADC) | Sensor de Luz LDR (GL5528) | Brilho adaptativo dia/noite |
| **IO2** | GPIO 2 (ADC) | Medição de Voltagem da Bateria | Divisor R10/R11 100k |
| **IO3** | GPIO 3 | Buzzer Ativo (Alarme Fallback) | Acionamento por Q1 S8050 |
| **IO4** | GPIO 4 | LCD_CS (Chip Select Ecrã) | SPI CS |
| **IO5** | GPIO 5 | LCD_DC (Data / Command) | SPI DC |
| **IO6** | GPIO 6 | LCD_RST (Hardware Reset) | Reset Ecrã |
| **IO7** | GPIO 7 | LCD_MOSI (SPI Master Out) | Dados SPI a 40 MHz |
| **IO8** | GPIO 8 | LCD_SCLK (SPI Clock) | Clock SPI a 40 MHz |
| **IO9** | GPIO 9 | LCD_BL_PWM (Backlight) | Controlo de intensidade do LCD |
| **IO10**| GPIO 10 | LED1 DIN (NeoPixel WS2812B) | Halo de luz ambiente na parede |
| **IO11**| I2S_BCLK | I2S Bit Clock (Partilhado) | Clock de áudio para Mic e Amp |
| **IO12**| I2S_LRCLK| I2S Word Select / LRCLK | Seleção canal Esquerdo/Direito |
| **IO13**| USB_D- | Linha USB Nativa D- | Ligação direta à porta USB-C |
| **IO14**| USB_D+ | Linha USB Nativa D+ | Ligação direta à porta USB-C |
| **IO15**| I2S_DATA_IN | I2S Mic Data In | Dados do microfone MEMS (voz) |
| **IO16**| I2S_DATA_OUT| I2S Amp Data Out | Dados para o amplificador MAX98357A |

---

## 4. Recursos Comerciais Permitidos pelo Subsistema de Áudio
1. **Leitura Falada da Glicemia**: Ao dar dois toques na caixa ou premir o botão, o monitor reproduz *"Glicemia 118, estável"*.
2. **Alarmes Sonoros Polifónicos**: Sons suaves de aviso para o dia e toques penetrantes mas não irritantes para o sono profundo.
3. **Comando de Voz Offline (Wake Word)**: Permite dizer *"Glico, silenciar"* sem sair da cama.
4. **Hardware-Ready**: Se a primeira versão do firmware ainda não tiver a IA de voz ativada, a placa já tem os componentes soldados — basta uma atualização por Wi-Fi (OTA) para ligar o recurso!
