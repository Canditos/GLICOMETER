$fn = 64;

larg_f = 114.0;
alt_f  = 72.0;
r_f    = 14.0;
ang    = 18.0;
prof   = 62.0;

esp_frontal = 2.4;
macho_len   = 3.0;

lcd_hole_dx = 92.00;
lcd_hole_dy = 49.50;

zc_f = (alt_f/2) * sin(90 - ang);

use <export_moldura.scad>
use <export_clips.scad>
use <export_corpo_final.scad>

// Conjunto 100% montado e encaixado, cortado ao meio
difference() {
    union() {
        // 1. Corpo
        color([0.32, 0.35, 0.40, 1.0])
        rotate([90, 0, 0])
        translate([0, 0, -prof])
        corpo_clean();

        // 2. Moldura Frontal perfeitamente assentada no degrau femea
        translate([0, 0, zc_f])
        rotate([90 - ang, 0, 0])
        color([0.92, 0.94, 0.96, 1.0])
        moldura_impressao();

        // 3. Vidro LCD
        translate([0, 0, zc_f])
        rotate([90 - ang, 0, 0])
        translate([0.8, 0, esp_frontal - 1.4 + 1.1])
        color([0.10, 0.12, 0.14, 0.95])
        cube([85.0, 55.4, 2.2], center=true);

        // 4. PCB Vermelho LCD
        translate([0, 0, zc_f])
        rotate([90 - ang, 0, 0])
        translate([0, 0, esp_frontal + macho_len])
        color([0.85, 0.12, 0.12, 1.0])
        difference() {
            translate([0, 0, 0.8]) cube([98.0, 56.34, 1.6], center=true);
            for (x = [-lcd_hole_dx/2, lcd_hole_dx/2])
            for (y = [-lcd_hole_dy/2, lcd_hole_dy/2])
            translate([x, y, -0.5]) cylinder(r=1.6, h=3.0);
        }

        // 5. Barras de Retencao (Azul Ciano)
        translate([0, 0, zc_f])
        rotate([90 - ang, 0, 0])
        translate([0, 0, esp_frontal + macho_len + 1.6]) {
            translate([-lcd_hole_dx/2, 0, 0])
            color([0.0, 0.75, 0.95, 1.0])
            barra_retencao();

            translate([lcd_hole_dx/2, 0, 0])
            color([0.0, 0.75, 0.95, 1.0])
            barra_retencao();
        }
    }

    // Corte longitudinal limpo (X > 0)
    translate([75, 0, 0])
    cube([150, 200, 200], center=true);
}