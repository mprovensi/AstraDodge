extends Node2D
## Orquestra a partida: menu, modos (campanha/infinito), estados, input de arraste,
## dificuldade, eventos do setor, colisões e pontuação.

enum State { MENU, READY, PLAYING, SLOWMO, PAUSED, DYING, GAME_OVER, SECTOR_CLEAR, CHOOSE }  # CHOOSE: escolhendo módulo
enum Mode { ENDLESS, CAMPAIGN }

const DYING_TIME := 1.2
const SECTORS: Array[SectorData] = [
	preload("res://data/sectors/sector_1.tres"),
	preload("res://data/sectors/sector_2.tres"),
	preload("res://data/sectors/sector_3.tres"),
	preload("res://data/sectors/sector_4.tres"),
	preload("res://data/sectors/sector_5.tres"),
	preload("res://data/sectors/sector_6.tres"),
	preload("res://data/sectors/sector_7.tres"),
	preload("res://data/sectors/sector_8.tres"),
]

var state := State.MENU
var mode := Mode.ENDLESS
var view_size := Vector2.ZERO

var world: Node2D
var nebula: Nebula
var starfield: Starfield
var asteroids: AsteroidField
var enemies: EnemyLayer
var hazards: HazardLayer
var telegraph: TelegraphLayer
var blackout: Blackout
var bullets: BulletLayer
var enemy_shots: EnemyBulletLayer
var pickups: PickupLayer
var fx: FxLayer
var ship: Ship
var hud: Hud

var director: SectorDirector
var sector_index := 0
var boss: Boss = null

var elapsed := 0.0
var distance := 0.0
var bonus_score := 0
var score := 0
var time_scale := 0.0
var scroll_speed := Tuning.SCROLL_SPEED_START
var enemies_destroyed := 0
var dust_destroyed := 0

var _state_timer := 0.0
var _touch_index := -1
var _shake := 0.0
var _kick := Vector2.ZERO
var _kick_vel := Vector2.ZERO
var _revive_used := false
var _pending_wall := -1.0  # segundos até o paredão avisado aparecer (-1 = nenhum)
var _last_ship_pos := Vector2.ZERO
var _engine_level := 0.0
# Chefe
var _alert_timer := -1.0      # > = 0: tela "ALERTA" antes do chefe entrar
var _alarm_beeps := 0
var _pending_boss_id := ""
var _boss_fought := false
var _boss_last_chance := false  # entrou em "última chance" durante a luta (perde a 2ª estrela)
var _corridor_left := 0.0       # s restantes do CORREDOR em andamento
var _corridor_timer := 0.0      # s até a próxima parede do corredor
var _corridor_walls := 0        # paredes já criadas no corredor atual
var _storm_left := 0.0          # s restantes da TEMPESTADE
var _storm_timer := 0.0         # s até o próximo raio
var _comets_left := 0           # cometas que ainda faltam na CHUVA DE COMETAS
var _comet_timer := 0.0
var _gates_left := 0            # portões de laser que ainda faltam na sequência
var _gate_timer := 0.0
var _slides_left := 0           # paredes móveis que ainda faltam
var _slide_timer := 0.0
var _invert_warn := 0.0         # s de aviso antes da inversão
var _invert_left := 0.0         # s restantes de inversão
var _invert_settle := 0.0       # s sem rochas novas depois da inversão
var _invert_duration := 0.0
var _escape_t := -1.0           # >= 0: cena de fuga depois do chefe final
var ice_shards := 0             # lascas criadas por gelo rachado (testes)
var eggs_destroyed := 0         # ovos destruídos antes de eclodir (testes)
var _boss_core_hits := 0        # acertos no núcleo desde o último orbe que o chefe soltou
var boss_orbs_dropped := 0      # orbes soltos por acertos no chefe (testes)
var _biome := 0                # setor cujo cenário está na tela (no Infinito, troca sozinho)
# Modo Infinito
var bosses_defeated := 0
var endless_seed := -1                  # >= 0: semente fixa (testes, Desafio do Dia)
var endless_biomes: Array[int] = []     # testes: força os biomas liberados
var endless_bosses: Array[String] = []  # testes: força os chefes liberados
var daily := false                      # Desafio do Dia (Infinito com a semente do dia)
var _daily_official := false            # esta partida é a tentativa valendo de hoje
var multiplier := 1.0                   # Infinito/Desafio: sobe sem levar dano, zera ao levar
var _no_hit_t := 0.0
var _last_raw := 0                      # pontos "crus" já somados (o multiplicador vale para os novos)
var _biomes_seen := {}                  # cenários vistos nesta partida (estatísticas)
var _best_multiplier := 1.0
# Módulos (PLANO_CARTAS.md)
var modules := Modules.new()
var auto_pick_modules := false        # testes/demo: escolhe a 1ª carta sozinho
var _offer: Array[String] = []
var _hand_at_start := {}              # mão no começo do setor (morrer recomeça com ela)
var _mod := "none"                      # modificador do Infinito nesta partida (Game.MODS)
var _mod_bonus := 1.0
var _env: Environment
var _gfx_simple := -1                   # gráficos simples aplicados (-1 = ainda não)


func _ready() -> void:
	_setup_glow()
	world = Node2D.new()
	add_child(world)
	nebula = Nebula.new()
	world.add_child(nebula)
	starfield = Starfield.new()
	world.add_child(starfield)
	pickups = PickupLayer.new()
	world.add_child(pickups)
	asteroids = AsteroidField.new()
	world.add_child(asteroids)
	enemies = EnemyLayer.new()
	world.add_child(enemies)
	hazards = HazardLayer.new()
	world.add_child(hazards)
	blackout = Blackout.new()  # acima de rochas e inimigos, abaixo dos avisos e da nave
	world.add_child(blackout)
	telegraph = TelegraphLayer.new()
	world.add_child(telegraph)
	bullets = BulletLayer.new()
	world.add_child(bullets)
	enemy_shots = EnemyBulletLayer.new()
	world.add_child(enemy_shots)
	enemies.shots = enemy_shots
	ship = Ship.new()
	ship.bullets = bullets
	world.add_child(ship)
	fx = FxLayer.new()
	world.add_child(fx)
	hud = Hud.new()
	add_child(hud)

	ship.weapon_level_changed.connect(_on_weapon_level_changed)
	ship.shield_depleted.connect(_on_shield_depleted)
	ship.fired.connect(func() -> void: Sfx.play("laser", -12.0, 1.0, 0.08, ship.position))
	hud.resume_pressed.connect(resume_checkpoint)
	hud.campaign_pressed.connect(start_new_game)
	hud.endless_pressed.connect(start_endless)
	hud.daily_pressed.connect(start_daily)
	hud.dev_sector_pressed.connect(start_sector_dev)
	var sector_names: Array = []
	for s in SECTORS:
		sector_names.append([s.title, s.subtitle])
	hud.setup_dev_selector(sector_names)  # só monta em build de desenvolvimento
	hud.new_game_pressed.connect(start_new_game)
	hud.restart_pressed.connect(_on_restart)
	hud.continue_pressed.connect(_on_continue)
	hud.menu_pressed.connect(go_to_menu)
	hud.next_pressed.connect(_on_next_sector)
	hud.module_chosen.connect(_on_module_chosen)
	hud.quit_pressed.connect(_on_quit)
	asteroids.row_spawned.connect(_on_row_spawned)
	get_viewport().size_changed.connect(_on_resized)

	_on_resized()
	go_to_menu()


func _notification(what: int) -> void:
	# App foi para segundo plano: pausa (e a pausa salva o ponto para "Continuar").
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if state == State.PLAYING or state == State.SLOWMO:
			_touch_index = -1
			_set_state(State.PAUSED)
		else:
			_save_checkpoint()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_checkpoint()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if hud.blocks_touch(touch.position):
				return  # toque em botão/opções: não inicia a partida
			if _touch_index == -1 and state in [State.READY, State.PLAYING, State.SLOWMO, State.PAUSED]:
				_touch_index = touch.index
				_set_state(State.PLAYING)
		elif touch.index == _touch_index:
			_touch_index = -1
			if state == State.PLAYING:
				_set_state(State.SLOWMO)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index and (state == State.PLAYING or state == State.SLOWMO):
			ship.move_by(drag.relative * Game.sensitivity)


## Brilho neon: desligado no modificador Retrô e nos gráficos simples (pesa em GPU antiga).
func _update_glow() -> void:
	_env.glow_enabled = _mod != "retro" and not Game.graphics_simple()


