# Astra Dodge — Plano: arte nova dos CHEFES

> Objetivo: refazer os 8 chefes com mais detalhe e volume, no **mesmo estilo que já funciona no
> jogo** (nave v3 e rochas com giro 3D pré-renderizado), sem mudar os ataques, os avisos nem a
> rota segura. Substitui a etapa A6 do [PLANO_ARTE_25D.md](PLANO_ARTE_25D.md) e a 3.3 do
> [PROXIMOS_PASSOS.md](PROXIMOS_PASSOS.md). Par deste plano: [PLANO_INDESTRUTIVEIS.md](PLANO_INDESTRUTIVEIS.md).
> Data: 05/11/2026 · base: commit `1947008`.

---

## 0. Regras (não podem piorar)

1. **Ponto fraco sempre óbvio**: núcleo/olho/coração = a **única parte que brilha** (glow HDR,
   pulsando). Armadura = metal/rocha/gelo/carapaça **opaco**. Escudo = anel tracejado (como hoje).
2. **Todo ataque avisado**: o aviso (TelegraphLayer) não muda; a arte só **acompanha** o aviso
   (canhão acende, boca abre, bobina carrega) — nunca o substitui.
3. **Colisão = desenho**: os testes "fora do desenho" de cada chefe continuam (≤ 5%).
4. **Rota segura**: os testes ROTA SEGURA S3–S8 não mudam de valor.
5. **Leve**: corpo pré-renderizado (PNG); partes que se mexem em sprites separados; nada de shader
   pesado em tempo real. Bom no Galaxy A5 (modo Compatibilidade).
6. **Cor de inimigo**: casco escuro + detalhes quentes (vermelho/laranja/âmbar). Ciano/magenta só no
   que é do jogador (exceção: o Núcleo da Fenda, magenta por ser o tema da Fenda — com contorno quente).

---

## 1. O que existe hoje

Cada chefe = **1 sprite plano** (SVG de ~2 KB, formas simples e gradiente) + partes desenhadas em
código (núcleos, canhões, tentáculos, anéis). Fica "vetor plano" ao lado da nave v3 e das rochas novas.

| Chefe | Setor | Sprite hoje | Desenhado em código | Partes que se mexem |
|---|---|---|---|---|
| **Rocha-Mãe** | 1 | rocha redonda + metade | 4 núcleos na borda | gira; racha em 2 metades |
| **Minerador** | 2 | corpo + broca | olho (abre/fecha), raio-trator, pedaços arremessados | olho, broca |
| **Medusa** | 3 | cúpula | núcleo, 3 tentáculos, nódulos, escudo | tentáculos (chicotada) |
| **Cruzador Fantasma** | 4 | casco | 2 canhões, lançador, ponte, escudo, "fantasma" | canhões mirando |
| **Colosso de Gelo** | 5 | bloco de gelo | núcleo, anel de placas girando | anel de placas |
| **Rainha da Colmeia** | 6 | corpo de inseto | coração, guardas do enxame | asas, guardas |
| **Sentinela** | 7 | corpo no teto | olho, 2 braços-canhão, drones de reparo, grade | braços, drones |
| **Núcleo da Fenda** | 8 | esfera com rachaduras | núcleo, anéis, inclinação da tela | anéis, rachaduras |

---

## 2. Como fazer (mesmo caminho da nave)

| Camada | O que é | Como |
|---|---|---|
| **Corpo** | o chefe com volume: painéis, rebites, sombras, desgaste; luz de cima à esquerda | SVG detalhado **gerado por código** (como `tools/gen_ship.gd`) → PNG 2× o tamanho na tela |
| **Partes** | o que se mexe (canhões, broca, tentáculos, placas, braços, metades) | sprites separados com o ponto de giro marcado no ArtSet |
| **Luzes** | ponto fraco, olhos, bocais, bobinas, faixas âmbar | PNG pequeno por cima, o único que brilha; pisca/pulsa em código |
| **Estados** | dano (rachaduras/fumaça a 50%), fase 2, escudo | variação do corpo (`*_dano.png`) + partículas leves |
| **Queda** | explosão em pedaços | o corpo é cortado em 4–6 pedaços (sprites) que voam com fogo |

- **Animação barata**: respiração (escala ±2%), balanço, peças girando, luzes pulsando — tudo em
  código, sobre sprites prontos. Nada de folha de quadros grande (memória do A5).
- Tamanho dos PNGs: 2× o tamanho na tela (ex.: Minerador 500 px → 1000 px); compressão VRAM.

---

## 3. Chefe por chefe

