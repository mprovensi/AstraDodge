# Astra Dodge — Plano v3: 8 Setores, Modo Infinito e Geração Procedural

> Continua o [PLANO_V2.md](PLANO_V2.md) (Sprints 1–6 prontos: Setores 1–4 com chefes).
> Amplia a campanha de **5 para 8 setores** e transforma o **Modo Infinito** num modo procedural de longa duração.
> Data: 04/11/2026 · Base: commit `a6cf78f`.

Os princípios do v2 continuam valendo: um dedo, desviar é o centro, todo ataque tem aviso, sempre existe rota segura, 60 FPS em aparelho de entrada.

---

## 1. Tamanho do jogo

| | Hoje (4 setores) | Com 8 setores |
|---|---|---|
| Campanha sem morrer | ~16 min | ~35 min |
| Campanha real (com mortes e checkpoints) | ~1 h | **2–4 h** |
| 3 estrelas em tudo | +1 h | +2–3 h |
| Infinito + Desafio do Dia | — | sem fim (rejogabilidade) |

Curva de dificuldade: setores 1–2 ensinam, 3–5 combinam, 6–7 exigem, 8 é o exame final.
Cada setor continua com **~2,5 min de fase + chefe de 60–90 s**.

---

## 2. Os 8 setores

Regra: cada setor traz **uma** mecânica nova e reaproveita as anteriores.
Os setores 5–7 são novos; a **Fenda Gravitacional vira o Setor 8 (final)**.

| # | Setor | Mecânica nova | Evento | Chefe | Status |
|---|---|---|---|---|---|
| 1 | Cinturão de Poeira | básico (arrastar, coletar) | chuva de poeira | Rocha-Mãe | ✅ |
| 2 | Campo Metálico | metálicos móveis, blindados, corredores | paredão | Minerador | ✅ |
| 3 | Nebulosa Iônica | nuvens que drenam, minas | tempestade | Medusa | ✅ |
| 4 | Destroços da Frota | inimigos que atiram (torretas, drones, mísseis) | emboscada | Cruzador Fantasma | ✅ |
| 5 | **Anel Glacial** | asteroides que **se dividem** e **cometas** | chuva de cometas | Colosso de Gelo | novo |
| 6 | **Colmeia** | **enxame** orgânico e **ovos** | eclosão | Rainha da Colmeia | novo |
| 7 | **Estação Abandonada** | **portões de laser** no ritmo e paredes móveis | blecaute | Sentinela | novo |
| 8 | **Fenda Gravitacional** *(final)* | gravidade, portais, inversão | inversão | Núcleo da Fenda | era o Setor 5 |

### Setor 5 — Anel Glacial
- **Paleta:** branco-gelo + azul-cobalto. **Música:** lofi cristalina (sinos, 88 BPM).
- **Novidades:**
  - **Gelo que racha:** asteroide de gelo que, ao quebrar, se divide em 2–3 lascas menores que saem em diagonal. Ensina a atirar cedo, de longe.
  - **Cometas:** atravessam a tela na diagonal, muito rápidos. Linha de aviso de 1 s antes.
- **Evento:** "chuva de cometas" — 4–6 cometas avisados em sequência.
- **Chefe: COLOSSO DE GELO** — bloco gigante cercado de placas de gelo.
  - Padrão A: as placas **refletem** seus tiros (ricochete visível); é preciso mirar nas fendas entre elas.
  - Padrão B: dispara estacas de gelo em leque que racham no meio do caminho em 2.
  - Fase 2: as placas se desprendem e orbitam o corpo; o núcleo fica exposto só quando a órbita abre.

### Setor 6 — Colmeia
- **Paleta:** verde-musgo + âmbar orgânico. **Música:** grave e pulsante, percussão "úmida".
- **Novidades:**
  - **Enxame:** muitos inimigos pequenos e fracos (1 tiro) que seguem a nave de leve, em grupo. Testa a arma em nível alto.
  - **Ovos:** presos em rochas; se não forem destruídos em ~4 s, eclodem em 3 larvas.
