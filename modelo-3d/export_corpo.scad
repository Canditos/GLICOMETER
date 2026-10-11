$fn = 64;

// =====================================================================
// CORPO GLICOMETER - 100% SÓLIDO, FECHADO E SEM BURACOS (DESIGN EM PÉ)
// 1. Envelope exterior continuo com base plana na mesa PEI (Z=0)
// 2. 4 Postes e pinos de fixacao do ESP32 no piso da caixa
// 3. Degrau femea frontal continuo a 360 graus, SEM BURACOS nem rasgos
// 4. Saida USB traseira
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

zc_f = (alt_f/2) * sin(90 - ang) + 4.0; // 38.2mm -> base com 4mm de espessura macica (sem fendas!)
yc_f = 0;

zc_t = (alt_t/2) + 2.0;

prof_junta = 3.2;
esp_labio  = 2.8;

femea_w = larg_f - 2*esp_labio; // 108.4 mm
femea_h = alt_f - 2*esp_labio; // 66.4 mm
femea_r = max(2, r_f - esp_labio);

module rounded_rect(w, h, r) {
    minkowski() {
        square([max(0.1, w - 2*r), max(0.1, h - 2*r)], center=true);
        circle(r=r);
    }
}

// Suporte interior do ESP32 com nervuras a 45 graus (100% autoportante quando deitado)
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

                    // Nervura de transição a 45 graus virada para a traseira (+Y)
                    // Ao rodar -90 em X, +Y vira -Z (aponta para a mesa), criando suporte natural a 45 graus!
                    hull() {
                        cylinder(r=2.4, h=h_elev);
                        translate([0, h_elev, 0])
                        cylinder(r=0.2, h=h_elev);
                    }
                }
            }
        }
        // Batentes de encosto com chanfro a 45 graus
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

            // 2. Cavidade Interior limpa e espaçosa
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

            // 3. Degrau Fêmea Frontal e ABERTURA TOTAL
            translate([0, yc_f, zc_f])
            rotate([90 - ang, 0, 0]) {
                // A. Degrau da moldura: do exterior (+5mm) até -prof_junta (-3.2mm)
                translate([0, 0, -prof_junta])
                linear_extrude(prof_junta + 5.0, center=false)
                rounded_rect(femea_w, femea_h, femea_r);

                // B. Abertura central para o interior: de -prof_junta até -12mm
                translate([0, 0, -prof_junta - 10.0])
                linear_extrude(10.1, center=false)
                rounded_rect(femea_w - 7.0, femea_h - 7.0, max(1.0, femea_r - 3.5));

                // C. Ranhuras Fêmea de retenção Snap (travamento positivo mecânico)
                for (side = [-1, 1]) {
                    // Laterais (esquerda e direita)
                    translate([side * femea_w/2, 0, -2.1])
                    rotate([0, 0, side == 1 ? 0 : 180])
                    translate([0.35, 0, 0])
                    cube([1.2, 16.0, 1.5], center=true);

                    // Topo e Base
                    translate([0, side * femea_h/2, -2.1])
                    rotate([0, 0, side == 1 ? 90 : -90])
                    translate([0.35, 0, 0])
                    cube([1.2, 16.0, 1.5], center=true);
                }
            }

            // 4. Saida USB Traseira
            translate([0, prof + 2, wall + 5.5])
            cube([14.0, 10.0, 9.0], center=true);
        }

        // Suporte do ESP32 no chao
        suporte_esp32(30.0);
    }
}

// =====================================================================
// EXPORTAÇÃO DEITADO: A face traseira (88x46) assenta a 100% plana na mesa PEI (Z=0)
// As paredes abrem para fora (draft autoportante) -> ZERO SUPORTES!
// =====================================================================
module corpo_deitado_impressao() {
    translate([0, -zc_t, prof])
    rotate([-90, 0, 0])
    corpo_clean();
}

corpo_deitado_impressao();