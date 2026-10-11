$fn = 64;

// 1. PARAMETROS GERAIS
larg_f = 114.0;
alt_f  = 72.0;
r_f    = 14.0;
ang    = 18.0;

prof   = 62.0;
wall   = 2.8;

larg_t = 88.0;
alt_t  = 46.0;
r_t    = 16.0;

// 2. ENCAIXE MACHO-FEMEA
prof_junta = 3.2;   // profundidade do rebaixo femea
esp_labio  = 2.8;   // espessura da parede do labio
folga_rad  = 0.38;  // folga radial para deslizamento suave FDM

femea_w = larg_f - 2*esp_labio;          // 108.4 mm
femea_h = alt_f - 2*esp_labio;           // 66.4 mm
femea_r = max(2, r_f - esp_labio);       // 11.2 mm

macho_w = femea_w - 2*folga_rad;         // 107.64 mm
macho_h = femea_h - 2*folga_rad;         // 65.64 mm
macho_r = max(1.5, femea_r - folga_rad); // 10.82 mm
macho_len = prof_junta - 0.4;            // 2.8 mm

// 3. PARAMETROS OFICIAIS MSP3520 (KMRTM3501)
pcb_w = 98.00;
pcb_h = 56.34;
lcd_hole_dx = 92.00; // BLUEPRINT EXATO
lcd_hole_dy = 49.50; // BLUEPRINT EXATO

janela_w = 75.0;
janela_h = 50.5;

module rounded_rect(w, h, r) {
    minkowski() {
        square([max(0.1, w - 2*r), max(0.1, h - 2*r)], center=true);
        circle(r=r);
    }
}

// ---------------------------------------------------------------------
// MODULO 1: MOLDURA FRONTAL COM BERCO E ENCAIXE MACHO
// ---------------------------------------------------------------------
module moldura_frontal() {
    difference() {
        union() {
            // Aba exterior (bezel visivel)
            hull() {
                translate([0, 0, 0])
                linear_extrude(1.2, center=false)
                rounded_rect(larg_f, alt_f, r_f);

                translate([0, 0, 1.2])
                linear_extrude(1.4, center=false)
                rounded_rect(larg_f - 1.2, alt_f - 1.2, r_f - 0.6);
            }

            // Labio macho de insercao no corpo
            translate([0, 0, -macho_len])
            hull() {
                // Chanfro guia de 45 graus para entrar sem esforco
                translate([0, 0, 0])
                linear_extrude(0.8, center=false)
                rounded_rect(macho_w - 1.6, macho_h - 1.6, max(1, macho_r - 0.8));

                translate([0, 0, 0.8])
                linear_extrude(macho_len - 0.8, center=false)
                rounded_rect(macho_w, macho_h, macho_r);
            }

            // 4 Postes para os furos de 92.0 x 49.5 mm
            for (x = [-lcd_hole_dx/2, lcd_hole_dx/2]) {
                for (y = [-lcd_hole_dy/2, lcd_hole_dy/2]) {
                    translate([x, y, -macho_len]) {
                        cylinder(r=2.5, h=macho_len);
                        // Pino de centralizacao calibrado para furo de 3.2mm
                        translate([0, 0, -1.8])
                        cylinder(r1=1.45, r2=1.30, h=1.8);
                    }
                }
            }
        }

        // Janela visivel com chanfro elegante
        hull() {
            translate([0, 0, -2.0])
            linear_extrude(0.1, center=true)
            rounded_rect(janela_w, janela_h, 2.0);

            translate([0, 0, 3.0])
            linear_extrude(0.1, center=true)
            rounded_rect(janela_w + 3.0, janela_h + 3.0, 3.5);
        }

        // Berco para o PCB do LCD (98.8 x 57.14 mm)
        translate([0, 0, -macho_len - 0.1])
        linear_extrude(macho_len - 1.4, center=false)
        square([pcb_w + 0.8, pcb_h + 0.8], center=true);

        // Recesso mais profundo para o vidro/touch
        translate([0, 0, -1.4])
        linear_extrude(2.0, center=false)
        square([86.0, pcb_h + 0.8], center=true);

        // ABERTURA TOTAL DE ALIVIO PARA OS 14 PINOS SPI (borda esquerda)
        translate([-pcb_w/2 + 2, 0, -macho_len - 0.5])
        cube([14.0, 38.0, macho_len + 2], center=true);

        // ABERTURA DE ALIVIO PARA OS 4 PINOS DO CARTAO SD (borda direita)
        translate([pcb_w/2 - 2, 0, -macho_len - 0.5])
        cube([8.0, 20.0, macho_len + 2], center=true);
    }
}

