# Astra Dodge — Plano: trocar meteoros e lixo pelos sprites de `sprite_test/`

> Avaliação das 2 folhas geradas por IA (`sprite_test/*.jpg`, 2048×2048) e como usá-las no jogo.
> Data: 05/11/2026 · base: J4 (lixo 3D pré-renderizado nos 8 setores).

---

## 1. Avaliação

### O que é bom
- **Estilo forte e coerente**: desenho "cartoon pintado" com contorno preto grosso, luz de cima à
  esquerda (a mesma do jogo). Lê muito bem em tela pequena.
- **Rochas com personalidade**: crateras, lascas, cores bem diferentes (cinza, vermelho, marrom,
  quase preto, bege). Resolve o "todos iguais" de hoje.
- **Lixo muito variado**: painéis solares, satélites, canos, chapas, engrenagens, motor, bocal,
  contêiner amassado — bem mais rico que as 4 peças por setor de hoje.
- **Extras aproveitáveis**: pedrinhas/lascas (pedaços da explosão), bolas de fogo (meteoro em
  chamas / Setor 8 vulcânico), cristais (cristalino, ícones de cartas).
- Resolução boa: cada objeto tem 300–450 px (o jogo usa 192–256).

### Problemas (precisam de tratamento)
| # | Problema | Efeito no jogo | Solução |
|---|---|---|---|
| P1 | **JPG com fundo branco** (sem transparência) | borda branca em volta (o "halo" que você já viu antes) | recorte por cor a partir das bordas + limpeza do contorno; melhor: **gerar de novo em PNG transparente** |
| P2 | **Pedrinhas soltas em volta das rochas** | parecem objetos que machucam e não machucam | o recorte descarta pedaços pequenos separados; viram partículas de explosão |
| P3 | **Rochas repetidas**: as 3 cinzas e as 3 vermelho-rosadas são quase iguais | sobra ~8 rochas realmente diferentes | girar no plano, espelhar, variar tamanho e cor por setor; pedir mais variações |
| P4 | **Metal claro (prata) e rochas escuras** | quebra a regra de leitura do jogo (poeira CLARA quebra, metal ESCURO não quebra) — o teste atual reprova | escurecer o lixo ~40% + luz âmbar piscando; clarear as rochas marrom-escuras **ou** mudar a regra (decisão 2) |
| P5 | **Peças compridas** (canos, painéis, satélite com braços, Sputnik, antena, treliça, fios) | não cobrem o círculo de colisão → tiro e nave "atravessam" o desenho | usar só as peças "gordas" como obstáculo; as compridas viram **destroços de fundo** (sem colisão) ou esperam a J3 (vários círculos) |
| P6 | **Desenho parado** (sem giro 3D) | perde o giro 3D das rochas atuais | giro no plano + leve "respiração"; no estilo cartoon isso funciona bem (decisão 1) |
| P7 | **Mina com espinhos** parece a mina inimiga | confunde obstáculo com inimigo | usar como **arte da mina inimiga** (Setor 3), não como lixo |

---

## 2. O que usar onde

### Rochas (destrutíveis)
| Grupo da folha | Setores |
|---|---|
| Cinza com crateras (3 + rachada + pequena) | 1 Cinturão, 5 Gelo (tingida de azul) |
| Vermelho-rosada / vermelha | 2 Campo Metálico (ferroso) |
| Quase preta / marrom-escura | 3 Nebulosa, 8 Fenda (com veios acesos por cima) |
| Marrom / bege / cinza-bege (2ª folha) | 4 Destroços, 6 Colmeia, 7 Estação |
| Bolas de fogo | 8 (rochas vulcânicas) e um obstáculo novo "meteoro em chamas" (avisado como o cometa) |
| Pedrinhas e lascas | partículas da explosão das rochas (no lugar dos pontinhos atuais) |

### Lixo espacial (indestrutível) — só peças que cobrem o círculo
| Peça | Uso |
|---|---|
| Contêiner amassado, chapa dobrada (×3), peça azul quebrada | obstáculo, todos os setores |
| Bocal de motor, peça circular com flange, bobina do motor, ventoinha | obstáculo |
| Tanque dourado com fios | obstáculo (é um pouco comprido: só no tamanho grande) |
| Engrenagens | obstáculo do Setor 2 (mineração) e Setor 7 |
| Painéis solares, canos, satélite, Sputnik, antena, treliça, fios | **fundo** (camada de destroços passando devagar, sem colisão) até a J3 |
| Mina com espinhos | arte da **mina inimiga** do Setor 3 |
| Cristais | material cristalino (Setor 3) e ícones das cartas de módulo |

O lixo 3D atual (J1) **continua** como reserva e no modo Gráficos Simples, se precisar.

---

## 3. Como fazer

1. **`tools/cut_sprites.gd`** (novo): lê a folha, apaga o fundo branco começando pelas bordas
   (o branco dentro do contorno fica), separa cada objeto, descarta pedacinhos soltos, recorta,
   centraliza num quadrado e salva `sprites/ia/rock_*.png` / `junk_*.png` (256 px).
2. **Escolha**: uma tabela no próprio script diz qual recorte vai para qual setor e tipo.
3. **Ajuste de leitura**: rochas e lixo passam pela regra de brilho (decisão 2); lixo ganha a
   luz âmbar (ponto fixo por peça, como hoje).
4. **ArtSet**: rochas e lixo por setor usam as imagens novas, girando no plano.
5. **Testes**: colisão × desenho de cada recorte (≤ 5%), brilho (regra), sem borda branca
   (nenhum pixel quase branco encostado na transparência).
6. **Fundo**: camada de destroços com as peças compridas, devagar e escurecida (não confunde).

---

## 4. Etapas

| Etapa | Entrega |
|---|---|
| **S1** | `cut_sprites.gd` + recortes de tudo; folha de conferência para você aprovar |
| **S2** | Rochas novas nos 8 setores (com pedrinhas na explosão) |
| **S3** | Lixo novo (peças gordas) + luz âmbar |
| **S4** | Destroços de fundo (peças compridas), mina inimiga, bolas de fogo |
| **S5** | Medir no A5 e ajustar |

---

## 5. Decisões (suas)

1. **Giro**: rochas cartoon girando só no plano (recomendado) ou manter o giro 3D atual e usar
   as imagens só no lixo?
2. **Regra de leitura**: manter "poeira clara / metal escuro" (escureço o lixo e clareio as
   rochas escuras — recomendado) ou trocar por "metal = cinza com rebites + luz âmbar" e deixar
   as cores originais?
3. **Gerar de novo em PNG transparente e sem pedrinhas soltas?** (recomendado: o recorte fica
   perfeito). Se sim, eu escrevo os prompts no SPRITES.md, incluindo mais variações das rochas
   cinza e vermelhas.
4. **Lixo 3D atual (J1)**: substituir de vez ou misturar (metade 3D, metade desenho)?
