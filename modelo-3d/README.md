# Sinalizador de Glucose — Caixa 3D

Caixa de mesa de cabeceira (bedside) para o sinalizador de glucose
(Dexcom G7 → ESP32-WROOM). Ficheiro: `sinalizador_glucose.scad`.

> **ACESSÓRIO INFORMATIVO — NÃO é um dispositivo médico.**

## Peças (2)

| Peça | Módulo | Descrição |
|------|--------|-----------|
| 1 — Corpo | `corpo()` | Caixa com janela do ecrã, 4 furos M2 do display, botão único no topo, saída USB e ranhuras de ventilação na traseira, postos internos M2 |
| 2 — Placa traseira | `placa_traseira()` | Tampa removível com 4 furos M2, fendas de ventilação e recorte USB alinhados com o corpo |

## Ficheiros STL (já exportados)

- `corpo.stl` — peça 1 (corpo com janela, botão, USB, ventilação e postos).
- `placa_traseira.stl` — peça 2 (tampa removível).

Para re-exportar após alterar parâmetros (OpenSCAD instalado em
`C:\Program Files\OpenSCAD\openscad.com`):

1. **Peça 1:** manter `corpo();` ativo na última linha e comentar
   `// placa_traseira();`. Executar **F6** (render) e **File → Export → Export as STL**.
2. **Peça 2:** comentar `// corpo();` e descomentar `placa_traseira();`. Exportar como STL.

## Impressão (Bambu Lab)

- **Material:** PLA (protótipo) / PETG (final).
- **Orientação:** face frontal na mesa — sem suportes.
- **Folgas:** 0.25 mm (validar com peças de teste).
- **Camada:** 0.2 mm; perímetros 3; preenchimento 15–20%.

## Montagem

1. Display ILI9341 (240×320) na janela frontal; fixar com 4 parafusos M2
   (furos `furos_frente`).
2. ESP32-WROOM no interior; cabo USB pela saída traseira (com alívio de tensão).
3. Botão único opcional no topo (furo `bot_d` = 7.6 mm).
4. Placa traseira com 4 parafusos M2 nos postos internos.

## Parâmetros principais (topo do ficheiro)

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| `larg` | 66 | Largura frontal (X) |
| `alt` | 86 | Altura frontal (Y) |
| `prof_ext` | 42 | Profundidade externa (Z) |
| `parede` | 1.8 | Espessura da parede |
| `r` | 4 | Raio dos cantos suaves |
| `angulo` | 20 | Inclinação do ecrã (15–30°) |
| `janel_l` / `janel_a` | 44 / 58 | Abertura da janela (retrato, ecrã 2.8") |
| `bot_d` | 7.6 | Diâmetro do furo do botão |
| `placa_esp` | 2.4 | Espessura da placa traseira |

## Conformidade com a spec (§5)

- Inclinação do ecrã: **20°** (spec 15–30°). ✓
- Dimensões: **66 × 94 × 50 mm** (larg × alt × prof, retrato, cantos `r=4`)
  — desenhado para o **ecrã TFT ILI9341 2.8"** (320×240, montado em retrato).
- Parede: **1.8 mm** (spec 1.6–2.0). ✓
- Janela embutida, sem moldura saliente. ✓
- **Um único botão opcional.** ✓
- Ventilação: ranhuras discretas na traseira. ✓
- Saída USB traseira com alívio de tensão. ✓
- Superfícies contínuas, cantos suaves, mate, uma cor, zero logos. ✓

## Notas de revisão

O modelo foi corrigido para alinhar todos os cortes às faces reais:

- **Interior oco** com parede uniforme de 1.8 mm (`caixa_inner` usa o perfil
  exterior erodido por `parede` e a mesma rotação da `caixa_outer`).
- **Janela e furos M2** centrados na face frontal inclinada (altura
  `alt/2 + janel_cy`, profundidade `prof_ext + r - yc·tan(angulo)`), corte
  perpendicular à face.
- **USB e ventilação** reposicionados na parede traseira (cortes passantes).
- **Placa traseira** fecha a abertura traseira (face exterior ao nível da
  caixa), com furos/fendas/recorte alinhados ao corpo.
- **Postos internos** reposicionados na parede traseira e unidos ao corpo
  (antes eram subtraídos, o que criava furos em vez de postos).
- **Botão único** centrado no topo (removidos os parâmetros `bot_x1`/`bot_x2`).
- **Recorte USB** afastado do furo M2 inferior-esquerdo (validação visual por
  render detetou sobreposição; corrigido com folga de ~5.6 mm).