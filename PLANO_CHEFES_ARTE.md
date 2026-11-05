# Astra Dodge — Plano: redesenho visual dos 8 CHEFES (estilo cartoon detalhado)

> **Versão 2 (05/11/2026).** Substitui a versão anterior deste plano, que previa SVG gerado por código.
> Agora o alvo é o **mesmo estilo das rochas e do lixo novos** (`sprite_test/`): cartoon pintado,
> contorno escuro grosso, sombreado suave, luz de cima à esquerda, muito detalhe.
> **Só muda o desenho.** Ataques, avisos, vida, colisão, fases e rota segura ficam **iguais**.
> Como os chefes estão hoje: [`sprite_test/chefes_atuais.png`](sprite_test/chefes_atuais.png).

---

## 0. Regras (não podem piorar)

1. **Mesma silhueta e mesmo tamanho**: o desenho novo cobre os mesmos círculos de colisão de hoje
   (teste "fora do desenho" ≤ 5%). Quem já sabe onde mirar continua sabendo.
2. **Ponto fraco é a única coisa que brilha**: núcleo, olho ou coração em cor quente brilhante (glow
   HDR, pulsando em código). Armadura = opaca, sem brilho. Ponto fraco **fechado** = coberto (pálpebra,
   placa, rocha) — "fechado = ricochete" tem que ser lido de longe.
3. **Cor de inimigo**: corpo escuro/terroso + detalhes quentes (vermelho, laranja, âmbar). Ciano e
   magenta são do jogador (exceção: Núcleo da Fenda e Medusa, temas roxos, com contorno quente).
4. **Avisos não mudam**: a arte só acompanha (canhão acende, boca abre) — o aviso vermelho continua.
5. **Leve no A5**: corpo em PNG; só as **partes que se mexem** são sprites separados; animação em
   código (giro, balanço, respiração ±2%, luz pulsando). Nada de folha de quadros grande.

---

## 1. O estilo (referência: as folhas de `sprite_test/`)

| Traço | Como fica nos chefes |
|---|---|
| Contorno escuro grosso (4–6 px no tamanho final) | em volta do corpo e de cada parte separada |
| Sombreado suave em 2–3 tons + realce claro no canto superior esquerdo | volume sem parecer 3D realista |
| Muito detalhe pequeno (crateras, rebites, arranhões, lascas) | painéis, cabos, chapas, veias, quitina |
| Formas "gordinhas" e arredondadas | chefe ameaçador, mas no mesmo mundo cartoon da nave e das rochas |
| Brilho só nos cristais (como os cristais da folha) | o mesmo brilho vai no ponto fraco |

---

## 2. Chefe por chefe — exemplos

Cada chefe: **o que mantém** (mecânica), **como fica** (exemplo do visual novo) e **o que gerar**
(peças separadas). O prompt de cada um está na seção 4.

### 1. Rocha-Mãe (Setor 1)
- **Mantém**: rocha redonda (raio 210) que gira; 4 núcleos na borda (abre/fecha); racha em 2 metades na fase 2; leque de pedras.
- **Como fica**: um asteroide **gigante cinza-azulado igual às rochas grandes da folha**, com crateras fundas e relevo, mas com **4 sondas de mineração enferrujadas** cravadas na borda. Em cada sonda, um **cristal vermelho-alaranjado** (no estilo dos cristais da folha) — é o núcleo. Fechado: a sonda fecha uma tampa de rocha por cima. Rachaduras finas com **brilho de lava** no meio do corpo, anunciando a fase 2.
- **Gerar**: corpo inteiro · metade esquerda e direita (com o interior em lava no corte) · núcleo aberto · núcleo fechado (tampa).

