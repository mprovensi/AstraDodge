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
	_test_sector2()
	_test_sector3()
	_test_sector4()
	_test_endless_generator()
	_test_endless_run()
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
	assert(main.boss_orbs_dropped >= 8, "acertar o núcleo deveria soltar orbes (%d)" % main.boss_orbs_dropped)
	print("CAMPANHA OK | setor 1 completo em %.1fs | paredoes=%d | chefe em %.1fs | orbes do chefe=%d | estrelas=%s | pontos=%d" % [
		frames * DT, walls, boss_time, main.boss_orbs_dropped, str(main.star_checks()), main.score])


## Continua de onde _test_campaign parou (Setor 1 completo): PRÓXIMO SETOR → Setor 2 inteiro.
func _test_sector2() -> void:
	var game := root.get_node("Game")
	var sfx := root.get_node("Sfx")
	assert(main.hud._buttons["next"].visible, "Setor 1 completo mostra PRÓXIMO SETOR")
	assert(int(game.checkpoint.get("sector", -1)) == 1, "o Continuar já aponta para o Setor 2")
	var weapon_before: int = main.ship.weapon_level
	main._on_next_sector()
	assert(main.state == main.State.READY and main.director.sector.id == "sector_2")
	assert(main.ship.weapon_level == weapon_before, "a arma continua de um setor para o outro")
	assert(sfx.current_track() == "sector2", "Setor 2 tem trilha própria")
	_touch(true)
	var corridor_walls := 0
	var saw_moving := false
	var saw_armored := false
	var shells_broken := 0
	var boss_seen := false
	var boss_time := 0.0
	var phase2_seen := false
	var frames := 0
	while main.state != main.State.SECTOR_CLEAR and frames < 60 * 340:
		main.ship.invuln = 1.0
		var boss = main.boss
		if boss != null:
			if not boss_seen:
				main.ship.weapon_level = 3
			boss_seen = true
			boss_time += DT
			phase2_seen = phase2_seen or boss.phase == 2
			main.ship.move_by(Vector2(boss.aim_x() - main.ship.target.x, main.view_size.y * 0.6 - main.ship.target.y))
		elif frames % 20 == 0:
			_drag(Vector2(randf_range(-120, 120), 0))
		var walls_before: int = main._corridor_walls
		var shells_before := _count_shells()
		main._process(DT)
		if main._corridor_walls > walls_before:
			corridor_walls += 1
		shells_broken += maxi(0, shells_before - _count_shells())
		for a in main.asteroids.asteroids:
			saw_moving = saw_moving or a.drift != 0.0
			saw_armored = saw_armored or a.shell > 0
		frames += 1
	assert(main.state == main.State.SECTOR_CLEAR, "o Setor 2 deveria terminar (Minerador derrotado)")
	assert(corridor_walls >= 15, "Setor 2 tem corredores (vi %d paredes)" % corridor_walls)
	assert(saw_moving and saw_armored, "metálicos com propulsor e poeira blindada")
	assert(boss_seen and phase2_seen, "Minerador e sua fase 2")
	assert(main.hud._buttons["next"].visible, "Setor 2 completo mostra PRÓXIMO SETOR")
	print("SETOR 2 OK | %.1fs | paredes de corredor=%d | cascas quebradas=%d | chefe em %.1fs | estrelas=%s" % [
		frames * DT, corridor_walls, shells_broken, boss_time, str(main.star_checks())])


func _count_shells() -> int:
	var n := 0
	for a in main.asteroids.asteroids:
		n += a.shell
	return n


