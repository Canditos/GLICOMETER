 = 64;

larg_f = 114.0;
alt_f  = 72.0;
r_f    = 14.0;
ang    = 18.0;

prof   = 62.0;
larg_t = 88.0;
alt_t  = 46.0;
r_t    = 16.0;

module rounded_rect(w, h, r) {
    minkowski() {
        square([max(0.1, w - 2*r), max(0.1, h - 2*r)], center=true);
        circle(r=r);
    }
}

// Alinhamento exato a Z=0 sem qualquer degrau
zc_f = (alt_f/2) * sin(90 - ang);
zc_t = alt_t/2;

module envelope_zero_overhang() {
    hull() {
        // Face frontal inclinada que toca exatamente em Z=0
        translate([0, 0, zc_f])
        rotate([90 - ang, 0, 0])
        linear_extrude(0.1, center=true)
        rounded_rect(larg_f, alt_f, r_f);

        // Traseira que toca exatamente em Z=0
        translate([0, prof, zc_t])
        rotate([90, 0, 0])
        linear_extrude(0.1, center=true)
        rounded_rect(larg_t, alt_t, r_t);
    }
}

envelope_zero_overhang();
