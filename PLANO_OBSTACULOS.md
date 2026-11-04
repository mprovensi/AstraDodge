# Astra Dodge — Plano: Obstáculos Novos (menos repetição)

> Problema: o "recheio" de todos os setores é sempre o mesmo — poeira cinza redonda e
> metálico escuro redondo, em fileiras aleatórias. As mecânicas especiais (gelo, enxame,
> portões...) aparecem em eventos, mas entre eles o jogo parece igual.
> Data: 05/11/2026.

Regras que continuam valendo: tudo é legível de relance (forma + cor, nunca só cor),
perigo novo sempre tem aviso ou movimento previsível, e o teste de rota segura cobre cada um.

---

## 1. Três frentes (da mais barata para a mais trabalhosa)

| Frente | O que muda | Custo | Impacto na repetição |
|---|---|---|---|
| **A. Visual por setor** | cada setor tem os seus próprios desenhos de poeira e metal | baixo (só arte + ArtSet) | alto |
| **B. Formações** | fileiras deixam de ser só aleatórias: padrões desenhados (V, escada, anel...) | médio | alto |
| **C. Obstáculos novos** | comportamentos novos (girar, explodir, atravessar de lado...) | médio/alto | alto |

Recomendação: **A + B primeiro** (rápido, muda a cara do jogo inteiro), depois os de C aos poucos.

---

## 2. A — Visual por setor

O ArtSet ganha conjuntos de textura **por setor** (cai no padrão se faltar):

| Setor | Poeira (destrutível) | Metal (indestrutível) |
|---|---|---|
| 1 Cinturão | rocha cinza (atual) | bloco de aço (atual) |
| 2 Campo Metálico | minério com veios âmbar | lingote enferrujado, viga quebrada |
| 3 Nebulosa | rocha com cristais violeta | casco escuro com brilho iônico |
| 4 Destroços | pedaço de painel / caixa de carga | pedaço de casco de nave |
| 5 Anel Glacial | (já tem gelo) neve compacta | gelo azul-escuro "eterno" |
| 6 Colmeia | favo seco âmbar | carapaça orgânica escura |
| 7 Estação | contêiner pequeno | bloco de concreto/aço com faixas |
| 8 Fenda | obsidiana com rachaduras magenta | rocha "invertida" (contorno brilhante, miolo vazio) |

- Forma também varia (não só cor): oval, angulosa, comprida — com colisão que acompanha
  (círculo ou dois círculos), conferida pelo teste "colisão x desenho".
- Tamanho mais variado: além das médias, **pedrinhas rápidas** e **pedregulhos lentos**.

---

## 3. B — Formações (padrões desenhados)

Biblioteca de formações; o spawner alterna entre fileira aleatória e uma formação a cada
poucas linhas. Cada formação é validada pelo teste de rota segura (sempre há passagem ≥ nave).

| Formação | Como é | Ensina |
|---|---|---|
| **V / V invertido** | rochas em V; a brecha é no centro ou nas pontas | ler o centro |
| **Escada** | diagonal de metais descendo; passagem segue a diagonal | movimento lateral contínuo |
| **Zigue-zague** | 3–4 paredes curtas alternando lados | ritmo esquerda/direita |
| **Anel** | círculo de metais com uma abertura | entrar e sair |
| **Tabuleiro** | poeira em xadrez (dá para atirar e abrir caminho) | atirar para passar |
| **Funil** | laterais fechando até um corredor estreito | precisão |
| **Chuva fina** | muitas pedrinhas pequenas e rápidas | reflexo |

Peças de código: `scripts/formations.gd` (lista de padrões em coordenadas relativas),
`AsteroidField.spawn_formation(id)`, evento `WaveEvent.Kind.FORMATION` e chance por setor
(`formations` no DENSITY). Entram também no Infinito como blocos baratos.

---

## 4. C — Obstáculos novos

| Obstáculo | Comportamento | Leitura / justiça | Setores |
|---|---|---|---|
| **Haltere giratório** | duas rochas ligadas por uma barra que gira devagar | a barra brilha; giro lento e constante | 2, 4, 7 |
| **Rocha explosiva** | poeira vermelha pulsando; ao ser destruída (ou se a nave encostar) solta um anel de estilhaços | anel de aviso igual ao da mina | 3, 4, 8 |
| **Pedregulho que racha** | poeira gigante (muita vida) que se parte em 4 médias | a rachadura cresce a cada tiro | 1, 2, 5 |
| **Rio de destroços** | fileira de pedrinhas atravessando a tela **de lado**, com uma brecha | aviso em linha horizontal antes | 4, 6, 7 |
| **Satélite** | metal com 2 painéis compridos que giram (colisão só no corpo + painéis) | painéis com contorno claro | 4, 7 |
| **Rocha ricochete** | metal que entra em diagonal e quica nas bordas (como o de propulsor, mas em X) | rastro mostra a direção | 2, 5, 8 |
| **Rocha magnética** | puxa as rochas próximas para ela (forma grupos) | aura tracejada = alcance | 3, 8 |
| **Cápsula de suprimento** | objeto frágil que dá orbe + cristal garantidos se destruído a tempo (recompensa, não perigo) | brilho dourado | todos (raro) |

Cada um entra **primeiro sozinho** (com dica na tela), depois misturado — mesmo esquema dos setores.

---

## 5. Roadmap

| Etapa | Entrega | Pronto quando |
|---|---|---|
| **O1 — Visual por setor** | 2 poeiras + 2 metais por setor (SVG), ArtSet por setor, tamanhos mais variados | cada setor "tem cara própria"; colisão x desenho ≤ 5% |
| **O2 — Formações** | 7 formações, evento FORMATION, chance por setor e no Infinito | teste de rota segura passa em todas |
| **O3 — Obstáculos 1** | haltere giratório, rocha explosiva, pedregulho que racha, cápsula | bot completa todos os setores |
| **O4 — Obstáculos 2** | rio de destroços, satélite, ricochete, magnética | idem + aviso de cada um testado |

Sugestão: O1 e O2 logo depois do lançamento atual (S13); O3/O4 como atualizações.

## 6. Decisões em aberto
1. Fazer O1 (visual por setor) antes ou depois de abrir o teste fechado?
2. Algum obstáculo da lista C que você quer primeiro (ou cortar)?