### 2. Minerador (Setor 2)
- **Mantém**: corpo (raio 125), olho que abre/fecha (raio 52), broca (raio 48), raio-trator, pedaços arremessados, carga com explosão.
- **Como fica**: **nave-fábrica amarela gasta** com listras de perigo pretas e amarelas, chaminés soltando fumaça, esteiras dos lados e uma **broca enorme com dentes** embaixo. O olho é uma **lente vermelha grande** com **pálpebra blindada** de metal rebitado.
- **Gerar**: corpo · broca (separada, gira) · olho aberto · pálpebra fechada · bocal do raio-trator (apagado/aceso).

### 3. Medusa (Setor 3)
- **Mantém**: cúpula, núcleo (raio 46), 3 tentáculos que chicoteiam, nódulos do escudo na fase 2 (raio 34).
- **Como fica**: **água-viva espacial** roxa translúcida, cúpula com **veias e órgãos visíveis** por dentro, borda ondulada, pintas claras. Tentáculos grossos com **ventosas** e ponta farpada. O núcleo é um **coração laranja** pulsando no meio da cúpula; os nódulos são bolhas âmbar presas na borda.
- **Gerar**: cúpula · 1 segmento de tentáculo + ponta (encadeados em código) · nódulo · núcleo.

### 4. Cruzador Fantasma (Setor 4)
- **Mantém**: casco largo, 2 canhões que miram, lançador de mísseis, ponte (raio 50) com escudo até os canhões caírem, fase "fantasma".
- **Como fica**: **cruzador de guerra cinza-escuro amassado**, com chapas rebitadas, **número de casco pintado** ("CF-04"), antenas e luzes vermelhas. Canhões em **torres redondas** com cano duplo. A ponte é uma **cúpula de vidro com brilho âmbar** (o ponto fraco). Na fase fantasma, o mesmo desenho verde-acinzentado translúcido (feito em código, sem sprite novo).
- **Gerar**: casco · torre do canhão (gira) · lançador (fechado/aberto) · ponte · canhão destruído (destroço).

### 5. Colosso de Gelo (Setor 5)
- **Mantém**: corpo (raio 128), núcleo (raio 44), anel de placas que gira com fendas, avalanche.
- **Como fica**: **bloco de gelo azul facetado** com reflexos brancos e uma **máquina antiga congelada** dentro (engrenagens escuras aparecendo pelo gelo). As placas do anel viram **lâminas de gelo** com borda branca; a fenda entre elas fica escura. Núcleo = **cristal vermelho-quente** preso no gelo (contraste forte com o azul).
- **Gerar**: corpo · 1 lâmina do anel (repetida em código) · núcleo · corpo trincado (fase 2).

### 6. Rainha da Colmeia (Setor 6)
- **Mantém**: corpo de inseto, coração (raio 40), asas, guardas do enxame (raio 26), ovos.
- **Como fica**: **vespa-rainha gigante** com carapaça marrom-esverdeada brilhante (quitina), **olhos compostos vermelhos**, mandíbulas, abdômen listrado com **bolsas de ovos**. O coração aparece entre **placas do tórax** que se abrem. Asas finas e translúcidas com nervuras.
- **Gerar**: corpo · asa (2 poses, espelhada em código) · coração · guarda (inseto pequeno) · ovo.

### 7. Sentinela (Setor 7)
- **Mantém**: corpo preso no teto (raio 140), olho (raio 42), 2 braços-canhão (raio 46), drones de reparo (raio 24), grade.
- **Como fica**: **IA de estação espacial**: carcaça octogonal cinza com **painéis, monitores e cabos grossos** saindo para cima. O olho é uma **lente com íris vermelha** que segue a nave. Braços articulados com canhão na ponta; drones pequenos e redondos com braço de solda.
- **Gerar**: corpo · braço (2 segmentos) · íris do olho · drone · braço destruído (faíscas).

