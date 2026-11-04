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
	_test_boss_safety()
	_test_checkpoint()
	_test_boss_resume()
	_test_music()
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
	# (Garante uma partida rodando: a simulação pode ter terminado no meio de uma explosão.)
	if main.state != main.State.PLAYING:
		_touch(false)
		main._on_restart()
		_touch(true)
		main._process(DT)
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
	var sfx := root.get_node("Sfx")
	main.go_to_menu()
	main.start_mode(main.Mode.CAMPAIGN)
	assert(main.state == main.State.READY)
	_touch(true)
	var walls := 0
	var rain_seen := false
	var alert_seen := false
	var boss_seen := false
	var boss_music := false
	var phase2_seen := false
	var boss_time := 0.0
	var frames := 0
	# Nave invencível: aqui testamos o roteiro do setor e o chefe, não a habilidade.
	# Durante o chefe, um "bot" fica embaixo do núcleo aberto (arma no nível 3).
	while main.state != main.State.SECTOR_CLEAR and frames < 60 * 330:
		main.ship.invuln = 1.0
		var boss = main.boss  # sem tipo: Boss só compila depois dos autoloads
		if boss != null:
			if not boss_seen:
				main.ship.weapon_level = 3
			boss_seen = true
			boss_time += DT
			phase2_seen = phase2_seen or boss.phase == 2
			# Fica embaixo do núcleo aberto, a uma distância segura (60% da tela).
			main.ship.move_by(Vector2(boss.aim_x() - main.ship.target.x, main.view_size.y * 0.6 - main.ship.target.y))
		elif frames % 20 == 0:
			_drag(Vector2(randf_range(-120, 120), 0))
		var before: float = main._pending_wall
		main._process(DT)
		if before >= 0.0 and main._pending_wall < 0.0:
			walls += 1
		rain_seen = rain_seen or main.asteroids.dust_rain
		alert_seen = alert_seen or main._alert_timer >= 0.0
		boss_music = boss_music or sfx.current_track() == "boss"
		frames += 1
	assert(main.state == main.State.SECTOR_CLEAR, "o setor 1 deveria terminar (chefe derrotado)")
	assert(walls == 3, "o setor 1 tem 3 paredões (vi %d)" % walls)
	assert(rain_seen, "o setor 1 tem chuva de poeira")
	assert(alert_seen and boss_seen and boss_music, "ALERTA, chefe e trilha de chefe")
	assert(phase2_seen, "a Rocha-Mãe deveria rachar (fase 2)")
	assert(sfx.current_track() == "main", "depois do chefe volta a trilha normal")
	var game := root.get_node("Game")
	assert(game.get_sector_best("sector_1") > 0 and game.sectors_cleared.has("sector_1"))
	assert(int(game.sector_stars.get("sector_1", 0)) >= 1, "pelo menos 1 estrela")
	print("CAMPANHA OK | setor 1 completo em %.1fs | paredoes=%d | chefe em %.1fs | estrelas=%s | pontos=%d" % [
		frames * DT, walls, boss_time, str(main.star_checks()), main.score])


## Rota segura: geometria dos ataques da Rocha-Mãe sempre deixa espaço para a nave.
func _test_boss_safety() -> void:
	var rm: GDScript = load("res://scripts/bosses/rock_mother.gd")  # carregado só agora (autoloads prontos)
	var ship_gap := 2.0 * Tuning.SHIP_HITBOX_RADIUS + 20.0
	for h: float in [1920.0, 2340.0]:
		# Distância do leque (borda de baixo do chefe) até a linha padrão da nave (80% da tela).
		var origin_y: float = h * rm.REST_Y_RATIO + rm.RADIUS
		var d := h * 0.8 - origin_y
		var gap: float = rm.fan_min_gap(d)
		assert(gap >= ship_gap, "leque: vão de %.0f px < %.0f (tela %d)" % [gap, ship_gap, h])
	var free: float = rm.lunge_free_width(1080.0)
	assert(free >= ship_gap * 3.0, "avanço das metades: só %.0f px livres" % free)
	print("ROTA SEGURA OK | vao do leque >= %.0f px | livre no avanco = %.0f px" % [ship_gap, free])


