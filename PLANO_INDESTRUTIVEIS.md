# Astra Dodge — Plano: arte nova das partes INDESTRUTÍVEIS

> Objetivo: refazer tudo que **não quebra** (metal, paredões, lixo, cometas, portões, poços, portais,
> nuvens) com mais detalhe, no **mesmo estilo que já funciona no jogo**: a nave v3 (metal com volume,
> painéis, rebites, luz de cima à esquerda) e as rochas novas (folhas de giro 3D pré-renderizadas).
> Substitui a etapa A3 do [PLANO_ARTE_25D.md](PLANO_ARTE_25D.md) e a 2.2 do [PROXIMOS_PASSOS.md](PROXIMOS_PASSOS.md).
> Data: 05/11/2026 · base: commit `1947008`.

---

## 0. Regras (não podem piorar)

1. **Ler em meio segundo**: indestrutível = **aço escuro + luz âmbar de alerta**. Nunca a cor das
   rochas (que quebram) nem ciano/magenta (do jogador). O tiro continua ricocheteando com faísca.
2. **Colisão = desenho**: o teste "colisão × desenho" passa a cobrir cada peça nova (≤ 5% fora).
3. **Justiça das fileiras**: a brecha continua garantida (teste FILEIRAS JUSTAS sem mudança).
4. **Leve no celular antigo**: nada de shader pesado em tempo real (foi o que deu errado no A1).
   Tudo **pré-renderizado** em PNG/folhas de quadros, como as rochas. Brilho só nas luzes pequenas.
5. **Gráficos: Simples** continua funcionando (menos quadros e sem luzes piscando).

---

## 1. O que existe hoje (inventário)

| Peça | Onde aparece | Como é desenhada hoje | Problema |
|---|---|---|---|
| **Bloco de metal** | fileiras de todos os setores | octógono escuro plano + 2 rebites + faixa amarela (`metal_s{N}_{1..2}`) | repetitivo, "adesivo", não gira |
| **Paredão / corredor** | S1–S4 (paredão), S2 (corredor) | a mesma fileira de blocos | parece uma fila de placas iguais |
| **Paredes móveis** | S7 (estação) | blocos de metal deslizando | não parece parte de estação |
| **Fileira invertida** | S8 | blocos vindo de baixo | igual às outras |
| **Destroço da torreta** | S4 | bloco de metal girado + canhão em linhas | parece um bloco comum com um tubo |
| **Cometa** | S5 | círculo + rastro em código | sem núcleo de gelo/rocha, rastro reto |
| **Portão de laser** | S7 | linha + emissores em código | emissores sem volume |
| **Poço gravitacional** | S8 | círculo tracejado | não parece um "buraco" |
| **Portal** | S8 | anéis ciano/magenta | ok, mas sem profundidade |
| **Nuvem iônica** | S3 | mancha + contorno tracejado | ok, só falta textura |

---

## 2. Como fazer (mesmo caminho das rochas e da nave)

| Técnica | Para quê | Ferramenta |
|---|---|---|
| **SVG detalhado gerado por código** | peças de metal com painéis, rebites, cortes, sombras em gradiente (como `tools/gen_ship.gd`) | `tools/gen_junk.gd` (novo) |
| **Folha de giro 3D pré-renderizada** | peça girando devagar em 3D (12 quadros, 4×3, igual às rochas) — o giro é desenhado no PC, o celular só troca o quadro | `tools/bake_junk.gd` (novo, reaproveita `bake_rocks.gd`) |
| **Camada de luz separada** | luz âmbar, janelas, emissores: um PNG pequeno por cima, o único que brilha (glow HDR) | `ArtSet` |
| **Efeito em código** | rastro do cometa, feixe do portão, distorção do poço: partículas e linhas, leves | `hazards.gd` |

- Luz sempre de **cima à esquerda** (igual nave e rochas). Contorno escuro de 2 px para destacar do fundo.
- Cada setor tem a sua **família de peças** (mesmo formato de colisão, desenhos diferentes) — fim da repetição.

---

## 3. As peças novas

### 3.1 Lixo espacial (substitui o bloco de metal)

Fase **J1**: todas cabem no **círculo atual** (a jogabilidade não muda). Fase **J3**: peças compridas
com vários círculos.

