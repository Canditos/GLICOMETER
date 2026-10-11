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

module rounded_rect(w, h, r) {
    minkowski() {
        square([max(0.1, w - 2*r), max(0.1, h - 2*r)], center=true);
        circle(r=r);
    }
}

zc_f = (alt_f/2) * sin(90 - ang) + 4.0;

// Teste de corte plano a Z=0
module corpo_base_plana_direta() {
    difference() {
        // Envoltoria exterior
        intersection() {
            hull() {
                // Face frontal inclinada
                translate([0, 0, zc_f])
                rotate([90 - ang, 0, 0])
                linear_extrude(0.1, center=true)
                rounded_rect(larg_f, alt_f, r_f);

                // Traseira
                translate([0, prof, (alt_t/2) + 2.0])
                rotate([90, 0, 0])
                linear_extrude(0.1, center=true)
                rounded_rect(larg_t, alt_t, r_t);
            }
            // Corte plano a Z >= 0 (tudo o que esta abaixo de Z=0 e cortado fora!)
            translate([0, prof/2, 50])
            cube([larg_f + 20, prof + 40, 100], center=true);
        }
    }
}

corpo_base_plana_direta();