func _test_boss_resume() -> void:
	var game := root.get_node("Game")
	game.checkpoint = {"sector": 0, "time": 146.0}
	main.go_to_menu()
	main.resume_checkpoint()
	assert(main.director.boss_id == "rock_mother", "o ponto salvo já passou pelo chefe")
	_touch(true)
	for i in 60 * 4:
		main.ship.invuln = 1.0
		main._process(DT)
	assert(main.boss != null, "Continuar no meio do chefe recomeça a luta")
	main.go_to_menu()
	assert(main.boss == null, "voltar ao menu remove o chefe")
	game.checkpoint = {}
	print("CHEFE+CONTINUAR OK | luta recomeça ao continuar")


func _test_checkpoint() -> void:
	var game := root.get_node("Game")
	main.go_to_menu()
	main.start_mode(main.Mode.CAMPAIGN)
	_touch(true)
	for i in 60 * 50:  # 50 s de setor, passando pela chuva de poeira (45 s)
		main.ship.invuln = 1.0
		main._process(DT)
	main.ship.add_crystal()
	# Soltar o dedo -> pausa -> ponto salvo.
	_touch(false)
	for i in 60:
		main._process(DT)
	assert(main.state == main.State.PAUSED)
	assert(not game.checkpoint.is_empty(), "a pausa deveria salvar o ponto")
	var saved_time: float = main.director.time
	var saved_score: int = main.score
	var saved_weapon: int = main.ship.weapon_level
	var saved_crystals: int = main.ship.crystals

	main.go_to_menu()
	assert(main.hud._buttons["resume"].visible, "menu deveria mostrar CONTINUAR")
	main.resume_checkpoint()
	assert(main.state == main.State.READY)
	assert(absf(main.director.time - saved_time) < 0.001, "deveria voltar ao mesmo momento do setor")
	assert(main.score == saved_score and main.ship.weapon_level == saved_weapon and main.ship.crystals == saved_crystals)
	assert(main.asteroids.dust_rain == false and main.director.rain_left > 0.0, "chuva em andamento deve continuar")

	# Fim de jogo descarta o ponto salvo.
	main._set_state(main.State.GAME_OVER)
	assert(game.checkpoint.is_empty(), "fim de jogo deveria limpar o ponto salvo")
	main.go_to_menu()
	assert(not main.hud._buttons["resume"].visible, "sem ponto salvo, sem CONTINUAR")
	assert(main.hud._buttons["campaign"].visible, "sem ponto salvo, o menu mostra JOGAR")

	# NOVO JOGO (em Opções) pede confirmação e descarta o ponto salvo.
	game.checkpoint = {"sector": 0, "time": 80.0}
	main.go_to_menu()
	assert(main.hud._buttons["resume"].visible and not main.hud._buttons["campaign"].visible)
	main.hud.open_options()
	main.hud._new_game_button.pressed.emit()
	assert(main.state == main.State.MENU, "1º toque em NOVO JOGO só pede confirmação")
	main.hud._new_game_button.pressed.emit()
	assert(main.state == main.State.READY and main.director.time == 0.0, "2º toque começa do zero")
	assert(game.checkpoint.is_empty(), "novo jogo descarta o ponto salvo")
	print("CONTINUAR OK | voltou em %.1fs do setor, pontos=%d, arma=%d" % [saved_time, saved_score, saved_weapon])


func _test_music() -> void:
	var sfx := root.get_node("Sfx")
	main.go_to_menu()
	main.start_mode(main.Mode.CAMPAIGN)
	_touch(true)
	main._process(DT)
	assert(sfx.current_track() == "main", "partida começa com a trilha normal")
	main._on_wave_event(WaveEvent.make(0.0, WaveEvent.Kind.MUSIC, {"text": "boss"}))
	assert(sfx.current_track() == "boss", "evento MUSIC troca para a trilha do chefe")
	for i in 120:  # 2 s de crossfade
		main._process(DT)
	main._on_restart()
	assert(sfx.current_track() == "main", "recomeçar volta para a trilha normal")
	print("MUSICA OK | normal -> chefe -> normal")


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