| Peça | Visual | Colisão | J |
|---|---|---|---|
| **Placa de casco** | chapa curva com rebites, borda rasgada, faixa de alerta | 1 círculo | J1 |
| **Turbina** | cilindro com bocal queimado (fuligem) visto de cima | 1 círculo | J1 |
| **Satélite morto** | corpo cúbico + antena parabólica amassada | 1 círculo | J1 |
| **Contêiner amassado** | caixa com faixas pretas/amarelas e número pintado | 1 círculo | J1 |
| **Tanque esférico** | esfera de metal com cintas e válvula | 1 círculo | J1 |
| **Viga / treliça** | barra comprida em X | 3 círculos em linha | J3 |
| **Painel solar quebrado** | placa azul escura em grade, moldura torta | 2–3 círculos | J3 |

Todas giram devagar (folha de 12 quadros) e têm **uma luz âmbar** piscando (camada de luz).

### 3.2 Família por setor

| Setor | Tema das peças | Cor do metal |
|---|---|---|
| 1 Cinturão | sucata comum (placas, tanques) | aço cinza |
| 2 Campo Metálico | peças de mineração (brocas, caçambas, trilhos) | aço amarelado/gasto |
| 3 Nebulosa Iônica | sondas e antenas com faíscas azuis | aço azulado |
| 4 Destroços | pedaços do cruzador (casco grosso, canhões mortos) | aço escuro queimado |
| 5 Gelo | peças congeladas (camada de gelo por cima) | aço + gelo |
| 6 Colmeia | metal coberto de resina orgânica | aço + resina âmbar |
| 7 Estação | contêineres, dutos, painéis da estação | aço claro com faixas |
| 8 Fenda | peças derretidas/torcidas | aço escuro + brilho magenta fraco |

### 3.3 Paredões e paredes

- **Paredão / corredor (S1–S4)**: em vez de blocos iguais lado a lado, **segmentos de destroço
  encaixados** (a mesma colisão por bloco, mas o desenho alterna peças e liga uma à outra com cabos).
  A brecha ganha **luzes de pista** verdes fracas nas bordas (lê "passe aqui" sem mudar a regra).
- **Paredes móveis (S7)**: módulos de estação (painel + duto + luz de trilho), com setas âmbar
  mostrando o lado para onde deslizam.
- **Fileira invertida (S8)**: as mesmas peças da Fenda, com rastro magenta fraco embaixo
  (mostra que vêm de baixo).

### 3.4 Perigos do ambiente

| Perigo | Novo visual |
|---|---|
| **Cometa (S5)** | núcleo de gelo/rocha (folha de giro) + cabeleira clara + rastro curvo de partículas; o aviso em linha não muda |
| **Destroço da torreta (S4)** | pedaço de casco do cruzador (do kit do S4) com a torreta presa em cima |
| **Portão de laser (S7)** | emissores com volume (caixas de metal com bobinas), feixe com núcleo branco + borda vermelha; o "tique" antes de ligar acende as bobinas |
| **Poço gravitacional (S8)** | disco escuro com anel de acreção que gira e estrelas sendo puxadas; o contorno tracejado (alcance exato) continua |
| **Portal (S8)** | anel de metal com 4 travas + interior em espiral (ciano entrada / magenta saída) |
| **Nuvem iônica (S3)** | textura de nuvem em 3 camadas com faíscas internas; o contorno tracejado (área exata) continua |

---

## 4. Técnico

- **ArtSet**: `junk_sheets(setor)` (folhas de giro por setor), `junk_lights` (camada de luz por peça),
  texturas dos perigos. O código nunca aponta direto para um PNG (regra atual).
- **Asteroides**: o metal passa a usar a folha de giro da família do setor (mesmo cálculo de
  quadro da poeira: `spin_rate`, `spin_phase`).
- **J3 (vários círculos)**: `Asteroid.bodies` (lista de círculos relativos) para peças compridas;
  `hit_test`, colisão com a nave, `clear_around` e a regra da brecha passam a usar os círculos.
  Mexe na jogabilidade → só depois de você aprovar.
- **Desempenho**: folhas de 192 px por quadro (igual às rochas); no **Simples**, 4 quadros e luz fixa.
- **Testes novos**: colisão × desenho de cada peça e de cada quadro; FILEIRAS JUSTAS com peças
  compridas (J3); FPS medido nos 2 celulares (contador do modo dev).

---

## 5. Roadmap

