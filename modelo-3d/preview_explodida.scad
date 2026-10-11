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

// Vista Explodida Didatica ao longo do eixo da frente (Z local)
module montagem_explodida() {
    // 1. Corpo na posicao base
    color([0.35, 0.38, 0.44, 1.0])
    rotate([90, 0, 0])
    translate([0, 0, -prof])
    corpo_clean();

    // No eixo normal da frente inclinada:
    translate([0, 0, zc_f])
    rotate([90 - ang, 0, 0]) {
        // 2. Barras de Retencao Azuis (afastadas 18mm para a frente)
        translate([0, 0, 18]) {
            translate([-lcd_hole_dx/2, 0, 0])
            color([0.0, 0.75, 0.95, 1.0])
            barra_retencao();

            translate([lcd_hole_dx/2, 0, 0])
            color([0.0, 0.75, 0.95, 1.0])
            barra_retencao();
        }

        // 3. PCB Vermelho do LCD (afastado 32mm)
        translate([0, 0, 32])
        color([0.85, 0.12, 0.12, 1.0])
        difference() {
            translate([0, 0, 0.8]) cube([98.0, 56.34, 1.6], center=true);
            for (x = [-lcd_hole_dx/2, lcd_hole_dx/2])
            for (y = [-lcd_hole_dy/2, lcd_hole_dy/2])
            translate([x, y, -0.5]) cylinder(r=1.6, h=3.0);
        }

        // 4. Vidro Touch do LCD (afastado 40mm)
        translate([0, 0, 40])
        color([0.15, 0.16, 0.18, 0.9])
        cube([85.0, 55.4, 2.2], center=true);

        // 5. Moldura Frontal Branca (afastada 58mm)
        translate([0, 0, 58])
        color([0.94, 0.95, 0.97, 1.0])
        moldura_impressao();
    }
}

montagem_explodida();