# Astra Dodge — Plano: Cartas (oficina, carga dos chefes e conquistas)

> Uma camada "roguelite" por cima do jogo atual: **cartas** mudam o estilo de jogo de cada
> partida. Três fontes: a **oficina** (carta inicial), a **carga dos chefes** (cartas no meio da
> partida) e as **conquistas** (desbloqueiam cartas para sempre).
> Data: 05/11/2026.

Princípios que continuam valendo: **um dedo**, partidas curtas, todo perigo avisado, nada de
"pagar para ganhar". As cartas mudam **como** você joga, não deixam o jogo trivial.

---

## 1. Como funciona (o ciclo)

```
OFICINA (escolhe 1 carta inicial)  →  DECOLA  →  joga o setor / o Infinito
      ↑                                              │
      │                              chefe derrotado → CONTÊINER DE CARGA
      │                                              │  (pausa: escolha 1 de 3 cartas)
      │                                              ↓
  CONQUISTAS ← metas cumpridas ← ... continua com mais cartas até o fim/morte
 (cartas novas para sempre)
```

- **Mão da partida:** até **5 cartas** ativas. Pegar uma carta que já tem = **sobe de nível** (I → II → III).
- **Escolha no meio do jogo:** o jogo **pausa**, aparecem **3 cartas grandes**, toca-se em uma
  (cabe no "um dedo": é fora da ação). Uma das 3 pode ser "Reparo" (escudo cheio) para nunca ser
  uma escolha ruim.

---

## 2. As três fontes

### 2.1 Oficina (antes de decolar)
- Nova tela entre o menu e o "Toque para pilotar": mostra as cartas **liberadas** e o jogador
  escolhe **1** para começar. Primeira vez: só 3 cartas disponíveis (ensina o sistema).
- Na campanha: a oficina aparece ao **começar um setor** (não ao continuar do checkpoint).
- No Infinito e no Desafio do Dia: ao começar a partida. **No Desafio do Dia a carta inicial é
  sorteada pela semente do dia** (todo mundo igual).

### 2.2 Contêiner de carga (no meio da partida)
- **Chefes** (fim de setor e os chefes do Infinito a cada 3 min) derrubam um **contêiner de carga**
  dourado. Encostar nele → escolha de carta.
- **Naves-mãe / chefes intermediários (novo):** no meio de cada setor (≈ 75 s), uma **nave-mãe**
  pequena atravessa a tela (30–40 s de luta, 1 padrão de ataque, vida baixa). Derrotada, solta um
  contêiner. Se escapar, nada acontece (sem punição).
- Campanha: as cartas **continuam entre os setores** (como a arma), e o checkpoint guarda a mão.
  Ao morrer, recomeça o setor com a mão que tinha no começo dele.

### 2.3 Conquistas (desbloqueio permanente)
- Lista de metas com progresso visível (tela "CONQUISTAS" no menu).
- Cada conquista libera **cartas** novas ou **modificadores** do Infinito. As estrelas continuam
  liberando skins.

---

## 3. Cartas (primeira leva — 18)

| Categoria | Carta | Efeito (nível I → III) |
|---|---|---|
| **Arma** | Ricochete | tiros quicam 1 vez em metal/borda → 2 → 3 vezes |
| | Perfurante | tiros atravessam 1 poeira → 2 → 3 |
| | Leque Lateral | +2 tiros diagonais a cada 1,2 s → 0,9 → 0,6 s |
| | Mini-mísseis | 1 míssil teleguiado a cada 2 s → 1,5 → 1 s (mira a poeira mais próxima) |
| | Canhão Pesado | tiros mais lentos e maiores, dano ×2 → ×2,5 → ×3 |
| | Raio Carregado | segurando parado 1 s, solta um raio que atravessa tudo na coluna |
| **Escudo** | Escudo Explosivo | quando o escudo quebra (último golpe), explode e limpa rochas em volta |
| | Recarga | o escudo para de drenar por 5 s após coletar orbe → 8 → 12 s |
| | Espelho | 1 tiro inimigo refletido a cada 6 s → 4 → 2 s |
| | Segunda Chance | 1 vez por partida, sobrevive à "última chance" com 30% de escudo |
| **Coleta** | Ímã | alcance do ímã de orbes/cristais ×1,5 → ×2 → ×2,5 |
| | Garimpeiro | +25% de cristais → +50% → +75% |
| | Médico | orbes curam +50% → +100% → +150% |
| **Movimento** | Câmera Lenta | soltar o dedo deixa o tempo mais lento por mais tempo (respirar) |
| | Fantasma | depois de levar dano, invencível por +0,5 s → +1 → +1,5 s |
| **Risco** | Vidro | dano recebido ×2, pontos ×1,5 → ×1,8 → ×2 |
| | Sem Freio | velocidade +15%, cristais ×2 |
| **Especial** | Drone Aliado | um drone pequeno ao lado atira junto (1 → 2 → 3 drones) |

Raridade: **comum** (aparece mais), **rara**, **épica** (Raio Carregado, Drone Aliado, Segunda Chance).

---

## 4. Conquistas (primeira leva — 15)

