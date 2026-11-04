extends Node2D
## Orquestra a partida: menu, modos (campanha/infinito), estados, input de arraste,
## dificuldade, eventos do setor, colisões e pontuação.

enum State { MENU, READY, PLAYING, SLOWMO, PAUSED, DYING, GAME_OVER, SECTOR_CLEAR }
enum Mode { ENDLESS, CAMPAIGN }

const DYING_TIME := 1.2
const SECTORS: Array[SectorData] = [preload("res://data/sectors/sector_1.tres")]

var state := State.MENU
var mode := Mode.ENDLESS
var view_size := Vector2.ZERO

var world: Node2D
var nebula: Nebula
var starfield: Starfield
var asteroids: AsteroidField
var enemies: EnemyLayer
var telegraph: TelegraphLayer
var bullets: BulletLayer
var enemy_shots: EnemyBulletLayer
var pickups: PickupLayer
var fx: FxLayer
var ship: Ship
var hud: Hud

var director: SectorDirector
var sector_index := 0

var elapsed := 0.0
var distance := 0.0
var bonus_score := 0
var score := 0
var time_scale := 0.0
var scroll_speed := Tuning.SCROLL_SPEED_START
var enemies_destroyed := 0

var _state_timer := 0.0
var _touch_index := -1
var _shake := 0.0
var _revive_used := false
var _pending_wall := -1.0  # segundos até o paredão avisado aparecer (-1 = nenhum)
var _last_ship_pos := Vector2.ZERO
var _engine_level := 0.0


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
	ship.fired.connect(func() -> void: Sfx.play("laser", -19.0, 1.0, 0.08, ship.position))
	hud.resume_pressed.connect(resume_checkpoint)
	hud.campaign_pressed.connect(start_new_game)
	hud.new_game_pressed.connect(start_new_game)
	hud.restart_pressed.connect(_on_restart)
	hud.continue_pressed.connect(_on_continue)
	hud.menu_pressed.connect(go_to_menu)
	hud.quit_pressed.connect(_on_quit)
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


func _process(delta: float) -> void:
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
	starfield.update(delta, scroll_speed * maxf(time_scale, 0.15))
	nebula.update(delta, scroll_speed * maxf(time_scale, 0.15))
	_update_shake(delta)
	var quiet := state != State.PLAYING and state != State.SLOWMO and state != State.DYING
	Sfx.set_music_intensity(time_scale, quiet)
	_update_engine_sound(delta)
	hud.set_values(score, maxi(score, _best_for_mode()), ship.shield_ratio(), ship.last_chance,
			ship.weapon_level, ship.weapon_progress())


# ---------------------------------------------------------------- fluxo

func go_to_menu() -> void:
	_touch_index = -1
	mode = Mode.ENDLESS
	director = null
	_new_run()
	ship.visible = false
	hud.clear_hint()
	_set_state(State.MENU)


## Começa a campanha do Setor 1, descartando o ponto salvo.
func start_new_game() -> void:
	_touch_index = -1
	Game.clear_checkpoint()
	start_mode(Mode.CAMPAIGN)


func start_mode(new_mode: Mode, index := 0) -> void:
	mode = new_mode
	sector_index = index
	_new_run()
	_set_state(State.READY)


func _new_run() -> void:
	elapsed = 0.0
	distance = 0.0
	bonus_score = 0
	score = 0
	enemies_destroyed = 0
	scroll_speed = Tuning.SCROLL_SPEED_START
	_revive_used = false
	_pending_wall = -1.0
	asteroids.reset()
	enemies.clear()
	enemy_shots.clear()
	telegraph.clear()
	bullets.clear()
	pickups.clear()
	fx.clear()
	hud.clear_hint()
	ship.reset(Vector2(view_size.x * 0.5, view_size.y * 0.8))
	if mode == Mode.CAMPAIGN:
		director = SectorDirector.new(SECTORS[sector_index])
		nebula.set_colors(director.sector.nebula_a, director.sector.nebula_b)
	else:
		director = null


## Volta ao ponto salvo: mesmo setor e momento, mesma pontuação, escudo e arma.
## O campo de asteroides recomeça limpo, com invencibilidade curta para retomar.
func resume_checkpoint() -> void:
	var cp := Game.checkpoint
	if cp.is_empty():
		return
	start_mode(Mode.CAMPAIGN, clampi(int(cp.get("sector", 0)), 0, SECTORS.size() - 1))
	director.seek(float(cp.get("time", 0.0)))
	elapsed = float(cp.get("elapsed", 0.0))
	distance = float(cp.get("distance", 0.0))
	bonus_score = int(cp.get("bonus", 0))
	score = int(distance * Tuning.SCORE_PER_PIXEL) + bonus_score
	_revive_used = bool(cp.get("revive_used", false))
	ship.shield = float(cp.get("shield", Tuning.SHIELD_MAX))
	ship.last_chance = bool(cp.get("last_chance", false))
	ship.weapon_level = clampi(int(cp.get("weapon", 1)), 1, Tuning.WEAPON_MAX_LEVEL)
	ship.crystals = int(cp.get("crystals", 0))
	ship.invuln = Tuning.REVIVE_INVULN_TIME


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
	})


