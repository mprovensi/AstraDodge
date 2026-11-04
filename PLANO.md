# Astra Dodge — Plano de Desenvolvimento

> Endless runner espacial vertical para Android (Godot 4), com movimento por arraste, escudo que se desgasta e arma automática que evolui.

**Gênero & estilo:** Arcade 2D / Endless Runner Espacial Vertical / Retro Sci-Fi Minimalista (Neon)
**Plataforma inicial:** Android (retrato) — iOS fica para depois do lançamento.
**Engine:** Godot 4.x (última estável), renderer Mobile (ou Compatibility para aparelhos fracos).

---

## 1. Conceito

### Sinopse
Você é o piloto de uma nave de reconhecimento perdida num cinturão de asteroides altamente instável. Com os motores de dobra danificados, a única saída é seguir em frente: destruir as rochas menores, coletar a energia que elas liberam para manter o escudo de pé e desviar dos rochedos metálicos indestrutíveis pelo maior tempo possível.

### Loop principal
> **Arraste** para desviar → **tiros automáticos** quebram a poeira → a poeira solta **orbes ciano (escudo)** e **cristais roxos (arma)** → os **metálicos** você só desvia → o escudo **vai acabando** e obriga você a buscar mais → a velocidade sobe.

O jogador decide o tempo todo duas coisas: *"arrisco buscar aquele orbe?"* e *"por onde passo entre os metálicos?"*.

---

## 2. Jogabilidade (especificação)

### 2.1 Controle — arraste relativo com um dedo
- **Movimento relativo:** a nave se desloca o mesmo delta do dedo (1:1, padrão 1,2×). O toque pode começar **em qualquer ponto da tela** — o dedo nunca precisa cobrir a nave.
- **Sensibilidade ajustável** nas opções: 0,8× a 1,6×.
- **Movimento livre em X e Y**, porém **Y limitado aos ~55% inferiores da tela** (garante tempo de reação).
- **Suavização leve** (lerp de 1–2 frames) para evitar tremor sem sensação de atraso.
- **Ao soltar o dedo:** câmera lenta (~30%) por 0,4 s → **pausa** com "Toque para continuar". Retoma instantaneamente ao tocar de novo (sem contagem). Evita mortes por soltar sem querer e permite reposicionar a mão.

### 2.2 Escudo automático (é a "vida" do jogador)
- Começa em **100%** e **drena devagar** com o tempo (pressão constante; valor inicial sugerido: −1,5%/s, ajustável).
- **Dano por colisão:** poeira −15%, metálico −50%.
- **Recarga:** asteroides de poeira destruídos soltam **orbes ciano** (+10%), puxados por um **ímã de raio curto**.
- **Escudo em 0% não mata na hora:** a nave entra em **"última chance"** (pisca vermelho + alarme suave); a **próxima** colisão é fatal. Coletar um orbe tira a nave desse estado.
- **Invencibilidade de 1 s** (nave piscando) após cada impacto.
- **Feedback visual:** anel ao redor da nave — espessura/brilho proporcionais à energia; abaixo de 25% pisca e o áudio fica levemente abafado. Sem barra no HUD (o olhar já está na nave).

### 2.3 Arma automática evolutiva
- Disparo **sempre automático** para o topo da tela.
- Evolui coletando **cristais roxos/magenta** (formato de losango — diferente do orbe circular, pensando em daltonismo).
- Barra fina de "nível da arma" sob a pontuação; ao subir: flash + texto curto "LEVEL UP".

| Nível | Disparo |
|---|---|
| 1 | Laser simples, 3 tiros/s |
| 2 | Laser duplo |
| 3 | Laser duplo rápido (5 tiros/s) |
| 4 | Triplo em leque |
| 5 | Leque + laser central perfurante |

- **Penalidade:** quando o escudo chega a 0% (entrada em "última chance"), a arma **perde 1 nível**. Ao reviver pelo anúncio, a arma **mantém** o nível atual.
- Se o início parecer lento nos testes, começar no **nível 2**.

### 2.4 Asteroides
- **Poeira (cinza):** destrutível; HP 1–3 (cresce com a dificuldade para acompanhar a arma). Solta orbes/cristais (chance configurável) e pontos.
- **Metálico (escuro):** indestrutível em qualquer nível de arma; tiros ricocheteiam com faísca. No nível 5, o tiro pode **empurrá-lo levemente**, nunca destruir.
- **Regra de justiça do spawner:** sempre existe um caminho transitável entre metálicos (checagem de largura mínima livre por "linha" de spawn).