## Opção Gráficos (Automático/Completo/Simples): aplica quando muda (inclusive na 1ª vez).
func _apply_graphics() -> void:
	var simple := Game.graphics_simple()
	if int(simple) == _gfx_simple:
		return
	_gfx_simple = int(simple)
	nebula.set_simple(simple)
	_update_glow()


func _process(delta: float) -> void:
	_apply_graphics()
	match state:
		State.PLAYING:
			time_scale = move_toward(time_scale, 1.0, delta * 6.0)
		State.SLOWMO:
			time_scale = move_toward(time_scale, Tuning.RELEASE_SLOWMO_SCALE, delta * 8.0)
			_state_timer -= delta
			if _state_timer <= 0.0:
				_set_state(State.PAUSED)
		State.DYING:
			time_scale = 0.4
			_state_timer -= delta
			if _state_timer <= 0.0:
				_set_state(State.GAME_OVER)
		_:
			time_scale = 0.0

	# Se o estado acabou de mudar para pausa/fim neste frame, nada mais avança.
	var running := state == State.PLAYING or state == State.SLOWMO or state == State.DYING
	var dt := delta * time_scale if running else 0.0
	if dt > 0.0:
		_step(dt)

	# As estrelas nunca param totalmente, para o menu e a pausa não parecerem "travados".
	# Na inversão o fundo também "sobe".
	var flow := -1.0 if asteroids.inverted else 1.0
	starfield.update(delta, flow * scroll_speed * maxf(time_scale, 0.15))
	nebula.update(delta, flow * scroll_speed * maxf(time_scale, 0.15))
	_update_shake(delta)
	var quiet := state != State.PLAYING and state != State.SLOWMO and state != State.DYING
	Sfx.set_music_intensity(time_scale, quiet)
	_update_engine_sound(delta)
	hud.set_values(score, maxi(score, _best_for_mode()), ship.shield_ratio(), ship.last_chance,
			ship.weapon_level, ship.weapon_progress())
	hud.set_alert(_alert_timer)
	hud.set_multiplier(multiplier if mode == Mode.ENDLESS else 1.0)
	if boss != null:
		hud.set_boss_hp(boss.hp_ratio())


# ---------------------------------------------------------------- fluxo

func go_to_menu() -> void:
	_touch_index = -1
	mode = Mode.ENDLESS
	_new_run()
	director = null  # o menu não roda linha do tempo
	_mod = "none"
	_update_glow()
	ship.visible = false
	hud.clear_hint()
	_set_state(State.MENU)


## Começa a campanha do Setor 1, descartando o ponto salvo.
func start_new_game() -> void:
	_touch_index = -1
	Game.clear_checkpoint()
	_hand_at_start = {}  # novo jogo: sem módulos
	start_mode(Mode.CAMPAIGN)


## SELETOR DE FASES (modo dev): começa o setor `index` do início ou já no ALERTA do chefe,
## com uma arma razoável para o ponto da campanha. Só existe em build de desenvolvimento.
func start_sector_dev(index: int, at_boss: bool) -> void:
	if not OS.is_debug_build():
		return
	_touch_index = -1
	_hand_at_start = {}
	start_mode(Mode.CAMPAIGN, clampi(index, 0, SECTORS.size() - 1))
	ship.weapon_level = clampi(index + 1, 2, 4)
	if at_boss:
		for e in director.sector.events:
			if e.kind == WaveEvent.Kind.BOSS:
				director.seek(maxf(0.0, e.at - 4.0))
				break


## Modo Infinito: nova semente a cada partida (o ponto salvo da campanha não é tocado).
func start_endless() -> void:
	_touch_index = -1
	daily = false
	start_mode(Mode.ENDLESS)
	if _mod != "none":
		hud.show_hint("MODIFICADOR: %s\n%s" % [Game.MODS[Game.mod][1], Game.MODS[Game.mod][4]], 4.0)


## DESAFIO DO DIA: o Infinito com a semente do dia e TODOS os cenários e chefes — a mesma
## sequência para todo mundo. Só a 1ª tentativa do dia vale; "Reiniciar" depois é treino.
func start_daily() -> void:
	_touch_index = -1
	daily = true
	start_mode(Mode.ENDLESS)
	if _daily_official:
		Game.begin_daily()
		hud.show_hint("DESAFIO DE %s\nTentativa VALENDO!" % _today_label(), 4.0)
	else:
		hud.show_hint("DESAFIO DE %s — TREINO\nA tentativa de hoje já foi: %d pontos" % [
				_today_label(), Game.daily_score], 4.0)


static func _today_label() -> String:
	var d := Time.get_date_dict_from_system()
	return "%02d/%02d" % [d.day, d.month]


func start_mode(new_mode: Mode, index := 0) -> void:
	mode = new_mode
	if new_mode == Mode.CAMPAIGN:
		daily = false
	sector_index = index
	_new_run()
	_set_state(State.READY)


func _new_run() -> void:
	elapsed = 0.0
	distance = 0.0
	bonus_score = 0
	score = 0
	multiplier = 1.0
	_no_hit_t = 0.0
	_last_raw = 0
	_biomes_seen = {}
	_best_multiplier = 1.0
	_daily_official = daily and Game.daily_available()
	# Módulos: na campanha começa com a mão do começo do setor; no Infinito/Desafio, vazia.
	if mode == Mode.CAMPAIGN:
		modules.load_dict(_hand_at_start)
	else:
		modules.clear()
	_apply_modules()
	enemies_destroyed = 0
	dust_destroyed = 0
	scroll_speed = Tuning.SCROLL_SPEED_START
	_revive_used = false
	_pending_wall = -1.0
	_corridor_left = 0.0
	_corridor_walls = 0
	_clear_boss()
	asteroids.reset()
	enemies.clear()
	enemy_shots.clear()
	telegraph.clear()
	hazards.clear()
	blackout.clear()
	_storm_left = 0.0
	_comets_left = 0
	_gates_left = 0
	_slides_left = 0
	_invert_warn = 0.0
	_invert_left = 0.0
	_invert_settle = 0.0
	_escape_t = -1.0
	ice_shards = 0
	eggs_destroyed = 0
	bosses_defeated = 0
	boss_orbs_dropped = 0
	bullets.clear()
	pickups.clear()
	fx.clear()
	hud.clear_hint()
	ship.reset(Vector2(view_size.x * 0.5, view_size.y * 0.8))
	if mode == Mode.CAMPAIGN:
		director = SectorDirector.new(SECTORS[sector_index])
		_biome = sector_index
	else:
		director = _make_endless_director()
		_biome = director.generator.biomes[0]
	# Modificador do Infinito (nunca no Desafio do Dia nem na campanha).
	_mod = Game.mod_id() if mode == Mode.ENDLESS and not daily else "none"
	_mod_bonus = Game.mod_bonus() if _mod != "none" else 1.0
	if _mod == "bosses":
		director.generator.boss_every = EndlessGenerator.BOSS_EVERY * 0.5
	_update_glow()
	nebula.set_colors(SECTORS[_biome].nebula_a, SECTORS[_biome].nebula_b)
	Sfx.play_music(SECTORS[_biome].music)


## Infinito: biomas = setores completos; chefes = os desses setores (ver PLANO_V3.md, seção 3).
func _make_endless_director() -> SectorDirector:
	var biomes: Array[int] = []
	var boss_ids: Array[String] = []
	for i in SECTORS.size():
		if Game.sectors_cleared.has(SECTORS[i].id):
			biomes.append(i)
			for e in SECTORS[i].events:
				if e.kind == WaveEvent.Kind.BOSS:
					boss_ids.append(e.text)
	if not endless_biomes.is_empty():
		biomes = endless_biomes
	if not endless_bosses.is_empty():
		boss_ids = endless_bosses
	var seed_value := endless_seed if endless_seed >= 0 else randi()
	if daily:
		# Igual para todos: todos os cenários e chefes, semente do dia (também no sorteio
		# das fileiras, para a partida ficar o mais parecida possível entre aparelhos).
		biomes.clear()
		boss_ids.clear()
		for i in SECTORS.size():
			biomes.append(i)
			for e in SECTORS[i].events:
				if e.kind == WaveEvent.Kind.BOSS:
					boss_ids.append(e.text)
		seed_value = Game.daily_seed()
		seed(seed_value)
	var data := SectorData.new()
	data.id = "daily" if daily else "endless"
	data.title = "DESAFIO DO DIA" if daily else "MODO INFINITO"
	data.duration = 1.0e9
	return SectorDirector.new(data, EndlessGenerator.new(seed_value, SECTORS, biomes, boss_ids))


