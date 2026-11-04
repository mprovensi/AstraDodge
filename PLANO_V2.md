# Astra Dodge — Plano de Melhorias v2: Campanha, Chefes e Novos Assets

> Evolui o endless runner atual (v1) para uma **campanha com 5 setores**, cada um com mecânica própria e **um chefe no final**, mantendo o **Modo Infinito** e o controle de um dedo.
> Data: 04/11/2026 · Base: commit `25e7b72` + remoção do botão de pausa.

---

## 0. Princípios (o que NÃO pode mudar)

1. **Um dedo, arraste relativo, tiro automático.** Nenhuma fase pode exigir um segundo gesto.
2. **Desviar continua sendo o coração do jogo.** Os chefes são "bullet hell leve": padrões legíveis, sempre com um caminho seguro e com aviso antes (*telegraph*).
3. **Partidas curtas.** Setor de ~2–3 min + chefe de ~60–90 s.
4. **Leitura instantânea:** o que é seu brilha em ciano/magenta; o que é perigo tem forma e cor próprias (vermelho/laranja, contorno duro). Nunca usar só a cor para diferenciar (daltonismo).
5. **Tudo continua leve** para celulares fracos (60 FPS em aparelho de entrada).

---

## 1. Estrutura de jogo

### 1.1 Modos
| Modo | Descrição |
|---|---|
| **Campanha** | 5 setores em sequência. Cada setor = trecho roteirizado + ondas aleatórias + chefe. Desbloqueio progressivo. |
| **Infinito** | O modo atual, agora usando inimigos/hazards dos setores já liberados. Placar de recorde. |
| **Desafio do Chefe** *(v2.1)* | Enfrentar qualquer chefe já derrotado, contra o relógio. |

### 1.2 Fluxo de um setor
```
Intro do setor (nome + 2 s)  →  Trecho 1 (ondas)  →  Evento do setor  →  Trecho 2 (mais denso)
→  "ALERTA" (sirene + tela escurece)  →  CHEFE (barra de vida)  →  Vitória: tela de resultado
```

### 1.3 Progressão dentro da campanha
- **Arma e escudo continuam entre setores** (recompensa por jogar bem). Ao morrer, o jogador **recomeça o setor** com a arma no nível em que entrou nele (checkpoint).
- **Resultado do setor:** pontuação + **até 3 estrelas**:
  - ★ completar o setor;
  - ★ derrotar o chefe sem entrar em "última chance";
  - ★ destruir ≥ 70% da poeira do setor.
- Estrelas liberam **skins de nave** (apenas cosméticas — sem "pagar para ganhar").
- **Reviver por anúncio:** 1 vez por setor (volta no mesmo ponto, com escudo cheio).

---

## 2. Os 5 setores e seus chefes

Cada setor introduz **uma** ideia nova e a mistura com as anteriores.

### Setor 1 — Cinturão de Poeira *(tutorial)*
- **Paleta:** azul-marinho + ciano. **Música:** synthwave atual, mais leve.
- **Novidade:** nada além da v1 — ensina arrastar, coletar orbes e cristais. Dicas curtas na tela nos primeiros 30 s.
- **Evento:** "chuva de poeira" — 10 s de densidade alta para subir a arma.
- **Chefe: ROCHA-MÃE** — asteroide gigante com 4 **núcleos brilhantes** (pontos fracos).
  - Padrão A: solta asteroides pequenos em leque lento.
  - Padrão B: gira e expõe um núcleo de cada vez.
  - Fase 2 (50%): racha ao meio; as duas metades descem alternadas pelos lados.
  - Ensina: "atire no ponto que brilha".

### Setor 2 — Campo Metálico
- **Paleta:** aço + âmbar. **Música:** mais pesada, baixo distorcido.
- **Novidades:** metálicos que **se movem lateralmente**; **corredores estreitos** roteirizados; asteroide **blindado** (poeira com casca: o 1º tiro tira a casca).
- **Evento:** "paredão" — fileira de metálicos com uma única brecha que se desloca.
- **Chefe: MINERADOR** — drone industrial de mineração.
  - Padrão A: **raio-trator** (faixa vertical marcada 1 s antes, depois dispara).
  - Padrão B: lança **cargas** que explodem em cruz após 1,5 s (círculo de aviso).
  - Fase 2: puxa metálicos para si e os arremessa em linha reta.

