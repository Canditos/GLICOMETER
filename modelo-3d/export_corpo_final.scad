$fn = 64;

// =====================================================================
// CORPO GLICOMETER - FIXACAO MECANICA PELOS 4 POSTES DO LCD
// 1. 4 Torres femea nos cantos (92.0 x 49.5mm) que recebem os pinos da moldura
// 2. Sanduiche firme: as torres apoiam as costas do PCB do LCD
// 3. Furo piloto de 1.8mm para fixacao opcional com parafusos M2
// 4. Guias verticais do ESP32 na parede traseira (Zero Suportes)
// 5. Orientado deitado de costas a Z=0 para impressao facil
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

zc_f = (alt_f/2) * sin(90 - ang);
zc_t = alt_t/2;

prof_junta = 3.2;
esp_labio  = 2.8;

femea_w = larg_f - 2*esp_labio; // 108.4
femea_h = alt_f - 2*esp_labio; // 66.4
femea_r = max(2, r_f - esp_labio);

// LCD MSP3520 (KMRTM3501)
lcd_hole_dx = 92.00;
lcd_hole_dy = 49.50;

module rounded_rect(w, h, r) {
    minkowski() {
        square([max(0.1, w - 2*r), max(0.1, h - 2*r)], center=true);
        circle(r=r);
    }
}

// Guias traseiras do ESP32 (sobem do chao da mesa PEI)
module guias_esp32_traseira() {
    esp_w = 28.5;
    guia_alt = 10.0;
    
    translate([0, prof - wall - guia_alt/2, zc_t]) {
        translate([-esp_w/2 - 1.2, 0, 0])
        cube([2.4, guia_alt, 36.0], center=true);

        translate([esp_w/2 + 1.2, 0, 0])
        cube([2.4, guia_alt, 36.0], center=true);

        translate([0, 0, -18.0 - 1.2])
        cube([esp_w + 4.8, guia_alt, 2.4], center=true);
    }
}

// 4 Torres femea que recebem os pinos de fixacao da moldura
module torres_fixacao_corpo() {
    // A face traseira do PCB fica a Z_local = -prof_junta - 1.6 = -4.8mm
    // As torres estendem-se de dentro da caixa e terminam em Z_local = -4.8mm
    translate([0, 0, zc_f])
    rotate([90 - ang, 0, 0]) {
        for (x = [-lcd_hole_dx/2, lcd_hole_dx/2]) {
            for (y = [-lcd_hole_dy/2, lcd_hole_dy/2]) {
                difference() {
                    // Corpo da torre macica
                    translate([x, y, -4.8 - 6.0])
                    cylinder(r1=5.0, r2=4.0, h=6.0);

                    // Furo femea que recebe o pino de 2.9mm da moldura com encaixe justo
                    translate([x, y, -4.8 - 3.5])
                    cylinder(r=1.55, h=4.0);

                    // Furo piloto para parafuso M2 opcional
                    translate([x, y, -4.8 - 10.0])
                    cylinder(r=0.9, h=12.0);
                }
            }
        }
    }
}

module corpo_clean() {
    rad_ang = ang * 3.14159265 / 180;
    ny = sin(ang);
    nz = -cos(ang);

    union() {
        difference() {
            // 1. Envelope Exterior
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

            // 3. Degrau Femea Frontal
            translate([0, 0, zc_f])
            rotate([90 - ang, 0, 0])
            translate([0, 0, -prof_junta/2])
            linear_extrude(prof_junta + 0.1, center=true)
            rounded_rect(femea_w, femea_h, femea_r);

            // 4. Saida USB Traseira
            translate([0, prof + 2, zc_t])
            cube([14.0, 10.0, 9.0], center=true);
        }

        // Torres femea de fixacao da moldura
        torres_fixacao_corpo();

        // Guias traseiras do ESP32
        guias_esp32_traseira();
    }
}

// Orientacao definitiva: Traseira 100% plana na mesa a Z=0
translate([0, 0, prof])
rotate([-90, 0, 0])
corpo_clean();