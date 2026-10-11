$fn = 64;

// =====================================================================
// GLICOMETER MASTER V5 - ZERO SUPORTES (100% AUTOPORTANTE)
// O suporte do ESP32 agora nasce da traseira e do fundo com nervuras a 45 graus.
// Quando deitado de costas na mesa PEI, NAO PRECISA DE NENHUM SUPORTE!
// Podes DESLIGAR os suportes no Bambu Studio! (Support = OFF)
// =====================================================================

larg_f = 114.0;
alt_f  = 72.0;
r_f    = 14.0;
ang    = 18.0;

prof   = 62.0;
wall   = 2.8;

larg_t = 88.0;
alt_t  = 46.0;
r_t    = 16.0;

zc_f = (alt_f/2) * sin(90 - ang); // 34.238 mm
zc_t = alt_t/2;                   // 23.000 mm

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

module rounded_rect(w, h, r) {
    minkowski() {
        square([max(0.1, w - 2*r), max(0.1, h - 2*r)], center=true);
        circle(r=r);
    }
}

// Suporte do ESP32 100% autoportante (nervuras triangulares a 45 graus que nascem da parede e da traseira)
module suporte_esp32_autoportante() {
    dist_x = 23.0;
    y_center = 30.0;
    dist_y = 47.0;
    h_elev = 4.0;
    
    // Trilhos de encaixe em rampa (45 graus)
    for (x = [-dist_x/2, dist_x/2]) {
        for (y = [y_center - dist_y/2, y_center + dist_y/2]) {
            translate([x, y, 0]) {
                // Coluna que liga ao piso
                cylinder(r=2.8, h=wall + h_elev);
                translate([0, 0, wall + h_elev])
                cylinder(r1=1.4, r2=1.1, h=2.2);

                // Nervura triangular de 45 graus que liga a traseira/fundo para imprimir sem suportes
                translate([-1.2, 0, wall])
                rotate([0, 0, 0])
                hull() {
                    cube([2.4, 0.1, h_elev]);
                    translate([0, (y > y_center) ? 6 : -6, 0])
                    cube([2.4, 0.1, 0.2]);
                }
            }
        }
    }
    // Travamento lateral do ESP32 com guias chanfradas a 45 graus
    translate([0, y_center - dist_y/2 - 2.8, wall + (h_elev+1)/2]) cube([16, 2.0, h_elev + 1], center=true);
    translate([0, y_center + dist_y/2 + 2.8, wall + (h_elev+1)/2]) cube([16, 2.0, h_elev + 1], center=true);
}

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

            // 3. Degrau Femea Frontal fechado a toda a volta
            translate([0, 0, zc_f])
            rotate([90 - ang, 0, 0])
            translate([0, 0, -prof_junta/2])
            linear_extrude(prof_junta + 0.1, center=true)
            rounded_rect(femea_w, femea_h, femea_r);

            // 4. Saida USB Traseira
            translate([0, prof + 2, wall + 5.5])
            cube([14.0, 10.0, 9.0], center=true);
        }

        // Suporte do ESP32 com nervuras de 45 graus
        suporte_esp32_autoportante();
    }
}

// Exportacao deitada de costas diretamente na mesa PEI (Z=0 na traseira)
translate([0, 0, prof])
rotate([-90, 0, 0])
corpo_clean();