### 2.5 Dificuldade e pontuação
- Velocidade de rolagem e densidade crescem por **curva ajustável** (`Curve` resource), mirando partidas médias de **2–3 minutos**.
- Velocidade do parallax acompanha a velocidade do jogo.
- **Pontuação** = distância percorrida + asteroides destruídos (+ bônus por coleta em "última chance").

---

## 3. Visual, áudio e UI

- **Arte:** vetorial 2D Neon Retro. Nave/tiros em azul e ciano com glow (`WorldEnvironment` Glow + modulate HDR). Fundo de estrelas com parallax em 2–3 camadas.
- **HUD minimalista:** pontuação em neon no topo, recorde, barra fina de nível da arma, botão de pausa. Respeitar safe area (notch/barra de gestos).
- **Áudio:** lasers 8-bit, explosões encorpadas, coleta, level up, alarme de escudo baixo, synthwave em loop. Buses separados de Música/SFX.
- **Vibração** na morte e no impacto (desligável).

---

## 4. Fases de desenvolvimento

### Fase 1 — Protótipo jogável (Dias 1 a 8)
Objetivo: loop completo com formas geométricas, já divertido.

1. **Projeto**
   - Godot 4.x, viewport **1080×1920**, `stretch = canvas_items`, `aspect = expand`, orientação **Portrait**, `emulate_touch_from_mouse` ligado.
   - Repositório Git desde o dia 1.
2. **Estrutura de cenas:** `Main`, `Ship`, `Bullet`, `Asteroid` (`type: DUST | METAL`), `Pickup` (`type: SHIELD | WEAPON`), `Spawner`, `HUD`; autoload `Game` (estado, pontuação, velocidade, dificuldade).
3. **Controle:** arraste relativo, sensibilidade, limite vertical, suavização, câmera lenta + pausa ao soltar.
4. **Escudo:** drenagem por tempo, dano por colisão, estado "última chance", invencibilidade pós-impacto, anel visual placeholder.
5. **Arma:** pool de projéteis (sem instanciar/destruir a cada tiro), 5 níveis de padrão de disparo, ganho/perda de nível.
6. **Spawner:** poeira e metálicos com regra de caminho livre; drop de orbes/cristais com ímã.
7. **Colisões (camadas separadas):** Tiro×Poeira (dano/HP), Tiro×Metal (ricochete), Nave×Asteroide (dano no escudo/morte), Nave×Pickup (coleta).
8. **Dificuldade e pontuação** via curva ajustável.
9. **APK de debug no celular já no dia 2–3** — toque só se valida no aparelho.

**Critério de saída:** 10 partidas seguidas no celular e vontade de jogar a 11ª.

**Status (04/11/2026):**
- [x] Projeto Godot 4.7.2 (GDScript) com retrato 1080×1920 e expand
- [x] Arraste relativo, limite vertical, câmera lenta + pausa ao soltar
- [x] Escudo com drenagem, dano, "última chance" e invencibilidade
- [x] Arma automática com 5 níveis e pool de projéteis
- [x] Spawner em linhas com corredor livre; drops com ímã
- [x] Colisões, pontuação, dificuldade progressiva, recorde salvo
- [x] HUD, telas de início/pausa/fim, "continuar" de teste (sem anúncio)
- [x] Teste de fumaça headless
- [ ] Ajuste fino de balanceamento jogando de verdade
- [x] Opções (música, efeitos, vibração, sensibilidade) e botão de pausa
- [x] APK de debug rodando no celular (Galaxy S20 FE)
- [x] Repositório Git

### Fase 2 — Arte, áudio e "juice" (Dias 9 a 14)
1. **Assets visuais:** Kenney.nl (*Space Shooter Redux*, *Space Kit* — CC0). Substituir placeholders; parallax com `Parallax2D`.
2. **VFX:** rastro do propulsor (partículas), explosão de asteroides, faísca no ricochete, anel do escudo definitivo, efeito de coleta, flash de level up, screen shake com decaimento, hit-stop de ~40 ms ao destruir asteroide.
3. **Áudio:** SFX via jsfxr/sfxr ou Kenney; música synthwave **apenas CC0 ou CC-BY** (OpenGameArt/Freesound — evitar NC por causa dos anúncios). Pitch variável e volume baixo no tiro. Créditos em `CREDITS.md`.
4. **Recrutar testadores** para o teste fechado obrigatório da Play Store (ver Fase 4).