## Volta ao ponto salvo: mesmo setor e momento, mesma pontuação, escudo e arma.
## O campo de asteroides recomeça limpo, com invencibilidade curta para retomar.
func resume_checkpoint() -> void:
	var cp := Game.checkpoint
	if cp.is_empty():
		return
	_hand_at_start = cp.get("modules_start", {})  # morrer recomeça o setor com a mão do começo dele
	start_mode(Mode.CAMPAIGN, clampi(int(cp.get("sector", 0)), 0, SECTORS.size() - 1))
	director.seek(float(cp.get("time", 0.0)))
	elapsed = float(cp.get("elapsed", 0.0))
	distance = float(cp.get("distance", 0.0))
	bonus_score = int(cp.get("bonus", 0))
	score = int(distance * Tuning.SCORE_PER_PIXEL) + bonus_score
	_last_raw = score  # os pontos novos (com módulos) contam a partir daqui
	score = int(cp.get("score", score))  # a pontuação salva (com os multiplicadores dos módulos)
	_revive_used = bool(cp.get("revive_used", false))
	ship.shield = float(cp.get("shield", Tuning.SHIELD_MAX))
	ship.last_chance = bool(cp.get("last_chance", false))
	ship.weapon_level = clampi(int(cp.get("weapon", 1)), 1, Tuning.WEAPON_MAX_LEVEL)
	ship.crystals = int(cp.get("crystals", 0))
	modules.load_dict(cp.get("modules", {}))
	_apply_modules()
	ship.invuln = Tuning.REVIVE_INVULN_TIME
	asteroids.dust_spawned = int(cp.get("dust_spawned", 0))
	dust_destroyed = int(cp.get("dust_destroyed", 0))
	Sfx.play_music(director.music_track)  # volta com a trilha do momento (ex.: chefe)
	# Parou durante o chefe? A luta recomeça do início (com o alerta).
	if director.boss_id != "":
		_begin_boss_alert(director.boss_id)


func _run_active() -> bool:
	return mode == Mode.CAMPAIGN and director != null and ship.alive \
			and state in [State.READY, State.PLAYING, State.SLOWMO, State.PAUSED]


func _save_checkpoint() -> void:
	if not _run_active():
		return
	Game.set_checkpoint({
		"sector": sector_index,
		"time": director.time,
		"elapsed": elapsed,
		"distance": distance,
		"bonus": bonus_score,
		"revive_used": _revive_used,
		"shield": ship.shield,
		"last_chance": ship.last_chance,
		"weapon": ship.weapon_level,
		"crystals": ship.crystals,
		"dust_spawned": asteroids.dust_spawned,
		"dust_destroyed": dust_destroyed,
		"score": score,
		"modules": modules.to_dict(),
		"modules_start": _hand_at_start,
	})


func _on_quit() -> void:
	_save_checkpoint()
	Game.save_data()
	get_tree().quit()


func _ready_title() -> String:
	return director.sector.title


func _best_for_mode() -> int:
	if mode == Mode.CAMPAIGN and director != null:
		return Game.get_sector_best(director.sector.id)
	if daily:
		return Game.daily_best
	return Game.high_score


## Estatísticas da partida do Infinito/Desafio (tela de fim de jogo).
func _run_stats() -> String:
	return "TEMPO %s · CHEFES %d · POEIRA %d\nCENÁRIOS %d · ATÉ: %s\nMULTIPLICADOR MÁXIMO x%.1f" % [
		_clock(elapsed), bosses_defeated, dust_destroyed, _biomes_seen.size(),
		SECTORS[_biome].subtitle.to_upper(), _best_multiplier]


## Vai para o próximo setor levando a arma (nível e cristais): recompensa por jogar bem.
func _on_next_sector() -> void:
	if sector_index + 1 >= SECTORS.size():
		return
	var weapon := ship.weapon_level
	var crystals := ship.crystals
	_touch_index = -1
	_hand_at_start = modules.to_dict()  # os módulos continuam no próximo setor
	start_mode(Mode.CAMPAIGN, sector_index + 1)
	ship.weapon_level = weapon
	ship.crystals = crystals


func _has_next_sector() -> bool:
	return mode == Mode.CAMPAIGN and sector_index + 1 < SECTORS.size()


func _on_restart() -> void:
	_new_run()
	_set_state(State.READY)


## Placeholder do "reviver com anúncio" (Fase 3 liga isto ao Rewarded Ad).
func _on_continue() -> void:
	_revive_used = true
	ship.revive()
	asteroids.clear_around(ship.position, Tuning.REVIVE_CLEAR_RADIUS)
	enemies.clear_around(ship.position, Tuning.REVIVE_CLEAR_RADIUS)
	enemy_shots.clear()
	bullets.clear()
	_set_state(State.READY)


func _set_state(new_state: State) -> void:
	state = new_state
	match new_state:
		State.MENU:
			hud.show_menu(not Game.checkpoint.is_empty(), Game.endless_unlocked(),
					"DESAFIO DO DIA" if Game.daily_available() else "DESAFIO (TREINO)")
		State.READY:
			hud.show_ready(_ready_title())
		State.PLAYING:
			hud.hide_center()
			Sfx.start_music()
		State.SLOWMO:
			_state_timer = Tuning.RELEASE_SLOWMO_TIME
		State.PAUSED:
			hud.show_paused()
			_save_checkpoint()
		State.DYING:
			_touch_index = -1
			_state_timer = DYING_TIME
		State.GAME_OVER:
			if mode == Mode.CAMPAIGN:
				Game.clear_checkpoint()  # a partida acabou: não há de onde continuar
				var is_record := Game.submit_sector(director.sector.id, score, false)
				hud.show_game_over(score, _best_for_mode(), is_record, not _revive_used)
			elif daily:
				var lines := [_run_stats()]
				var is_record := false
				if _daily_official:
					is_record = Game.submit_daily(score)
					_daily_official = false  # "Reiniciar" agora é treino
					lines.append("DESAFIO DE HOJE: %d · MELHOR %d" % [score, Game.daily_best])
				else:
					lines.append("TREINO · VALENDO HOJE: %d" % Game.daily_score)
				hud.show_game_over(score, Game.daily_best, is_record, not _revive_used, "\n".join(lines))
			else:
				var records := Game.submit_endless(score, elapsed)
				var info := "%s\nRECORDE %d · %s%s" % [_run_stats(), Game.high_score,
						_clock(Game.endless_best_time), "  NOVO TEMPO!" if records[1] else ""]
				hud.show_game_over(score, Game.high_score, records[0], not _revive_used, info)
		State.SECTOR_CLEAR:
			_touch_index = -1
			# Próximo setor liberado: o "Continuar" do menu já leva para ele, com a arma atual.
			if _has_next_sector():
				Game.set_checkpoint({"sector": sector_index + 1, "time": 0.0,
						"weapon": ship.weapon_level, "crystals": ship.crystals,
						"modules": modules.to_dict(), "modules_start": modules.to_dict()})
			else:
				Game.clear_checkpoint()
			var is_record := Game.submit_sector(director.sector.id, score, true)
			var checks := star_checks()
			Game.submit_stars(director.sector.id, checks.count(true))
			hud.clear_hint()
			var clear_title := director.sector.title if _has_next_sector() else "CAMPANHA\nCOMPLETA!"
			hud.show_sector_clear(clear_title, score, _best_for_mode(), is_record, checks,
					_has_next_sector())
			Sfx.play("level_up", -2.0, 1.0, 0.0)


# ---------------------------------------------------------------- simulação

