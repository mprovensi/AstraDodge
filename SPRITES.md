# Trocar sprites usando outra IA (ou um artista)

Guia para gerar sprites novos **fora do projeto** (outra IA de imagem, artista, banco de imagens)
e colocá-los no jogo sem quebrar nada.

## Resumo do processo

1. Escolha o sprite na tabela abaixo e copie o **prompt** dele para a outra IA.
2. Confira a imagem recebida com o **checklist** (tamanho, fundo transparente, orientação).
3. Salve em `sprites/` com **exatamente o mesmo nome** (substituindo o antigo).
4. Abra o Godot (ou rode `--import`): ele reimporta sozinho, mantendo o mesmo `.import`.
5. Veja no jogo: peça ao Claude "ver o jogo rápido" (ou "ver o chefe do setor N").
6. Rode os testes: o teste de **colisão x desenho** avisa se um chefe ficou com formato
   diferente da área de colisão (evita "dano sem encostar").
7. Se algo ficou fora do lugar (motores da nave, encaixes dos chefes), ajuste as posições —
   ver **"Pontos de encaixe"** abaixo.

> **PNG trocado à mão é protegido:** `tools/gen_sprites.gd` só recria um PNG a partir do SVG
> quando o SVG for **mais novo** que o PNG. Para voltar à arte vetorial original, apague o PNG
> (ou edite/salve o SVG) e rode o gerador.

## Regras para TODA imagem (checklist)

- [ ] **PNG com fundo transparente** (canal alfa). Nada de fundo preto, branco ou "xadrez" desenhado.
- [ ] **Tamanho exato** da tabela (quadrado, exceto o Cruzador, que é 2:1).
- [ ] **Objeto centralizado**, sem encostar nas bordas (deixe ~4% de margem).
- [ ] **Sem sombra externa, sem texto, sem moldura.**
- [ ] **Vista de cima** (top-down), luz vindo de cima/esquerda.
- [ ] Estilo do jogo: **neon vetorial / retro sci-fi** — preenchimentos escuros e **contornos claros**.
      Na nave, as partes claras brilham (glow); evite nave toda clara (vira um borrão de luz).
- [ ] Inimigos/perigos em tons **vermelho/laranja**; o que é do jogador em **ciano/magenta**.

## Tabela de sprites

| Arquivo (`sprites/`) | Tamanho | Orientação / formato | Encaixes (pixels da imagem) |
|---|---|---|---|
| `ship.png` | 256×256 | nave, **nariz para CIMA** | motores (117,197) e (139,197); ponta (128,14) |
| `dust_1.png` … `dust_3.png` | 256×256 | rocha cinza **redonda**, ocupa ~92% do raio | — |
| `metal_1.png` … `metal_3.png` | 256×256 | bloco de aço escuro **redondo**, ~94% do raio | — |
| `dust_shell.png` | 256×256 | **só o anel** de placas de aço; **centro transparente** | — |
| `boss_rock_mother.png` | 512×512 | rocha gigante redonda, ~95% do raio | núcleos desenhados pelo jogo **na borda** |
| `boss_rock_mother_half.png` | 384×384 | metade **ESQUERDA** da rocha: lado redondo à esquerda, **lado quebrado à direita** | (a direita do jogo é esta imagem espelhada) |
| `boss_miner.png` | 512×512 | drone industrial, **frente para BAIXO** | olho no **centro** (256,256); brocas em (80,392) e (432,392) |
| `boss_medusa.png` | 512×512 | cúpula de água-viva (só a cúpula) | núcleo no **centro** (256,256); tentáculos saem de ~y 320 |
| `boss_cruiser.png` | **1024×512** | nave de guerra **larga**, vista de cima | canhões (220,300) e (804,300); lançador (512,184); ponte (512,280) |
| `ice_1.png`, `ice_2.png` | 256×256 | bloco de **gelo** facetado azul-claro, **redondo**, ~92% do raio (racha ao quebrar) | — |
| `boss_ice_colossus.png` | 512×512 | bloco de gelo gigante **redondo** (~94% do raio) | núcleo no **centro** (256,256), encaixe ~160 px; as placas em volta o jogo desenha |
| `boss_hive_queen.png` | 512×512 | inseto rainha visto de cima, **cabeça para BAIXO**: abdômen em cima, tórax no centro, cabeça embaixo | coração no **centro** (256,256), encaixe ~120 px; corpo: abdômen centro (256,130) raio ~110, tórax raio ~120, cabeça centro (256,398) raio ~65 |
| `boss_sentinel.png` | 512×512 | núcleo de IA **octogonal** de aço, preso ao teto (cabos em cima) | olho no **centro** (256,256), encaixe ~110 px; corpo: círculo de raio ~200 px; braços e drones o jogo desenha |
| `boss_rift_core.png` | 512×512 | esfera escura de matéria distorcida com **borda magenta** e rachaduras de luz (~88% do raio) | núcleo no **centro** (256,256), encaixe ~110 px; halo giratório o jogo desenha |

