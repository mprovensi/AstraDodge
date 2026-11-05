extends SceneTree
## DEMONSTRAÇÃO EM MODO RÁPIDO: abre o jogo numa janela e joga sozinho, acelerado,
## para acompanhar o jogo funcionando. Feche a janela (ou Ctrl+C no terminal) para parar.
##
## Uso:
##   godot --path . --script res://tests/fast_demo.gd -- [opções]
## Opções (todas opcionais):
##   --velocidade=3     multiplicador de velocidade (1 = normal; padrão 3)
##   --setor=1          setor da campanha (1 ou 2)
##   --inicio=0         segundo do setor onde começar (ex.: 120)
##   --chefe            começa direto no ALERTA do chefe do setor
##   --mortal           sem escudo infinito (a nave pode morrer; recomeça sozinha)
##   --arma=2           nível inicial da arma (1–5)
##   --infinito         Modo Infinito procedural (todos os biomas e chefes liberados)
##   --limpo            sem o letreiro "DEMO" (para capturas de tela)
##
## O piloto automático foge de metálicos, tiros, avisos vermelhos e do corpo do chefe,
## e procura poeira para atirar (ou o ponto fraco do chefe).


var main: Node2D
var speed := 3.0
var sector := 1
var start_time := 0.0
var mortal := false
var weapon := 2
var endless := false
var clean := false  # --limpo: sem o letreiro da demo (capturas para a loja)
var _frame := 0
var _clear_wait := 0.0
var _label: Label
var _pilot: Autopilot


func _initialize() -> void:
	_parse_args()
	root.get_node("Game").persist = false  # a demo nunca mexe no save real
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.auto_pick_modules = true  # a demo escolhe o 1º módulo sozinha
	_pilot = Autopilot.new(main)
	if not clean:
		_add_overlay()
	process_frame.connect(_tick)


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=")
		match kv[0]:
			"velocidade":
				speed = clampf(float(kv[1]), 0.25, 8.0)
			"setor":
				sector = clampi(int(kv[1]), 1, 9)
			"inicio":
				start_time = maxf(0.0, float(kv[1]))
			"chefe":
				start_time = -1.0
			"mortal":
				mortal = true
			"infinito":
				endless = true
			"limpo":
				clean = true
			"arma":
				weapon = clampi(int(kv[1]), 1, 5)


func _add_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	root.add_child(layer)
	_label = Label.new()
	# Embaixo à esquerda: o cabeçalho do jogo (pontos, barras, chefe) fica livre.
	_label.anchor_top = 1.0
	_label.anchor_bottom = 1.0
	_label.offset_left = 24.0
	_label.offset_top = -90.0
	_label.offset_bottom = -40.0
	_label.add_theme_font_size_override("font_size", 34)
	_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("outline_size", 8)
	layer.add_child(_label)


func _tick() -> void:
	_frame += 1
	if _frame == 3:
		_start_sector(sector)
		return
	if _frame < 3:
		return
	if _label != null:
		_label.text = "DEMO %sx · %s · %s" % [str(speed), _sector_title(), _state_name()]

	match main.state:
		main.State.GAME_OVER:
			main._on_restart()
			_touch()
		main.State.SECTOR_CLEAR:
			# Mostra o resultado um pouco e segue para o próximo setor (ou recomeça).
			_clear_wait += 1.0 / 60.0
			if _clear_wait > 2.5:
				_clear_wait = 0.0
				if main._has_next_sector():
					var lvl: int = main.ship.weapon_level
					main._on_next_sector()
					main.ship.weapon_level = lvl
				else:
					main.start_mode(main.Mode.CAMPAIGN, 0)
				_touch()
		main.State.READY, main.State.PAUSED:
			_touch()
		_:
			_pilot.step(not mortal)


func _start_sector(number: int) -> void:
	Engine.time_scale = speed
	if endless:
		main.endless_biomes.assign([0, 1, 2, 3, 4, 5, 6, 7])
		main.endless_bosses.assign(["rock_mother", "miner", "medusa", "cruiser", "ice_colossus", "hive_queen", "sentinel", "rift_core"])
		main.start_endless()
		main.ship.weapon_level = weapon
		_touch()
		return
	var index := clampi(number - 1, 0, main.SECTORS.size() - 1)
	var t := start_time
	if t < 0.0:
		t = _boss_time(index)
	var game := root.get_node("Game")
	game.checkpoint = {"sector": index, "time": t, "weapon": weapon}
	main.go_to_menu()
	main.resume_checkpoint()
	_touch()


## Segundo do evento BOSS do setor, um pouco antes (para ver o "Algo enorme..." e o ALERTA).
func _boss_time(index: int) -> float:
	for e in main.SECTORS[index].events:
		if e.kind == WaveEvent.Kind.BOSS:
			return maxf(0.0, e.at - 4.0)
	return 0.0


func _touch() -> void:
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.pressed = true
	t.position = Vector2(30, main.view_size.y - 30)
	main._input(t)


func _sector_title() -> String:
	return main.director.sector.title if main.director != null else "MENU"


func _state_name() -> String:
	if main.boss != null:
		return "CHEFE %s %d%%" % [main.boss.display_name, int(main.boss.hp_ratio() * 100.0)]
	if main.director != null:
		return "%ds" % int(main.director.time)
	return ""