## Continua do Setor 2 completo: PRÓXIMO SETOR → Setor 3 inteiro (nuvens, minas, tempestade, Medusa).
func _test_sector3() -> void:
	var sfx := root.get_node("Sfx")
	main._on_next_sector()
	assert(main.director.sector.id == "sector_3")
	assert(sfx.current_track() == "sector3", "Setor 3 tem trilha própria")
	_touch(true)
	var clouds_seen := 0
	var mines_seen := 0
	var strikes := 0
	var drain_boost := false
	var boss_seen := false
	var phase2_seen := false
	var nodes_killed := false
	var boss_time := 0.0
	var frames := 0
	var last_mine_ids := {}
	while main.state != main.State.SECTOR_CLEAR and frames < 60 * 360:
		main.ship.invuln = 1.0
		var boss = main.boss
		if boss != null:
			if not boss_seen:
				main.ship.weapon_level = 3
			boss_seen = true
			boss_time += DT
			phase2_seen = phase2_seen or boss.phase == 2
			if boss.phase == 2 and boss._alive_nodes() == 0:
				nodes_killed = true
			main.ship.move_by(Vector2(boss.aim_x() - main.ship.target.x, main.view_size.y * 0.6 - main.ship.target.y))
		elif frames % 20 == 0:
			_drag(Vector2(randf_range(-120, 120), 0))
		main._process(DT)
		clouds_seen = maxi(clouds_seen, main.hazards.clouds.size())
		strikes += main.hazards.take_strikes().size()
		drain_boost = drain_boost or main.ship.drain_scale >= Tuning.ION_DRAIN_MULT * 0.7
		for e in main.enemies.enemies:
			if e.kind == 1 and not last_mine_ids.has(e.id):
				last_mine_ids[e.id] = true
				mines_seen += 1
		frames += 1
	assert(main.state == main.State.SECTOR_CLEAR, "o Setor 3 deveria terminar (Medusa derrotada)")
	assert(clouds_seen > 0 and drain_boost, "nuvens iônicas aparecem e drenam mais")
	assert(mines_seen >= 5, "minas iônicas (vi %d)" % mines_seen)
	assert(strikes >= 15, "tempestade com raios (vi %d)" % strikes)
	assert(boss_seen and phase2_seen and nodes_killed, "Medusa, fase 2 e os 3 nódulos")
	assert(main.hud._buttons["next"].visible, "Setor 3 completo mostra PRÓXIMO SETOR")
	print("SETOR 3 OK | %.1fs | minas=%d | raios=%d | chefe em %.1fs | estrelas=%s" % [
		frames * DT, mines_seen, strikes, boss_time, str(main.star_checks())])