- **Evento:** "eclosão" — vários ovos ao mesmo tempo, com contagem visível.
- **Chefe: RAINHA DA COLMEIA**
  - Padrão A: chuva de ácido em colunas (aviso em coluna), deixa poças que somem.
  - Padrão B: põe ovos que caem; ovo destruído solta orbe de escudo (recompensa por agir rápido).
  - Fase 2: o enxame forma um **escudo vivo** em volta dela; é preciso abrir uma brecha atirando.

### Setor 7 — Estação Abandonada
- **Paleta:** cinza-grafite + vermelho de alarme. **Música:** industrial, metrônomo marcado (ritmo = jogabilidade).
- **Novidades:**
  - **Portões de laser:** liga/desliga **no compasso da música**; a cor e o som avisam o próximo pulso.
  - **Paredes móveis:** metálicos encaixados que deslizam abrindo e fechando corredores.
- **Evento:** "blecaute" — a tela escurece por 8 s e só os perigos ficam com contorno aceso.
- **Chefe: SENTINELA** — IA da estação, presa ao teto, com braços.
  - Padrão A: grade de lasers (linhas horizontais e verticais avisadas) com uma célula segura.
  - Padrão B: solta drones de reparo que consertam as partes destruídas (prioridade: derrubar os drones).
  - Fase 2: a arena "fecha" — paredes laterais avançam e a área útil diminui por alguns segundos.

### Setor 8 — Fenda Gravitacional *(final)*
Igual ao Setor 5 do v2:
- poços gravitacionais, portais e inversão;
- **Núcleo da Fenda** em 3 fases, com "ecos" dos chefes anteriores, agora escolhidos entre os 7 chefes;
- cena de fuga e tema de vitória.

---

## 3. Modo Infinito

### 3.1 Como funciona
- **Libera ao completar o Setor 2.** Fica no menu como "INFINITO".
- O jogo é uma sequência sem fim de **trechos** de 20–40 s gerados proceduralmente (ver seção 4).
- A cada ~90 s o **bioma muda** (troca de nebulosa e música) entre os **setores já liberados**, usando as mecânicas de cada um.
- A dificuldade sobe sem parar (velocidade, densidade, mistura de mecânicas).
- **A cada 3 minutos:** um **chefe sorteado** entre os já derrotados, com vida reduzida (~60%) e mais rápido a cada repetição. Vencer dá orbes e cristais.
- A arma começa no nível 1 e sobe normalmente. Não há checkpoint: morreu, acabou.

### 3.2 Pontuação e metas
- **Recorde de pontos** e de **tempo**; multiplicador que sobe sem levar dano e zera ao levar dano.
- **Marcos** na tela: 1 min, 3 min (1º chefe), 5 min, 10 min…
- **Estatísticas** no fim: tempo, chefes derrotados, poeira destruída, bioma mais longe.

### 3.3 Desafio do Dia
- Todo dia uma **semente** diferente (a data). Todos os jogadores recebem **a mesma sequência**.
- Uma tentativa "valendo" por dia (as outras são treino). Recorde próprio do desafio.
- Depois do lançamento: placar online pelo Google Play Games (opcional).

### 3.4 Modificadores *(opcional, depois)*
Liberados por estrelas da campanha, mudam a partida e o multiplicador:
- "Só metal" (×1,5), "Escudo frágil" (×2), "Chefes em dobro" (×1,5), "Retrô" (sem glow, ×1).

---

## 4. Geração procedural no nosso caso

**Sim, dá — e em parte já usamos:**
- o spawner sorteia as fileiras;
- a nebulosa é um shader de ruído;
- todo o áudio é sintetizado por código.

A recomendação é **procedural onde ele brilha e roteirizado onde a qualidade importa**.

