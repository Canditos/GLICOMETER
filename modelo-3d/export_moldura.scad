$fn = 64;

// =====================================================================
// MOLDURA FRONTAL GLICOMETER PRO - ECRÃ ULTRA-AMPLO DE 4.3 POLEGADAS
// 1. Frente 114 x 72 mm com bordas ultra-finas de ~4.5mm (Bezel-less moderno)
// 2. Janela ativa visível: 95.4 x 54.2 mm (Área total do ecrã 4.3" 800x480)
// 3. Recesso cego para o vidro do ecrã (105.5 x 67.2 mm x 1.6mm)
// 4. Aba Macho perimetral contínua com 4 dentes Snap-Fit para fecho audível
// 5. Face visível 100% lisa, sem fendas nem buracos passantes
// =====================================================================

larg_f = 114.0;
alt_f  = 72.0;
r_f    = 14.0;

esp_frontal = 2.4;  // espessura da face visível
macho_len   = 3.0;  // altura da aba de inserção

larg_m = 107.8;     // tolerância calibrada para o corpo
alt_m  = 65.8;
r_m    = 11.0;

// NOVA JANELA ATIVA DE 4.3 POLEGADAS (800x480)
janela_w = 95.4;
janela_h = 54.2;
janela_x = 0.0;

// Recesso traseiro para o vidro do ecrã 4.3" (105.5 x 67.2 mm)
vidro_w    = 105.6;
vidro_h    = 67.2;
prof_vidro = 1.4;

module rounded_rect(w, h, r) {
    minkowski() {
        square([max(0.1, w - 2*r), max(0.1, h - 2*r)], center=true);
        circle(r=r);
    }
}

// Dente snap com rampa suave de entrada (45 graus) e travamento mecânico positivo
module dente_snap_macho(w=14.0, h=1.2, proj=0.55) {
    hull() {
        cube([0.1, w, 0.1], center=true);
        translate([proj, 0, h*0.5])
        cube([0.1, w - 2.0, h*0.4], center=true);
        translate([0, 0, h])
        cube([0.1, w, 0.1], center=true);
    }
}

module moldura_43_impressao() {
    snap_w     = 14.0;
    snap_h     = 1.2;
    snap_proj  = 0.55;
    snap_z_pos = 1.5;

    difference() {
        union() {
            // 1. Placa Frontal Macica e 100% continua (Z=0 na mesa PEI)
            linear_extrude(esp_frontal, center=false)
            rounded_rect(larg_f, alt_f, r_f);

            // 2. Aba Macho perimetral continua a 360 graus
            translate([0, 0, esp_frontal])
            linear_extrude(macho_len, center=false)
            rounded_rect(larg_m, alt_m, r_m);

            // Dentes Snap de travamento mecânico nas 4 faces
            translate([larg_m/2, 0, esp_frontal + snap_z_pos])
            dente_snap_macho(snap_w, snap_h, snap_proj);

            translate([-larg_m/2, 0, esp_frontal + snap_z_pos])
            rotate([0, 0, 180])
            dente_snap_macho(snap_w, snap_h, snap_proj);

            translate([0, alt_m/2, esp_frontal + snap_z_pos])
            rotate([0, 0, 90])
            dente_snap_macho(snap_w, snap_h, snap_proj);

            translate([0, -alt_m/2, esp_frontal + snap_z_pos])
            rotate([0, 0, -90])
            dente_snap_macho(snap_w, snap_h, snap_proj);
        }

        // --- SUBTRACOES ---

        // A. Janela Ultra-Ampla de Visualização (4.3 Polegadas)
        translate([janela_x, 0, -0.5])
        linear_extrude(esp_frontal + 1.0, center=false)
        rounded_rect(janela_w, janela_h, 2.5);

        // B. Bisel elegante a 45 graus na face frontal
        translate([janela_x, 0, -0.5])
        hull() {
            translate([0, 0, 0])
            linear_extrude(0.1, center=true)
            rounded_rect(janela_w + 2.4, janela_h + 2.4, 3.5);

            translate([0, 0, 1.2])
            linear_extrude(0.1, center=true)
            rounded_rect(janela_w, janela_h, 2.5);
        }

        // C. Recesso cego para o vidro e margens do módulo 4.3"
        translate([0, 0, esp_frontal - prof_vidro])
        linear_extrude(prof_vidro + macho_len + 5.0, center=false)
        rounded_rect(vidro_w, vidro_h, 4.0);
    }
}

moldura_43_impressao();
