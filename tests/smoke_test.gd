extends SceneTree
## Teste de fumaça: simula partidas sem tela e exercita os sistemas principais.
## Uso: godot --headless --path . --script res://tests/smoke_test.gd

const DT := 1.0 / 60.0
const FRAMES := 60 * 240  # 4 minutos simulados no modo infinito

var main: Node2D


func _initialize() -> void:
	var game := root.get_node("Game")
	game.persist = false
	game.high_score = 0
	game.sector_best = {}
	game.sectors_cleared = {}
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	# _ready só roda quando a árvore processa o primeiro frame.
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	assert(main.state == main.State.MENU, "o jogo deve abrir no menu principal")
	# Toque no menu (fora dos botões) não pode iniciar partida.
	_touch(true)
	_touch(false)
	assert(main.state == main.State.MENU, "toque no menu não deve iniciar a partida")

	_test_endless()
	_test_campaign()
	_test_enemies()
	main.free()
	quit()


func _test_endless() -> void:
	main.start_mode(main.Mode.ENDLESS)
	var deaths := 0
	var max_level := 1
	var max_asteroids := 0
	var max_score := 0
	_touch(true)
	for i in FRAMES:
		if i % 20 == 0:
			_drag(Vector2(randf_range(-120, 120), randf_range(-60, 60)))
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
			_touch(true)

	# Soltar o dedo deve levar a câmera lenta e depois à pausa.
	_touch(false)
	for i in 60:
		main._process(DT)
	assert(main.state == main.State.PAUSED, "soltar o dedo deveria pausar")

	# Arma sobe até o máximo coletando cristais.
	for i in 50:
		main.ship.add_crystal()
	assert(main.ship.weapon_level == Tuning.WEAPON_MAX_LEVEL, "arma deveria chegar ao nível máximo")

	print("INFINITO OK | mortes=%d nivel_arma_max=%d asteroides_max=%d pontos_max=%d recorde=%d" % [
		deaths, max_level, max_asteroids, max_score, root.get_node("Game").high_score])


func _test_campaign() -> void:
	main.go_to_menu()
	main.start_mode(main.Mode.CAMPAIGN)
	assert(main.state == main.State.READY)
	_touch(true)
	var walls := 0
	var rain_seen := false
	var frames := 0
	# Nave invencível: aqui testamos o roteiro do setor, não a habilidade.
	while main.state != main.State.SECTOR_CLEAR and frames < 60 * 220:
		main.ship.invuln = 1.0
		if frames % 20 == 0:
			_drag(Vector2(randf_range(-120, 120), 0))
		var before: float = main._pending_wall
		main._process(DT)
		if before >= 0.0 and main._pending_wall < 0.0:
			walls += 1
		rain_seen = rain_seen or main.asteroids.dust_rain
		frames += 1
	assert(main.state == main.State.SECTOR_CLEAR, "o setor 1 deveria terminar")
	assert(walls == 3, "o setor 1 tem 3 paredões (vi %d)" % walls)
	assert(rain_seen, "o setor 1 tem chuva de poeira")
	var best: int = root.get_node("Game").get_sector_best("sector_1")
	assert(best > 0 and root.get_node("Game").sectors_cleared.has("sector_1"))
	print("CAMPANHA OK | setor 1 completo em %.1fs | paredoes=%d | pontos=%d" % [frames * DT, walls, main.score])


func _test_enemies() -> void:
	main.go_to_menu()
	main.start_mode(main.Mode.ENDLESS)
	_touch(true)
	main.asteroids.spawn_enabled = false
	var w: float = main.view_size.x
	for i in 3:
		main.enemies.spawn_drone(Vector2(w * 0.5 + (i - 1) * 40.0, -40.0 - i * 120.0))
	var max_shots := 0
	var hits_taken := 0
	for i in 60 * 8:
		main.asteroids.spawn_enabled = false
		var shield_before: float = main.ship.shield
		main._process(DT)
		max_shots = maxi(max_shots, main.enemy_shots.active_count())
		if main.ship.shield < shield_before - 5.0:
			hits_taken += 1
		main.ship.invuln = 0.0 if i % 120 < 60 else main.ship.invuln
		if main.state == main.State.GAME_OVER:
			break
	assert(max_shots > 0, "drones deveriam atirar")
	assert(main.enemies_destroyed > 0, "tiros do jogador deveriam destruir drones")
	print("INIMIGOS OK | drones destruidos=%d | tiros inimigos max=%d | golpes recebidos=%d" % [
		main.enemies_destroyed, max_shots, hits_taken])


func _touch(pressed: bool) -> void:
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.pressed = pressed
	# Canto inferior: longe dos botões (e do canto 0,0, onde ficam antes do 1º layout).
	t.position = Vector2(30, main.view_size.y - 30)
	main._input(t)


func _drag(relative: Vector2) -> void:
	var d := InputEventScreenDrag.new()
	d.index = 0
	d.relative = relative
	main._input(d)