func _on_quit() -> void:
	_save_checkpoint()
	Game.save_data()
	get_tree().quit()


func _ready_title() -> String:
	return director.sector.title if mode == Mode.CAMPAIGN else "MODO INFINITO"


func _best_for_mode() -> int:
	if mode == Mode.CAMPAIGN and director != null:
		return Game.get_sector_best(director.sector.id)
	return Game.high_score


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
			hud.show_menu(not Game.checkpoint.is_empty())
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
			Game.clear_checkpoint()  # a partida acabou: não há de onde continuar
			var is_record: bool
			if mode == Mode.CAMPAIGN:
				is_record = Game.submit_sector(director.sector.id, score, false)
			else:
				is_record = Game.submit_score(score)
			hud.show_game_over(score, _best_for_mode(), is_record, not _revive_used)
		State.SECTOR_CLEAR:
			_touch_index = -1
			Game.clear_checkpoint()
			var is_record := Game.submit_sector(director.sector.id, score, true)
			hud.clear_hint()
			hud.show_sector_clear(director.sector.title, score, _best_for_mode(), is_record)
			Sfx.play("level_up", -2.0, 1.0, 0.0)


# ---------------------------------------------------------------- simulação

func _step(dt: float) -> void:
	if ship.alive:
		elapsed += dt

	var difficulty: float
	if mode == Mode.CAMPAIGN:
		if ship.alive:
			for e in director.update(dt):
				_on_wave_event(e)
		difficulty = director.difficulty()
		asteroids.density = director.density
		asteroids.metals_enabled = director.metals
		asteroids.dust_rain = director.rain_left > 0.0
		asteroids.spawn_enabled = director.calm_left <= 0.0 and _pending_wall < 0.0 and not director.finished
	else:
		difficulty = Tuning.difficulty(elapsed)

	scroll_speed = lerpf(Tuning.SCROLL_SPEED_START, Tuning.SCROLL_SPEED_MAX, difficulty)
	if ship.alive:
		distance += scroll_speed * dt
		fx.trail(ship.position + Vector2(0, 40), scroll_speed)

	if _pending_wall >= 0.0:
		_pending_wall -= dt
		if _pending_wall < 0.0:
			asteroids.spawn_wall()

	asteroids.update(dt, scroll_speed, difficulty)
	enemies.update(dt, ship.position)
	telegraph.update(dt)
	bullets.update(dt)
	enemy_shots.update(dt)
	ship.update(dt)
	for kind in pickups.update(dt, scroll_speed, ship.position, ship.alive):
		_on_pickup(kind)
	fx.update(dt)

	_check_bullet_hits()
	_check_ship_hits()
	score = int(distance * Tuning.SCORE_PER_PIXEL) + bonus_score

	# Fim do setor: depois do evento END, quando a tela esvaziar.
	if mode == Mode.CAMPAIGN and director.finished and ship.alive \
			and asteroids.asteroids.is_empty() and enemies.enemies.is_empty() \
			and (state == State.PLAYING or state == State.SLOWMO):
		_set_state(State.SECTOR_CLEAR)


func _on_wave_event(e: WaveEvent) -> void:
	match e.kind:
		WaveEvent.Kind.MESSAGE:
			hud.show_hint(e.text, e.duration if e.duration > 0.0 else 3.5)
		WaveEvent.Kind.METAL_WALL:
			_pending_wall = Tuning.WALL_TELEGRAPH_TIME
			for span in asteroids.wall_spans():
				telegraph.column(span.x, span.y, Tuning.WALL_TELEGRAPH_TIME)
			hud.show_hint("PAREDÃO! Procure a brecha", 2.5)
			Sfx.play("alarm", -8.0, 1.2, 0.0)


func _check_bullet_hits() -> void:
	for b in bullets.pool:
		if not b.alive:
			continue
		var a := asteroids.hit_test(b.pos, b.hit_ids)
		if a != null:
			_bullet_hits_asteroid(b, a)
			continue
		var e := enemies.hit_test(b.pos, b.hit_ids)
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


