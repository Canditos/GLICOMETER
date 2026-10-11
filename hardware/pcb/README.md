# GLICOMETER Carrier Board (Hardware v2.0 Pro)

Placa de circuito impresso personalizada (Carrier Board) projetada para eliminar os 10 fios DuPont soltos e transformar o GLICOMETER num produto comercializável montado em menos de 60 segundos.

---

## 1. Visão Geral da Arquitetura
A placa atua como ponte rígida entre o microcontrolador **ESP32** e o ecrã **MSP3520 (ILI9488 3.5")**, integrando no mesmo PCB:
- **Conector do Ecrã**: Header fêmea de 14 pinos passo 2.54 mm onde o ecrã encaixa diretamente de costas.
- **Encaixe do ESP32**: Soquete para ESP32 DevKit V1 (30 ou 38 pinos) ou footprint direto para ESP32-WROOM-32E / ESP32-S3.
- **Sub-sistema de Alimentação & Bateria**:
  - IC de Carga Li-Ion / LiPo: **TP4056** ou **IP5306** com conector JST-PH 2.0mm.
  - Regulador LDO de Baixo Dropout: **AP2112K-3.3V** (600mA pico, ultra baixo ruído para SPI estável a 40 MHz).
  - Porta **USB-C** de montagem em superfície com resistências de pulldown CC1/CC2 de 5.1 kΩ (compatível com carregadores USB-PD modernos).
- **Sub-sistema de Alarme & Conforto**:
  - Buzzer Piezoelétrico Ativo (5V/3.3V com transistor de comutação NPN S8050 e díodo flyback 1N4148).
  - Sensor de Luz Ambiente (LDR GL5528 ou fototransistor) para escurecimento automático do ecrã (auto-dimming noturno).
  - LED RGB NeoPixel (WS2812B) para "Glow" ambiental projetado na parede com o código de cores da glicemia.
  - Botão multifunções (Snooze / Mute / Reset Wi-Fi).

---

## 2. Mapa de Conexões da PCB (Schematic Netlist)

### A. Interface Display (MSP3520 Header 14-pin)
| Pino LCD | Nome do Sinal | Ligação na PCB | Função |
| :---: | :---: | :---: | :--- |
| **1** | **VCC** | **+5V / VBUS** | Entrada regulador LDO interno do ecrã |
| **2** | **GND** | **GND** | Plano de massa contínuo |
| **3** | **CS** | **GPIO 15** | Chip Select Display |
| **4** | **RESET** | **GPIO 4** | Reset por hardware |
| **5** | **DC/RS** | **GPIO 2** | Data / Command |
| **6** | **SDI (MOSI)**| **GPIO 23** | SPI Master Out |
| **7** | **SCK** | **GPIO 18** | SPI Clock (40 MHz) |
| **8** | **LED** | **Q1 (PWM GPIO 32)** | Controlo de luminosidade Backlight |
| **9** | **SDO (MISO)**| **GPIO 19** | SPI Master In |
| **10**| **T_CLK** | **GPIO 18** (Partilhado)| Touch Clock |
| **11**| **T_CS** | **GPIO 5** | Touch Chip Select |
| **12**| **T_DIN** | **GPIO 23** (Partilhado)| Touch Data In |
| **13**| **T_DO** | **GPIO 19** (Partilhado)| Touch Data Out |
| **14**| **T_IRQ** | **GPIO 25** | Interrupção de Toque |

### B. Periféricos da Placa
| Periférico | Circuito / Componente | GPIO ESP32 | Função |
| :--- | :--- | :---: | :--- |
| **Buzzer** | NPN S8050 + Resistor 1kΩ | **GPIO 27** | Alarmes sonoros de Hipo/Hiper |
| **Sensor de Luz** | LDR em divisor de tensão (10kΩ) | **GPIO 34 (ADC1_CH6)** | Leitura de iluminação ambiente |
| **Botão Frontal** | Botão tátil 6x6mm com capacitor 100nF | **GPIO 13** | Silenciar alarme (Snooze/Mute) |
| **LED Ambiente** | WS2812B 5050 RGB | **GPIO 33** | Iluminação ambiente colorida |
| **Medição Bateria** | Divisor resistivo 100kΩ / 100kΩ | **GPIO 35 (ADC1_CH7)** | Monitor de percentagem da bateria |

---

## 3. Especificações Físicas para Fabrico (JLCPCB / PCBWay)
- **Dimensões**: 85.0 mm × 60.0 mm
- **Número de Camadas**: 2 camadas (Layer 1: Sinais + Alimentação; Layer 2: Plano de Massa GND sólido)
- **Espessura da Placa**: 1.6 mm (FR-4 standard)
- **Acabamento de Superfície**: HASL Lead-Free ou ENIG (ouro de imersão)
- **Cor da Máscara de Solda**: Preto Mate (Matte Black) para acabamento comercial de luxo
- **Furos de Montagem**: 4x furos passantes M2.5 coincidentes com os postes da caixa 3D.
