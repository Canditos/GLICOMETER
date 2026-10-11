# Guia Rápido de Encomenda na JLCPCB • Passo a Passo

Siga estes passos simples para encomendar as suas placas montadas por robô (SMT) com os melhores descontos.

---

## Passo 1: Abrir a Ferramenta de Pedido
1. Aceda a [jlcpcb.com](https://jlcpcb.com) e faça login na sua conta.
2. Na página inicial, clique no botão azul grande **"Order Now"** (ou "Instant Quote").

---

## Passo 2: Configuração da Placa (PCB)
1. **Dimensões**: Insira `85 mm` (Largura) × `60 mm` (Altura).
2. **Quantidade**: Escolha `5` (o valor mais económico para protótipos).
3. **Layers**: `2 Layers`.
4. **PCB Color**: Escolha `Black` (Preto mate elegante) ou `Green` (Verde clássico). Ambas têm o mesmo preço base ($2).
5. **Surface Finish**: `HASL (with lead)` ou `LeadFree HASL-RoHS` (sem chumbo).

---

## Passo 3: Ativar a Montagem Robotizada (SMT Assembly)
1. Mais abaixo na página, ative o interruptor **"PCB Assembly"** (mude de OFF para **ON**).
2. **Assembly Side**: Escolha **"Top Side"** (todos os chips principais estão na face superior).
3. **PCBA Type**: Escolha **"Economic"**.
4. **Tooling Holes**: Deixe na opção padrão **"Added by JLCPCB"**.

---

## Passo 4: Ficheiros de Fabrico
A JLCPCB vai pedir-lhe 3 ficheiros:
1. **Gerber File**: O arquivo comprimido `.zip` com o traçado das pistas.
2. **BOM File**: Carregue o ficheiro [`hardware/pcb/bom_lcsc.csv`](bom_lcsc.csv) que criámos. A máquina reconhece imediatamente as peças da LCSC!
3. **CPL (Pick and Place)**: O ficheiro de coordenadas dos componentes.

---

## Passo 5: Aplicar o Desconto e Envio para Portugal
1. No resumo do carrinho, clique em **"Use Coupon"** e escolha o seu cupão de boas-vindas de **PCBA/SMT ($7 a $9 OFF)**.
2. Na morada de entrega em Portugal, selecione o método de envio:
   - **Recomendado**: **"EuroPacket (Priority Line / IOSS)"**.
   - O IVA (23%) fica pago logo no site e **nunca fica retido na alfândega dos CTT**!
3. Pague com Cartão ou PayPal e acompanhe o fabrico em tempo real no painel de cliente da JLCPCB.