// ---------------------------------------------------------------------
// MODULO 2: SUPORTE INTERIOR DO ESP32 (30 PINOS)
// ---------------------------------------------------------------------
module suporte_esp32(y_pos=30.0) {
    dist_x = 23.0;
    dist_y = 47.0;
    h_elev = 4.0;
    
    translate([0, y_pos, wall]) {
        for (x = [-dist_x/2, dist_x/2]) {
            for (y = [-dist_y/2, dist_y/2]) {
                translate([x, y, 0]) {
                    cylinder(r=2.6, h=h_elev);
                    translate([0, 0, h_elev])
                    cylinder(r1=1.35, r2=1.1, h=2.5);
                }
            }
        }
        // Batentes longitudinais de retencao
        translate([0, -dist_y/2 - 2.8, (h_elev + 2.0)/2]) cube([14, 1.8, h_elev + 2.0], center=true);
        translate([0,  dist_y/2 + 2.8, (h_elev + 2.0)/2]) cube([14, 1.8, h_elev + 2.0], center=true);
    }
}

// ---------------------------------------------------------------------
// MODULO 3: CORPO SOLIDO IMPRIMIVEL (ZERO BALANCOS > 30 GRAUS)
// ---------------------------------------------------------------------
module corpo_clean() {
    zc_f = (alt_f/2) * sin(90 - ang) + 4.0;
    yc_f = 0;

    union() {
        difference() {
            // Envelope Exterior
            hull() {
                // Frente inclinada a 18 graus
                translate([0, yc_f, zc_f])
                rotate([90 - ang, 0, 0])
                linear_extrude(0.1, center=true)
                rounded_rect(larg_f, alt_f, r_f);

                // Traseira vertical/suave
                translate([0, prof, (alt_t/2) + 2.0])
                rotate([90, 0, 0])
                linear_extrude(0.1, center=true)
                rounded_rect(larg_t, alt_t, r_t);

                // Base 100% plana na mesa (Z=0 a Z=2mm)
                translate([0, prof*0.48, 1.0])
                linear_extrude(2.0, center=true)
                rounded_rect(larg_f - 12, prof - 6, 12);
            }

            // Cavidade Interior
            translate([0, 0, wall])
            hull() {
                translate([0, yc_f + wall*0.35, zc_f - wall])
                rotate([90 - ang, 0, 0])
                linear_extrude(0.1, center=true)
                rounded_rect(larg_f - 2*wall, alt_f - 2*wall, max(1.5, r_f - wall));

                translate([0, prof - wall, (alt_t/2) + 2.0 - wall*0.5])
                rotate([90, 0, 0])
                linear_extrude(0.1, center=true)
                rounded_rect(larg_t - 2*wall, alt_t - 2*wall, max(1.5, r_t - wall));

                translate([0, prof*0.48, 1.0])
                linear_extrude(2.0, center=true)
                rounded_rect(larg_f - 12 - 2*wall, prof - 6 - 2*wall, max(1.5, 12 - wall));
            }

            // REBAIXO FEMEA FRONTAL (Encaixa com o labio macho da moldura)
            translate([0, yc_f, zc_f])
            rotate([90 - ang, 0, 0]) {
                // Abertura do recesso femea
                translate([0, 0, -prof_junta/2])
                linear_extrude(prof_junta + 0.1, center=true)
                rounded_rect(femea_w, femea_h, femea_r);

                // Abertura central passante para os componentes e fios entrarem
                translate([0, 0, -15])
                linear_extrude(25, center=true)
                rounded_rect(femea_w - 6.0, femea_h - 6.0, max(1.0, femea_r - 3.0));
            }

            // Saida USB na parede traseira
            translate([0, prof + 2, wall + 5.5])
            cube([14.0, 10.0, 9.0], center=true);
        }

        // Suporte do ESP32 no chao
        suporte_esp32(30.0);
    }
}

// ---------------------------------------------------------------------
// MONTAGEM FINAL EM POSICAO REAL
// ---------------------------------------------------------------------
module montagem_completa() {
    zc_f = (alt_f/2) * sin(90 - ang) + 4.0;
    
    color([0.30, 0.30, 0.34]) corpo_clean();

    translate([0, 0, zc_f])
    rotate([90 - ang, 0, 0])
    color([0.92, 0.92, 0.95])
    moldura_frontal();
}

montagem_completa();
