# Astra Dodge — Plano: Arte Nova "2.5D" (asteroides, lixo espacial e naves inimigas)

> Objetivo: trocar a arte "vetor plano" por algo **mais detalhado e com volume** (aparência 2.5D:
> luz, sombra, relevo, objetos que giram em 3D), sem perder a leitura rápida do jogo.
> Entra: vários tipos de asteroides, **lixo espacial** (pedaços de naves, satélites) no lugar dos
> blocos de metal, e **naves inimigas** de verdade no lugar dos hexágonos.
> Data: 05/11/2026 · Base: commit `6ecf165` (O1 — visual por setor).

---

## 0. O que NÃO pode piorar
1. **Ler em meio segundo**: o que quebra × o que não quebra × o que atira. Forma + cor + brilho,
   nunca só cor.
2. **Colisão = desenho**: o teste "colisão x desenho" continua valendo para tudo (≤ 5%).
3. **60 FPS em aparelho de entrada** (meta) e no S20 FE.
4. **O que é do jogador brilha em ciano/magenta**; perigo tem contorno quente (vermelho/laranja).

---

## 1. Como chegar no "2.5D" (técnicas)

| Técnica | O que faz | Onde usar | Custo |
|---|---|---|---|
| **A. Asteroide por shader (esfera 3D falsa)** | um quadrado vira uma esfera **iluminada que gira em 3D**: textura de rocha "enrolada" na esfera + relevo + borda irregular por ruído. Cada asteroide é único | todos os asteroides | médio (1 shader), quase sem arte |
| **B. Mapas de normal + luz 2D** | cada sprite ganha um "mapa de relevo"; uma luz (o "sol" da cena + explosões) ilumina as bordas e faz sombra | lixo espacial, naves, chefes | baixo por sprite (o mapa é gerado automaticamente) |
| **C. Arte pintada com volume** | sprites desenhados/gerados já com luz, sombra e detalhes (estilo "pintado", não vetor) | lixo, naves, chefes | depende da fonte (ver seção 5) |
| **D. Camadas e profundidade** | parallax com 3–4 camadas (poeira distante, destroços ao fundo desfocados, planetas) | fundo | baixo |

Recomendação: **A para asteroides** (variedade infinita e giro 3D de verdade, sem depender de
arte externa) + **B + C para lixo, naves e chefes** + **D no fundo**.

---

## 2. Asteroides — vários tipos (destrutíveis)

Todos gerados pelo shader (técnica A), cada um com **parâmetros de material**:

| Tipo | Visual | Comportamento | Setores |
|---|---|---|---|
| **Rochoso** | cinza, crateras, giro lento | o atual | 1, 2, 4 |
| **Ferroso** | marrom-avermelhado com brilho metálico nas bordas | +vida, solta mais cristais | 2, 4 |
| **Carbonáceo** | quase preto e poroso — **com borda clara** para ler | quebra em 2 pedaços | 3, 8 |
| **Gelo** | translúcido, reflexo especular | já racha em lascas (Setor 5) | 5 |
| **Cristalino** | rocha com cristais que brilham (emissivo) | ao quebrar, solta um orbe garantido | 3, 6 |
| **Pedra-pomes** | clara, cheia de furos, leve | rápido e frágil (1 tiro) | 1, 6 |
| **Vulcânico** | rachaduras incandescentes | ao quebrar, espirra brasas (dano leve, avisado pelo brilho) | 7, 8 |

- Silhueta irregular por ruído (não redonda), mas a **colisão continua um círculo** dentro dela
  (o teste garante que o círculo fica no desenho).
- Tamanhos: pedrinha / média / pedregulho (já existe), agora com **giro 3D** proporcional ao tamanho.
- Ao quebrar: pedaços com o mesmo material + poeira iluminada.

---

## 3. Lixo espacial (indestrutível) — substitui os blocos de metal

Peças de naves e estações, **com cara de metal pesado** (técnica B + C), girando devagar:

| Peça | Forma | Colisão |
|---|---|---|
| **Pedaço de casco** | chapa curva com rebites e bordas rasgadas | 2 círculos |
| **Viga/treliça** | barra comprida | 3 círculos em linha |
| **Painel solar quebrado** | placa retangular azul com moldura | 2–3 círculos |
| **Satélite morto** | corpo + antena parabólica | 2 círculos |
| **Turbina/motor** | cilindro com bocal queimado | 2 círculos |
| **Contêiner amassado** | caixa com faixas de alerta | 1 círculo grande |
| **Cápsula de fuga** (rara) | casulo com janela | 1 círculo; destruível → recompensa |

- **Leitura**: todo lixo tem **aço escuro + uma luz de alerta piscando** (âmbar) — "isso é metal,
  não quebra". O tiro ricocheteia com faísca (já existe).
- **Colisão por vários círculos** (já usada nos chefes): permite formas compridas sem dano injusto.
  O teste "colisão x desenho" passa a cobrir cada peça.
- Por setor: Campo Metálico = peças de mineração; Destroços = cascos de cruzador; Estação =
  contêineres e treliças; Fenda = peças distorcidas/derretidas.

---

## 4. Naves inimigas (substituem os drones hexagonais)

| Nave | Comportamento | Aviso (justiça) | Setores |
|---|---|---|---|
| **Caça** | desce em formação e atira mirado (o drone atual) | luz frontal acende antes do tiro | 2+ |
| **Interceptador** | entra pelo lado e faz uma investida em linha | linha vermelha 0,8 s antes | 4+ |
| **Bombardeiro** | lento e resistente; solta minas no caminho | compartimento abre antes | 3+ |
| **Atirador** | para no alto, carrega um laser fino | feixe-guia fino → laser | 6+ |
| **Porta-drones** | nave média que lança 3 caças pequenos | escotilha pisca | 7+ |
| **Kamikaze** | trava na nave e mergulha | mira vermelha na nave + bip | 8 |