func _step(dt: float) -> void:
	if ship.alive:
		elapsed += dt

	var difficulty: float
	if director != null:
		# No Infinito a linha do tempo para durante o chefe (o próximo trecho espera a luta acabar).
		var boss_busy := mode == Mode.ENDLESS and (boss != null or _alert_timer >= 0.0)
		if ship.alive and not boss_busy:
			for e in director.update(dt):
				_on_wave_event(e)
		difficulty = director.difficulty()
		if _mod == "fast":
			difficulty = maxf(difficulty, 0.7)  # modificador VELOCIDADE MÁXIMA
		asteroids.density = director.density
		asteroids.metals_enabled = director.metals
		asteroids.dust_rain = director.rain_left > 0.0
		asteroids.moving_metals = director.moving
		asteroids.armored = director.armored
		asteroids.ice = director.ice
		asteroids.look = _biome  # visual das rochas do setor/cenário atual
		asteroids.spawn_enabled = director.calm_left <= 0.0 and _pending_wall < 0.0 and not director.finished \
				and boss == null and _alert_timer < 0.0 and _corridor_left <= 0.0 \
				and _gates_left <= 0 and hazards.gates.is_empty() and _slides_left <= 0 \
				and _invert_warn <= 0.0 and _invert_settle <= 0.0
		_update_corridor(dt)
		_update_storm(dt)
		_update_comets(dt)
		_update_station(dt)
		_update_invert(dt)
	else:
		difficulty = Tuning.difficulty(elapsed)

	_update_boss_flow(dt)

	scroll_speed = lerpf(Tuning.SCROLL_SPEED_START, Tuning.SCROLL_SPEED_MAX, difficulty)
	_update_escape(dt)
	if ship.alive:
		distance += scroll_speed * dt  # (o rastro do motor é a própria chama da nave)

	if _pending_wall >= 0.0:
		_pending_wall -= dt
		if _pending_wall < 0.0:
			asteroids.spawn_wall()

	asteroids.update(dt, scroll_speed, difficulty)
	enemies.update(dt, ship.position, scroll_speed)
	hazards.update(dt, scroll_speed)
	_apply_rift(dt)
	# Drenagem do escudo: menor durante chefes, 3x dentro de nuvem iônica.
	var boss_drain := Tuning.BOSS_SHIELD_DRAIN_SCALE if boss != null else 1.0
	var cloud_drain := Tuning.ION_DRAIN_MULT if hazards.in_cloud(ship.position) else 1.0
	ship.drain_scale = boss_drain * cloud_drain
	telegraph.update(dt)
	blackout.update(dt, ship.position)
	bullets.update(dt)
	enemy_shots.update(dt)
	ship.scroll_speed = scroll_speed  # o rastro dos motores "escorre" com o cenário
	ship.update(dt)
	for kind in pickups.update(dt, scroll_speed, ship.position, ship.alive):
		_on_pickup(kind)
	fx.update(dt)

	_check_bullet_hits()
	_check_ship_hits()
	_update_score(dt)

	# Fim do setor: depois do END (ou do chefe derrotado), quando a tela esvaziar
	# — inclusive a chuva de orbes/cristais da vitória, para dar tempo de coletar.
	if mode == Mode.CAMPAIGN and director.finished and ship.alive and boss == null and _escape_t < 0.0 \
			and asteroids.asteroids.is_empty() and enemies.enemies.is_empty() and pickups.pickups.is_empty() \
			and (state == State.PLAYING or state == State.SLOWMO):
		_set_state(State.SECTOR_CLEAR)