O jogo **desenha por cima** (não precisam estar na imagem): núcleos/olhos dos chefes,
tentáculos da Medusa, canhões/lançador/ponte do Cruzador, chamas dos motores, escudo da nave.
Na imagem deixe só **encaixes vazios** (círculos/placas escuras) nesses pontos.

## Prompts prontos

Copie, cole na outra IA e anexe um print do jogo como referência de estilo, se ela aceitar.

### Nave do jogador — `ship.png`
```
Sprite 2D para jogo mobile de nave, estilo neon vetorial retro sci-fi, vista de cima.
PNG 256x256 com fundo TRANSPARENTE, sem sombra, sem texto, objeto centralizado com margem.
Caça espacial com o nariz apontando para CIMA. Casco azul-marinho escuro com contornos
ciano/branco bem visíveis, cabine de vidro azul, faixas magenta nas asas.
Dois motores na traseira, centrados em x≈117 e x≈139, y≈197. Ponta do nariz em (128,14).
```

### Poeira (destrutível) — `dust_1.png` (repita para 2 e 3 com formatos diferentes)
```
Sprite 2D de asteroide pequeno para jogo mobile, vista de cima, estilo vetorial limpo.
PNG 256x256 com fundo TRANSPARENTE, sem sombra externa, sem texto.
Rocha cinza-clara REDONDA (levemente irregular) centralizada, ocupando ~92% do raio da imagem,
com 3–4 crateras e luz vindo de cima/esquerda. Contorno claro fino.
```

### Metálico (indestrutível) — `metal_1.png` (repita para 2 e 3)
```
Sprite 2D de bloco metálico flutuante para jogo mobile, vista de cima, estilo vetorial.
PNG 256x256 com fundo TRANSPARENTE, sem sombra, sem texto.
Forma REDONDA/octogonal centralizada (~94% do raio), aço muito escuro com placas,
rebites e arranhões; borda de aço azulada clara. Deve parecer pesado e indestrutível.
```

### Casca da poeira blindada — `dust_shell.png`
```
Sprite 2D para jogo mobile: APENAS um anel de placas de aço (4 segmentos com rebites),
PNG 256x256 com fundo e CENTRO TRANSPARENTES (a rocha aparece por baixo no jogo).
Anel centralizado com raio externo ~95% e espessura ~25% do raio. Aço azulado com brilho.
```

### Chefe 1 — Rocha-Mãe — `boss_rock_mother.png`
```
Sprite 2D de chefe para jogo mobile, vista de cima. PNG 512x512, fundo TRANSPARENTE.
Asteroide GIGANTE avermelhado e escuro, REDONDO, centralizado (~95% do raio), com crateras
e rachaduras incandescentes laranja. Sem núcleos (o jogo desenha 4 núcleos na borda).
```

### Chefe 1 — metade rachada — `boss_rock_mother_half.png`
```
PNG 384x384, fundo TRANSPARENTE. Metade ESQUERDA do mesmo asteroide avermelhado:
lado esquerdo arredondado, lado DIREITO quebrado em zigue-zague com a borda em brasa laranja.
O pedaço centralizado na imagem.
```

### Chefe 2 — Minerador — `boss_miner.png`
```
Sprite 2D de chefe para jogo mobile, vista de cima. PNG 512x512, fundo TRANSPARENTE.
Drone industrial de mineração com a FRENTE PARA BAIXO: casco hexagonal cinza-escuro com
faixas de aviso amarelo/preto, dois braços laterais terminando em BROCAS cônicas apontando
para baixo (pontas em ~(80,392) e (432,392)). No CENTRO (256,256), um encaixe circular vazio
escuro com aro amarelo, diâmetro ~150 px (o jogo desenha o olho ali).
```

### Chefe 3 — Medusa — `boss_medusa.png`
```
Sprite 2D de chefe para jogo mobile. PNG 512x512, fundo TRANSPARENTE.
Cúpula de água-viva de plasma, violeta translúcida com brilho interno e manchas
bioluminescentes verde-água, borda de baixo ondulada (saia). SEM tentáculos (o jogo desenha).
No CENTRO (256,256), um encaixe circular escuro de ~130 px de diâmetro (o jogo desenha o núcleo).
A cúpula ocupa de y≈44 até y≈340.
```

### Chefe 4 — Cruzador Fantasma — `boss_cruiser.png`
```
Sprite 2D de chefe para jogo mobile, vista de cima. PNG 1024x512 (LARGO), fundo TRANSPARENTE.
Nave de guerra abandonada e enferrujada, casco alongado na horizontal (pontas afinando à
esquerda e à direita), aço escuro com placas de ferrugem laranja, rombos com bordas em brasa
e luzes espectrais verde-água. Encaixes VAZIOS (círculos/placas escuras) para o jogo desenhar
as partes: canhões em (220,300) e (804,300), lançador em (512,184), ponte em (512,280).
```