| Chefe | Visual novo | Partes / luzes | Dano (fase 2) |
|---|---|---|---|
| **Rocha-Mãe** | asteroide gigante no estilo das rochas novas (crateras, relevo), com **sondas de mineração cravadas** onde ficam os núcleos | núcleos = cristais incandescentes; o núcleo aberto brilha, os fechados ficam cobertos de rocha | racha com lava no corte; as 2 metades têm o interior quente |
| **Minerador** | nave-fábrica industrial amarela/gasta, com esteiras, chaminés e broca enorme com dentes | olho = lente vermelha com **pálpebra blindada** que fecha (lê "fechado = ricochete"); broca gira; bocal do raio acende antes | chapas soltas, faíscas, fumaça escura |
| **Medusa** | criatura de plasma: cúpula translúcida com órgãos visíveis e veias | tentáculos em segmentos (sprites encadeados) com ventosas; nódulos brilham; núcleo pulsa | cúpula rachada, plasma vazando |
| **Cruzador Fantasma** | cruzador de guerra com casco riscado, números de casco e ponte de comando | canhões giram de verdade (sprite com cano); lançador abre a escotilha antes dos mísseis; escudo da ponte em hexágonos | fase "fantasma": casco translúcido com contorno espectral e estática |
| **Colosso de Gelo** | bloco de gelo facetado com reflexos, máquina congelada dentro | placas do anel = lâminas de gelo com borda clara (a **fenda** entre elas fica escura e fácil de ver); núcleo azul-branco | gelo trincado, lascas caindo |
| **Rainha da Colmeia** | inseto gigante com carapaça brilhante (quitina), olhos compostos, abdômen com bolsas de ovos | coração visível atrás de placas do tórax; asas batendo (2 sprites); guardas = insetos do enxame | carapaça partida, ácido pingando |
| **Sentinela** | IA da estação: carcaça presa ao teto com cabos, painéis e monitores | olho = lente com íris que segue a nave; braços articulados (2 segmentos); drones de reparo com faísca de solda | painéis abertos, cabos soltos soltando faíscas |
| **Núcleo da Fenda** | esfera de matéria escura com anéis de metal antigos em volta, rachaduras de luz | núcleo magenta com contorno quente; anéis de metal giram em eixos diferentes (efeito 3D); rachaduras crescem por fase | fase 3: pedaços da casca flutuando em volta |

---

## 4. Técnico

- **ArtSet**: para cada chefe, `*_body`, `*_body_hurt`, lista de `parts` (textura + ponto de giro +
  posição) e `*_lights`. O código do chefe continua decidindo **onde** e **quando**; só troca o desenho.
- **Colisão**: os círculos de cada chefe **não mudam** (o desenho novo é feito em volta deles). Se um
  desenho pedir colisão nova, isso vira uma decisão sua (muda a dificuldade).
- **Ferramenta**: `tools/gen_bosses.gd` (gera os SVGs detalhados) + `tools/prep_sprite.gd` (recorta,
  centraliza e confere colisão × desenho), para aceitar também imagens de IA no futuro.
- **Testes**: os atuais de colisão × desenho e rota segura de cada chefe; teste novo de que **cada
  ponto fraco tem luz** (camada de luz cobre o círculo que leva dano) e de que a queda solta os pedaços.
- **Gráficos Simples**: sem pedaços na queda, sem partículas de dano, luzes sem pulsar.

---

## 5. Roadmap

| Etapa | Entrega | Pronto quando |
|---|---|---|
| **B0 — Amostra** | **Minerador** completo no estilo novo (corpo, broca, pálpebra, dano, queda) | você aprova no S20 FE e no A5 |
| **B1 — Setores 1–2** | Rocha-Mãe (casando com as rochas novas) e o resto do Minerador | testes de colisão e rota segura passam |
| **B2 — Setores 3–4** | Medusa (tentáculos em segmentos) e Cruzador (canhões girando, fase fantasma) | idem |
| **B3 — Setores 5–6** | Colosso de Gelo e Rainha da Colmeia | idem |
| **B4 — Setores 7–8** | Sentinela e Núcleo da Fenda (chefe final, a mais caprichada) | idem; cena de fuga ok |
| **B5 — Infinito e Simples** | chefes do Infinito com a arte nova (mesmos sprites com tom por bioma); modo Simples | A5 sem queda de FPS nas lutas |

---

## 6. Decisões em aberto

1. **Fonte da arte**: gerada por código e pré-renderizada (recomendado) ou imagens de IA preparadas
   pela ferramenta? (mesma pergunta do plano dos indestrutíveis)
2. **Amostra**: começar pelo **Minerador** (muita peça mecânica, mostra bem o estilo) ou pela
   **Rocha-Mãe** (primeiro chefe que o jogador vê)?
3. **Pedaços na queda** e **estado de dano**: quer os dois? (custo maior de arte, ótimo efeito)
4. **Ordem**: fazer depois dos indestrutíveis (recomendado: o fundo/obstáculos primeiro, chefes
   depois para casar com eles) ou antes?