func _on_wave_event(e: WaveEvent) -> void:
	match e.kind:
		WaveEvent.Kind.MESSAGE:
			hud.show_hint(e.text, e.duration if e.duration > 0.0 else 3.5)
		WaveEvent.Kind.MUSIC:
			Sfx.play_music(e.text)
		WaveEvent.Kind.BIOME:
			_biome = clampi(e.count, 0, SECTORS.size() - 1)
			nebula.fade_to(SECTORS[_biome].nebula_a, SECTORS[_biome].nebula_b)
			if boss == null and _alert_timer < 0.0:
				Sfx.play_music(SECTORS[_biome].music)
		WaveEvent.Kind.BOSS:
			_begin_boss_alert(e.text)
		WaveEvent.Kind.METAL_WALL:
			_pending_wall = Tuning.WALL_TELEGRAPH_TIME
			for span in asteroids.wall_spans():
				telegraph.column(span.x, span.y, Tuning.WALL_TELEGRAPH_TIME)
			hud.show_hint("PAREDÃO! Procure a brecha", 2.5)
			Sfx.play("alarm", -8.0, 1.2, 0.0)
		WaveEvent.Kind.DRONES:
			var margin := Tuning.DRONE_V_SPACING * (e.count - 1) * 0.5 + 60.0
			enemies.spawn_drone_v(e.count, randf_range(margin, view_size.x - margin))
			if e.text != "":
				hud.show_hint(e.text, 2.5)
		WaveEvent.Kind.SWARM:
			enemies.spawn_swarm(e.count, randf_range(view_size.x * 0.25, view_size.x * 0.75))
			if e.text != "":
				hud.show_hint(e.text, 2.5)
		WaveEvent.Kind.MOTHERSHIP:
			enemies.spawn_mothership(randf() < 0.5)
			hud.show_hint("NAVE-MÃE!
Derrube para ganhar um módulo" if _modules_unlocked()
					else "NAVE-MÃE!
Derrube antes que ela fuja", 2.5)
			Sfx.play("alarm", -10.0, 0.7, 0.0)
		WaveEvent.Kind.HATCH:
			# Ovos espalhados pela largura, todos de uma vez: dá para destruir quase todos.
			for i in e.count:
				var x := view_size.x * (i + 0.5) / e.count + randf_range(-40.0, 40.0)
				enemies.spawn_egg(Vector2(x, -60.0 - randf_range(0.0, 160.0)))
			hud.show_hint("ECLOSÃO! Destrua os ovos\nantes do anel fechar", 2.5)
			Sfx.play("alarm", -10.0, 0.9, 0.0)
		WaveEvent.Kind.INVERT:
			_invert_warn = Tuning.INVERT_WARN
			_invert_duration = e.duration
			hud.show_hint("INVERSÃO!\nAs rochas vão subir — fique no alto", 3.0)
			Sfx.play("alarm", -4.0, 0.7, 0.0)
		WaveEvent.Kind.GATES:
			_gates_left = e.count
			_gate_timer = 0.0
			hud.show_hint("PORTÕES DE LASER!\nCruze quando estiverem apagados", 3.0)
		WaveEvent.Kind.SLIDE:
			_slides_left = e.count
			_slide_timer = 0.0
			hud.show_hint("PAREDES MÓVEIS!\nAcompanhe a brecha", 2.5)
			Sfx.play("alarm", -8.0, 1.2, 0.0)
		WaveEvent.Kind.BLACKOUT:
			blackout.start(e.duration)
			hud.show_hint("BLECAUTE!", 2.0)
			Sfx.play("level_down", -6.0, 0.6, 0.0)
		WaveEvent.Kind.COMETS:
			_comets_left = e.count
			_comet_timer = 0.0
			hud.show_hint("CHUVA DE COMETAS!\nFuja das faixas vermelhas", 2.5)
		WaveEvent.Kind.STORM:
			_storm_left = e.duration
			_storm_timer = 0.3
			hud.show_hint("TEMPESTADE! Fuja das colunas", 2.5)
		WaveEvent.Kind.CORRIDOR:
			# A 1ª parede é avisada como um paredão; as seguintes vêm em sequência,
			# com a brecha andando pouco (dá para seguir sem susto).
			_corridor_left = e.duration
			_corridor_timer = Tuning.WALL_TELEGRAPH_TIME
			_corridor_walls = 0
			for span in asteroids.wall_spans():
				telegraph.column(span.x, span.y, Tuning.WALL_TELEGRAPH_TIME)
			hud.show_hint("CORREDOR! Siga a brecha", 2.5)
			Sfx.play("alarm", -8.0, 1.2, 0.0)


## Setor 3: cada linha nova pode trazer uma nuvem iônica e/ou uma mina (fora do corredor).
func _on_row_spawned(gap_x: float) -> void:
	if director == null:
		return
	if randf() < director.clouds:
		var r := randf_range(Tuning.CLOUD_RADIUS_MIN, Tuning.CLOUD_RADIUS_MAX)
		hazards.spawn_cloud(Vector2(randf_range(r * 0.5, view_size.x - r * 0.5), -r), r)
	var half_gap := Tuning.SAFE_GAP_WIDTH * 0.5 + 60.0
	if randf() < director.mines:
		for attempt in 6:
			var x := randf_range(60.0, view_size.x - 60.0)
			if absf(x - gap_x) > half_gap:
				enemies.spawn_mine(Vector2(x, -60.0))
				break
	# Setor 6: grupinho do enxame e ovos avulsos (fora do corredor livre).
	if randf() < director.swarm:
		enemies.spawn_swarm(4, randf_range(view_size.x * 0.2, view_size.x * 0.8))
	if randf() < director.eggs:
		for attempt in 6:
			var x := randf_range(60.0, view_size.x - 60.0)
			if absf(x - gap_x) > half_gap:
				enemies.spawn_egg(Vector2(x, -60.0))
				break
	# Setor 8: poços gravitacionais e pares de portais (saída longe da entrada).
	if randf() < director.wells:
		hazards.spawn_well(randf_range(150.0, view_size.x - 150.0))
	if randf() < director.portals:
		var xa := randf_range(Tuning.PORTAL_RADIUS, view_size.x - Tuning.PORTAL_RADIUS)
		var xb := xa
		for attempt in 10:
			xb = randf_range(Tuning.PORTAL_RADIUS, view_size.x - Tuning.PORTAL_RADIUS)
			if absf(xb - xa) >= Tuning.PORTAL_SHIFT_MIN:
				break
		if absf(xb - xa) >= Tuning.PORTAL_SHIFT_MIN:
			hazards.spawn_portal(xa, xb)
	# Setor 5: cometa avulso de vez em quando.
	if randf() < director.comets:
		_spawn_comet()
	# Setor 4: torretas em destroços, sempre fora do corredor livre.
	if randf() < director.turrets:
		for attempt in 6:
			var x := randf_range(70.0, view_size.x - 70.0)
			if absf(x - gap_x) > half_gap:
				enemies.spawn_turret(Vector2(x, -70.0))
				break


## TEMPESTADE: um raio por vez, avisado em coluna. Metade cai perto da nave (pressão),
## metade em qualquer lugar.
## CHUVA DE COMETAS: um cometa por vez, cada um avisado em linha.
func _update_comets(dt: float) -> void:
	if _comets_left <= 0:
		return
	_comet_timer -= dt
	if _comet_timer <= 0.0:
		_comet_timer = Tuning.COMET_SHOWER_INTERVAL
		_comets_left -= 1
		_spawn_comet()


## Cometa na diagonal: entra por cima e sai por baixo, cruzando boa parte da largura.
func _spawn_comet() -> void:
	var w := view_size.x
	var x0 := randf_range(0.0, w)
	var dx := randf_range(350.0, 800.0) * (-1.0 if x0 > w * 0.5 else 1.0)
	var from := Vector2(x0, -80.0)
	var to := Vector2(x0 + dx, view_size.y + 80.0)
	hazards.spawn_comet(from, to, telegraph)
	Sfx.play("alarm", -14.0, 1.8, 0.0, from)


func _update_storm(dt: float) -> void:
	if _storm_left <= 0.0:
		return
	_storm_left -= dt
	_storm_timer -= dt
	if _storm_timer <= 0.0:
		_storm_timer = Tuning.STORM_INTERVAL
		var x := ship.position.x + randf_range(-160.0, 160.0) if randf() < 0.5 \
				else randf_range(0.0, view_size.x)
		hazards.spawn_strike(x, telegraph)
		Sfx.play("alarm", -14.0, 1.5, 0.0, Vector2(x, 0))


## Pontuação. Campanha: distância + bônus. Infinito/Desafio: os pontos NOVOS são
## multiplicados — o multiplicador sobe +0,5 a cada MULT_STEP_TIME s sem levar dano (até
## MULT_MAX) e volta a x1 ao levar dano (ver _damage_ship).
func _update_score(dt: float) -> void:
	var raw := int(distance * Tuning.SCORE_PER_PIXEL) + bonus_score
	if mode == Mode.CAMPAIGN:
		# Campanha: distância + bônus (o módulo VIDRO multiplica os pontos novos).
		score += int(round((raw - _last_raw) * modules.score_scale()))
		_last_raw = raw
		return
	_biomes_seen[_biome] = true
	if ship.alive:
		_no_hit_t += dt
		var before := multiplier
		multiplier = minf(Tuning.MULT_MAX, 1.0 + floorf(_no_hit_t / Tuning.MULT_STEP_TIME) * 0.5)
		if multiplier > before:
			hud.on_multiplier_up(multiplier)
		_best_multiplier = maxf(_best_multiplier, multiplier)
	score += int(round((raw - _last_raw) * multiplier * _mod_bonus * modules.score_scale()))
	_last_raw = raw


## Setor 8 — INVERSÃO: aviso (sem rochas novas) → rochas vindo de baixo → respiro → normal.
func _update_invert(dt: float) -> void:
	if _invert_warn > 0.0:
		_invert_warn -= dt
		if _invert_warn <= 0.0:
			asteroids.inverted = true
			_invert_left = _invert_duration
		return
	if _invert_left > 0.0:
		_invert_left -= dt
		if _invert_left <= 0.0:
			asteroids.inverted = false
			_invert_settle = Tuning.INVERT_SETTLE
		return
	_invert_settle = maxf(0.0, _invert_settle - dt)


## Setor 8: gravidade dos poços (puxa a nave, curva os tiros) e portais (rochas teleportam).
func _apply_rift(dt: float) -> void:
	if not hazards.wells.is_empty():
		if ship.alive:
			ship.move_by(hazards.well_pull(ship.position) * dt)
		for b in bullets.pool:
			if b.alive:
				var speed := b.vel.length()
				b.vel = (b.vel + hazards.well_bend(b.pos) * dt).normalized() * speed
	if not hazards.portals.is_empty():
		for a in asteroids.asteroids:
			if a.ported or not a.alive:
				continue
			var jump := hazards.portal_jump(a.pos)
			if jump != Vector2.ZERO:
				fx.burst(a.pos, Palette.NEON_HDR, 10, 260.0, 0.3, 4.0)
				a.pos += jump
				a.ported = true
				fx.burst(a.pos, Palette.MAGENTA_HDR, 10, 260.0, 0.3, 4.0)
				Sfx.play("pickup_crystal", -12.0, 0.5, 0.1, a.pos)


## Setor 7: sequências de portões de laser e de paredes móveis.
## Os portões saem um compasso depois do outro: na altura da nave chegam todos no mesmo
## ponto do compasso — quem acertou o tempo no 1º passa por todos parado.
func _update_station(dt: float) -> void:
	if _gates_left > 0:
		_gate_timer -= dt
		if _gate_timer <= 0.0:
			_gate_timer = Tuning.GATE_PERIOD
			_gates_left -= 1
			hazards.spawn_gate()
	if _slides_left > 0:
		_slide_timer -= dt
		if _slide_timer <= 0.0:
			_slide_timer = Tuning.SLIDE_INTERVAL
			_slides_left -= 1
			asteroids.spawn_sliding_wall()


func _update_corridor(dt: float) -> void:
	if _corridor_left <= 0.0:
		return
	_corridor_left -= dt
	_corridor_timer -= dt
	if _corridor_timer <= 0.0:
		_corridor_timer = Tuning.CORRIDOR_INTERVAL
		if _corridor_walls == 0:
			asteroids.spawn_wall(false)  # a 1ª parede usa a brecha avisada
		else:
			asteroids.spawn_corridor_wall()
		_corridor_walls += 1
	if _corridor_left <= 0.0:
		_corridor_walls = 0


func _check_bullet_hits() -> void:
	for b in bullets.pool:
		if not b.alive:
			continue
		if boss != null and _bullet_hits_boss(b):
			continue
		var a := asteroids.hit_test(b.pos, b.hit_ids, b.prev)
		if a != null:
			_bullet_hits_asteroid(b, a)
			continue
		var e := enemies.hit_test(b.pos, b.hit_ids, b.prev)
		if e != null:
			if b.pierce:
				b.hit_ids[-e.id] = true
			else:
				b.alive = false
			if enemies.damage(e, Tuning.BULLET_DAMAGE):
				_on_enemy_destroyed(e)
			else:
				fx.spark(b.pos, Palette.ENEMY)
				Sfx.play("hit", -12.0, 1.3, 0.1, b.pos)


## Tiro no chefe: núcleo aberto leva dano; o resto é armadura (ricochete).
func _bullet_hits_boss(b: BulletLayer.Bullet) -> bool:
	var hit := boss.hit_bullet(b.pos)
	if hit == Boss.Hit.NONE:
		return false
	b.alive = false
	if hit == Boss.Hit.CORE:
		boss.damage(Tuning.BULLET_DAMAGE)
		fx.spark(b.pos, Palette.BLAST_HDR)
		Sfx.play("hit", -12.0, 1.5, 0.1, b.pos)
		# Acertar o ponto fraco recompensa com escudo: a luta não depende só da poeira.
		_boss_core_hits += 1
		if _boss_core_hits >= maxi(1, roundi(boss.max_hp * Tuning.BOSS_ORB_EVERY_HP)):
			_boss_core_hits = 0
			boss_orbs_dropped += 1
			pickups.spawn(b.pos, PickupLayer.Kind.SHIELD)
	else:
		fx.spark(b.pos, Palette.METAL_LINE)
		Sfx.play("ricochet", -8.0, 0.8, 0.1, b.pos)
	return true


func _bullet_hits_asteroid(b: BulletLayer.Bullet, a: AsteroidField.Asteroid) -> void:
	if a.kind == AsteroidField.Kind.METAL:
		# Metálicos são indestrutíveis: o tiro ricocheteia. Com o módulo RICOCHETE ele
		# continua voando (espelhado na superfície) e pode acertar outra coisa.
		if b.bounces_left > 0:
			b.bounces_left -= 1
			var normal := (b.pos - a.pos).normalized()
			b.vel = b.vel.bounce(normal)
			b.pos = a.pos + normal * (a.radius + 6.0)
			b.prev = b.pos
		else:
			b.alive = false
		fx.spark(b.pos, Palette.METAL_LINE)
		asteroids.impact(a, b.vel.normalized())
		Sfx.play("ricochet", -3.0, 1.0, 0.1, b.pos)
		if ship.weapon_level >= Tuning.WEAPON_MAX_LEVEL:
			a.vel.x += signf(a.pos.x - b.pos.x) * Tuning.METAL_PUSH
		return
	if b.pierce:
		b.hit_ids[a.id] = true
	elif b.pierce_left > 0:
		# Módulo PERFURANTE: atravessa esta poeira e segue.
		b.pierce_left -= 1
		b.hit_ids[a.id] = true
	else:
		b.alive = false
	if a.shell > 0:
		# Poeira blindada: a casca absorve os primeiros tiros (som de metal) e depois quebra.
		asteroids.impact(a, b.vel.normalized())
		if asteroids.hit_shell(a):
			fx.burst(a.pos, Palette.METAL_LINE, 18, 360.0, 0.45, 5.0)
			Sfx.play("ricochet", -4.0, 0.7, 0.05, b.pos)
		else:
			fx.spark(b.pos, Palette.METAL_LINE)
			Sfx.play("ricochet", -8.0, 1.1, 0.1, b.pos)
		return
	if asteroids.damage(a, Tuning.BULLET_DAMAGE):
		_on_dust_destroyed(a)
	else:
		asteroids.impact(a, b.vel.normalized())
		fx.spark(b.pos, Palette.DUST_LINE)
		Sfx.play("hit", -17.0, 1.0, 0.1, b.pos)


func _check_ship_hits() -> void:
	if not ship.alive:
		return
	for a in asteroids.asteroids:
		if not a.alive:
			continue
		var reach := a.radius * 0.85 + Tuning.SHIP_HITBOX_RADIUS
		if ship.position.distance_squared_to(a.pos) > reach * reach:
			continue
		var is_metal := a.kind == AsteroidField.Kind.METAL
		if _damage_ship(Tuning.SHIELD_DMG_METAL if is_metal else Tuning.SHIELD_DMG_DUST):
			if not is_metal:
				a.alive = false
				fx.explosion(a.pos, a.radius, Palette.DUST_FILL)
			if not ship.alive:
				return

	for e in enemies.enemies:
		if e.alive and ship.position.distance_to(e.pos) < e.radius * 0.85 + Tuning.SHIP_HITBOX_RADIUS:
			var body_dmg := Tuning.SHIELD_DMG_SWARM if e.kind == EnemyLayer.Kind.SWARM else Tuning.SHIELD_DMG_ENEMY_BODY
			if _damage_ship(body_dmg):
				e.alive = false
				fx.explosion(e.pos, e.radius, Palette.ENEMY_HDR)
				if not ship.alive:
					return

	if boss != null:
		if boss.touches(ship.position, Tuning.SHIP_HITBOX_RADIUS):
			if _damage_ship(Tuning.SHIELD_DMG_METAL) and not ship.alive:
				return
		# Explosões de área (cargas do Minerador): o círculo de aviso é a área do dano.
		for blast in boss.take_blasts():
			if ship.position.distance_to(Vector2(blast.x, blast.y)) < blast.z + Tuning.SHIP_HITBOX_RADIUS:
				if _damage_ship(Tuning.SHIELD_DMG_ENEMY_BODY) and not ship.alive:
					return

	# Minas iônicas: o anel vermelho que aparece ao armar é a área exata da explosão.
	for blast in enemies.take_blasts():
		var at := Vector2(blast.x, blast.y)
		fx.explosion(at, 90.0, Palette.ION_HDR)
		Sfx.play("explosion", -3.0, 1.3, 0.05, at)
		_shake = maxf(_shake, 8.0)
		if ship.position.distance_to(at) < blast.z + Tuning.SHIP_HITBOX_RADIUS:
			if _damage_ship(Tuning.SHIELD_DMG_ENEMY_BODY) and not ship.alive:
				return

	# Portões de laser: só machucam ligados (feixe forte); apagados dá para cruzar.
	if hazards.gate_hits(ship.position, Tuning.SHIP_HITBOX_RADIUS):
		if _damage_ship(Tuning.SHIELD_DMG_BEAM) and not ship.alive:
			return

	# Feixes do chefe (grade de laser, paredes que fecham a arena).
	if boss != null and boss.beam_hits(ship.position, Tuning.SHIP_HITBOX_RADIUS):
		if _damage_ship(Tuning.SHIELD_DMG_BEAM) and not ship.alive:
			return

	# Cometas: só na faixa que foi avisada.
	if hazards.comet_hits(ship.position, Tuning.SHIP_HITBOX_RADIUS):
		if _damage_ship(Tuning.SHIELD_DMG_COMET) and not ship.alive:
			return

	# Raios da tempestade: atinge quem estava na coluna avisada.
	for x in hazards.take_strikes():
		_shake = maxf(_shake, 10.0)
		Sfx.play("death", -8.0, 1.6, 0.05, Vector2(x, ship.position.y))
		if absf(ship.position.x - x) < Tuning.STORM_WIDTH * 0.5 + Tuning.SHIP_HITBOX_RADIUS * 0.5:
			if _damage_ship(Tuning.SHIELD_DMG_STORM) and not ship.alive:
				return

	# Durante a invencibilidade os tiros inimigos atravessam a nave.
	if ship.invuln <= 0.0 and enemy_shots.hit_ship(ship.position, Tuning.SHIP_HITBOX_RADIUS):
		_damage_ship(Tuning.SHIELD_DMG_ENEMY_SHOT)


## Aplica dano na nave. Retorna false se o golpe foi ignorado (invencibilidade).
func _damage_ship(amount: float) -> bool:
	if _mod == "fragile":
		amount *= 2.0  # modificador ESCUDO FRÁGIL
	amount *= modules.damage_scale()  # módulo VIDRO
	var result := ship.take_hit(amount)
	if result == Ship.HitResult.IGNORED:
		return false
	if multiplier > 1.0:
		hud.on_multiplier_lost()
	multiplier = 1.0  # levou dano: o multiplicador volta a x1
	_no_hit_t = 0.0
	if result == Ship.HitResult.DEAD:
		_on_ship_died()
		return true
	_shake = maxf(_shake, 18.0)
	fx.burst(ship.position, Palette.NEON_HDR, 16, 380.0, 0.35, 4.0)
	Sfx.play("shield_hit", -2.0, 1.0, 0.06, ship.position)
	Sfx.duck(-4.0)
	Game.vibrate(60)
	return true


func _on_dust_destroyed(a: AsteroidField.Asteroid) -> void:
	dust_destroyed += 1
	bonus_score += Tuning.SCORE_PER_DUST_HP * a.max_hp
	fx.explosion(a.pos, a.radius, Palette.DUST_FILL)
	_break_kick(Tuning.KICK_BASE + a.radius * Tuning.KICK_PER_RADIUS)
	Game.vibrate(Tuning.KICK_VIBRATE_MS)
	# Asteroides maiores soam mais graves.
	Sfx.play("explosion", -5.0, lerpf(1.35, 0.8, clampf((a.radius - 40.0) / 45.0, 0.0, 1.0)), 0.06, a.pos)
	if a.radius > 70.0:
		Sfx.duck(-3.0)
	# Gelo (Setor 5) racha em lascas que saem em diagonal: estilhaços azulados + som de cristal.
	if a.ice:
		fx.burst(a.pos, Color(1.6, 2.0, 2.4), 14, 420.0, 0.4, 5.0)
		Sfx.play("pickup_crystal", -10.0, 0.6, 0.1, a.pos)
		ice_shards += asteroids.split_ice(a)

	var shield_chance := Tuning.DROP_SHIELD_CHANCE
	if boss != null:
		shield_chance += Tuning.BOSS_SHIELD_DROP_BONUS  # mais orbes durante a luta
	if ship.last_chance or ship.shield_ratio() < Tuning.SHIELD_LOW_RATIO:
		shield_chance += Tuning.DROP_SHIELD_CHANCE_LOW_BONUS
	var roll := randf()
	if roll < shield_chance:
		pickups.spawn(a.pos, PickupLayer.Kind.SHIELD)
	elif roll < shield_chance + Tuning.DROP_CRYSTAL_CHANCE:
		pickups.spawn(a.pos, PickupLayer.Kind.CRYSTAL)


func _on_enemy_destroyed(e: EnemyLayer.Enemy) -> void:
	enemies_destroyed += 1
	fx.explosion(e.pos, e.radius, Palette.ENEMY_HDR)
	match e.kind:
		EnemyLayer.Kind.SWARM:
			# Enxame: muitos e fracos — pouco ponto e poucos cristais cada, som curtinho.
			bonus_score += Tuning.SCORE_PER_SWARM
			Sfx.play("hit", -10.0, 1.6, 0.1, e.pos)
			if randf() < Tuning.SWARM_CRYSTAL_CHANCE:
				pickups.spawn(e.pos, PickupLayer.Kind.CRYSTAL)
			return
		EnemyLayer.Kind.MOTHERSHIP:
			bonus_score += Tuning.MOTHERSHIP_SCORE
			_shake = maxf(_shake, 14.0)
			fx.explosion(e.pos, e.radius * 1.8, Palette.BLAST_HDR)
			Sfx.play("explosion", 0.0, 0.7, 0.0, e.pos)
			Game.vibrate(120)
			# Antes do 1º chefe os módulos ainda não existem: vira escudo + cristal.
			if _modules_unlocked():
				pickups.spawn(e.pos, PickupLayer.Kind.CARGO)
			else:
				pickups.spawn(e.pos, PickupLayer.Kind.SHIELD)
				pickups.spawn(e.pos + Vector2(40, 0), PickupLayer.Kind.CRYSTAL)
			return
		EnemyLayer.Kind.EGG:
			# Ovo destruído a tempo: na luta contra a Rainha sempre vira orbe de escudo.
			eggs_destroyed += 1
			bonus_score += Tuning.SCORE_PER_ENEMY
			Sfx.play("explosion", -6.0, 1.4, 0.06, e.pos)
			if boss != null:
				pickups.spawn(e.pos, PickupLayer.Kind.SHIELD)
			elif randf() < 0.5:
				pickups.spawn(e.pos, PickupLayer.Kind.CRYSTAL)
			return
	bonus_score += Tuning.SCORE_PER_ENEMY
	_shake = maxf(_shake, 6.0)
	Sfx.play("explosion", -4.0, 1.1, 0.06, e.pos)
	if randf() < Tuning.ENEMY_CRYSTAL_CHANCE:
		pickups.spawn(e.pos, PickupLayer.Kind.CRYSTAL)


func _on_pickup(kind: int) -> void:
	if kind == PickupLayer.Kind.CARGO:
		_open_module_pick()
		return
	if kind == PickupLayer.Kind.SHIELD:
		if ship.add_shield(Tuning.SHIELD_ORB_VALUE * modules.heal_scale()):  # módulo MÉDICO
			bonus_score += Tuning.SCORE_LAST_CHANCE_SAVE
		fx.burst(ship.position, Palette.NEON_HDR, 10, 220.0, 0.3, 4.0)
		Sfx.play("pickup_shield", -6.0)
	else:
		ship.add_crystal()
		fx.burst(ship.position, Palette.MAGENTA_HDR, 10, 220.0, 0.3, 4.0)
		Sfx.play("pickup_crystal", -6.0)


# ---------------------------------------------------------------- módulos

## Contêiner de carga coletado: pausa e oferece 3 módulos (cartas).
## Os módulos começam depois do chefe do Setor 1 (PLANO_CARTAS.md §9).
func _modules_unlocked() -> bool:
	return not (mode == Mode.CAMPAIGN and sector_index == 0)


func _open_module_pick() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = randi()
	_offer = modules.offer(rng)
	Sfx.play("level_up", -4.0, 0.8, 0.0)
	if auto_pick_modules:
		_on_module_chosen(0)
		return
	_touch_index = -1
	state = State.CHOOSE
	var cards := []
	for id in _offer:
		cards.append(modules.card_text(id))
	hud.show_module_pick(cards, _hand_text(), not Game.modules_seen)


func _hand_text() -> String:
	if modules.hand.is_empty():
		return "Na nave: nenhum módulo (até %d)" % Modules.MAX_HAND
	var parts: Array[String] = []
	for id: String in modules.hand:
		parts.append("%s %s" % [Modules.CATALOG[id][0], ["", "I", "II", "III"][modules.hand[id]]])
	return "Na nave: " + " · ".join(parts)


func _on_module_chosen(index: int) -> void:
	var id: String = _offer[clampi(index, 0, _offer.size() - 1)]
	if id == Modules.REPAIR:
		ship.shield = Tuning.SHIELD_MAX
		ship.last_chance = false
	else:
		modules.take(id)
	Game.modules_seen = true
	Game.save_data()
	_apply_modules()
	hud.hide_module_pick()
	if state == State.CHOOSE:
		_set_state(State.READY)  # toque para voltar a pilotar


## Valores dos módulos que outras camadas usam direto.
func _apply_modules() -> void:
	pickups.magnet_scale = modules.magnet_scale()
	bullets.bounces = modules.ricochets()
	bullets.pierces = modules.pierces()


func _on_weapon_level_changed(level: int, went_up: bool) -> void:
	hud.on_weapon_level(level, went_up)
	if went_up:
		fx.burst(ship.position, Palette.MAGENTA_HDR, 28, 520.0, 0.5, 5.0)
	Sfx.play("level_up" if went_up else "level_down", -4.0, 1.0, 0.0)


func _on_shield_depleted() -> void:
	Game.vibrate(120)
	_shake = maxf(_shake, 10.0)
	Sfx.play("alarm", -4.0, 1.0, 0.0)
	# Módulo ESCUDO EXPLOSIVO: o escudo quebra explodindo e limpa o que está em volta.
	var radius := modules.blast_radius()
	if radius > 0.0:
		asteroids.clear_around(ship.position, radius)
		enemies.clear_around(ship.position, radius)
		fx.explosion(ship.position, radius * 0.6, Palette.NEON_HDR)
		_shake = maxf(_shake, 22.0)
		Sfx.play("explosion", 0.0, 0.7, 0.0, ship.position)


func _on_ship_died() -> void:
	fx.explosion(ship.position, 120.0, Palette.NEON_HDR)
	fx.explosion(ship.position, 80.0, Palette.FLAME_HDR)
	_shake = 40.0
	Game.vibrate(250)
	Sfx.play("death", 0.0, 1.0, 0.0)
	Sfx.duck(-12.0)
	_set_state(State.DYING)


# ---------------------------------------------------------------- chefe

## Tela "ALERTA" + sirene + trilha de chefe; o chefe entra quando o alerta acaba.
func _begin_boss_alert(boss_id: String) -> void:
	if boss != null or _alert_timer >= 0.0:
		return
	_pending_boss_id = boss_id
	_alert_timer = Tuning.BOSS_ALERT_TIME
	_alarm_beeps = 0
	hud.clear_hint()
	Sfx.play_music("boss")
	Sfx.duck(-6.0)
	Game.vibrate(80)


func _update_boss_flow(dt: float) -> void:
	if _alert_timer >= 0.0:
		var t := Tuning.BOSS_ALERT_TIME - _alert_timer
		if _alarm_beeps < Tuning.BOSS_ALARM_BEEPS and t >= _alarm_beeps * 0.85:
			Sfx.play("alarm", -2.0, 0.85, 0.0)
			_alarm_beeps += 1
		_alert_timer -= dt
		if _alert_timer < 0.0:
			_spawn_boss(_pending_boss_id)
	if boss != null:
		boss.update(dt, ship.position)
		if ship.last_chance:
			_boss_last_chance = true


func _spawn_boss(boss_id: String) -> void:
	match boss_id:
		"rock_mother":
			boss = RockMother.new()
		"cruiser":
			var cruiser := Cruiser.new()
			cruiser.enemies = enemies  # lança mísseis pela camada de inimigos
			boss = cruiser
		"medusa":
			boss = Medusa.new()
		"rift_core":
			boss = RiftCore.new()
		"sentinel":
			boss = Sentinel.new()
		"hive_queen":
			var queen := HiveQueen.new()
			queen.enemies = enemies  # os ovos nascem na camada de inimigos
			boss = queen
		"ice_colossus":
			boss = IceColossus.new()
		"miner":
			boss = Miner.new()
		_:
			push_error("chefe desconhecido: " + boss_id)
			return
	if director.generator != null:
		# Infinito: luta mais curta na 1ª aparição; cada repetição volta com mais vida.
		boss.max_hp = maxi(1, roundi(boss.max_hp * director.generator.boss_hp_scale(boss_id)))
	world.add_child(boss)
	world.move_child(boss, asteroids.get_index() + 1)  # atrás de tiros, pickups da frente e nave
	boss.setup(view_size, enemy_shots, telegraph, asteroids, fx)
	boss.impact = func(amount: float) -> void: _shake = maxf(_shake, amount)
	boss.defeated.connect(_on_boss_defeated)
	_boss_fought = true
	_boss_last_chance = ship.last_chance
	_boss_core_hits = 0
	hud.show_boss_bar(boss.display_name)


func _on_boss_defeated() -> void:
	var at: Vector2 = boss.aim_x() * Vector2.RIGHT + Vector2(0.0, view_size.y * 0.25)
	bonus_score += Tuning.BOSS_SCORE
	for i in Tuning.BOSS_REWARD_ORBS + Tuning.BOSS_REWARD_CRYSTALS:
		var kind := PickupLayer.Kind.SHIELD if i < Tuning.BOSS_REWARD_ORBS else PickupLayer.Kind.CRYSTAL
		pickups.spawn(Vector2(randf_range(view_size.x * 0.15, view_size.x * 0.85),
				at.y + randf_range(-80.0, 120.0)), kind)
	hud.show_hint("%s DERROTADA!" % boss.display_name, 3.0)
	var final_boss := mode == Mode.CAMPAIGN and not _has_next_sector()
	# Contêiner de carga: escolha de um módulo (PLANO_CARTAS.md). O primeiro vem da Rocha-Mãe.
	# (Não no chefe final: a campanha acabou.)
	if not final_boss:
		pickups.spawn(Vector2(at.x, at.y), PickupLayer.Kind.CARGO)
	_clear_boss()
	Game.vibrate(200)
	if final_boss:
		# Chefe final: a Fenda se fecha e o motor de dobra volta — cena de fuga + tema de vitória.
		_escape_t = 0.0
		Sfx.play_music("victory")
		hud.show_hint("A FENDA SE FECHOU!\nMOTOR DE DOBRA RESTAURADO", Tuning.ESCAPE_TIME)
	else:
		Sfx.play_music(SECTORS[_biome].music)  # volta a trilha do setor/bioma
	if mode == Mode.CAMPAIGN:
		director.finished = true  # o setor acaba quando a tela esvaziar
	else:
		bosses_defeated += 1      # o Infinito segue: a linha do tempo volta a andar


## Cena de fuga (depois do chefe final): a nave sobe, as estrelas viram riscos e, no fim,
## um clarão. Os orbes e cristais da vitória são recolhidos no caminho.
func _update_escape(dt: float) -> void:
	if _escape_t < 0.0:
		return
	_escape_t += dt
	var k := clampf(_escape_t / Tuning.ESCAPE_TIME, 0.0, 1.0)
	scroll_speed = lerpf(scroll_speed, Tuning.ESCAPE_SCROLL, smoothstep(0.0, 1.0, k))
	ship.invuln = 1.0
	ship.move_by(Vector2((view_size.x * 0.5 - ship.target.x) * 2.0 * dt, -260.0 * dt))
	for p in pickups.pickups:
		p.pos = p.pos.move_toward(ship.position, 1600.0 * dt)
	_shake = maxf(_shake, 4.0 * k)
	if _escape_t >= Tuning.ESCAPE_TIME:
		_escape_t = -1.0
		fx.explosion(ship.position, 400.0, Palette.WHITE_HDR)
		asteroids.reset()
		enemies.clear()
		enemy_shots.clear()
		hazards.clear()
		for i in pickups.pickups.size():
			_on_pickup(pickups.pickups[i].kind)
		pickups.clear()


func escaping() -> bool:
	return _escape_t >= 0.0


static func _clock(seconds: float) -> String:
	return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]


