$fn = 64;

// =====================================================================
// GLICOMETER MASTER V4 - DESIGN COMPLETO E FECHADO
// Moldura fechada a 360 graus (Sem dentes, sem cortes no degrau)
// Janela perfeitamente calibrada ao ecrã: 73.0 x 48.6 mm
// 4 Postes de bloqueio de 3.0mm nos furos 92.0 x 49.5 mm
// =====================================================================

// 1. PARAMETROS PRINCIPAIS
larg_f = 114.0;
alt_f  = 72.0;
r_f    = 14.0;
ang    = 18.0;

prof   = 62.0;
wall   = 2.8;

larg_t = 88.0;
alt_t  = 46.0;
r_t    = 16.0;

zc_f = (alt_f/2) * sin(90 - ang); // 34.238 mm -> borda inferior perfeita a Z=0
zc_t = alt_t/2;                   // 23.000 mm -> borda traseira perfeita a Z=0

// 2. ENCAIXE MACHO-FEMEA
prof_junta = 3.2;
esp_labio  = 2.8;
folga_rad  = 0.38;

femea_w = larg_f - 2*esp_labio;
femea_h = alt_f - 2*esp_labio;
femea_r = max(2, r_f - esp_labio);

macho_w = femea_w - 2*folga_rad;
macho_h = femea_h - 2*folga_rad;
macho_r = max(1.5, femea_r - folga_rad);
macho_len = prof_junta - 0.4;

// 3. PARAMETROS OFICIAIS MSP3520 (KMRTM3501)
pcb_w = 98.00;
pcb_h = 56.34;
lcd_hole_dx = 92.00;
lcd_hole_dy = 49.50;

janela_w = 73.0;
janela_h = 48.6;

module rounded_rect(w, h, r) {
    minkowski() {
        square([max(0.1, w - 2*r), max(0.1, h - 2*r)], center=true);
        circle(r=r);
    }
}

// ---------------------------------------------------------------------
// MODULO 1: MOLDURA FRONTAL COM BERCO DO LCD & POSTES DE BLOQUEIO
// ---------------------------------------------------------------------
module moldura_frontal() {
    difference() {
        union() {
            // Aba exterior
            hull() {
                translate([0, 0, 0])
                linear_extrude(1.2, center=false)
                rounded_rect(larg_f, alt_f, r_f);

                translate([0, 0, 1.2])
                linear_extrude(1.4, center=false)
                rounded_rect(larg_f - 1.2, alt_f - 1.2, r_f - 0.6);
            }

            // Labio macho
            translate([0, 0, -macho_len])
            hull() {
                translate([0, 0, 0])
                linear_extrude(0.8, center=false)
                rounded_rect(macho_w - 1.6, macho_h - 1.6, max(1, macho_r - 0.8));

                translate([0, 0, 0.8])
                linear_extrude(macho_len - 0.8, center=false)
                rounded_rect(macho_w, macho_h, macho_r);
            }

            // 4 Postes com ombro e pino de bloqueio
            for (x = [-lcd_hole_dx/2, lcd_hole_dx/2]) {
                for (y = [-lcd_hole_dy/2, lcd_hole_dy/2]) {
                    translate([x, y, -macho_len]) {
                        cylinder(r=3.0, h=macho_len);
                        translate([0, 0, -2.4])
                        cylinder(r1=1.40, r2=1.50, h=2.4);
                    }
                }
            }
        }

        // Janela calibrada para a area util do LCD
        hull() {
            translate([0, 0, -2.0])
            linear_extrude(0.1, center=true)
            rounded_rect(janela_w, janela_h, 2.0);

            translate([0, 0, 3.0])
            linear_extrude(0.1, center=true)
            rounded_rect(janela_w + 3.0, janela_h + 3.0, 3.5);
        }

        // Berco de assentamento do PCB
        translate([0, 0, -macho_len - 0.1])
        linear_extrude(macho_len - 1.4, center=false)
        square([pcb_w + 0.6, pcb_h + 0.6], center=true);

        // Recesso para o vidro frontal do LCD
        translate([0, 0, -1.4])
        linear_extrude(2.0, center=false)
        square([85.2, 55.8], center=true);

        // Alivio para a barra de 14 pinos SPI
        translate([-pcb_w/2 + 2, 0, -macho_len - 0.5])
        cube([14.0, 38.0, macho_len + 4], center=true);

        // Alivio para o leitor de cartao SD
        translate([pcb_w/2 - 2, 0, -macho_len - 0.5])
        cube([8.0, 20.0, macho_len + 4], center=true);

        // Furos para fixacao opcional M2
        for (x = [-lcd_hole_dx/2, lcd_hole_dx/2]) {
            for (y = [-lcd_hole_dy/2, lcd_hole_dy/2]) {
                translate([x, y, -macho_len - 3.0])
                cylinder(r=0.95, h=macho_len + 5.0);
            }
        }
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
        translate([0, -dist_y/2 - 2.8, (h_elev + 2.0)/2]) cube([14, 1.8, h_elev + 2.0], center=true);
        translate([0,  dist_y/2 + 2.8, (h_elev + 2.0)/2]) cube([14, 1.8, h_elev + 2.0], center=true);
    }
}

// ---------------------------------------------------------------------
// MODULO 3: CORPO ELEGANTE 100% FECHADO (INTEGRIDADE TOTAL)
// ---------------------------------------------------------------------
module corpo_clean() {
    rad_ang = ang * 3.14159265 / 180;
    ny = sin(ang);
    nz = -cos(ang);

    union() {
        difference() {
            // 1. Envelope Exterior continuo
            hull() {
                translate([0, 0, zc_f])
                rotate([90 - ang, 0, 0])
                linear_extrude(0.1, center=true)
                rounded_rect(larg_f, alt_f, r_f);

                translate([0, prof, zc_t])
                rotate([90, 0, 0])
                linear_extrude(0.1, center=true)
                rounded_rect(larg_t, alt_t, r_t);
            }

            // 2. Cavidade Interior
            hull() {
                translate([0, prof_junta * ny, zc_f + prof_junta * nz])
                rotate([90 - ang, 0, 0])
                linear_extrude(0.1, center=true)
                rounded_rect(femea_w - 6.0, femea_h - 6.0, max(1.5, femea_r - 3.0));

                translate([0, prof - wall, zc_t])
                rotate([90, 0, 0])
                linear_extrude(0.1, center=true)
                rounded_rect(larg_t - 2*wall, alt_t - 2*wall, max(1.5, r_t - wall));
            }

            // 3. Degrau Femea Frontal fechado a toda a volta (sem dentes!)
            translate([0, 0, zc_f])
            rotate([90 - ang, 0, 0])
            translate([0, 0, -prof_junta/2])
            linear_extrude(prof_junta + 0.1, center=true)
            rounded_rect(femea_w, femea_h, femea_r);

            // 4. Saida USB Traseira
            translate([0, prof + 2, wall + 5.5])
            cube([14.0, 10.0, 9.0], center=true);
        }

        // Suporte do ESP32 no piso
        suporte_esp32(30.0);
    }
}

module montagem_completa() {
    color([0.35, 0.35, 0.38]) corpo_clean();

    translate([0, 0, zc_f])
    rotate([90 - ang, 0, 0])
    color([0.92, 0.92, 0.95])
    moldura_frontal();
}

montagem_completa();
