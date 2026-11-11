# Astra Dodge — Próximos passos (roteiro único)

> Junta o que está aberto nos planos (ESPEC_ASTEROIDES, PLANO_OBSTACULOS, PLANO_ARTE_25D,
> PLANO_V3, PLANO_INDESTRUTIVEIS, PLANO_CHEFES_ARTE) numa ordem só. Atualizado em 11/11/2026 · base anterior: commit `7cfa71a`.
> Regra de ouro de cada etapa: **testar nos dois celulares** (S20 FE e Galaxy A5 2017) antes de seguir.
> Os testes da versão anterior nos celulares já foram realizados, conforme informado pelo usuário em 11/11/2026.

---

## Fase 1 — Asteroides novos (implementada)

| # | Etapa | Entrega | Depende de você |
|---|---|---|---|
| 1.1 ✅ | **Protótipo integrado e testado** | asteroides estilizados no Setor 1; testes nos celulares confirmados | — |
| 1.2 ✅ | **Levar aos 8 setores** | 4 rochas e 4 peças de lixo desenhadas por setor; giro no plano (PLANO_SPRITES_IA) | — |
| 1.3 ✅ | **Física nova (P/M/G)** | P: raio 34–44, vida 1, +60 px/s; M: 45–75, vida 2–3, +0–80; G: 76–95, vida 4–6, −40 | — |
| 1.4 ✅ | **Contador de FPS (dev)** | número de FPS no canto no modo dev, para medir os 2 celulares | — |
| 1.5 ✅ | **Comportamento por material** | cristalino do Setor 3 garante orbe; vulcânico do Setor 8 solta 2 brasas diagonais após aviso de 0,9 s, com passagem central | — |

## Fase 2 — Variedade (menos repetição)

| # | Etapa | Entrega |
|---|---|---|
| 2.1 ✅ | **O2 — Formações** | V, escada, zigue-zague, anel aberto, tabuleiro, funil e chuva fina; rota de 260 px; campanha, Infinito e Desafio |
| 2.2 (J0–J2, J4 ✅) | **Indestrutíveis novos (J0–J5)** | lixo espacial por setor girando em 3D, paredões encaixados, cometa/portão/poço/portal/nuvem novos — [PLANO_INDESTRUTIVEIS.md](PLANO_INDESTRUTIVEIS.md) |
| 2.3 | **Obstáculos novos (O3)** | haltere giratório, rocha explosiva, pedregulho que racha, cápsula de suprimento |

## Fase 3 — Inimigos e chefes

| # | Etapa | Entrega |
|---|---|---|
| 3.1 | **Naves inimigas 1 (A4)** | caça, interceptador, bombardeiro (no lugar dos hexágonos) |
| 3.2 | **Naves inimigas 2 (A5)** | atirador, porta-drones, kamikaze |
| 3.3 (arte implementada) | **Chefes no estilo novo (B0–B5)** | arte cartoon dos 8 chefes integrada, com partes móveis e ponto fraco; B5 (tom por bioma no Infinito) segue no plano — [PLANO_CHEFES_ARTE.md](PLANO_CHEFES_ARTE.md) |
| 3.4 | **Obstáculos novos 2 (O4)** | rio de destroços, satélite giratório, ricochete, rocha magnética |

## Fase 2B — Arma (PLANO_ARMA.md)

| # | Etapa | Entrega |
|---|---|---|
| Arma v2 ✅ | **Potência + padrão + tipo** | potência por setor; 4 padrões por cristais; Pulso/Laser/Dispersão/Míssil por carta; Sobrecarga; vida dos chefes ajustada (substitui W1–W5 da v1) |

## Fase 3B — Cartas (PLANO_CARTAS.md)

| # | Etapa | Entrega |
|---|---|---|
| C1 ✅ | Base dos módulos | catálogo, mão de 3, escolha de 3 cartas no contêiner dos chefes, 6 módulos |
| C2 | Oficina | carta inicial + cartas na campanha |
| C3 ✅ | Naves-mãe | nave-mãe aos 60 s de cada setor; derrubada dá contêiner (Setor 1: escudo + cristal) |
| C4 | Conquistas | tela, progresso e desbloqueios + 12 cartas |
| C5 | Equilíbrio | testes por carta + Desafio do Dia com cartas |

## Fase 4 — Publicação (quando você decidir)

| # | Etapa | Depende de você |
|---|---|---|
| 4.1 | Criar a chave (`tools\criar_chave_release.ps1`) e autorizar o 1º build (.aab) | sim |
| 4.2 | Conta no Play Console + teste fechado (12 testadores, 14 dias) | sim |
| 4.3 | Ajustes de dificuldade com os testadores + imagens/vídeo novos da loja | parte |

---

## Decisões em aberto (resumo)
1. Quando publicar.
2. Prioridade das expansões de conteúdo depois das formações: finalizar indestrutíveis e naves inimigas.

**Sugestão de ordem:** concluir o que resta de 2.2 → 3.1 → 2.3 …
