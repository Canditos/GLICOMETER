# Como Abrir e Encomendar o Projeto no EasyEDA

O EasyEDA é a ferramenta online oficial da JLCPCB (funciona diretamente no browser em [easyeda.com](https://easyeda.com)).

---

### Passo 1: Abrir o Editor Online
1. Aceda a [https://easyeda.com/editor](https://easyeda.com/editor).
2. Faça login com a mesma conta que criou na **JLCPCB**.

---

### Passo 2: Criar o Projeto e Adicionar os Componentes
1. Clique em **File -> New -> Project** e dê o nome: `GLICOMETER_PRO`.
2. Para cada componente da placa, os códigos da **LCSC** já estão definidos no nosso ficheiro [`bom_lcsc.csv`](../bom_lcsc.csv):
   - Pressione o atalho **`Shift + F`** (ou clique no ícone **Library / Biblioteca** à esquerda).
   - Na barra de pesquisa, cole o código LCSC (exemplo: `C2913200` para o ESP32-S3, `C2682619` para o amplificador MAX98357A, `C2765186` para a porta USB-C).
   - Clique em **"Place"** para colocar na folha! Todos os footprints e modelos 3D já vêm oficiais de fábrica da JLCPCB.

---

### Passo 3: Encomendar com 1 Clique (One-Click Order)
1. No menu superior do EasyEDA, clique em:
   👉 **Fabrication -> One-Click Order at JLCPCB** (ou *Order PCB/SMT*).
2. O EasyEDA empacota automaticamente o ficheiro Gerber, a lista de peças BOM e as coordenadas de montagem (CPL).
3. A página da JLCPCB abre-se já com tudo preenchido e com as peças associadas!
4. Aplique os cupões de **PCBA** que recolheu e escolha o envio **EuroPacket para Portugal**.
