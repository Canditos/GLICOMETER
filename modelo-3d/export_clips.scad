$fn = 64;

// =====================================================================
// BARRAS RETANGULARES DE RETENÇÃO DO LCD - VERSÃO ULTRA ROBUSTA
// 1. Barras 100% maciças (sem fendas abertas nas pontas para não descolar)
// 2. Furo calibrado de 3.30mm com chanfro guia inferior de entrada
// 3. Recesso de retenção superior onde a cabeça do pino trava com clique mecânico
// 4. Imprime em ~4 minutos sem suportes
// =====================================================================

dist_y    = 49.50; // distância oficial entre furos KMRTM35018
comp      = 57.5;  // comprimento total da barra
larg      = 7.5;   // largura reforçada
esp       = 2.4;   // espessura reforçada
furo_d    = 3.30;  // diâmetro para pino de 3.0mm
recesso_d = 4.40;  // diâmetro do recesso para a cabeça do pino

module barra_retencao_rigida() {
    difference() {
        // Corpo maciço com cantos arredondados
        hull() {
            translate([0,  dist_y/2, 0]) cylinder(r=larg/2, h=esp);
            translate([0, -dist_y/2, 0]) cylinder(r=larg/2, h=esp);
        }

        // Furos de engate calibrados nos 2 cantos
        for (y = [-dist_y/2, dist_y/2]) {
            translate([0, y, -0.1]) {
                // 1. Furo passante principal
                cylinder(r=furo_d/2, h=esp + 0.2);

                // 2. Chanfro de entrada na base (comprime a cabeça do pino na inserção)
                cylinder(r1=furo_d/2 + 0.5, r2=furo_d/2, h=0.8);

                // 3. Recesso de travamento superior (o ombro da cabeça snap assenta aqui)
                translate([0, 0, esp - 0.7])
                cylinder(r=recesso_d/2, h=0.85);
            }
        }
    }
}

// Imprime as duas barras gémeas (Esquerda e Direita)
translate([-5.5, 0, 0]) barra_retencao_rigida();
translate([ 5.5, 0, 0]) barra_retencao_rigida();