| Etapa | Entrega | Pronto quando |
|---|---|---|
| **J0 — Amostras** | 3 peças (placa, turbina, contêiner) girando no Setor 1, para você aprovar | você aprova no S20 FE e no A5 |
| **J1 — Lixo nos 8 setores** | 5 peças × 8 famílias, folhas de giro + luz âmbar, no lugar do bloco de metal | testes passam; FPS igual ao de hoje |
| **J2 — Paredões e paredes** | paredão/corredor encaixado com cabos e luzes de pista; paredes da estação; fileira invertida | rota segura e fileiras justas passam |
| **J3 — Peças compridas** | viga e painel solar com vários círculos | você aprova a jogabilidade; testes novos |
| **J4 — Perigos do ambiente** | cometa, destroço da torreta, portão, poço, portal, nuvem | colisão/área exata igual à de hoje |
| **J5 — Gráficos Simples** | versão leve de tudo + medição no A5 | A5 sem queda de FPS |

---

## 6. Decisões em aberto

1. **Fonte da arte**: gerada por código e pré-renderizada (recomendado, igual à nave e às rochas)
   ou imagens de IA preparadas pela ferramenta?
2. **Luzes de pista na brecha** do paredão: quer? Ajudam a ler, mas facilitam um pouco.
3. **J3 (peças compridas)** muda a jogabilidade: fazer agora ou deixar para depois?
4. **Ordem**: antes ou depois das naves inimigas e do [plano dos chefes](PLANO_CHEFES_ARTE.md)?

---

## Status

**J0 — Amostras: pronto para você aprovar (05/11/2026)**
- [x] `tools/bake_junk.gd`: monta a peça em 3D (sombreado estilizado), gira e balança e grava 24 quadros + a camada da luz âmbar
- [x] 3 peças no Setor 1 no lugar do bloco de metal: placa de casco, turbina (as pás giram), contêiner octogonal
- [x] Sem giro no plano: a luz pintada fica sempre de cima à esquerda; a luz âmbar pisca por cima
- [x] Teste LIXO ESPACIAL: colisão dentro do desenho em todos os quadros (pior 0,2%), peça escura, cada peça com a sua luz
- [ ] Aprovar no S20 FE e no A5 → J1 (8 famílias)

**J1 — Lixo nos 8 setores: concluído (05/11/2026)**
- [x] 4 peças por setor (32 no total), cada setor com a sua família: sucata (1), mineração com broca (2), sondas e satélites (3), canhões do cruzador (4), peças com gelo (5), metal com resina da colmeia (6), dutos e contêineres da estação (7), metal escuro com veios magenta da Fenda (8)
- [x] Peças novas: tanque esférico, satélite, broca, canhão morto, duto
- [x] Memória do celular antigo: só as folhas do setor em jogo ficam carregadas (no máximo 2 setores); a luz âmbar virou um ponto calculado no bake (posição e quanto aparece por quadro), sem folha extra
- [x] Teste LIXO ESPACIAL: 32 peças × 24 quadros, colisão dentro do desenho, peça escura, luz âmbar dentro do quadro e visível em boa parte do giro
- [ ] Medir no A5 (FPS e memória) → J2 (paredões e paredes)

**J2 — Paredões e paredes: concluído (05/11/2026)**
- [x] Paredão, corredor e parede móvel: peças vizinhas ligadas por 2 cabos (nunca atravessam a brecha)
- [x] Luzes de pista verdes nas duas peças da brecha, piscando em sequência para dentro (fixas no modo Simples)
- [x] Parede móvel (Setor 7): setas âmbar mostram para que lado ela está indo
- [x] Inversão (Setor 8): rastro magenta fraco embaixo das rochas (lê "vem de baixo")
- [x] Teste FILEIRAS JUSTAS: todas as peças na mesma parede, luzes nas duas bordas, cabos fora da brecha

**J4 — Perigos do ambiente: concluído (05/11/2026)**
- [x] Cometa: núcleo de gelo girando (folha do Setor 5), cabeleira e cauda de partículas que ondula; contorno quente
- [x] Torreta do Setor 4 em cima de um pedaço de casco do cruzador (lixo do Setor 4)
- [x] Portão de laser: emissores de metal com 3 bobinas (acendem no aviso, vermelhas ligado)
- [x] Poço: estrelas puxadas em espiral até o olho
- [x] Portal: anel de metal com 4 travas e miolo em espiral (entrada gira para dentro, saída para fora)
- [x] Nuvem iônica: 3ª camada de névoa e faíscas presas dentro
- [x] Áreas e colisões iguais às de antes (contornos tracejados mantidos)