- Visual: naves com volume (técnica B + C), **cor de facção inimiga** (casco escuro + detalhes
  vermelho/laranja) — nunca ciano/magenta (cor do jogador).
- Explosão em pedaços (o casco se parte nas peças do sprite) + luz da explosão iluminando o
  lixo em volta (técnica B).
- As torretas e mísseis do Setor 4 ganham o mesmo estilo.

---

## 5. De onde vem a arte (decisão importante)

| Fonte | Prós | Contras |
|---|---|---|
| **1. IA de imagem (você gera; eu preparo prompts e o "encaixe")** | rápido, muito detalhe, estilo consistente se o prompt for bom | precisa de você gerando; às vezes exige retoque; ver licença da ferramenta |
| **2. Procedural no próprio jogo (shader + SVG com luz)** | sem dependência externa; asteroides infinitos | detalhe limitado para naves |
| **3. Pacotes de arte CC0 (ex.: Kenney)** | grátis e liberados | estilo mais "plano", não é 2.5D; download precisa da sua autorização |
| **4. Artista contratado** | melhor resultado | custo e prazo |

**Recomendação: 2 para asteroides + 1 para lixo, naves e chefes.**
Para a fonte 1 eu entrego:
- `ARTE_25D.md` com **prompts prontos** (estilo único para tudo: "2.5D pintado, luz de cima à
  esquerda, fundo transparente, vista de cima"), tamanhos e pontos de encaixe;
- `tools/prep_sprite.gd`: recorta, centraliza, ajusta o tamanho, **gera o mapa de normal** a partir
  da imagem e confere a colisão — você só joga o PNG numa pasta.

---

## 6. Técnico

- **Shader de asteroide** (`shaders/asteroid.gdshader`): esfera falsa com textura de superfície
  tileável (gerada por ruído ou pintada), luz direcional, borda irregular, giro em 2 eixos;
  material por tipo (cor, rugosidade, emissão, especular).
- **Luz 2D**: `DirectionalLight2D` (sol da cena, cor por setor) + `PointLight2D` curtas nas
  explosões e nos tiros. `CanvasTexture` (cor + normal + especular) no lixo e nas naves.
- **Colisão por círculos** genérica para lixo e naves (`bodies` por tipo, como nos chefes).
- **Desempenho**: limite de luzes simultâneas, LOD (pedrinhas sem normal map), teste de FPS no
  S20 FE com a tela cheia; se cair, opção "Gráficos: simples" nas Opções (volta ao visual atual).
- O ArtSet ganha: materiais de asteroide por setor, lista de peças de lixo por setor, sprites e
  "bodies" das naves inimigas.

---

## 7. Roadmap

| Etapa | Entrega | Pronto quando |
|---|---|---|
| **A1 — Asteroides 2.5D** | shader de esfera + 7 tipos de material + quebra em pedaços | todos os setores usando; 60 FPS no S20 FE |
| **A2 — Luz e profundidade** | luz 2D por setor, luzes de explosão/tiro, fundo em camadas | cena com volume; FPS ok |
| **A3 — Lixo espacial** | 7 peças + colisão por círculos + luz de alerta; substitui o metal | teste colisão x desenho e rota segura passam |
| **A4 — Naves inimigas** | Caça, Interceptador, Bombardeiro (arte + comportamento) | bot passa os setores; avisos testados |
| **A5 — Naves inimigas 2** | Atirador, Porta-drones, Kamikaze | idem |
| **A6 — Chefes e nave do jogador** | refazer os 8 chefes e a nave no mesmo estilo | visual unificado |
| **A7 — Opção de gráficos** | "Completo / Simples" + ajuste de desempenho | aparelho fraco a 60 FPS no Simples |

A1 e A2 eu faço sozinho (procedural). A3–A6 dependem da fonte de arte (seção 5).

---

## 8. Decisões em aberto
1. **Fonte da arte** para lixo, naves e chefes: IA de imagem (recomendado), CC0 ou artista?
   Se for IA: qual ferramenta você usa?
2. Manter o **neon** como identidade (tiros, escudo, pickups brilhando) junto com o 2.5D? (recomendado: sim)
3. Fazer isso **antes** ou **depois** do O2 (formações) e da publicação?

---

## Status

**Nave do jogador (antecipado do A6): concluído (05/11/2026)**
- [x] Nave v3 realista (metal com volume, painéis, rebites, cabine com moldura, canhões) em 5 poses de rolagem — `tools/gen_ship.gd`
- [x] Efeitos de voo: uma chama lisa por bocal (cresce acelerando, verga nas curvas), propulsor lateral, vapor nas pontas das asas, linhas de velocidade

**A1 — Asteroides 2.5D: concluído (05/11/2026)**
- [x] `shaders/asteroid_field.gdshader`: esfera irregular iluminada que gira em 3D (crateras, relevo, poros, brilho especular, translucidez, veios emissivos)
- [x] 7 materiais (`scripts/art/rock_materials.gd`) e quais aparecem em cada setor; o gelo do Setor 5 usa o material GELO
- [x] Pedaços da explosão na cor do material; dano escurece e o tiro faz piscar como antes
- [x] Teste: a menor silhueta do shader cobre o círculo que machuca a nave
- [x] Comportamentos por material (11/11/2026): cristalino garante orbe; vulcânico solta brasas avisadas — sobre os sprites desenhados atuais (ESPEC_ASTEROIDES.md, seção 10)
- [ ] Medir FPS em aparelho de entrada (A7: opção "Gráficos: simples")