## Continua do Setor 3 completo: PRÓXIMO SETOR → Setor 4 inteiro (torretas, drones, Cruzador).
func _test_sector4() -> void:
	var sfx := root.get_node("Sfx")
	main._on_next_sector()
	assert(main.director.sector.id == "sector_4")
	assert(sfx.current_track() == "sector4", "Setor 4 tem trilha própria")
	_touch(true)
	var seen := {}
	var turrets_killed := 0
	var missiles_seen := 0
	var boss_seen := false
	var phase2_seen := false
	var parts_min := 3
	var boss_time := 0.0
	var frames := 0
	var destroyed_before: int = main.enemies_destroyed
	while main.state != main.State.SECTOR_CLEAR and frames < 60 * 360:
		main.ship.invuln = 1.0
		var boss = main.boss
		if boss != null:
			if not boss_seen:
				main.ship.weapon_level = 3
			boss_seen = true
			boss_time += DT
			phase2_seen = phase2_seen or boss.phase == 2
			parts_min = mini(parts_min, boss.alive_parts())
			main.ship.move_by(Vector2(boss.aim_x() - main.ship.target.x, main.view_size.y * 0.6 - main.ship.target.y))
		elif frames % 20 == 0:
			_drag(Vector2(randf_range(-120, 120), 0))
		main._process(DT)
		for e in main.enemies.enemies:
			if not seen.has(e.id):
				seen[e.id] = e.kind
				if e.kind == 3:
					missiles_seen += 1
		frames += 1
	var kinds := {}
	for id in seen:
		kinds[seen[id]] = true
	assert(main.state == main.State.SECTOR_CLEAR, "o Setor 4 deveria terminar (Cruzador derrotado)")
	assert(kinds.has(0) and kinds.has(2), "drones e torretas aparecem")
	assert(missiles_seen >= 2, "o Cruzador lança mísseis (vi %d)" % missiles_seen)
	assert(main.enemies_destroyed > destroyed_before, "inimigos são destruídos")
	assert(boss_seen and phase2_seen and parts_min == 0, "Cruzador: fase 2 e todas as partes destruídas")
	assert(not main.hud._buttons["next"].visible, "último setor: sem PRÓXIMO SETOR")
	print("SETOR 4 OK | %.1fs | inimigos=%d | misseis=%d | chefe em %.1fs | estrelas=%s" % [
		frames * DT, seen.size(), missiles_seen, boss_time, str(main.star_checks())])


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
	# Minerador: raio só ocupa a coluna dele; explosão das cargas deixa vão entre os tiros
	# onde está uma nave que saiu do círculo de aviso (centro a ≥ raio + corpo da nave).
	var mn: GDScript = load("res://scripts/bosses/miner.gd")
	var beam_free: float = mn.beam_free_width(1080.0)
	assert(beam_free >= ship_gap * 6.0, "raio do Minerador: só %.0f px livres" % beam_free)
	var outside: float = mn.CHARGE_RADIUS + 2.0 * Tuning.SHIP_HITBOX_RADIUS
	var blast_gap: float = mn.blast_min_gap(outside, 8)
	assert(blast_gap >= ship_gap, "explosão em 8: vão de %.0f px < %.0f" % [blast_gap, ship_gap])

	# Colisão x desenho das metades da Rocha-Mãe (fase 2): no máximo 5% da área de
	# colisão pode ficar fora dos pixels do desenho — "dano sem encostar" é bug.
	var outside_pct := _half_collision_outside_pct(rm)
	assert(outside_pct <= 5.0, "metade da Rocha-Mãe: %.0f%% da colisão fora do desenho" % outside_pct)

	# Setor 3 / Medusa: brecha da chicotada, espiral, coluna do raio, anel da mina, cúpula.
	var md: GDScript = load("res://scripts/bosses/medusa.gd")
	assert(md.sweep_gap() >= ship_gap * 3.0, "brecha da chicotada: %.0f px" % md.sweep_gap())
	var spiral_gap: float = md.spiral_min_gap(300.0)
	assert(spiral_gap >= ship_gap, "espiral: vão de %.0f px a 300 px do núcleo" % spiral_gap)
	assert(1080.0 - Tuning.STORM_WIDTH >= ship_gap * 6.0, "raio da tempestade deixa a tela livre")
	var mine_gap := 2.0 * Tuning.MINE_TRIGGER * sin(PI / Tuning.MINE_SHOTS) - 28.0
	assert(mine_gap >= ship_gap, "anel da mina: vão de %.0f px" % mine_gap)
	var dome_out := _dome_collision_outside_pct(md)
	assert(dome_out <= 5.0, "cúpula da Medusa: %.0f%% da colisão fora do desenho" % dome_out)
	print("ROTA SEGURA S3 OK | brecha=%.0f | espiral=%.0f | mina=%.0f | cupula fora do desenho=%.0f%%" % [
		md.sweep_gap(), spiral_gap, mine_gap, dome_out])

	# Setor 4 / Cruzador: leque dos canhões (a 600 px), anel da ponte (a 300 px), casco x desenho.
	var cr: GDScript = load("res://scripts/bosses/cruiser.gd")
	var cannon_gap: float = cr.cannon_min_gap(600.0)
	assert(cannon_gap >= ship_gap, "canhão: vão de %.0f px" % cannon_gap)
	var ring_gap: float = cr.ring_min_gap(300.0)
	assert(ring_gap >= ship_gap, "anel da ponte: vão de %.0f px" % ring_gap)
	var hull_out := _hull_collision_outside_pct(cr)
	assert(hull_out <= 5.0, "casco do Cruzador: %.0f%% da colisão fora do desenho" % hull_out)
	print("ROTA SEGURA S4 OK | canhao=%.0f | anel=%.0f | casco fora do desenho=%.0f%%" % [cannon_gap, ring_gap, hull_out])
	print("ROTA SEGURA OK | vao do leque >= %.0f px | livre no avanco = %.0f px | raio livre = %.0f px | vao da explosao = %.0f px | colisao fora do desenho = %.0f%%" % [
		ship_gap, free, beam_free, blast_gap, outside_pct])


func _hull_collision_outside_pct(cr: GDScript) -> float:
	var boss = cr.new()
	boss.view_size = Vector2(1080, 2340)
	boss.state = 1  # FIGHT
	var c := Vector2(540, 600)
	boss.center = c
	var img: Image = root.get_node("Game").art.cruiser_body.get_image()
	var hw: float = cr.SPRITE_W * 0.5
	var hh: float = cr.SPRITE_H * 0.5
	var hits := 0
	var outside := 0
	for y in range(-230, 231, 10):
		for x in range(-460, 461, 10):
			if not boss.touches(c + Vector2(x, y), 0.0):
				continue
			hits += 1
			var u := int((x + hw) / (2.0 * hw) * img.get_width())
			var v := int((y + hh) / (2.0 * hh) * img.get_height())
			if u < 0 or v < 0 or u >= img.get_width() or v >= img.get_height() or img.get_pixel(u, v).a <= 0.5:
				outside += 1
	boss.free()
	return 100.0 * outside / maxf(1.0, hits)


