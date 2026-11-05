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
| `scripts/bosses/` | `Boss` (base: vida, fases, núcleos/armadura) e os chefes (`RockMother`, `Miner`, `Medusa`, `Cruiser`). |
| `scripts/hazards.gd` | `HazardLayer`: nuvens iônicas (drenam o escudo) e raios da tempestade (Setor 3). |
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

> Vai gerar a arte com outra IA ou um artista? Veja **[SPRITES.md](SPRITES.md)**: tamanhos,
> encaixes e um prompt pronto para cada sprite.

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

Pacote definitivo: **`com.mprovensi.astradodge`** (não muda depois de publicado).

### Publicar na Google Play (versão de lançamento)

1. **Chave de lançamento (uma vez):** `powershell -ExecutionPolicy Bypass -File tools\criar_chave_release.ps1`
   — cria `%USERPROFILE%\.astradodge\astradodge-release.keystore`. **Faça backup** do arquivo e guarde a senha.
2. **Gerar o .aab:** `powershell -ExecutionPolicy Bypass -File tools\exportar_release.ps1`
   — pede a senha (não fica salva) e gera `build\AstraDodge-release.aab` (perfil "Android Release",
   build Gradle). Na 1ª vez baixa as ferramentas de build do Android.
3. Subir o `.aab` no Play Console (teste fechado: 12 testadores por 14 dias).
4. Imagens da loja: `store/screenshots/` (1080×1920). Na versão de lançamento o seletor
   FASES (DEV) não aparece.

Antes de cada envio: aumente `version/code` (e `version/name`) nos dois perfis de `export_presets.cfg`.

## Ver o jogo em modo rápido (demo com piloto automático)

Abre uma janela com o jogo jogando sozinho, acelerado (escudo infinito por padrão):

```
Godot_v4.7.2-stable_win64_console.exe --path . --script res://tests/fast_demo.gd -- --velocidade=3
```

Opções depois de `--`: `--velocidade=N`, `--setor=N`, `--inicio=SEGUNDOS`, `--chefe`, `--mortal`, `--arma=N`.
No Claude Code, a skill **ver-jogo-rapido** faz isso a pedido ("quero ver o jogo rápido", "ver o chefe do setor 2").

## Testes

**Rodam sozinhos a cada envio ao GitHub** (`.github/workflows/testes.yml`): o GitHub baixa o Godot e
roda a bateria completa (~10 min). O resultado aparece na aba **Actions** do repositório (✅/❌) e o
log fica guardado em cada execução.

**Deploy de teste** (roda a bateria e só instala no celular se tudo passar):

```
powershell -ExecutionPolicy Bypass -File toolsdeploy_dev.ps1
```

No PC, só a bateria com resumo (sai com erro se algo falhar):

```
powershell -ExecutionPolicy Bypass -File tools\rodar_testes.ps1
```

O que a bateria cobre (`tests/smoke_test.gd`): o bot joga a campanha inteira (8 setores e chefes) e o
Infinito; Desafio do Dia; checkpoint/Continuar; rota segura de todos os chefes; colisão × desenho de
chefes, rochas e todos os quadros do giro 3D; tiro que não atravessa rocha; módulos; gráficos; volume;
**save** (ida e volta de todos os campos, save antigo, arquivo estragado usa a reserva); app indo para
segundo plano; **justiça das fileiras** (nenhum metal na brecha); regras da nave.

`tests/demo_capture.gd` grava frames de uma demo automática (`--write-movie`) para conferir o visual.
Os testes não alteram o save real.