func _clear_boss() -> void:
	if boss != null:
		boss.queue_free()
		boss = null
	_alert_timer = -1.0
	_pending_boss_id = ""
	hud.hide_boss_bar()


## As 3 estrelas do setor: [completou, chefe sem "última chance", ≥ 70% da poeira].
func star_checks() -> Array[bool]:
	var no_last_chance := (not _boss_last_chance) if _boss_fought else not ship.last_chance
	var dust_ok := asteroids.dust_spawned > 0 \
			and float(dust_destroyed) / float(asteroids.dust_spawned) >= Tuning.STAR_DUST_RATIO
	return [true, no_last_chance, dust_ok]


# ---------------------------------------------------------------- tela

func _on_resized() -> void:
	view_size = get_viewport_rect().size
	nebula.resize(view_size)
	starfield.resize(view_size)
	asteroids.resize(view_size)
	enemies.resize(view_size)
	telegraph.resize(view_size)
	hazards.resize(view_size)
	blackout.resize(view_size)
	bullets.resize(view_size)
	enemy_shots.resize(view_size)
	pickups.resize(view_size)
	ship.resize(view_size)

	var safe_top := 0.0
	if OS.has_feature("mobile"):
		var window_h := float(DisplayServer.window_get_size().y)
		if window_h > 0.0:
			safe_top = DisplayServer.get_display_safe_area().position.y * view_size.y / window_h
	hud.set_safe_top(safe_top)


