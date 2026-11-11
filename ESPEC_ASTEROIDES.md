# Astra Dodge — Especificação: Asteroides (visual + física)

> Rascunho para revisão. Substitui a tentativa A1 (asteroides 2.5D por shader), que foi
> desfeita em 05/11/2026. Marque as decisões na seção 7 e eu sigo a partir daqui.
> Atualização de 11/11/2026: física P/M/G e comportamentos por material implementados (seções 9–10). Para a arte atual,
> prevalece PLANO_SPRITES_IA.md: sprites desenhados por setor, com giro no plano.

---

## 1. O que deu errado na tentativa anterior (para não repetir)

| Problema | Causa | Regra nova |
|---|---|---|
| **Borda estranha** | o efeito era calculado na hora (shader) e o recorte da silhueta ficava serrilhado/diferente em GPU antiga (modo de compatibilidade) | visual **pré-renderizado em imagem** (PNG com borda suave), nada de recorte calculado na hora |
| **Tiro passando direto** | celular lento = quadro longo = o tiro "pula" ~70 px; as pedrinhas novas (raio 24–34) eram menores que o pulo | **já corrigido**: o acerto testa o trajeto do tiro no quadro, não só o ponto |
| **Pesado no aparelho antigo** | ruído 3D calculado por pixel em cada rocha, todo quadro | custo por rocha = **1 imagem desenhada** (como antes) |
| **Desenho maior que a colisão** | silhueta irregular desenhada 10% maior que o raio | **desenho e colisão casados**: o teste mede os dois lados (ver 5) |

---

## 2. Física (jogabilidade)

| Item | Hoje (voltou ao original) | Proposta |
|---|---|---|
| Tamanhos da poeira | raio 40–85 | 3 classes: **P** 34–44, **M** 45–75, **G** 76–95 (nada menor que 34) |
| Velocidade | rolagem + 0–80 px/s | P: +60, M: +0–80, G: −40 (mais lenta) |
| Vida | 1–5 (pelo tamanho e dificuldade) | P: 1, M: 2–3, G: 4–6 |
| Recompensa | 10 × vida | igual (G vale mais) |
| Colisão com a nave | círculo de 85% do raio | igual (é o que deixa justo) |
| Colisão com o tiro | círculo de 100% do raio, **trajeto do quadro** | igual |
| Metálico | raio 70–130, indestrutível | igual (vira lixo espacial no A3) |

- **Regra de ouro:** nenhuma rocha destrutível menor que o "pulo" do tiro num quadro de 30 FPS
  (≈ 73 px de diâmetro → raio ≥ 34). Mesmo com o teste de trajeto, isso garante a sensação.

---

## 3. Visual

**Estilo:** rocha com volume (luz fixa vindo de cima/esquerda, sombra embaixo/direita),
crateras e relevo — o "2.5D" do exemplo da galeria —, porém **assado em imagem**.

| Item | Especificação |
|---|---|
| Como é feito | **Pré-renderizado**: uma ferramenta gera os PNGs uma vez (pode ser o próprio shader da galeria rodando fora do jogo, ou arte de IA/artista) |
| Giro | **Rotação 2D** da imagem (como antes). Opcional: 8 quadros de giro 3D pré-renderizados (ver decisão 7.2) |
| Tamanho do PNG | 256×256 (como hoje), borda suave (antialias), fundo transparente |
| Variações | 3 poeiras + 3 metais **por setor** (hoje: 2 + 2) |
| Contorno | sem contorno neon; só a "borda de luz" do lado iluminado (como a lua da galeria) |
| Leitura | **poeira clara/quente** × **metal escuro com luz de alerta** (testado) |
| Silhueta | irregular, mas **casada com a colisão**: o círculo de colisão cobre ≥ 92% da área desenhada e fica ≥ 95% dentro do desenho |
| Ao levar tiro | pisca branco + recuo (como hoje) |
| Ao quebrar | pedaços na cor da rocha + poeira (como hoje) |
| Tipos (7) | rochoso, ferroso, carbonáceo, gelo, cristalino, pedra-pomes, vulcânico — distribuídos por setor como no plano 2.5D |

---

## 4. Desempenho

- **Meta:** 60 FPS no Galaxy S20 FE; **≥ 50 FPS no Galaxy A5 2017** (modo compatibilidade).
- Até ~30 rochas na tela; cada uma = 1 imagem (sem shader por rocha).
- Gráficos "Simples" (já existe): nebulosa leve e sem brilho neon.
- Medição: contador de FPS no modo dev (FASES DEV) para conferir nos dois aparelhos.

---

## 5. Aceite (como saber que ficou bom)

1. Teste automático "colisão × desenho" em **todas** as imagens: colisão ≥ 95% dentro do desenho
   **e** desenho ≥ 92% coberto pela colisão (as duas direções — a anterior só olhava uma).