| Conquista | Meta | Libera |
|---|---|---|
| Sobrevivente | sobreviver **30 min** no Infinito | carta Segunda Chance |
| Arma no Talo | chegar à arma nível 5 sem levar dano por 60 s | Canhão Pesado |
| Minerador | destruir 1.000 poeiras (total) | Garimpeiro |
| Sem Arranhão | derrotar qualquer chefe sem entrar em "última chance" | Espelho |
| Ricocheteiro | acertar 200 ricochetes em metal | Ricochete |
| Colecionador | coletar 500 orbes | Médico |
| Caçador | derrotar 3 naves-mãe numa partida | Mini-mísseis |
| Campanha | completar a campanha | Drone Aliado |
| Perfeição | 3 estrelas em qualquer setor | Perfurante |
| Fendeiro | completar o Setor 8 sem perder o checkpoint | Raio Carregado |
| Maratona | 10 chefes no Infinito numa partida | modificador "Chefes em Dobro" |
| Vidraceiro | 5 min no Infinito com Vidro nível III | modificador "Escudo Frágil" |
| Velocista | 2 min com Sem Freio | modificador "Velocidade Máxima" |
| Retrô | 3 min no Infinito sem coletar cristal | modificador "Retrô" |
| Diário | jogar 7 Desafios do Dia | skin especial |

(Os modificadores hoje são liberados por estrelas; passam a ser liberados por conquistas.)

---

## 5. Equilíbrio e justiça
- Cartas fortes têm custo (Vidro, Sem Freio) ou cooldown.
- Teste automático por carta: o bot completa um setor com cada carta e a rota segura continua
  existindo (cartas não podem criar morte inevitável).
- No Desafio do Dia, as escolhas de carta são as mesmas para todos (semente do dia).
- Pontuação do Infinito informa a mão usada (recorde "com cartas").

## 6. Técnico (resumo)
- `scripts/cards/card_data.gd` (Resource: id, nome, categoria, raridade, níveis) e um catálogo `.tres`.
- `CardHand` na partida: aplica os efeitos (ganchos em Ship, BulletLayer, PickupLayer, Main).
- Telas: Oficina, Escolha de Carta (3 cartas), Conquistas.
- Save: cartas liberadas, progresso das conquistas, mão no checkpoint.
- Nave-mãe: novo inimigo intermediário (reaproveita a base `Boss` com vida baixa e 1 padrão).

## 7. Roadmap

| Etapa | Entrega |
|---|---|
| **C1** | Base: catálogo, mão (5 cartas, níveis), tela de escolha de 3 cartas; contêiner nos chefes; 6 cartas (Ricochete, Perfurante, Ímã, Médico, Escudo Explosivo, Vidro) |
| **C2** | Oficina (carta inicial) + cartas na campanha (entre setores e no checkpoint) |
| **C3** | Naves-mãe no meio dos setores + contêiner |
| **C4** | Conquistas (tela, progresso, desbloqueios) + mais 12 cartas |
| **C5** | Equilíbrio com testes por carta + Desafio do Dia com cartas pela semente |

## 8. Decisões em aberto
1. **Nome**: "cartas" mesmo, ou "módulos"/"upgrades" (combina com nave)?
2. **Mão máxima**: 5 cartas está bom?
3. **Campanha**: cartas continuam entre setores (recomendado) ou zeram a cada setor?
4. **Naves-mãe** no meio de todo setor, ou só a partir do Setor 2?
5. Prioridade: fazer as cartas **antes** ou **depois** do resto da Fase 1 (física P/M/G, materiais)?

---

## 9. Decisões (05/11/2026)
1. **Nome: MÓDULOS** (no formato de cartas). No texto do jogo: "módulo", "contêiner de carga".
2. **Mão: até 3 módulos.** Pegar um que já tem sobe o nível (I → II → III).
3. **Campanha: os módulos continuam entre os setores** (e o checkpoint guarda a mão).
4. **Naves-mãe em todos os setores.**
5. **O sistema começa ao derrotar o chefe do Setor 1**: a Rocha-Mãe solta o primeiro contêiner
   (e a tela ensina o que são módulos). Antes disso, nada de módulos/oficina.

---

## Status

**C1 — Base dos módulos: concluído (05/11/2026)**
- [x] `scripts/modules.gd`: catálogo, mão de 3 com níveis I–III, oferta de 3 cartas (com REPARO quando faltam opções)
- [x] Contêiner de carga dourado que os chefes derrubam (puxado até a nave); a Rocha-Mãe solta o primeiro (a tela explica o que são módulos); o chefe final não solta
- [x] Tela de escolha com 3 cartas coloridas pela categoria; o jogo pausa e volta com "toque para pilotar"
- [x] 6 módulos: Ricochete (metal e bordas), Perfurante, Ímã, Médico, Escudo Explosivo, Vidro
- [x] Campanha: a mão segue para o próximo setor e vai para o checkpoint; morrer recomeça o setor com a mão do começo dele
- [x] Testes: regras da mão/oferta, contêiner abre a escolha, efeitos, próximo setor e checkpoint

**C3 — Naves-mãe: concluído (05/11/2026)**
- [x] Nave-mãe (40 de vida) cruza o alto da tela aos 60 s de todos os 8 setores, atirando leques de 5 com aviso (canhão brilha antes)
- [x] Derrubada: +300 pontos e contêiner de módulo; no Setor 1 (módulos ainda bloqueados) dá escudo + cristal
- [x] Se cruzar a tela sem cair, foge e não dá nada
- [x] Casco desenhado dentro do círculo de colisão
- [x] Testes: está nos 8 setores, morre a tiro, prêmio certo por setor, fuga sem prêmio
