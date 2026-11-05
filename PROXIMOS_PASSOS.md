# Astra Dodge — Próximos passos (roteiro único)

> Junta o que está aberto nos planos (ESPEC_ASTEROIDES, PLANO_OBSTACULOS, PLANO_ARTE_25D,
> PLANO_V3) numa ordem só. Atualizado em 05/11/2026 · base: commit `1b6b333`.
> Regra de ouro de cada etapa: **testar nos dois celulares** (S20 FE e Galaxy A5 2017) antes de seguir.

---

## Fase 1 — Asteroides novos (em andamento)

| # | Etapa | Entrega | Depende de você |
|---|---|---|---|
| 1.1 ✅ | **Aprovar o protótipo** | asteroides estilizados girando em 3D no Setor 1 | testar no A5 e aprovar o visual |
| 1.2 ✅ | **Levar aos 8 setores** | folhas de giro para todos (ferroso, cristalino, gelo, carbonáceo, vulcânico, pomes) | — |
| 1.3 | **Física nova (P/M/G)** | 3 tamanhos (raio ≥ 34), vida e velocidade por tamanho | aprovar a tabela da ESPEC |
| 1.4 ✅ | **Contador de FPS (dev)** | número de FPS no canto no modo dev, para medir os 2 celulares | anotar o FPS nos 2 celulares |
| 1.5 | **Comportamento por material** | cristalino solta orbe; vulcânico espirra brasas (avisadas) | — |

## Fase 2 — Variedade (menos repetição)

| # | Etapa | Entrega |
|---|---|---|
| 2.1 | **O2 — Formações** | V, escada, zigue-zague, anel, tabuleiro, funil, chuva fina (sempre com passagem) |
| 2.2 | **Lixo espacial (A3)** | pedaços de casco, vigas, painéis solares, satélites, turbinas, contêineres no lugar dos blocos de metal (mesmo estilo estilizado, colisão por círculos) |
| 2.3 | **Obstáculos novos (O3)** | haltere giratório, rocha explosiva, pedregulho que racha, cápsula de suprimento |

## Fase 3 — Inimigos e chefes

| # | Etapa | Entrega |
|---|---|---|
| 3.1 | **Naves inimigas 1 (A4)** | caça, interceptador, bombardeiro (no lugar dos hexágonos) |
| 3.2 | **Naves inimigas 2 (A5)** | atirador, porta-drones, kamikaze |
| 3.3 | **Chefes no estilo novo (A6)** | os 8 chefes redesenhados no mesmo estilo da nave e das rochas |
| 3.4 | **Obstáculos novos 2 (O4)** | rio de destroços, satélite giratório, ricochete, rocha magnética |

## Fase 4 — Publicação (quando você decidir)

| # | Etapa | Depende de você |
|---|---|---|
| 4.1 | Criar a chave (`tools\criar_chave_release.ps1`) e autorizar o 1º build (.aab) | sim |
| 4.2 | Conta no Play Console + teste fechado (12 testadores, 14 dias) | sim |
| 4.3 | Ajustes de dificuldade com os testadores + imagens/vídeo novos da loja | parte |

---

## Decisões em aberto (resumo)
1. Visual do protótipo de asteroides: aprovado? (1.1)
2. Tabela de tamanhos P/M/G (1.3)
3. Fonte da arte para lixo/naves/chefes: estilizado gerado por mim (recomendado, mesmo caminho dos asteroides) ou IA/artista?
4. Quando publicar.

**Sugestão de ordem:** 1.1 → 1.2 → 1.4 → 1.3 → 2.1 → 2.2 → 3.1 …