func _dome_collision_outside_pct(md: GDScript) -> float:
	var boss = md.new()
	boss.view_size = Vector2(1080, 2340)
	boss.state = 1  # FIGHT (sem chicotada ativa: só a cúpula conta)
	var c := Vector2(540, 600)
	boss.center = c
	var img: Image = root.get_node("Game").art.medusa_body.get_image()
	var half: float = md.SPRITE_SIZE * 0.5
	var hits := 0
	var outside := 0
	for y in range(-220, 221, 10):
		for x in range(-220, 221, 10):
			if not boss.touches(c + Vector2(x, y), 0.0):
				continue
			hits += 1
			var u := int((x + half) / (2.0 * half) * img.get_width())
			var v := int((y + half) / (2.0 * half) * img.get_height())
			if u < 0 or v < 0 or u >= img.get_width() or v >= img.get_height() or img.get_pixel(u, v).a <= 0.5:
				outside += 1
	boss.free()
	return 100.0 * outside / maxf(1.0, hits)


func _half_collision_outside_pct(rm: GDScript) -> float:
	var boss = rm.new()
	boss.view_size = Vector2(1080, 2340)
	boss.phase = 2
	boss.state = 1  # FIGHT
	var c := Vector2(300, 600)
	boss._halves.assign([{"pos": c, "rest_y": 600.0, "lunge": -1.0},
			{"pos": Vector2(800, 600), "rest_y": 600.0, "lunge": -1.0}])
	var art = root.get_node("Game").art
	var img: Image = art.rock_mother_half.get_image()
	var half: float = rm.HALF_RADIUS / art.boss_fill
	var hits := 0
	var outside := 0
	for y in range(-200, 201, 10):
		for x in range(-200, 201, 10):
			if not boss.touches(c + Vector2(x, y), 0.0):
				continue
			hits += 1
			var u := int((x + half) / (2.0 * half) * img.get_width())
			var v := int((y + half) / (2.0 * half) * img.get_height())
			if u < 0 or v < 0 or u >= img.get_width() or v >= img.get_height() or img.get_pixel(u, v).a <= 0.5:
				outside += 1
	boss.free()
	return 100.0 * outside / maxf(1.0, hits)


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


## Infinito procedural: mesma semente = mesma partida; 100 sementes respeitam as regras de ritmo.
func _test_endless_generator() -> void:
	var K := WaveEvent.Kind
	var biomes: Array[int] = [0, 1, 2, 3]
	var bosses: Array[String] = ["rock_mother", "miner", "medusa", "cruiser"]
	var horizon := 900.0  # 15 min de linha do tempo
	var a := _endless_timeline(42, biomes, bosses, horizon)
	var b := _endless_timeline(42, biomes, bosses, horizon)
	assert(a == b, "mesma semente deveria gerar a mesma partida")
	assert(a != _endless_timeline(43, biomes, bosses, horizon), "sementes diferentes, partidas diferentes")

	var boss_count := {}
	var heavy_total := 0
	for seed_value in 100:
		var gen := EndlessGenerator.new(seed_value, main.SECTORS, biomes, bosses)
		var events := gen.generate_until(horizon)
		events.sort_custom(func(x: WaveEvent, y: WaveEvent) -> bool: return x.at < y.at)
		var last_heavy := -INF
		var boss_times: Array[float] = []
		var last_boss := ""
		for e in events:
			var heavy := e.kind == K.CORRIDOR or e.kind == K.STORM or (e.kind == K.DRONES and e.text == "EMBOSCADA!")
			if heavy:
				assert(e.at - last_heavy >= 18.0, "semente %d: dois blocos pesados seguidos (%.1fs)" % [seed_value, e.at])
				assert(e.duration <= 8.5, "bloco pesado longo demais")
				last_heavy = e.at
				heavy_total += 1
			if e.kind == K.BIOME:
				assert(e.count in biomes, "bioma não liberado")
			if e.kind == K.BOSS:
				assert(e.text in bosses)
				assert(e.text != last_boss, "o mesmo chefe duas vezes seguidas")
				last_boss = e.text
				boss_count[e.text] = boss_count.get(e.text, 0) + 1
				boss_times.append(e.at)
		assert(boss_times.size() == int(horizon / EndlessGenerator.BOSS_EVERY), "um chefe a cada 3 min")
		# Antes do chefe: calmaria (nenhum bloco começa na janela de limpeza da tela).
		for t in boss_times:
			for e in events:
				if e.kind in [K.METAL_WALL, K.CORRIDOR, K.STORM, K.DRONES, K.DUST_RAIN]:
					assert(e.at < t - EndlessGenerator.BOSS_CALM - 0.5 or e.at > t,
							"semente %d: bloco em %.1fs atrapalha a entrada do chefe" % [seed_value, e.at])
	for id in bosses:
		assert(boss_count.get(id, 0) > 0, "o chefe %s deveria aparecer" % id)
	# Sem chefes liberados (só o bioma 1): nenhum chefe, nenhuma troca de cenário.
	var only_first: Array[int] = [0]
	var no_bosses: Array[String] = []
	var solo := _endless_timeline(1, only_first, no_bosses, 400.0)
	assert(not solo.any(func(s: String) -> bool: return s.begins_with("%d:" % K.BOSS)))
	print("INFINITO PROCEDURAL OK | 100 sementes x 15 min | chefes=%s | blocos pesados=%d" % [
		str(boss_count), heavy_total])