### Setor 3 — Nebulosa Iônica
- **Paleta:** violeta + verde-ácido. **Música:** pads etéreos, arpejo rápido.
- **Novidades:** **nuvens iônicas** (drenam o escudo 3× mais rápido enquanto você está dentro); **minas iônicas** (explodem em anel quando você se aproxima — atire de longe); visibilidade reduzida nas bordas.
- **Evento:** "tempestade" — relâmpagos marcam colunas que serão atingidas.
- **Chefe: MEDUSA** — criatura de plasma com tentáculos.
  - Padrão A: tentáculos varrem da esquerda para a direita (arco com brecha).
  - Padrão B: **espirais** de projéteis lentos (clássico bullet hell, densidade baixa).
  - Fase 2: corpo fica invulnerável; é preciso destruir os 3 tentáculos primeiro.

### Setor 4 — Destroços da Frota
- **Paleta:** vermelho-ferrugem + laranja. **Música:** marcial, tambores.
- **Novidades:** **primeiros inimigos que atiram** — *torretas* presas em destroços (tiro mirado lento) e *drones* em formação (descem em V). Inimigos soltam mais cristais.
- **Evento:** "emboscada" — drones entram pelos lados.
- **Chefe: CRUZADOR FANTASMA** — nave grande **multi-partes** que ocupa a largura da tela.
  - Partes destrutíveis: 2 canhões laterais, 1 lançador de mísseis, ponte de comando (núcleo).
  - Destruir cada parte remove um padrão de ataque (o jogador escolhe a ordem).
  - Mísseis teleguiados lentos que podem ser abatidos.

### Setor 5 — Fenda Gravitacional *(final)*
- **Paleta:** preto + branco + magenta. **Música:** synthwave épico, tema do jogo em tom maior no final.
- **Novidades:** **poços gravitacionais** que curvam os tiros e puxam a nave levemente; **portais** que reposicionam asteroides.
- **Evento:** "inversão" — por 8 s os asteroides vêm de baixo (a nave pode subir até 70% da tela).
- **Chefe: NÚCLEO DA FENDA** — 3 fases, revisita ataques dos chefes anteriores numa versão nova.
  - Fase 1: anéis concêntricos com brechas giratórias.
  - Fase 2: invoca "ecos" da Rocha-Mãe e do Minerador.
  - Fase 3: a tela inteira gira lentamente; padrão final + **cena de fuga** (motor de dobra restaurado — fecha a história).

### 2.1 Regras de design para todos os chefes
- **Barra de vida** no topo (substitui a pontuação durante a luta) com marcas nas transições de fase.
- **Todo ataque tem aviso** de 0,6–1,2 s (linha/círculo/brilho vermelho + som).
- **Sempre existe uma rota segura**; validada por teste automático (simulação de padrão).
- **Fase 2 em 50% de vida** com mudança visual (cor, velocidade) e 1 s de pausa dramática.
- **Pontos fracos piscam** ao receber dano; dano em armadura faz faísca e som metálico (já temos ricochete).
- **Derrota do chefe:** câmera lenta, cadeia de explosões, chuva de orbes e cristais.
- Duração-alvo: **60–90 s** com arma nível 3.

---

## 3. Novo conjunto de assets

