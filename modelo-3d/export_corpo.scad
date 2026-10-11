$fn = 64;

// =====================================================================
// CORPO GLICOMETER MASTER V9 - COM BOTÃO SNOOZE NO TOPO + BATERIA 21700 + SOM 1511
// 1. Envelope exterior continuo com base plana na mesa PEI (Z=0)
// 2. Botão Snooze no Topo: Abertura ergonómica de 10x6mm para tecla tátil com clique fácil à noite
// 3. Berço para 21700 com ranhuras de contacto de mola Keystone (sem soldar na bateria!)
// 4. Altifalante 1511 integrado com grelha acústica traseira
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

// Berço para 21700 com ranhuras de contacto de mola
module berco_bateria_21700_molas() {
    bat_d = 21.6;
    bat_r = bat_d / 2;
    espaco_mola = 74.0;
    y_bat = prof * 0.45;
    z_center = wall + bat_r - 2.0;

    translate([0, y_bat, z_center]) {
        for (x_pos = [-22.0, 22.0]) {
            translate([x_pos, 0, 0])
            rotate([0, 90, 0]) {
                difference() {
                    union() {
                        cylinder(r=bat_r + 2.4, h=10.0, center=true);
                        translate([bat_r + 1.0, 0, 0])
                        rotate([0, 0, 45])
                        cube([4.0, 4.0, 10.0], center=true);
                    }
                    cylinder(r=bat_r, h=10.2, center=true);
                    translate([0, bat_r + 2.0, 0])
                    cube([bat_d * 0.90, bat_d, 10.4], center=true);
                }
            }
        }

        for (side = [-1, 1]) {
            x_tower = side * (espaco_mola / 2);
            translate([x_tower, 0, 0]) {
                difference() {
                    cube([3.6, 16.0, bat_d + 1.0], center=true);
                    translate([-side * 0.5, 0, 0])
                    cube([1.2, 12.5, bat_d + 2.0], center=true);
                    cube([6.0, 3.5, 3.5], center=true);
                }
            }
        }
    }
}

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

// Abertura e berço do Botão Snooze no topo inclinado da caixa
module abertura_botao_snooze() {
    btn_y = prof * 0.35;
    btn_z = alt_f * 0.85; // No topo superior
    translate([0, btn_y, btn_z])
    rotate([15, 0, 0]) {
        // Furo elíptico ergonómico para a tecla
        hull() {
            translate([-5.0, 0, 0]) cylinder(r=3.0, h=wall + 8.0, center=true);
            translate([ 5.0, 0, 0]) cylinder(r=3.0, h=wall + 8.0, center=true);
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

            // 6. Botão de Snooze Ergonómico no Topo
            abertura_botao_snooze();
        }

        // Berço com Ranhuras para Contactos de Mola (Keystone)
        berco_bateria_21700_molas();

        // Berço do Altifalante 1511
        berco_altifalante();
    }
}

// EXPORTAÇÃO DEITADO: Z=0 na traseira assente na chapa PEI
translate([0, -zc_t, prof])
rotate([-90, 0, 0])
corpo_clean();
