$fn = 64;

// =====================================================================
// MOLDURA FRONTAL GLICOMETER - 100% LIMPA, SÓLIDA E SEM BURACOS
// 1. Perimetro exterior 100% solido e continuo (zero cortes, zero fendas)
// 2. Janela calibrada: 70.0 x 46.5 mm (offset X=+0.8mm) -> Tapa a risca inativa
// 3. Recesso cego para o vidro do LCD (zero furos passantes)
// 4. 4 Pinos solidos nos cantos (92.0 x 49.5mm) para travar o ecra com as 2 barras
// 5. Aba macho continua para fecho Press-Fit justo no corpo
// =====================================================================

larg_f = 114.0;
alt_f  = 72.0;
r_f    = 14.0;

esp_frontal = 2.4;  // espessura da face frontal
macho_len   = 2.8;  // altura da aba de insercao

larg_m = 107.8;     // tolerancia calibrada para entrar justo sem folga
alt_m  = 65.8;
r_m    = 11.0;

// Janela do LCD calibrada (cobre a margem inativa da foto)
janela_w = 70.0;
janela_h = 46.5;
janela_x = 0.8;

// Recesso cego para o vidro LCD (profundidade de 1.4mm na face traseira)
vidro_w  = 85.2;
vidro_h  = 55.8;
prof_vidro = 1.4;

// Berco do PCB (98.2 x 56.5 mm)
pcb_w = 98.2;
pcb_h = 56.5;

// Furacao oficial KMRTM35018-SPI
lcd_hole_dx = 92.00;
lcd_hole_dy = 49.50;

module rounded_rect(w, h, r) {
    minkowski() {
        square([max(0.1, w - 2*r), max(0.1, h - 2*r)], center=true);
        circle(r=r);
    }
}

// Pino de retenção Snap Fendido (Split Snap-Barb) que comprime na entrada e expande para travar
module pino_retencao_barra() {
    pcb_esp   = 1.6;
    barra_esp = 2.4;
    h_haste   = pcb_esp + barra_esp; // 4.0mm
    h_cabeca  = 1.6;

    difference() {
        union() {
            // Haste de 3.0mm (passa pelo PCB de 3.2mm e pelo furo da barra de 3.3mm)
            cylinder(r1=1.55, r2=1.50, h=h_haste);
            
            // Cabeça cónica com ombro a 90 graus (expande para 4.2mm de diametro)
            translate([0, 0, h_haste])
            cylinder(r1=2.10, r2=1.40, h=h_cabeca);
        }

        // Fenda elástica central para compressão suave
        translate([0, 0, (h_haste + h_cabeca)/2 + 0.3])
        cube([0.85, 5.0, h_haste + h_cabeca + 1.0], center=true);
    }
}

// Dente snap com rampa suave de entrada (45 graus) e travamento mecânico positivo
module dente_snap_macho(w=14.0, h=1.2, proj=0.55) {
    hull() {
        cube([0.1, w, 0.1], center=true);
        translate([proj, 0, h*0.5])
        cube([0.1, w - 2.0, h*0.4], center=true);
        translate([0, 0, h])
        cube([0.1, w, 0.1], center=true);
    }
}

module moldura_impressao() {
    snap_w     = 14.0;
    snap_h     = 1.2;
    snap_proj  = 0.55;
    snap_z_pos = 1.5;

    difference() {
        union() {
            // 1. Placa Frontal Macica e 100% continua (assenta na mesa PEI a Z=0)
            linear_extrude(esp_frontal, center=false)
            rounded_rect(larg_f, alt_f, r_f);

            // 2. Aba Macho perimetral solida e continua a 360 graus
            translate([0, 0, esp_frontal])
            linear_extrude(macho_len, center=false)
            rounded_rect(larg_m, alt_m, r_m);

            // Dentes Snap de travamento mecânico nas 4 faces da aba macho
            // Laterais (esquerda e direita)
            translate([larg_m/2, 0, esp_frontal + snap_z_pos])
            dente_snap_macho(snap_w, snap_h, snap_proj);

            translate([-larg_m/2, 0, esp_frontal + snap_z_pos])
            rotate([0, 0, 180])
            dente_snap_macho(snap_w, snap_h, snap_proj);

            // Topo e Base
            translate([0, alt_m/2, esp_frontal + snap_z_pos])
            rotate([0, 0, 90])
            dente_snap_macho(snap_w, snap_h, snap_proj);

            translate([0, -alt_m/2, esp_frontal + snap_z_pos])
            rotate([0, 0, -90])
            dente_snap_macho(snap_w, snap_h, snap_proj);

            // 3. Os 4 Postes macicos com pinos de trava
            for (x = [-lcd_hole_dx/2, lcd_hole_dx/2]) {
                for (y = [-lcd_hole_dy/2, lcd_hole_dy/2]) {
                    translate([x, y, 0]) {
                        cylinder(r=3.3, h=esp_frontal + macho_len);
                        translate([0, 0, esp_frontal + macho_len])
                        pino_retencao_barra();
                    }
                }
            }
        }

        // --- SUBTRACOES (APENAS O ECRÃ, ZERO FUROS EXTERIORES!) ---

        // A. A Unica abertura passante da moldura: Janela de visualizacao do ecrã!
        translate([janela_x, 0, -0.5])
        linear_extrude(esp_frontal + 1.0, center=false)
        rounded_rect(janela_w, janela_h, 2.0);

        // B. Bisel elegante a 45 graus na face frontal exterior da janela
        translate([janela_x, 0, -0.5])
        hull() {
            translate([0, 0, 0])
            linear_extrude(0.1, center=true)
            rounded_rect(janela_w + 2.0, janela_h + 2.0, 3.0);

            translate([0, 0, 1.0])
            linear_extrude(0.1, center=true)
            rounded_rect(janela_w, janela_h, 2.0);
        }

        // C. Recesso cego para o vidro LCD (nao fura para a frente!)
        translate([0, 0, esp_frontal - prof_vidro])
        linear_extrude(prof_vidro + macho_len + 5.0, center=false)
        square([vidro_w, vidro_h], center=true);

        // D. Berco cego do PCB (preservando 100% os 4 pilares)
        translate([0, 0, esp_frontal])
        difference() {
            linear_extrude(macho_len + 5.0, center=false)
            square([pcb_w, pcb_h], center=true);

            for (x = [-lcd_hole_dx/2, lcd_hole_dx/2]) {
                for (y = [-lcd_hole_dy/2, lcd_hole_dy/2]) {
                    translate([x, y, -1])
                    cylinder(r=3.6, h=macho_len + 7.0);
                }
            }
        }
    }
}

moldura_impressao();