| Onde | Usar procedural? | Por quê |
|---|---|---|
| **Modo Infinito (trechos)** | **Sim — principal uso** | variedade sem fim, Desafio do Dia, reaproveita todo o conteúdo |
| Campanha — trechos entre eventos | Sim, leve (já é assim) | sorteio dentro de regras roteirizadas |
| Campanha — eventos e chefes | **Não** | precisam ser pensados, testados e justos; é o que dá identidade |
| Variações dos chefes (velocidade, posição da brecha) | Sim, com limites | evita decorar, sem perder a justiça |
| Formas dos asteroides | Sim | contorno gerado por ruído → nenhum asteroide igual |
| Nebulosa e estrelas | Já é | — |
| Música | Talvez | camadas que entram/saem com a intensidade (música adaptativa) |

### 4.1 Como gerar trechos sem ficar injusto (técnica)
1. **Blocos de construção:** cada mecânica vira um **bloco** — um `WaveEvent` parametrizado (ex.: "paredão com brecha", "3 minas", "nuvem + drones em V", "chuva de cometas"). Os blocos são os mesmos da campanha, então já estão testados.
2. **Orçamento de dificuldade:** cada bloco tem um **custo** (1–10). O orçamento por trecho cresce com o tempo de partida. O gerador sorteia blocos do bioma atual até gastar o orçamento.
3. **Regras de ritmo:**
   - nunca dois blocos pesados seguidos;
   - sempre uma **calmaria** depois de evento ou chefe;
   - mecânicas novas aparecem sozinhas antes de serem misturadas.
4. **Semente:** tudo usa um `RandomNumberGenerator` com semente → a mesma semente gera a mesma partida (Desafio do Dia, replay e reprodução de bugs).
5. **Garantia de justiça:** o teste automático roda **100 sementes com o bot** e confere:
   - rota segura em todos os padrões (os testes de vão ≥ 72 px que já existem);
   - nenhum ponto sem saída;
   - tempo médio de sobrevivência do bot dentro do esperado.

### 4.2 Peças novas de código
- `scripts/endless/endless_director.gd` — gera a linha do tempo sob demanda (alimenta o `SectorDirector` com eventos, em vez de ler um `.tres`).
- `data/endless/blocks.tres` — catálogo de blocos (bioma, custo, parâmetros, frequência).
- `Game`: recordes do Infinito e do Desafio do Dia.
- Teste: `tests/smoke_test.gd` ganha "INFINITO PROCEDURAL" (100 sementes).

---

## 5. Roadmap

O Infinito vem **antes** dos setores novos: reaproveita os 4 setores prontos, já dá rejogabilidade para os testadores, e o gerador de blocos facilita montar os setores 5–8.

| Sprint | Entrega | Pronto quando |
|---|---|---|
| **S7 — Infinito procedural** | catálogo de blocos, orçamento, biomas 1–4, chefe a cada 3 min, recordes, item no menu | 100 sementes passam no teste; recorde salvo |
| **S8 — Desafio do Dia** | semente diária, tentativa valendo, tela de estatísticas | mesma sequência em 2 aparelhos |
| **S9 — Setor 5 (Anel Glacial)** | gelo que racha, cometas, Colosso de Gelo (reflexo de tiros) | setores 1–5 completos |
| **S10 — Setor 6 (Colmeia)** | enxame, ovos, Rainha da Colmeia | setores 1–6 completos |
| **S11 — Setor 7 (Estação)** | portões no ritmo, paredes móveis, blecaute, Sentinela | setores 1–7 completos |
| **S12 — Setor 8 + final** | gravidade, portais, inversão, Núcleo da Fenda, cena de fuga | campanha completa |
| **S13 — Polimento** | skins, modificadores, volumes 0–100%, balanceamento com testadores, loja | release |

Cada setor novo também entra no Infinito como bioma assim que fica pronto.

**Cortes se o prazo apertar** (nesta ordem):
1. modificadores;
2. Desafio do Dia vai para uma atualização;
3. lançar com 6 setores + final (corta o 7);
4. lançar com 4 setores + final (versão do v2).

---

## 6. Decisões em aberto
1. Liberar o Infinito após o Setor 2 (recomendado) ou só após zerar a campanha?
2. Ordem: Infinito primeiro (recomendado) ou setores primeiro?
3. Placar online (Google Play Games) no lançamento ou depois?
4. Os temas dos setores 5–7 (Gelo, Colmeia, Estação) estão bons ou prefere outros?