### Fase 3 — Interface, salvamento e monetização (Dias 15 a 19)
1. **Telas**
   - **Menu:** título, Jogar, som on/off, vibração on/off, sensibilidade.
   - **HUD:** pontuação, recorde, nível da arma, pausa.
   - **Game Over:** pontuação final, "Novo recorde!", Reiniciar, **Continuar (anúncio)** — 1× por partida.
   - Pausa automática quando o app vai para segundo plano (`NOTIFICATION_APPLICATION_PAUSED`).
2. **Persistência:** `ConfigFile` em `user://save.cfg` (recorde, opções, flag de "sem anúncios").
3. **AdMob**
   - Plugin Godot 4 mantido (ex.: Poing Studios *godot-admob-plugin*) — conferir compatibilidade com a versão do Godot.
   - **Rewarded Ad** para reviver: volta com **escudo em 100%, arma mantida**, área próxima limpa e 2 s de invencibilidade. Texto: "Assista a um vídeo para reviver" (não prometer duração).
   - **IDs de teste durante todo o desenvolvimento.**
   - Consentimento **UMP (GDPR)** integrado.
4. **IAP "Remover anúncios" (US$ 0,99):** plugin oficial *Godot Google Play Billing* — **adiado para a v1.1**.

### Fase 4 — Testes e publicação (Dias 20 a 23 + prazos da loja)
1. **Build de release:** export templates Android, JDK 17, Android SDK, keystore de release (**backup seguro — se perder, não atualiza mais o app**), export `.aab` com o target API mínimo exigido pelo Google no momento.
2. **Testes em aparelhos reais** (no mínimo um fraco e um bom): 60 FPS estável, resposta do arraste, safe area, interrupções (ligação/notificação), áudio em background, bateria.
3. **Google Play Console:** taxa única de US$ 25 + verificação de identidade.
   - ⚠️ **Contas pessoais novas exigem teste fechado com 12 testadores ativos por 14 dias seguidos** antes de liberar produção.
4. **Página da loja:** ícone 512×512, feature graphic 1024×500, 4–8 screenshots, vídeo curto (recomendado), título ≤ 30 caracteres, descrição curta ≤ 80.
5. **Formulários:** classificação indicativa (IARC); **Segurança de dados** (AdMob coleta ID de publicidade e dados do dispositivo); **política de privacidade** em URL pública (ex.: GitHub Pages); **público-alvo 13+**; declaração "contém anúncios".
6. **Envio para revisão** (geralmente de alguns dias a uma semana).

---

## 5. Cronograma

| Período | Entrega |
|---|---|
| Dias 1–8 | Protótipo jogável com a nova jogabilidade + APK de debug |
| Dias 9–14 | Arte, VFX e áudio; recrutamento de testadores |
| Dias 15–19 | UI, salvamento, AdMob (IDs de teste) |
| Dias 20–23 | AAB de release, testes, página da loja, início do teste fechado |
| +14 dias | Teste fechado obrigatório + correções |
| +3–7 dias | Revisão do Google e lançamento |

---

## 6. Fora do escopo da v1 (backlog)
- Placar online / Google Play Games
- Novos tipos de pickup / power-ups temporários
- Múltiplas naves ou skins
- IAP "remover anúncios" (v1.1)
- Versão iOS

---

## 7. Texto para a Google Play Store

**Título:** Astra Dodge: Space Runner
**Descrição curta:** Arraste, desvie e evolua seus lasers num cinturão de asteroides sem fim!

**Descrição completa:**

Desvie, atire e sobreviva no espaço profundo!

Em Astra Dodge, seus reflexos são sua única defesa. Pilote sua nave com um só dedo através de um cinturão de asteroides implacável. Seus lasers disparam sozinhos e ficam cada vez mais fortes — mas seu escudo está se esgotando, e só a energia das rochas destruídas pode mantê-lo de pé.

**Destaques:**
- **Um dedo, controle total:** arraste para qualquer direção e jogue com uma mão em partidas de 2 a 3 minutos.
- **Arma que evolui:** colete cristais e transforme um laser simples numa chuva de tiros em leque.
- **Escudo vivo:** destrua asteroides, colete energia e decida quando arriscar.
- **Ritmo acelerado:** a velocidade aumenta à medida que sua pontuação cresce.
- **Desafio infinito:** supere seus próprios recordes.

**Palavras-chave:** jogo espacial, nave, asteroides, arcade 2D, endless runner, neon, shooter, um dedo.