## Linha do tempo como texto comparável ("tipo:tempo:count:texto").
func _endless_timeline(seed_value: int, biomes: Array[int], bosses: Array[String], horizon: float) -> Array[String]:
	var gen := EndlessGenerator.new(seed_value, main.SECTORS, biomes, bosses)
	var out: Array[String] = []
	for e in gen.generate_until(horizon):
		out.append("%d:%.2f:%d:%s" % [e.kind, e.at, e.count, e.text])
	return out


## Partida do Infinito de verdade: troca de bioma, 2 chefes (com vida reduzida), fim de jogo
## com recorde de tempo — e o ponto salvo da campanha não é tocado.
func _test_endless_run() -> void:
	var game := root.get_node("Game")
	var sfx := root.get_node("Sfx")
	main.go_to_menu()
	assert(game.endless_unlocked(), "Setor 2 completo libera o Infinito")
	assert(main.hud._buttons["endless"].visible, "botão INFINITO no menu")
	var saved_cp := {"sector": 2, "time": 33.0, "weapon": 3}
	game.checkpoint = saved_cp.duplicate()
	main.endless_seed = 7
	main.endless_biomes.assign([0, 1, 2, 3])
	main.endless_bosses.assign(["rock_mother", "miner", "medusa", "cruiser"])
	main.start_endless()
	assert(main.state == main.State.READY and main.mode == main.Mode.ENDLESS)
	_touch(true)
	var biomes_seen := {}
	var boss_hp := []
	var frames := 0
	var boss_frames := 0
	while main.bosses_defeated < 2 and frames < 60 * 600:
		main.ship.invuln = 1.0
		var boss = main.boss
		if boss != null:
			if boss_frames == 0:
				boss_hp.append(boss.max_hp)
				main.ship.weapon_level = maxi(main.ship.weapon_level, 3)
			boss_frames += 1
			main.ship.move_by(Vector2(boss.aim_x() - main.ship.target.x, main.view_size.y * 0.6 - main.ship.target.y))
		else:
			boss_frames = 0
			if frames % 20 == 0:
				_drag(Vector2(randf_range(-120, 120), 0))
		main._process(DT)
		biomes_seen[main._biome] = true
		frames += 1
	assert(main.bosses_defeated >= 2, "o Infinito deveria trazer chefes (derrotados: %d)" % main.bosses_defeated)
	assert(biomes_seen.size() >= 2, "o cenário deveria trocar de bioma")
	assert(boss_hp[0] < 235, "1ª aparição do chefe com vida reduzida")
	for i in 240:  # crossfade de volta
		main.ship.invuln = 1.0
		main._process(DT)
	assert(sfx.current_track() == main.SECTORS[main._biome].music, "depois do chefe volta a trilha do bioma")
	# Fim de jogo: recorde de tempo salvo, checkpoint da campanha intacto.
	var t: float = main.elapsed
	main.ship.invuln = 0.0
	main._on_ship_died()
	for i in 120:
		main._process(DT)
	assert(main.state == main.State.GAME_OVER)
	assert(game.endless_best_time >= t - 1.0, "recorde de tempo do Infinito")
	assert(game.checkpoint == saved_cp, "o Infinito não mexe no ponto salvo da campanha")
	print("INFINITO PARTIDA OK | %.0fs | biomas=%s | chefes=%d (vida %s) | recorde tempo=%.0fs" % [
		t, str(biomes_seen.keys()), main.bosses_defeated, str(boss_hp), game.endless_best_time])
	main.endless_seed = -1
	main.endless_biomes.clear()
	main.endless_bosses.clear()
	game.checkpoint = {}


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
