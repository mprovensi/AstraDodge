# Astra Dodge

Endless runner espacial vertical para Android, feito em **Godot 4.7 (GDScript, versão padrão sem .NET)**.
Plano completo em [PLANO.md](PLANO.md).

## Como abrir e jogar no PC
1. Abra o Godot 4.7.2 → **Importar** → selecione `project.godot` desta pasta.
2. Aperte **F5**. O mouse simula o dedo: clique e arraste para pilotar, solte para pausar.

## Controles (protótipo)
- **Arrastar (qualquer ponto da tela):** move a nave (movimento relativo, até ~55% da altura).
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

Todo o visual atual é desenhado por código (placeholders da Fase 1); a Fase 2 troca por sprites.

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