### 3.1 Direção de arte
Manter e elevar a estética **neon vetorial**, coerente com o ícone já criado:
- **Pipeline próprio SVG → PNG** (o mesmo de `tools/gen_icons.gd`): todos os sprites desenhados como SVG em `art/`, renderizados em várias resoluções por script. Vantagens: estilo 100% consistente, sem licenças, fácil de ajustar cor por setor.
- **Glow HDR** continua (só o que é "energia" brilha); inimigos ganham brilho **vermelho/laranja**.
- **Shaders** para dar acabamento "premium" sem pesar:
  - *hit flash* e *dissolve* (morte de inimigos/chefes);
  - fundo de **nebulosa procedural** por setor (ruído fBm animado, cores da paleta);
  - leve *chromatic aberration* em impactos fortes de chefe (desligável);
  - linhas de varredura CRT opcionais (opção "Retrô").
- **Fonte de interface:** trocar a fonte padrão por uma fonte sci-fi livre (ex.: **Orbitron** ou **Exo 2**, licença OFL) — registrar em `CREDITS.md`.

### 3.2 Lista de assets
| Categoria | Itens |
|---|---|
| **Nave do jogador** | Nave base redesenhada (3 quadros de inclinação esquerda/centro/direita) + **4 skins** desbloqueáveis por estrelas |
| **Asteroides** | Poeira (3 formas × 3 tamanhos), blindado (com casca), metálico (3 formas), metálico móvel (com propulsor) |
| **Hazards** | Nuvem iônica, mina iônica, poço gravitacional, portal, destroço com torreta |
| **Inimigos** | Drone, torreta, míssil teleguiado |
| **Chefes** | 5 chefes, cada um **em partes separadas** (corpo, núcleos, braços/tentáculos, canhões) para animar por código |
| **Projéteis inimigos** | Bolha (lenta), losango (mirado), míssil, raio (faixa) — formas diferentes, não só cores |
| **Pickups** | Orbe de escudo e cristal redesenhados + **cristal grande** (dropado por chefe/inimigo, +1 nível direto) |
| **VFX** | Explosões em 3 tamanhos, onda de choque (anel), faíscas, fumaça, aviso de ataque (linha/círculo/coluna) |
| **Fundos** | 5 nebulosas (shader) + 3 camadas de estrelas/objetos distantes por setor (planetas, estações em silhueta) |
| **UI** | Mapa de setores, cartões de setor, estrelas, barra de chefe, tela "ALERTA", tela de resultado, botões e painéis com cantos chanfrados |
| **Áudio — música** | 5 temas de setor + 1 tema de chefe (variação por setor) + tema de vitória + tema do menu — em **camadas (stems)** para música adaptativa (ver 3.3) |
| **Áudio — efeitos** | Todos os sons atuais refeitos em versão realista (ver 3.3) + sirene de alerta, tiro inimigo, carga de raio, dano no chefe, armadura, explosão de chefe, transição de fase, estrela ganha, desbloqueio |

### 3.3 Áudio mais realista

Hoje todos os sons são 8-bit sintetizados (ótimos para protótipo, mas "finos"). A meta é um som **cinematográfico**: peso, textura e espaço — como em filmes de ficção científica (no vácuo não haveria som; o "realismo" aqui é o do cinema).

**Abordagem híbrida (recomendada):**
- **Gravações reais como base** para impactos, explosões, metal e destroços, vindas de bibliotecas **livres para uso comercial**:
  - *Sonniss GDC Game Audio Bundles* (royalty-free, uso comercial sem atribuição);
  - *Freesound* — **somente CC0**;
  - *Kenney* (CC0).
  - Cada arquivo registrado em `CREDITS.md` com origem e licença.
- **Síntese por cima** para o que é "energia" (lasers, escudo, cristais), mas com timbre mais rico: osciladores desafinados, ruído filtrado, *pitch envelopes* e cauda com reverb — mantém a identidade neon sem soar "bip".