### 8. Núcleo da Fenda (Setor 8, chefe final)
- **Mantém**: corpo (raio 130), núcleo (raio 46), anéis girando, rachaduras que crescem por fase, inclinação da tela.
- **Como fica**: **esfera de rocha escura** (como as rochas pretas da folha) envolta por **anéis de metal antigo com runas**, rachaduras de onde sai **luz magenta** com contorno laranja. O núcleo é uma **joia magenta-violeta** (como o cristal roxo da folha). Na fase 3, pedaços da casca flutuam em volta.
- **Gerar**: corpo (3 níveis de rachadura) · anel de metal (girado em código) · núcleo · 4 pedaços da casca.

---

## 3. Como fazer

| Passo | O quê |
|---|---|
| **Gerar a arte** | 1 folha por chefe no gerador de IA (prompts da seção 4), **PNG com fundo transparente** (ou branco liso), peças separadas com espaço entre elas |
| **Recortar** | `tools/cut_sprites.gd` (já existe, das rochas): tira o fundo, separa as peças, descarta pedacinhos |
| **Preparar** | `tools/gen_boss_sprites.gd` (novo): escala cada peça para a colisão de hoje, marca o ponto de giro, aplica a regra "ponto fraco brilha / armadura opaca", salva em `sprites/ia/boss_*` |
| **Ligar** | ArtSet ganha, por chefe: corpo, corpo de dano, partes (textura + ponto de giro) e luzes. O código do chefe continua decidindo **onde** e **quando** desenhar |
| **Testar** | colisão × desenho (≤ 5%), rota segura S3–S8 com os mesmos valores, ponto fraco com luz em cima, sem borda branca |

Os desenhos atuais continuam como reserva (e no modo Gráficos Simples, se pesar no A5).

---

## 4. Prompts (para o gerador de imagens)

**Base (vai no começo de todos):**
> 2D game sprite sheet for a vertical space shooter, giant boss seen from top-down, cartoon painted style
> with thick dark outline, soft cel shading in 2-3 tones, light from the top-left, lots of small details,
> same style as a cartoon asteroid sprite sheet, each part separated with empty space between them,
> transparent background, no text, no shadow on the ground.

| Chefe | Complemento |
|---|---|
| Rocha-Mãe | huge grey-blue cratered asteroid with 4 rusty mining probes stuck into its edge, each probe holding a glowing orange-red crystal; thin lava-glowing cracks; also: the asteroid split into a left half and a right half with molten interior on the cut; a crystal, and a rock lid covering the probe |
| Minerador | worn yellow industrial mining ship with black-yellow hazard stripes, smokestacks, side tracks, a big separate toothed drill; a large red lens eye; a separate riveted armored eyelid; a separate tractor-beam nozzle off and glowing |
| Medusa | translucent purple space jellyfish dome with visible veins and organs, wavy rim, light spots, glowing orange heart in the middle; separate thick tentacle segment with suckers and a barbed tentacle tip; separate amber bubble node |
| Cruzador | dark grey battered war cruiser, wide hull, riveted plates, painted hull number, antennas, small red lights; separate round turret with twin barrel; separate missile launcher closed and open; separate glass bridge dome glowing amber; separate destroyed turret wreck |
| Colosso de Gelo | faceted blue ice block with white reflections and an old dark machine frozen inside; separate curved ice blade plate with white edge; separate hot red crystal core; the ice block cracked version |
| Rainha | giant queen wasp with glossy brown-green chitin shell, red compound eyes, mandibles, striped abdomen with egg sacs, chest plates around a glowing orange heart; separate translucent veined wing; separate small guard insect; separate egg |
| Sentinela | octagonal grey space-station AI hull with panels, small monitors and thick cables going up; separate eye lens with red iris; separate two-segment articulated arm with a cannon tip; separate small round repair drone with welding arm; separate broken arm with sparks |
| Núcleo da Fenda | dark rocky sphere with glowing magenta cracks outlined in orange, wrapped by ancient metal rings with runes; separate metal ring; separate magenta-violet jewel core; four floating shell fragments; versions with few, medium and many cracks |

---

## 5. Etapas

