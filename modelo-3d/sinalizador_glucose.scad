// ============================================================
//  Sinalizador de Glucose — caixa 3D (bedside)
//  Ficheiro: sinalizador_glucose.scad
//  Spec: ANALISE-SINALIZADOR-GLUCOSE.md §5
//
//  ACESSORIO INFORMATIVO — NAO e um dispositivo medico.
//
//  Impressao: face na mesa (sem suportes).
//  PLA (prototipo) / PETG (final).
//  Folgas 0.25 mm validas com pecas de teste na Bambu Lab.
// ============================================================

// ------------------------------------------------------------
// PARAMETROS GERAIS  (medidas em mm)
// ------------------------------------------------------------
larg        = 58;     // largura frontal  (X)
alt         = 76;     // altura frontal   (Y)
prof_ext    = 34;     // profundidade externa (Z) — fino
parede      = 1.8;    // espessura parede (spec: 1.6–2.0)
r           = 8;      // raio generoso (monolito suave, menos "quadrado")
angulo      = 20;     // cunha inclinada (spec: 15–30 graus)

// ------------------------------------------------------------
// ECRÃ  (display ILI9341 240x320 -> area visivel ~ 40x53)
// ------------------------------------------------------------
janel_l     = 44;     // abertura janela (X) — retrato (ecra 2.8" 320x240)
janel_a     = 58;     // abertura janela (Y)
janel_cx    = 0;      // centro janela em X (0 = centrado)
janel_cy    = 4;      // centro janela em Y (deslocado p/ cima)

// ------------------------------------------------------------
// PARAFUSOS M2 (placa + tampa)
// ------------------------------------------------------------
paraf_dx    = 36;     // distancia entre furos X
paraf_dy    = 52;     // distancia entre furos Y
paraf_d     = 2.4;    // furo M2 (com folga)

// ------------------------------------------------------------
// BOTAO (topo) — botao fisico unico opcional embutido
// ------------------------------------------------------------
bot_d       = 7.6;    // diametro furo botao

// ------------------------------------------------------------
// PLACA TRASEIRA
// ------------------------------------------------------------
placa_esp   = 2.4;    // espessura placa traseira
vent_l      = 24;     // comprimento fenda ventilacao
vent_a      = 2.5;    // altura fenda
vent_n      = 4;      // numero de fendas
usb_l       = 12;     // recorte saida USB (largura)
usb_a       = 7;      // recorte saida USB (altura)
postos_d    = 2.4;    // furo poste M2 traseiro

// ============================================================
//  NAO EDITAR ABAIXO
// ============================================================
prof_int = prof_ext - 2*parede;
$fn = 96;

// ------------------------------------------------------------
// perfil 2D da caixa no plano XZ (vista de lado)
// frente inclinada: base em z=0, topo deslocado p/ tras por alt*tan(angulo)
module perfil_lado() {
    off = alt * tan(angulo);
    // quadrilatero: base (z=0) .. topo (z=alt), profundidade prof_ext
    // frente inclinada: topo da frente recuado por alt*tan(angulo)
    polygon(points = [
        [0,       0],          // canto inferior tras
        [prof_ext, 0],         // canto inferior frente
        [prof_ext - off, alt], // topo frente (recuado pela inclinacao)
        [0,       alt]         // topo tras
    ]);
}

// --- Construcao real: extrudar o perfil lateral ao longo de X ---
module caixa_outer() {
    // perfil no plano (z,y) -> extrudar ao longo de X
    rotate([0, -90, 0])
        linear_extrude(height = larg, center = true)
            offset(r = r, $fn = 32)
                perfil_lado();
}

module caixa_inner() {
    // perfil interior: perfil exterior erodido por `parede`, depois arredondado
    rotate([0, -90, 0])
        linear_extrude(height = larg - 2*parede, center = true)
            offset(r = r, $fn = 32)
                offset(r = -parede, $fn = 32)
                    perfil_lado();
}

// ------------------------------------------------------------
// JANELA DO ECRÃ (abertura na face frontal inclinada)
// A face frontal esta inclinada `angulo`; cortamos perpendicular.
// ------------------------------------------------------------
module janela_cut() {
    // centro da janela na face frontal inclinada (deslocado p/ cima)
    yc = alt/2 + janel_cy;                    // altura do centro da janela
    zf = prof_ext + r - yc * tan(angulo);     // profundidade da face em yc
    translate([janel_cx, yc, zf])
        rotate([-angulo, 0, 0])
            cube([janel_l, janel_a, parede + 4], center = true);
}

// furos M2 na face frente (fixam a placa do display)
module furos_frente() {
    yc = alt/2 + janel_cy;
    zf = prof_ext + r - yc * tan(angulo);
    translate([janel_cx, yc, zf])
        rotate([-angulo, 0, 0])
            for (sx = [-1, 1], sy = [-1, 1])
                translate([sx*paraf_dx/2, sy*paraf_dy/2, 0])
                    cylinder(h = parede + 4, d = paraf_d, center = true);
}

