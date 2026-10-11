$fn = 64;

// =====================================================================
// CORPO GLICOMETER MASTER V7 - COM BATERIA 21700 (5000 mAh) & ALTIFALANTE 1511
// 1. Envelope exterior continuo com base plana na mesa PEI (Z=0)
// 2. Berço Snap-in para Bateria Cilíndrica Li-Ion 21700 (Diam: 21.4mm x Comp: 71.0mm)
// 3. Altifalante 1511 com câmara acústica e grelha traseira
// 4. Degrau fêmea frontal com 4 dentes snap-fit
// 5. 100% Autoportante na mesa PEI (Z=0 na traseira - Zero suportes!)
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

// Berço Snap-in para Célula Li-Ion 21700 (5000 mAh)
// Diâmetro 21.2mm (+0.5mm folga), Comprimento 70.5mm
// Dois anéis elásticos de retenção no chão com rampa de 45 graus para imprimir sem suportes
module berco_bateria_21700() {
    bat_d = 21.6;
    bat_r = bat_d / 2;
    bat_len = 71.5;
    y_bat = prof * 0.45; // Centrada na base (Y = ~28mm)
    z_center = wall + bat_r - 2.0; // Encaixada parcialmente no fundo

    translate([0, y_bat, z_center]) {
        // Dois berços em anel nas extremidades (X = -26mm e X = +26mm)
        for (x_pos = [-24.0, 24.0]) {
            translate([x_pos, 0, 0])
            rotate([0, 90, 0]) {
                difference() {
                    // Corpo exterior do anel com nervura chanfrada de apoio
                    union() {
                        cylinder(r=bat_r + 2.4, h=10.0, center=true);
                        // Nervuras a 45 graus viradas para a mesa PEI (+Y quando deitado)
                        translate([bat_r + 1.0, 0, 0])
                        rotate([0, 0, 45])
                        cube([4.0, 4.0, 10.0], center=true);
                    }
                    // Cavidade cilíndrica onde assenta a bateria
                    cylinder(r=bat_r, h=10.2, center=true);

                    // Abertura superior a 110 graus para a bateria entrar por pressão (snap-in)
                    translate([0, bat_r + 2.0, 0])
                    cube([bat_d * 0.90, bat_d, 10.4], center=true);
                }
            }
        }
        // Batentes longitudinais para a bateria não correr de lado
        for (side = [-1, 1]) {
            translate([side * (bat_len/2 + 1.2), 0, -bat_r/2])
            cube([2.4, 12.0, bat_r], center=true);
        }
    }
}

// Berço interno onde o altifalante 1511 (15x11x3.5mm) assenta e cola
module berco_altifalante() {
    spk_x = 24.0;
    spk_z = zc_t + 2.0;
    spk_y = prof - wall;

    translate([spk_x, spk_y, spk_z])
    rotate([90, 0, 0]) {
        difference() {
            translate([0, 0, 1.8])
            cube([18.0, 14.0, 3.6], center=true);

            translate([0, 0, 2.0])
            cube([15.4, 11.4, 4.2], center=true);
        }
    }
}

module grelha_acustica_traseira() {
    spk_x = 24.0;
    spk_z = zc_t + 2.0;
    spk_y = prof;

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
            // 1. Envelope Exterior 100% maciço com base plana
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

            // 4. Saída USB Traseira
            translate([0, prof + 2, wall + 5.5])
            cube([14.0, 10.0, 9.0], center=true);

            // 5. Grelha Acústica
            grelha_acustica_traseira();
        }

        // Berço Snap-in da Bateria 21700 (5000 mAh) no chão
        berco_bateria_21700();

        // Berço do Altifalante 1511
        berco_altifalante();
    }
}

// EXPORTAÇÃO DEITADO: Z=0 na traseira assente na chapa PEI
translate([0, -zc_t, prof])
rotate([-90, 0, 0])
corpo_clean();