## Pontos de encaixe (se a arte nova mudou de lugar)

| O que | Onde ajustar |
|---|---|
| Motores, ponta e tamanho da nave | `data/art/default.tres` pelo Inspetor (`ship_engines_px`, `ship_muzzle_px`, `ship_size`) |
| Quanto a rocha ocupa da imagem | mesmo arquivo (`dust_fill`, `metal_fill`, `boss_fill`) |
| Núcleos/olho/encaixes dos chefes | constantes no topo de cada script em `scripts/bosses/` (`PARTS`, `TENTACLE_BASES`, `DRILL_OFFSETS`…) |
| Área de colisão dos chefes | também nesses scripts (`DOME_BODIES`, `HULL_BODIES`, `HALF_BODY_*`); o teste diz se ficou fora do desenho |

Variações extras (ex.: `dust_4.png`): adicione a textura na lista `dust_textures` do
`data/art/default.tres` — o jogo sorteia entre todas.

## O que são os arquivos `.import`

O Godot não usa o PNG direto: ele **importa** (converte) cada arquivo para `.godot/imported/`.
O `.import` ao lado de cada PNG/WAV guarda **as configurações dessa conversão** e o **uid**
(identificador que o ArtSet e as cenas usam para achar o arquivo).

- Vão para o Git; a pasta `.godot/` não.
- Trocar o PNG **com o mesmo nome** mantém o `.import` (mesmas configurações, mesmo uid).
- Não precisa editar à mão. Exceção conhecida: o **loop das músicas** fica no `.wav.import`
  (`edit/loop_mode=2`) — apagar esse arquivo faz a música parar de repetir.

## Prompts prontos — Setor 5

### Gelo (Setor 5) — `ice_1.png` e `ice_2.png`
```
Sprite 2D de bloco de gelo para jogo mobile, vista de cima, estilo vetorial neon.
PNG 256x256 com fundo TRANSPARENTE, sem sombra, sem texto.
Cristal de gelo REDONDO e facetado, centralizado, ~92% do raio, azul-claro quase branco em cima
e azul-cobalto embaixo, facetas brancas e 2–3 rachaduras escuras (é por onde ele vai rachar).
```

### Chefe 5 — Colosso de Gelo — `boss_ice_colossus.png`
```
Sprite 2D de chefe para jogo mobile, vista de cima. PNG 512x512, fundo TRANSPARENTE.
Bloco de gelo GIGANTE, REDONDO e facetado (~94% do raio), branco-gelo com azul-cobalto nas
bordas, facetas que convergem para o centro e rachaduras escuras. No CENTRO (256,256), um
encaixe circular escuro de ~160 px de diâmetro com aro gelo (o jogo desenha o núcleo).
SEM as placas em volta (o jogo desenha o anel de placas que gira).
```

## Prompts prontos — Setor 6

### Chefe 6 — Rainha da Colmeia — `boss_hive_queen.png`
```
Sprite 2D de chefe para jogo mobile, vista de cima. PNG 512x512, fundo TRANSPARENTE.
Rainha inseto (vespa/abelha alienígena) com a CABEÇA PARA BAIXO: abdômen listrado verde-musgo
em cima (centro ~256,130), tórax âmbar arredondado no centro, cabeça embaixo (centro ~256,398)
com mandíbulas e olhos laranja, 6 patas escuras e asas translúcidas (bem transparentes) nos lados.
No CENTRO (256,256), um encaixe circular escuro de ~120 px com aro dourado (o jogo desenha o coração).
Os insetos e ovos são desenhados pelo jogo (não precisam de imagem).
```

## Prompts prontos — Setor 7

### Chefe 7 — Sentinela — `boss_sentinel.png`
```
Sprite 2D de chefe para jogo mobile, vista de frente/de cima. PNG 512x512, fundo TRANSPARENTE.
Núcleo de inteligência artificial de uma estação espacial abandonada: bloco OCTOGONAL de aço
grafite (ocupa ~90% da imagem), faixas de alarme vermelhas em cima e embaixo, respiros e
painéis nas laterais, cabos saindo do topo (preso ao teto), luzes de status.
No CENTRO (256,256), um encaixe circular escuro de ~110 px com aro claro e anel tracejado
vermelho (o jogo desenha o olho). Braços-canhão e drones são desenhados pelo jogo.
```

## Prompts prontos — Setor 8

### Chefe final — Núcleo da Fenda — `boss_rift_core.png`
```
Sprite 2D de chefe FINAL para jogo mobile. PNG 512x512, fundo TRANSPARENTE.
Esfera de energia escura (quase preta, roxo profundo) centralizada, ~88% do raio, como um
buraco na realidade: borda brilhante MAGENTA com um leve branco na beirada, rachaduras de
luz branco-rosada saindo da borda. No CENTRO (256,256), um encaixe circular escuro de ~110 px
com aro claro e um anel tracejado magenta (o jogo desenha o núcleo e o halo girando).
```
