$fn = 64;

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

femea_w = larg_f - 2*esp_labio; // 108.4 mm
femea_h = alt_f - 2*esp_labio; // 66.4 mm
femea_r = max(2, r_f - esp_labio);

snap_w = 16.0; // largura do sulco femea (folga para garra de 14mm)

module rounded_rect(w, h, r) {
    minkowski() {
        square([max(0.1, w - 2*r), max(0.1, h - 2*r)], center=true);
        circle(r=r);
    }
}

// ---------------------------------------------------------------------
// SUPORTE INTERIOR DO ESP32 (4 PINOS + 2 BATENTES NO CHAO)
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

module corpo_clean() {
    union() {
        difference() {
            // 1. Envelope Exterior continuo e solido com base plana
            hull() {
                // Frente inclinada
                translate([0, yc_f, zc_f])
                rotate([90 - ang, 0, 0])
                linear_extrude(0.1, center=true)
                rounded_rect(larg_f, alt_f, r_f);

                // Traseira vertical suave
                translate([0, prof, zc_t])
                rotate([90, 0, 0])
                linear_extrude(0.1, center=true)
                rounded_rect(larg_t, alt_t, r_t);

                // Base 100% plana na mesa (Z=0 a Z=2mm)
                translate([0, prof*0.48, 1.0])
                linear_extrude(2.0, center=true)
                rounded_rect(larg_f - 12, prof - 6, 12);
            }

            // 2. Cavidade Interior
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

            // 3. Degrau Femea Frontal
            translate([0, yc_f, zc_f])
            rotate([90 - ang, 0, 0]) {
                // Degrau de assentamento da moldura
                translate([0, 0, -prof_junta/2])
                linear_extrude(prof_junta + 0.1, center=true)
                rounded_rect(femea_w, femea_h, femea_r);

                // Abertura interna passante limpa para fios e componentes
                translate([0, 0, -15])
                linear_extrude(25, center=true)
                rounded_rect(femea_w - 6.0, femea_h - 6.0, max(1.0, femea_r - 3.0));

                // 4. Os 2 Sulcos Snap-Fit Fêmea (Topo e Base a X=0)
                // Sulco Topo (+Y)
                translate([0, femea_h/2 + 0.35, -1.6])
                cube([snap_w, 1.4, 1.3], center=true);

                // Sulco Base (-Y)
                translate([0, -femea_h/2 - 0.35, -1.6])
                cube([snap_w, 1.4, 1.3], center=true);
            }

            // 5. Saida USB Traseira
            translate([0, prof + 2, wall + 5.5])
            cube([14.0, 10.0, 9.0], center=true);
        }

        // Suporte do ESP32 no chao
        suporte_esp32(30.0);
    }
}

corpo_clean();