// ------------------------------------------------------------
// BOTAO no topo (botao fisico unico opcional)
// ------------------------------------------------------------
module botoes_cut() {
    // botao fisico unico opcional, centrado no topo
    translate([0, alt/2, prof_ext*0.25])
        rotate([90, 0, 0])
            translate([0, 0, -alt])
                cylinder(h = alt + 4, d = bot_d, center = false);
}

// ------------------------------------------------------------
// Saida USB + alivio de tensao (canto inferior tras)
// ------------------------------------------------------------
module usb_cut() {
    // saida USB traseira (canto inferior esquerdo) + alivio de tensao
    translate([-larg/2 + parede + 20, alt*0.15, -r])
        cube([usb_l + 2, usb_a, parede + 8], center = true);
}

// ------------------------------------------------------------
// VENTILACAO — ranhuras discretas na parede traseira
// ------------------------------------------------------------
module ventilacao_cut() {
    for (i = [0 : vent_n - 1])
        translate([
            -vent_l/2,
            alt*0.35 + i*(vent_a + 3),
            -r
        ])
            cube([vent_l, vent_a, parede + 8], center = true);
}

// ------------------------------------------------------------
// PLACA TRASEIRA (removivel, 4 furos M2 + saida USB + ventilacao)
// ------------------------------------------------------------
module placa_traseira() {
    difference() {
        // placa: fecha a abertura traseira (folga 0.25 mm), face exterior ao nivel da caixa
        translate([0, alt/2, -r + placa_esp/2])
            cube([larg - 0.4, alt + 2*r - 0.4, placa_esp], center = true);

        // furos poste M2 (4 cantos, alinhados com os postos internos)
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx*(larg/2 - 8), alt/2 + sy*(alt/2 - 8), -r + placa_esp/2])
                cylinder(h = placa_esp + 2, d = postos_d, center = true);

        // fendas ventilacao (alinhadas com as da caixa)
        for (i = [0 : vent_n - 1])
            translate([-vent_l/2, alt*0.35 + i*(vent_a + 3), -r + placa_esp/2])
                cube([vent_l, vent_a, placa_esp + 2], center = true);

        // recorte USB (alinhado com a saida da caixa)
        translate([-larg/2 + parede + 20, alt*0.15, -r + placa_esp/2])
            cube([usb_l, usb_a, placa_esp + 2], center = true);
    }
}

// ------------------------------------------------------------
// POSTOS internos (fixacao da placa da placa eletronica)
// ------------------------------------------------------------
module glow_slot() {
    // fenda fina na base tras — saida do GLOW ambiente (LED RGB por baixo)
    translate([-18, 6, -r])
        cube([36, 2.5, parede + 6], center = true);
}

// Textura: por omissão monólito liso (premium minimal).
// Ative FLUTES=1 para nervuras verticais caneladas nos lados.
FLUTES = 0;

module fluted() {
    for (sx = [-1, 1])
        for (zz = [-r + 5 : flute_s : prof_ext + r - 8]) {
            ytop = (zz <= prof_ext - alt * tan(angulo))
                       ? alt + r
                       : alt * (prof_ext - zz) / (alt * tan(angulo)) + r;
            translate([sx * (larg/2 + flute_p - flute_r), (ytop - r) / 2, zz])
                cylinder(h = ytop + r, r = flute_r, center = true, $fn = 16);
        }
}

module postos() {
    for (sx = [-1, 1], sy = [-1, 1])
        translate([sx*(larg/2 - 8), alt/2 + sy*(alt/2 - 8), -r + parede])
            difference() {
                cylinder(h = 8, d = 6);
                translate([0, 0, -1]) cylinder(h = 10, d = postos_d);
            }
}

// ------------------------------------------------------------
// CORPO PRINCIPAL
// ------------------------------------------------------------
// Parametros da textura canelada (usada se FLUTES=1)
flute_s = 5.5;    // espacamento entre nervuras
flute_r = 1.7;    // raio da nervura
flute_p = 1.4;    // saliencia (quanto sobressai)

module corpo() {
    difference() {
        union() {
            caixa_outer();
            if (FLUTES == 1) fluted();   // nervuras caneladas (opcional)
        }
        caixa_inner();          // oco
        janela_cut();           // ecrã
        furos_frente();         // M2 display
        botoes_cut();           // botao
        usb_cut();              // saida USB
        ventilacao_cut();       // ranhuras
        glow_slot();            // saida do glow ambiente (base tras)
    }
    postos();                   // posts solidos (fixacao da placa)
}

// ============================================================
//  PECAS
//  - Peca 1: corpo  (ja com furos)
//  - Peca 2: placa traseira (imprimir a parte)
//  Para exportar: isolar cada modulo e exportar STL.
// ============================================================
corpo();
// placa_traseira();   // <- descomentar para exportar a placa (encaixe a parte)