| Etapa | Entrega | Pronto quando |
|---|---|---|
| **B0 — Amostra** | **Rocha-Mãe** completa no estilo novo (é o 1º chefe e casa direto com as rochas da folha) | você aprova no S20 FE |
| **B1** | Minerador e Medusa | testes de colisão e rota segura passam |
| **B2** | Cruzador e Colosso de Gelo | idem |
| **B3** | Rainha e Sentinela | idem |
| **B4** | Núcleo da Fenda (o mais caprichado) | idem; cena de fuga ok |
| **B5** | Infinito (tom por bioma) e conferência no A5 | sem queda de FPS nas lutas |

---

## 6. Decisões (suas)

1. **Quem gera as imagens**: você, no mesmo gerador que fez as folhas de `sprite_test/` (recomendado:
   grátis e já deu certo), ou eu, pelo gerador do Figma (usa créditos de IA da sua conta)?
2. **Amostra**: começar pela **Rocha-Mãe** (recomendado) ou por outro chefe?
3. **Estado de dano** (corpo rachado na fase 2) e **pedaços na queda**: quer os dois?

---

## 7. Avaliação das folhas geradas (05/11/2026, `sprite_test/*boss*`)

Todas no estilo certo e com muito detalhe. O que falta é **separar as partes que se mexem**:

| Chefe | Nota | Usa como está? | Falta / problema |
|---|---|---|---|
| Rocha-Mãe | ótima | não | 6 cristais desenhados (o jogo tem 4 núcleos que abrem/fecham e giram); faltam as 2 metades da fase 2 |
| Minerador | ótima | quase | brocas laterais já batem com o código; falta a **pálpebra** separada (olho fechado) |
| Medusa | boa | não | tentáculos fixos no desenho (o jogo anima 3 tentáculos); rochas da referência coladas na cúpula |
| Cruzador | ótima | não | canhões fixos (no jogo eles miram e são destruídos); nave alta, o jogo usa casco largo; falta o lançador |
| Colosso de Gelo | excelente | **sim** | corpo + núcleo + lâminas já separadas (o anel tem 5 lâminas: usar 1 repetida) |
| Rainha | excelente | **sim** | asas fixas (ficam paradas, ok); guardas e ovos continuam os atuais |
| Sentinela | ótima | não | canhões fixos (no jogo são braços destrutíveis); cabos para baixo (ela fica presa no teto: virar a imagem resolve) |
| Núcleo da Fenda | excelente | **sim** | anéis no desenho (girar a imagem inteira devagar); rachaduras brilham muito: escurecer para o núcleo continuar sendo o ponto óbvio |

Geral: fundo cinza liso (o recorte resolve); objetos da referência (rochas, meteoro, cristal)
soltos na folha são descartados no recorte.

---

## Status

**B0–B4 — arte nova nos 8 chefes: em teste (05/11/2026)**
- [x] `tools/cut_sprites.gd`: fundo cinza (cor medida nas bordas), `--rect` (peças próximas), `--halo` (brilho em volta)
- [x] `tools/gen_boss_sprites.gd`: máscaras (restos de outras peças), corpo montado no quadrado de cada chefe com o ponto fraco no lugar e conferência de colisão × desenho (todos ≤ 5%)
- [x] Ponto fraco: a arte (olho, coração, joia, cristal) com brilho translúcido e anel pulsando (`Boss._weak_glow`)
- [x] Partes: cristal/tampa da Rocha-Mãe, pálpebra do Minerador, tentáculos com textura e nódulos da Medusa, torres/lançador/destroços do Cruzador, lâminas do Colosso, braços/drones da Sentinela; o Núcleo da Fenda gira devagar
- [x] Cruzador refeito ao desenho novo (decisão: usar o casco "alto"): ponte no centro, canhões nos encaixes (±182, +62), lançador na espinha, colisão do casco = espinha + asas
- [x] `tests/boss_shots.gd`: captura de cada chefe (fase 1 ou 2) para conferir
- [ ] Você testar no celular · B5 (Infinito com tom por bioma, conferir no A5)