**Como cada som fica mais realista — em camadas:**
| Som | Camadas |
|---|---|
| **Explosão de asteroide** | *transiente* (estalo seco gravado) + *corpo* (rocha quebrando) + *sub-grave* (impacto 40–60 Hz) + *destroços* (pedrinhas caindo, cauda de 0,5–1 s) |
| **Explosão de chefe** | sequência de 4–6 explosões + rugido grave + "chuva" de metal + cauda longa com reverb |
| **Tiro do jogador** | ataque elétrico curto + "zap" sintetizado + leve eco; volume e brilho sobem com o nível da arma |
| **Ricochete no metálico** | batida metálica gravada + ressonância ("ping") + faísca |
| **Impacto no escudo** | batida abafada + zumbido elétrico de energia + distorção curta |
| **Motor da nave** | *loop* contínuo de propulsor (ruído grave filtrado) que responde à velocidade do arraste |
| **Coletas** | brilho cristalino (sinos/vidro processados) em vez de bip quadrado |
| **Chefes** | assinatura sonora própria: rangido de rocha (Rocha-Mãe), servo-motores (Minerador), vozes aquáticas (Medusa), sirenes de bordo (Cruzador), drone grave pulsante (Núcleo) |

**Técnicas de mixagem e motor de áudio (Godot):**
- **3 a 5 variações** de cada som frequente (tiro, impacto, explosão) + variação de pitch/volume → acaba a repetição "metralhadora".
- **Estéreo posicional:** sons acompanham a posição na tela (asteroide explodindo à esquerda soa à esquerda) via `AudioStreamPlayer2D`/pan.
- **Bus de reverb** por setor (campo aberto, nebulosa "molhada", interior de destroços metálicos) e **compressor** no master.
- **Ducking:** a música abaixa um pouco em explosões grandes e na entrada do chefe (sidechain), deixando o impacto em primeiro plano.
- **Limite de vozes por tipo** (ex.: no máximo 4 explosões simultâneas) para não embolar.
- **Música adaptativa por camadas:** bateria/baixo/melodia/tensão entram e saem conforme a intensidade; transição para o tema do chefe **no tempo da música** (no compasso).
- **Música com produção melhor:** baterias com samples reais (CC0), estéreo, reverb e sidechain — continua synthwave, mas "de estúdio".
- **Formatos:** música em **OGG Vorbis** (streaming, menor tamanho); efeitos curtos em WAV. Meta: áudio total < 25 MB.
- **Vibração sincronizada** com explosões e impactos (curta, média, longa).
- **Opções:** volume separado de música e efeitos (barra 0–100%), além dos interruptores atuais.

**Ferramentas:** Audacity ou REAPER (gratuito para avaliar) para editar/camadas; o gerador `tools/gen_audio.gd` continua para os sons sintetizados e para protótipos rápidos.

---

## 4. Mudanças técnicas

| Sistema | O que muda |
|---|---|
| **Dados de setor** | Novo recurso `SectorData` (`.tres`): paleta, música, duração, lista de **ondas** (linha do tempo de eventos) e chefe. Permite criar/ajustar fases sem mexer em código. |
| **Spawner** | Passa de "linhas aleatórias" para **ondas roteirizadas + preenchimento aleatório**, mantendo a regra do corredor livre. |
| **Entidades** | Classe base `Enemy` (vida, hitbox, pontos, drops, flash) e `Hazard`; asteroides passam a usá-la. |
| **Projéteis inimigos** | Novo pool (como o de tiros do jogador), com padrões reutilizáveis: leque, espiral, mirado, anel, linha. |
| **Chefes** | Classe `Boss` com **máquina de estados** (entrada → padrões → transição → morte) e partes com vida própria. Cada chefe = uma cena + script de padrões. |
| **Avisos** | Sistema `Telegraph` (linha, círculo, coluna) com tempo de aviso padronizado. |
| **Câmera/efeitos** | Câmera 2D dedicada (shake, zoom leve em chefes), pós-processo com shaders opcionais. |
| **Save** | Progresso por setor (desbloqueado, estrelas, melhor pontuação), skins, estatísticas. Migração do save atual sem perder o recorde. |
| **Telas** | Menu principal (Campanha / Infinito / Opções), mapa de setores, resultado, pausa com "Sair do setor". |
| **Testes** | Teste de fumaça por setor; **teste de rota segura** dos padrões dos chefes (simula a nave procurando caminho); captura automática de screenshots (já temos `--write-movie`). |
| **Áudio** | `Sfx` passa a ter: variações por som, pan estéreo pela posição, limite de vozes por tipo, buses de reverb por setor, compressor, ducking da música e música adaptativa por camadas sincronizada ao compasso. |
| **Opções novas** | Reduzir tremor de tela, reduzir flashes, modo retrô (CRT), volume de música e de efeitos (0–100%). |

