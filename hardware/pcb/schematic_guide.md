# GLICOMETER Pro v3.0 • Esquema Eletrónico Oficial JLCPCB (Ecrã 4.3" IPS + ESP32-S3)

Documento mestre de arquitetura para fabrico SMT robotizado na **JLCPCB**.

---

## 1. Visão Geral do Sistema
- **Microcontrolador**: **ESP32-S3-WROOM-1-N8R8** (240 MHz Dual-Core, 8MB PSRAM Octal, 8MB Flash).
- **Interface do Ecrã**: **FPC 40 Pinos Passo 0.5 mm** ligado diretamente ao periférico RGB/SPI nativo do ESP32-S3 para conduzir o ecrã IPS de 4.3" (480x272) a 60 fps.
- **Gestão de Energia**: **TP4056** + Comutação P-MOSFET **AO3401A** + Regulador LDO de 3.3V **ME6211C33M5G-N**.
- **Alimentação**: Célula Li-Ion **21700 de 5000 mAh** (via contactos de mola Keystone sem soldadura na bateria).
- **Áudio Digital**: Amplificador I2S **MAX98357A (3.2W)** com conector JST para micro-altifalante de caixa 1511.
- **Alarmes e Sensores**: Buzzer magnético ativo, Sensor de Luz LDR (GL5528), NeoPixel RGB (WS2812B) e Botão de Snooze de topo.

---

## 2. Mapa de Conexões do Conector FPC de 40 Pinos (Ecrã 4.3" IPS)

| Pino FPC | Nome do Sinal | Ligação na PCB / ESP32-S3 | Função |
| :---: | :---: | :---: | :--- |
| **1 - 2** | **VLED- (LEDK)**| **GND** | Catodo do Backlight |
| **3 - 4** | **VLED+ (LEDA)**| **+5V_VBUS / VBAT via Q_BL (PWM GPIO 21)**| Ânodo do Backlight |
| **5 - 8** | **GND** | **Plano de Terra Geral** | Blindagem e retorno |
| **9** | **DISP / CS** | **GPIO 15** | Ativação do Display |
| **10** | **CLK / PCLK** | **GPIO 18** | Pixel Clock (9 MHz para 480x272) |
| **11** | **HSYNC** | **GPIO 17** | Sincronismo Horizontal |
| **12** | **VSYNC** | **GPIO 16** | Sincronismo Vertical |
| **13** | **DE** | **GPIO 4** | Data Enable |
| **14 - 19**| **B3 - B7** | **GPIO 5, 6, 7, 8, 9** | Barramento de Cor Azul (Blue) |
| **20 - 25**| **G2 - G7** | **GPIO 10, 11, 12, 13, 14, 21**| Barramento de Cor Verde (Green) |
| **26 - 31**| **R3 - R7** | **GPIO 38, 39, 40, 41, 42** | Barramento de Cor Vermelha (Red) |
| **32 - 34**| **GND** | **Plano de Terra Geral** | Massa |
| **35** | **VCC (3.3V)** | **+3.3V_SYSTEM (ME6211)** | Alimentação digital da lógica do ecrã |
| **36 - 40**| **NC / GND** | **GND** | Pinos não conectados / terra |

---

## 3. Sub-sistema de Bateria 21700 & Alimentação USB-C

```
[ Porta USB-C ] ──┬──> [ D1 (SS34) ] ──> [ Q2 AO3401A P-MOSFET ] ──> [ VSYS ] ──> [ ME6211 (3.3V) ] ──> ESP32-S3
                  │                                ▲
                  └──> [ TP4056 (Carga) ]          │ (Comuta automaticamente entre USB e Bateria)
                             │                     │
                             ▼                     │
                  [ Bateria 21700 (5000 mAh) ] ────┘
                  (Contactos de Mola J2 Keystone)
```

---

## 4. Sub-sistema de Áudio & Alarme Noturno

- **Amplificador MAX98357A**:
  - `BCLK` ➔ **GPIO 1**
  - `LRCLK` ➔ **GPIO 2**
  - `DIN` ➔ **GPIO 3**
  - `OUTP / OUTN` ➔ Conector `SPK1` (Micro-altifalante 1511).
- **Botão Snooze de Topo (SW2)**:
  - Ligado ao **GPIO 0** com pull-up interno e capacitor de debounce de 100nF ao GND.
- **Buzzer Magnético (BZ1)**:
  - Acionado pelo transistor `Q1 (S8050)` com base ligada ao **GPIO 47**.