## Glow neon: só as cores HDR (> 1.0) da Palette acendem. O HUD (CanvasLayer acima) fica nítido.
func _setup_glow() -> void:
	var env := Environment.new()
	_env = env
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_strength = 1.0
	# Só os níveis menores: brilho curto e "neon", sem halo enorme.
	for level in 7:
		env.set_glow_level(level, [1.0, 0.55, 0.12, 0.0, 0.0, 0.0, 0.0][level])
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


## Ronco do propulsor: sobe com a velocidade em que a nave está sendo arrastada.
func _update_engine_sound(delta: float) -> void:
	var on := ship.alive and (state == State.PLAYING or state == State.SLOWMO)
	var speed := 0.0
	if delta > 0.0:
		speed = ship.position.distance_to(_last_ship_pos) / delta
	_last_ship_pos = ship.position
	_engine_level = lerpf(_engine_level, clampf(speed / 1400.0, 0.0, 1.0), 1.0 - exp(-8.0 * delta))
	Sfx.set_engine(on, _engine_level)


## Dois tipos de tremor que se somam:
## - `_shake`: caótico, em todas as direções (ser atingido, morte).
## - `_kick`: tranco direcional com mola, curto e "seco" (quebrar asteroide).
func _update_shake(delta: float) -> void:
	_shake *= exp(-8.0 * delta)
	if _shake < 0.3:
		_shake = 0.0
	# Mola em passos curtos: com um frame longo (engasgo, ou o jogo acelerado) a conta
	# num passo só ficava instável e jogava o mundo para fora da tela.
	var steps := maxi(1, ceili(delta / Tuning.KICK_MAX_STEP))
	var h := delta / steps
	for i in steps:
		var accel := -Tuning.KICK_STIFFNESS * _kick - Tuning.KICK_DAMPING * _kick_vel
		_kick_vel += accel * h
		_kick = (_kick + _kick_vel * h).limit_length(Tuning.KICK_MAX)  # várias quebras seguidas não "explodem"
	# Chefe final (fase 3): a tela inteira balança devagar, girando em volta do centro.
	var tilt: float = boss.screen_tilt() if boss != null and boss.has_method("screen_tilt") else 0.0
	world.rotation = tilt
	var pivot := view_size * 0.5
	world.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake + _kick \
			+ pivot - pivot.rotated(tilt)


## Tranco ao quebrar: empurra a tela para baixo e ela volta com uma pequena mola.
func _break_kick(strength: float) -> void:
	_kick_vel += Vector2(randf_range(-0.25, 0.25), 1.0) * strength