func _bullet_hits_asteroid(b: BulletLayer.Bullet, a: AsteroidField.Asteroid) -> void:
	if a.kind == AsteroidField.Kind.METAL:
		# Metálicos são indestrutíveis: o tiro ricocheteia.
		b.alive = false
		fx.spark(b.pos, Palette.METAL_LINE)
		asteroids.impact(a, b.vel.normalized())
		Sfx.play("ricochet", -13.0, 1.0, 0.1, b.pos)
		if ship.weapon_level >= Tuning.WEAPON_MAX_LEVEL:
			a.vel.x += signf(a.pos.x - b.pos.x) * Tuning.METAL_PUSH
		return
	if b.pierce:
		b.hit_ids[a.id] = true
	else:
		b.alive = false
	if asteroids.damage(a, Tuning.BULLET_DAMAGE):
		_on_dust_destroyed(a)
	else:
		asteroids.impact(a, b.vel.normalized())
		fx.spark(b.pos, Palette.DUST_LINE)
		Sfx.play("hit", -12.0, 1.0, 0.1, b.pos)


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
			if _damage_ship(Tuning.SHIELD_DMG_ENEMY_BODY):
				e.alive = false
				fx.explosion(e.pos, e.radius, Palette.ENEMY_HDR)
				if not ship.alive:
					return

	# Durante a invencibilidade os tiros inimigos atravessam a nave.
	if ship.invuln <= 0.0 and enemy_shots.hit_ship(ship.position, Tuning.SHIP_HITBOX_RADIUS):
		_damage_ship(Tuning.SHIELD_DMG_ENEMY_SHOT)


## Aplica dano na nave. Retorna false se o golpe foi ignorado (invencibilidade).
func _damage_ship(amount: float) -> bool:
	var result := ship.take_hit(amount)
	if result == Ship.HitResult.IGNORED:
		return false
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
	bonus_score += Tuning.SCORE_PER_DUST_HP * a.max_hp
	fx.explosion(a.pos, a.radius, Palette.DUST_FILL)
	_shake = maxf(_shake, 3.0 + a.radius * 0.04)
	# Asteroides maiores soam mais graves.
	Sfx.play("explosion", -5.0, lerpf(1.35, 0.8, clampf((a.radius - 40.0) / 45.0, 0.0, 1.0)), 0.06, a.pos)
	if a.radius > 70.0:
		Sfx.duck(-3.0)

	var shield_chance := Tuning.DROP_SHIELD_CHANCE
	if ship.last_chance or ship.shield_ratio() < Tuning.SHIELD_LOW_RATIO:
		shield_chance += Tuning.DROP_SHIELD_CHANCE_LOW_BONUS
	var roll := randf()
	if roll < shield_chance:
		pickups.spawn(a.pos, PickupLayer.Kind.SHIELD)
	elif roll < shield_chance + Tuning.DROP_CRYSTAL_CHANCE:
		pickups.spawn(a.pos, PickupLayer.Kind.CRYSTAL)


func _on_enemy_destroyed(e: EnemyLayer.Enemy) -> void:
	enemies_destroyed += 1
	bonus_score += Tuning.SCORE_PER_ENEMY
	fx.explosion(e.pos, e.radius, Palette.ENEMY_HDR)
	_shake = maxf(_shake, 6.0)
	Sfx.play("explosion", -4.0, 1.1, 0.06, e.pos)
	if randf() < Tuning.ENEMY_CRYSTAL_CHANCE:
		pickups.spawn(e.pos, PickupLayer.Kind.CRYSTAL)


func _on_pickup(kind: int) -> void:
	if kind == PickupLayer.Kind.SHIELD:
		if ship.add_shield(Tuning.SHIELD_ORB_VALUE):
			bonus_score += Tuning.SCORE_LAST_CHANCE_SAVE
		fx.burst(ship.position, Palette.NEON_HDR, 10, 220.0, 0.3, 4.0)
		Sfx.play("pickup_shield", -6.0)
	else:
		ship.add_crystal()
		fx.burst(ship.position, Palette.MAGENTA_HDR, 10, 220.0, 0.3, 4.0)
		Sfx.play("pickup_crystal", -6.0)


func _on_weapon_level_changed(level: int, went_up: bool) -> void:
	hud.on_weapon_level(level, went_up)
	if went_up:
		fx.burst(ship.position, Palette.MAGENTA_HDR, 28, 520.0, 0.5, 5.0)
	Sfx.play("level_up" if went_up else "level_down", -4.0, 1.0, 0.0)


func _on_shield_depleted() -> void:
	Game.vibrate(120)
	_shake = maxf(_shake, 10.0)
	Sfx.play("alarm", -4.0, 1.0, 0.0)


func _on_ship_died() -> void:
	fx.explosion(ship.position, 120.0, Palette.NEON_HDR)
	fx.explosion(ship.position, 80.0, Palette.FLAME_HDR)
	_shake = 40.0
	Game.vibrate(250)
	Sfx.play("death", 0.0, 1.0, 0.0)
	Sfx.duck(-12.0)
	_set_state(State.DYING)


# ---------------------------------------------------------------- tela

func _on_resized() -> void:
	view_size = get_viewport_rect().size
	nebula.resize(view_size)
	starfield.resize(view_size)
	asteroids.resize(view_size)
	enemies.resize(view_size)
	telegraph.resize(view_size)
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


func _update_shake(delta: float) -> void:
	_shake *= exp(-8.0 * delta)
	if _shake < 0.3:
		_shake = 0.0
	world.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
