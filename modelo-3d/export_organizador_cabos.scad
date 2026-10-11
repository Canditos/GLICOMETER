$fn = 64;

// =====================================================================
// ORGANIZADOR DE CABOS GLICOMETER (LCD <-> ESP32)
// Imprime em ~2 minutos na mesa em PETG (junto com os clips de retenção)
// 1. Pente Plano: Alinha e mantém os 10 fios do LCD em fita ordenada
// 2. Presilha em C: Agrupa o chicote para não ficar solto na caixa
// =====================================================================

module pente_cabos(num_fios = 10) {
    pitch      = 2.6; // passo entre fios (fio DuPont ~1.4mm)
    furo_w     = 1.5; // cavidade redonda para o fio
    fenda_ent  = 0.85; // abertura elástica snap
    esp        = 2.4; // espessura
    h_total    = 6.0; // altura
    larg_total = (num_fios + 1) * pitch;

    difference() {
        hull() {
            translate([-larg_total/2 + 2, 0, 0]) cylinder(r=2, h=esp);
            translate([ larg_total/2 - 2, 0, 0]) cylinder(r=2, h=esp);
            translate([-larg_total/2 + 2, h_total - 2, 0]) cylinder(r=2, h=esp);
            translate([ larg_total/2 - 2, h_total - 2, 0]) cylinder(r=2, h=esp);
        }

        for (i = [0 : num_fios - 1]) {
            x_pos = -larg_total/2 + (i + 1) * pitch;
            translate([x_pos, h_total/2 - 0.4, -0.1])
            cylinder(r=furo_w/2 + 0.1, h=esp + 0.2);

            translate([x_pos, h_total - 1.0, (esp+0.2)/2 - 0.1])
            cube([fenda_ent, 2.5, esp + 0.2], center=true);

            translate([x_pos, h_total + 0.1, -0.1])
            cylinder(r1=1.1, r2=fenda_ent/2, h=esp + 0.2);
        }
    }
}

module bracadeira_chicote() {
    w_int = 14.0;
    h_int = 5.0;
    wall  = 1.8;
    prof  = 6.0;

    difference() {
        hull() {
            translate([-w_int/2 - wall, 0, 0]) cylinder(r=wall, h=prof);
            translate([ w_int/2 + wall, 0, 0]) cylinder(r=wall, h=prof);
            translate([-w_int/2 - wall, h_int + wall, 0]) cylinder(r=wall, h=prof);
            translate([ w_int/2 + wall, h_int + wall, 0]) cylinder(r=wall, h=prof);
        }

        translate([0, (h_int + wall)/2, -0.1])
        cube([w_int, h_int, prof + 0.2], center=true);

        translate([0, h_int + wall*1.5, prof/2])
        cube([3.5, wall*2 + 0.2, prof + 0.2], center=true);
    }
}

// Exporta as 2 peças úteis:
translate([0, -8, 0]) pente_cabos(10);
translate([0, 10, 0]) bracadeira_chicote();