---

## 5. Roadmap (sprints de ~1 semana)

> **Recomendação:** publicar a **v1 atual no teste fechado** do Google Play **já**, para correr os 14 dias obrigatórios enquanto a campanha é construída. Atualizações durante o teste fechado são permitidas.

| Sprint | Entrega | Critério de pronto |
|---|---|---|
| **S1 — Fundação** | `SectorData`, ondas roteirizadas, classe `Enemy`, pool de projéteis inimigos, `Telegraph`, menu principal com Campanha/Infinito | Setor 1 jogável do início ao fim (sem chefe), Infinito igual ao atual |
| **S2 — Arte e áudio** | Pipeline SVG→PNG para sprites, shaders (flash, dissolve, nebulosa), fonte nova, nave redesenhada, asteroides novos. **Motor de áudio novo** (variações, pan, reverb, compressor, ducking) + **efeitos realistas do Setor 1** (explosões em camadas, tiro, ricochete, escudo, motor, coletas) | Setor 1 com arte e som novos rodando a 60 FPS no S20 FE e num aparelho de entrada |
| **S3 — Chefe 1 + resultado** | Classe `Boss`, Rocha-Mãe (com assinatura sonora), barra de chefe, tela "ALERTA", tela de resultado com estrelas, save de progresso, **música adaptativa em camadas** com transição para o tema de chefe | Setor 1 completo; teste de rota segura passando |
| **S4 — Setor 2** | Metálicos móveis, blindado, paredão, Minerador, música do setor | Setores 1–2 completos |
| **S5 — Setor 3** | Nuvens/minas iônicas, tempestade, Medusa | Setores 1–3 completos |
| **S6 — Setor 4** | Torretas, drones, mísseis, Cruzador Fantasma (multi-partes) | Setores 1–4 completos |
| **S7 — Setor 5 + final** | Gravidade, portais, inversão, Núcleo da Fenda, cena de fuga, tema de vitória | Campanha completa |
| **S8 — Polimento** | Skins, balanceamento com testadores, acessibilidade, otimização, **mixagem final** (volumes, ducking, teste em fone e alto-falante do celular), novos screenshots/vídeo da loja | Release v2.0 |

> Cada setor (S4–S7) inclui seus sons próprios: assinatura sonora do chefe, música do setor em camadas e efeitos das novas mecânicas.

**Cortes possíveis se o prazo apertar** (nesta ordem): modo Desafio do Chefe → skins → modo retrô → setor 5 vira atualização posterior (lançar com 4 setores).

---

## 6. Métricas de sucesso (medir com os testadores)
- ≥ 60% dos jogadores completam o Setor 1 na primeira sessão.
- Tempo médio para derrotar cada chefe dentro de 60–90 s.
- Nenhum padrão de chefe com taxa de "morte inevitável" (feedback "não tinha como desviar").
- 60 FPS estáveis em aparelho de entrada; APK/AAB < 80 MB (áudio < 25 MB).
- Testadores avaliam o som como "encorpado/satisfatório" e ninguém relata som repetitivo ou cansativo após 10 min.

---

## 7. Decisões em aberto
1. Número de setores no lançamento da v2: **5** (recomendado) ou **3** + atualizações?
2. Arma: manter entre setores (recomendado) ou zerar a cada setor?
3. Publicar a v1 no teste fechado agora (recomendado) ou esperar a campanha?
4. Fonte: Orbitron (mais "sci-fi") ou Exo 2 (mais legível)?
5. Som: híbrido gravação + síntese (recomendado) ou 100% gravações? Os downloads de bibliotecas (Sonniss/Freesound CC0) precisam da sua autorização caso a caso.
