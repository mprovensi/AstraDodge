extends SceneTree
## Teste de fumaça: simula partidas sem tela e exercita os sistemas principais.
## Uso: godot --headless --path . --script res://tests/smoke_test.gd

const DT := 1.0 / 60.0
const FRAMES := 60 * 240  # 4 minutos simulados


var main: Node2D


func _initialize() -> void:
	var game := root.get_node("Game")
	game.persist = false
	game.high_score = 0
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	# _ready só roda quando a árvore processa o primeiro frame.
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var deaths := 0
	var max_level := 1
	var max_asteroids := 0
	var max_score := 0
	_touch(main, true)

	for i in FRAMES:
		if i % 20 == 0:
			var drag := InputEventScreenDrag.new()
			drag.index = 0
			drag.relative = Vector2(randf_range(-120, 120), randf_range(-60, 60))
			main._input(drag)
		main._process(DT)
		max_level = maxi(max_level, main.ship.weapon_level)
		max_asteroids = maxi(max_asteroids, main.asteroids.asteroids.size())
		max_score = maxi(max_score, main.score)
		if main.state == main.State.GAME_OVER:
			deaths += 1
			if deaths % 2 == 1:
				main._on_continue()
			else:
				main._on_restart()
			_touch(main, true)

	# Soltar o dedo deve levar a câmera lenta e depois à pausa.
	_touch(main, false)
	for i in 60:
		main._process(DT)
	assert(main.state == main.State.PAUSED, "soltar o dedo deveria pausar")

	# Arma sobe até o máximo coletando cristais.
	for i in 50:
		main.ship.add_crystal()
	assert(main.ship.weapon_level == Tuning.WEAPON_MAX_LEVEL, "arma deveria chegar ao nível máximo")

	print("SMOKE OK | mortes=%d nivel_arma_max=%d asteroides_max=%d pontos_max=%d pool_tiros=%d recorde=%d" % [
		deaths, max_level, max_asteroids, max_score, main.bullets.pool.size(), root.get_node("Game").high_score])
	main.free()
	quit()


func _touch(main: Node, pressed: bool) -> void:
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.pressed = pressed
	main._input(t)