2. Teste do tiro: rochas P, M e G sempre atingidas com quadros de 1/60, 1/30 e 1/20 s.
3. FPS medido nos dois celulares no Setor 1 (chuva de poeira) e Setor 6 (muitos inimigos).
4. Revisão visual sua nos dois celulares antes de seguir para o lixo espacial e naves.

---

## 6. Etapas

| Etapa | Entrega |
|---|---|
| **E1** | contador de FPS (dev) + medir a versão atual nos dois celulares (linha de base) |
| **E2** | ferramenta que gera os PNGs 2.5D (assar o shader da galeria) + 1 setor de teste |
| **E3** | física nova (P/M/G) + testes de aceite |
| **E4** | todos os setores + revisão visual sua |

---

## 7. Decisões (preencha)

1. **Tamanhos P/M/G** como na tabela da seção 2? Ou manter só o tamanho atual (40–85)?
2. **Giro**: só rotação 2D da imagem (leve) ou 8 quadros de giro 3D pré-renderizados (mais bonito,
   mais imagens)?
3. **Fonte da arte**: assar o shader da galeria (eu faço tudo) ou IA de imagem/artista?
4. **Quantas variações por setor**: 3 poeiras + 3 metais está bom?
5. O **metal** muda agora junto (pré-renderizado) ou espera o lixo espacial (A3)?

---

## 8. Decisão (05/11/2026)

**Meio-termo:** sprites pré-renderizados **com giro 3D**, em estilo **estilizado** (não realista):
- sombreado em **3 tons chapados** (claro, médio, escuro), crateras simples, **contorno escuro** e
  uma borda de luz no lado iluminado — combina com o resto do jogo (neon/cartoon);
- o giro 3D é uma **folha de quadros** (ex.: 12 quadros) gerada uma vez por uma ferramenta
  (`tools/bake_rocks.gd`) a partir de um shader só de geração; no jogo cada rocha é 1 imagem
  por quadro (mesmo custo de um sprite);
- borda lisa (antialias na imagem), sem recorte calculado no celular;
- protótipo no **Setor 1** para aprovação antes de levar aos outros setores.

---

## 9. Física P/M/G implementada (11/11/2026)

- Fileiras comuns da campanha, Infinito e Desafio usam os raios, vidas e velocidades da seção 2.
- Distribuição antes da tentativa de posicionamento: 20% P, 65% M, 15% G. A maioria continua média;
  rochas que não cabem sem sobreposição são descartadas, como antes.
- A dificuldade sobe a vida dentro da faixa de cada tamanho (início: 1/2/4; máximo: 1/2–3/4–6).
- As velocidades são somadas à rolagem; na inversão, o sentido acompanha as fileiras.
- Metálicos, colisões, recompensa por vida e ataques de chefes mantêm suas regras. O raio mínimo
  de 34 vale para as rochas comuns; lascas de gelo e projéteis rochosos dos chefes mantêm raios próprios.
- Teste `ASTEROIDES P/M/G`: 1.200 fileiras nas duas direções e em três dificuldades; tiros reais
  a 60/30/20 FPS nos limites dos três tamanhos, incluindo tiros que passam ao lado; gelo continua rachando.
- Os testes da versão anterior nos celulares foram confirmados pelo usuário. O balanceamento
  desta mudança é novo; a validação automatizada inclui o ritmo da arma e a campanha completa.

## 10. Comportamentos por material (11/11/2026)

- O material é registrado por imagem em `AsteroidLook.dust_materials` e guardado na rocha quando
  ela nasce. Ao mudar o bioma no Infinito, rochas antigas mantêm seu comportamento. Arte sem
  metadados mantém rochas comuns; não se deduz comportamento pela cor do arquivo.
- **Cristalino:** a 4ª rocha do Setor 3, azul com cristais ciano em losango, garante exatamente
  um orbe de escudo quando destruída a tiro, substituindo o sorteio comum de recompensa.
- **Vulcânico:** 3ª e 4ª rochas do Setor 8, vermelhas com fissuras luminosas, soltam duas brasas
  diagonais para baixo após aviso de 0,9 s. O voo dura 1,2 s a 360 px/s (alcance de 432 px), com
  passagem central. As faixas mostram a trajetória e incluem a largura da brasa e da nave.
- Brasas usam o pool existente de projéteis inimigos e o dano normal de tiro inimigo. Não se
  movem nem machucam durante o aviso; pausas congelam o relógio, e limpar os tiros cancela
  também os disparos pendentes. A colisão considera o trajeto entre quadros.
- Esses materiais se aplicam às fileiras comuns, também no Infinito e Desafio. Gelo, lascas,
  metálicos, ataques de chefes e rochas removidas por colisão/limpeza mantêm as regras anteriores.
- Teste `MATERIAIS`: geração por sprite, troca de bioma, recompensa única a tiro, faixas e
  corredor seguro, transição do aviso em quadro longo, alcance, pausa e reutilização do pool.
