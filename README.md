# Astra Dodge

Endless runner espacial vertical para Android, feito em **Godot 4.7 (GDScript, versão padrão sem .NET)**.
Plano completo em [PLANO.md](PLANO.md).

## Como abrir e jogar no PC
1. Abra o Godot 4.7.2 → **Importar** → selecione `project.godot` desta pasta.
2. Aperte **F5**. O mouse simula o dedo: clique e arraste para pilotar, solte para pausar.

## Controles (protótipo)
- **Arrastar (qualquer ponto da tela):** move a nave (movimento relativo, até ~67% da altura).
- **Soltar o dedo:** câmera lenta por 0,4 s e depois pausa. Tocar de novo retoma na hora.
- **Tiro:** automático, evolui com cristais magenta (5 níveis).
- **Escudo:** automático, drena com o tempo e com impactos; orbes ciano recarregam.
  Em 0% a nave entra em "última chance" (anel vermelho): a próxima batida é fatal.

## Estrutura
| Arquivo | Função |
|---|---|
| `scripts/tuning.gd` | **Todos os valores de balanceamento** (velocidades, dano, drops, dificuldade). |
| `scripts/palette.gd` | Cores neon. |
| `scripts/game.gd` | Autoload `Game`: recorde e opções salvos em `user://save.cfg`. |
| `scripts/main.gd` | Estados da partida, input, colisões, pontuação, screen shake. |
| `scripts/ship.gd` | Nave, escudo, níveis e padrões de tiro. |
| `scripts/asteroids.gd` | Asteroides e spawner com corredor sempre livre de metálicos. |
| `scripts/bullets.gd` | Pool de projéteis. |
| `scripts/pickups.gd` | Orbes de escudo e cristais com ímã. |
| `scripts/fx.gd` | Partículas (explosões, faíscas, coletas). |
| `scripts/starfield.gd` | Fundo de estrelas com parallax. |
| `scripts/hud.gd` | HUD e telas de início, pausa e fim de jogo. |
| `scripts/sfx.gd` | Autoload `Sfx`: pool de efeitos, música, buses Music/SFX e limitador. |
| `scripts/art/art_set.gd` | `ArtSet`: texturas e ajustes de todos os sprites (ver "Trocar sprites"). |
| `scripts/campaign/` | `SectorData`, `WaveEvent`, `SectorDirector`: setores e linha do tempo das fases. |
| `scripts/bosses/` | `Boss` (base: vida, fases, núcleos/armadura) e os chefes (`RockMother`). |
| `tools/gen_sprites.gd` / `tools/gen_art_set.gd` | SVG → PNG dos sprites / cria o ArtSet padrão. |
| `tools/gen_audio.gd` | Sintetiza todos os sons e a música em `audio/*.wav` (sem assets de terceiros). |

Visual vetorial desenhado por código com glow HDR: só as cores `*_HDR` da `Palette` brilham
(nave, tiros, pickups, explosões); metálicos e poeira ficam opacos de propósito.

Para regenerar o áudio depois de mexer no sintetizador:

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/gen_audio.gd
```

(`audio/music.wav.import` usa `edit/loop_mode=2` para a música tocar em loop.)

## Trocar sprites

Toda a arte passa por um **ArtSet** ([scripts/art/art_set.gd](scripts/art/art_set.gd)): um recurso com as
texturas e os ajustes de cada sprite. O código nunca aponta direto para um PNG — ele lê o ArtSet ativo
(`Game.art`, definido por `Game.ART_SET_PATH` em [scripts/game.gd](scripts/game.gd)).

| Arquivo | O que é |
|---|---|
| `art/sprites/*.svg` | Desenhos-fonte (vetor). Edite em Inkscape/Figma ou à mão. |
| `sprites/*.png` | Imagens usadas no jogo (geradas dos SVGs ou trazidas de fora). |
| `data/art/default.tres` | ArtSet padrão: quais PNGs usar + tamanho, brilho, motores, ponta da nave, encaixe das rochas. |

**Três jeitos de trocar, do mais simples ao mais flexível:**

1. **Ajustar o desenho atual:** edite o SVG em `art/sprites/` e rode
   `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/gen_sprites.gd`.
2. **Trocar por uma imagem pronta:** substitua o PNG em `sprites/` por outro **com o mesmo nome**
   (quadrado, fundo transparente, objeto centralizado; a nave com o nariz para cima).
3. **Conjunto novo (ex.: skin):** no Godot, duplique `data/art/default.tres`, troque as texturas e os
   ajustes pelo Inspetor e aponte `Game.ART_SET_PATH` para o novo arquivo.

**Ajustes do ArtSet (Inspetor):**
- `ship_size`: tamanho da nave na tela (não muda a colisão).
- `ship_glow`: > 1 faz as partes claras brilharem como neon (glow HDR); 1 = sem brilho extra.
- `ship_engines_px` / `ship_muzzle_px`: posições **no PNG** (pixels da imagem) dos motores (uma chama
  por item) e da ponta de onde saem os tiros. Se mudar o desenho, confira essas posições.
- `dust_textures` / `metal_textures`: quantas variações quiser; o jogo sorteia uma por asteroide.
- `dust_fill` / `metal_fill`: quanto do raio da imagem a rocha ocupa (0,92 = até 92% da borda);
  serve para o desenho casar com o círculo de colisão.

Ainda desenhados por código (próximos a migrar para o ArtSet): tiros, orbes/cristais, drones, efeitos.

## Android (APK de debug)
Ambiente já configurado nesta máquina: JDK 17/21, Android SDK em `%LOCALAPPDATA%\Android\Sdk`
(platform-tools, build-tools 36.1.0, android-36), export templates 4.7.2 (só Android) e keystore de debug do Godot.

Gerar o APK (preset "Android" em `export_presets.cfg`, sai em `build/`):

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-debug "Android" build/AstraDodge-debug.apk
```

Instalar com o celular no USB (depuração USB ligada):

```
%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe install -r build\AstraDodge-debug.apk
```

> `package/unique_name` está como `com.astradodge.game` provisoriamente — defina o definitivo antes da Play Store (não muda depois).

## Testes
Teste de fumaça (simula 4 minutos de partidas sem abrir janela):

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_test.gd
```

`tests/demo_capture.gd` grava frames de uma demo automática (`--write-movie`) para conferir o visual.
Os testes não alteram o save real.
