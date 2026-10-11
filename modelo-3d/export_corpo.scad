$fn = 64;

// =====================================================================
// CORPO GLICOMETER MASTER V6 - COM ALTIFALANTE E GRELHA ACÚSTICA INTEGRADA
// 1. Envelope exterior continuo com base plana na mesa PEI (Z=0)
// 2. Berco interno para micro-altifalante 1511 (15x11x3.5mm)
// 3. Grelha acustica com furos de 1.2mm no painel traseiro inclinado
// 4. Degrau femea frontal com 4 cavidades snap-fit
// 5. Suporte autoportante na mesa PEI (Zero suportes!)
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

zc_f = (alt_f/2) * sin(90 - ang) + 4.0;
yc_f = 0;
zc_t = (alt_t/2) + 2.0;

prof_junta = 3.2;
esp_labio  = 2.8;

femea_w = larg_f - 2*esp_labio;
femea_h = alt_f - 2*esp_labio;
femea_r = max(2, r_f - esp_labio);

module rounded_rect(w, h, r) {
    minkowski() {
        square([max(0.1, w - 2*r), max(0.1, h - 2*r)], center=true);
        circle(r=r);
    }
}

// Suporte interior do ESP32 com nervuras a 45 graus
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

                    hull() {
                        cylinder(r=2.4, h=h_elev);
                        translate([0, h_elev, 0])
                        cylinder(r=0.2, h=h_elev);
                    }
                }
            }
        }
        hull() {
            translate([0, -dist_y/2 - 2.8, (h_elev + 2.0)/2])
            cube([14, 1.8, h_elev + 2.0], center=true);
            translate([0, -dist_y/2 - 2.8 + 2.0, 0.5])
            cube([14, 0.2, 1.0], center=true);
        }
        hull() {
            translate([0,  dist_y/2 + 2.8, (h_elev + 2.0)/2])
            cube([14, 1.8, h_elev + 2.0], center=true);
            translate([0,  dist_y/2 + 2.8 + 2.0, 0.5])
            cube([14, 0.2, 1.0], center=true);
        }
    }
}

// Berco interno onde o altifalante 1511 (15x11x3.5mm) assenta e cola
module berco_altifalante() {
    spk_x = 24.0; // Deslocado para a direita da porta USB
    spk_z = zc_t + 2.0;
    spk_y = prof - wall;

    // Parede de retencao do altifalante no interior da traseira
    translate([spk_x, spk_y, spk_z])
    rotate([90, 0, 0]) {
        difference() {
            // Caixa envolvente interna
            translate([0, 0, 1.8])
            cube([18.0, 14.0, 3.6], center=true);

            // Cavidade interior onde encaixa o altifalante 1511
            translate([0, 0, 2.0])
            cube([15.4, 11.4, 4.2], center=true);
        }
    }
}

module grelha_acustica_traseira() {
    spk_x = 24.0;
    spk_z = zc_t + 2.0;
    spk_y = prof;

    // Matriz de furos acusticos de 1.2mm no painel traseiro
    translate([spk_x, spk_y + 1.0, spk_z])
    rotate([90, 0, 0]) {
        for (gx = [-5.0 : 2.5 : 5.0]) {
            for (gz = [-3.5 : 2.2 : 3.5]) {
                translate([gx, gz, 0])
                cylinder(r=0.65, h=wall + 4.0, center=true);
            }
        }
    }
}

module corpo_clean() {
    union() {
        difference() {
            // 1. Envelope Exterior 100% macico com base plana
            hull() {
                translate([0, yc_f, zc_f])
                rotate([90 - ang, 0, 0])
                linear_extrude(0.1, center=true)
                rounded_rect(larg_f, alt_f, r_f);

                translate([0, prof, zc_t])
                rotate([90, 0, 0])
                linear_extrude(0.1, center=true)
                rounded_rect(larg_t, alt_t, r_t);

                translate([0, prof*0.48, 1.0])
                linear_extrude(2.0, center=true)
                rounded_rect(larg_f - 12, prof - 6, 12);
            }

            // 2. Cavidade Interior limpa e espacosa
            translate([0, 0, wall])
            hull() {
                translate([0, yc_f + wall*0.35, zc_f - wall])
                rotate([90 - ang, 0, 0])
                linear_extrude(0.1, center=true)
                rounded_rect(larg_f - 2*wall, alt_f - 2*wall, max(1.5, r_f - wall));

                translate([0, prof - wall, zc_t - wall*0.5])
                rotate([90, 0, 0])
                linear_extrude(0.1, center=true)
                rounded_rect(larg_t - 2*wall, alt_t - 2*wall, max(1.5, r_t - wall));

                translate([0, prof*0.48, 1.0])
                linear_extrude(2.0, center=true)
                rounded_rect(larg_f - 12 - 2*wall, prof - 6 - 2*wall, max(1.5, 12 - wall));
            }

            // 3. Degrau Femea Frontal e ABERTURA TOTAL
            translate([0, yc_f, zc_f])
            rotate([90 - ang, 0, 0]) {
                translate([0, 0, -prof_junta])
                linear_extrude(prof_junta + 5.0, center=false)
                rounded_rect(femea_w, femea_h, femea_r);

                translate([0, 0, -prof_junta - 10.0])
                linear_extrude(10.1, center=false)
                rounded_rect(femea_w - 7.0, femea_h - 7.0, max(1.0, femea_r - 3.5));

                // Ranhuras Snap
                for (side = [-1, 1]) {
                    translate([side * femea_w/2, 0, -2.1])
                    rotate([0, 0, side == 1 ? 0 : 180])
                    translate([0.35, 0, 0])
                    cube([1.2, 16.0, 1.5], center=true);

                    translate([0, side * femea_h/2, -2.1])
                    rotate([0, 0, side == 1 ? 90 : -90])
                    translate([0.35, 0, 0])
                    cube([1.2, 16.0, 1.5], center=true);
                }
            }

            // 4. Saida USB Traseira
            translate([0, prof + 2, wall + 5.5])
            cube([14.0, 10.0, 9.0], center=true);

            // 5. Grelha Acustica do Altifalante na Traseira
            grelha_acustica_traseira();
        }

        // Suporte do ESP32 no chao
        suporte_esp32(30.0);

        // Berco de fixacao do altifalante no interior
        berco_altifalante();
    }
}

// EXPORTACAO DEITADO: Z=0 na traseira assente na chapa PEI
translate([0, -zc_t, prof])
rotate([-90, 0, 0])
corpo_clean();
