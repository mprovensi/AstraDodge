extends Node2D
## Orquestra a partida: estados, input de arraste, dificuldade, colisões e pontuação.

enum State { READY, PLAYING, SLOWMO, PAUSED, DYING, GAME_OVER }

const DYING_TIME := 1.2

var state := State.READY
var view_size := Vector2.ZERO

var world: Node2D
var starfield: Starfield
var asteroids: AsteroidField
var bullets: BulletLayer
var pickups: PickupLayer
var fx: FxLayer
var ship: Ship
var hud: Hud

var elapsed := 0.0
var distance := 0.0
var bonus_score := 0
var score := 0
var time_scale := 0.0
var scroll_speed := Tuning.SCROLL_SPEED_START

var _state_timer := 0.0
var _touch_index := -1
var _shake := 0.0
var _revive_used := false


func _ready() -> void:
	_setup_glow()
	world = Node2D.new()
	add_child(world)
	starfield = Starfield.new()
	world.add_child(starfield)
	pickups = PickupLayer.new()
	world.add_child(pickups)
	asteroids = AsteroidField.new()
	world.add_child(asteroids)
	bullets = BulletLayer.new()
	world.add_child(bullets)
	ship = Ship.new()
	ship.bullets = bullets
	world.add_child(ship)
	fx = FxLayer.new()
	world.add_child(fx)
	hud = Hud.new()
	add_child(hud)

	ship.weapon_level_changed.connect(_on_weapon_level_changed)
	ship.shield_depleted.connect(_on_shield_depleted)
	ship.fired.connect(func() -> void: Sfx.play("laser", -14.0, 1.0, 0.08))
	hud.restart_pressed.connect(_on_restart)
	hud.continue_pressed.connect(_on_continue)
	get_viewport().size_changed.connect(_on_resized)

	_on_resized()
	_new_run()
	_set_state(State.READY)
	hud.show_ready(true)


func _notification(what: int) -> void:
	# App foi para segundo plano: pausa.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if state == State.PLAYING or state == State.SLOWMO:
			_touch_index = -1
			_set_state(State.PAUSED)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if (state == State.PLAYING or state == State.SLOWMO) and hud.is_pause_button(touch.position):
				_touch_index = -1
				Sfx.play("click", -4.0, 1.0, 0.0)
				_set_state(State.PAUSED)
				return
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

	var dt := delta * time_scale
	if dt > 0.0:
		_step(dt)

	# As estrelas nunca param totalmente, para o menu e a pausa não parecerem "travados".
	starfield.update(delta, scroll_speed * maxf(time_scale, 0.15))
	_update_shake(delta)
	Sfx.set_music_intensity(time_scale, state == State.PAUSED or state == State.READY or state == State.GAME_OVER)
	hud.set_values(score, maxi(score, Game.high_score), ship.shield_ratio(), ship.last_chance,
			ship.weapon_level, ship.weapon_progress())


func _step(dt: float) -> void:
	if ship.alive:
		elapsed += dt
	var difficulty := Tuning.difficulty(elapsed)
	scroll_speed = lerpf(Tuning.SCROLL_SPEED_START, Tuning.SCROLL_SPEED_MAX, difficulty)
	if ship.alive:
		distance += scroll_speed * dt
		fx.trail(ship.position + Vector2(0, 40), scroll_speed)

	asteroids.update(dt, scroll_speed, difficulty)
	bullets.update(dt)
	ship.update(dt)
	for kind in pickups.update(dt, scroll_speed, ship.position, ship.alive):
		_on_pickup(kind)
	fx.update(dt)

	_check_bullet_hits()
	_check_ship_hits()
	score = int(distance * Tuning.SCORE_PER_PIXEL) + bonus_score


func _check_bullet_hits() -> void:
	for b in bullets.pool:
		if not b.alive:
			continue
		var a := asteroids.hit_test(b.pos, b.hit_ids)
		if a == null:
			continue
		if a.kind == AsteroidField.Kind.METAL:
			# Metálicos são indestrutíveis: o tiro ricocheteia.
			b.alive = false
			fx.spark(b.pos, Palette.METAL_LINE)
			asteroids.impact(a, b.vel.normalized())
			Sfx.play("ricochet", -12.0, 1.0, 0.12)
			if ship.weapon_level >= Tuning.WEAPON_MAX_LEVEL:
				a.vel.x += signf(a.pos.x - b.pos.x) * Tuning.METAL_PUSH
			continue
		if b.pierce:
			b.hit_ids[a.id] = true
		else:
			b.alive = false
		if asteroids.damage(a, Tuning.BULLET_DAMAGE):
			_on_dust_destroyed(a)
		else:
			asteroids.impact(a, b.vel.normalized())
			fx.spark(b.pos, Palette.DUST_LINE)
			Sfx.play("hit", -12.0, 1.0, 0.1)


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
		var result := ship.take_hit(Tuning.SHIELD_DMG_METAL if is_metal else Tuning.SHIELD_DMG_DUST)
		if result == Ship.HitResult.IGNORED:
			continue
		if not is_metal:
			a.alive = false
			fx.explosion(a.pos, a.radius, Palette.DUST_FILL)
		if result == Ship.HitResult.DEAD:
			_on_ship_died()
			return
		_shake = maxf(_shake, 18.0)
		fx.burst(ship.position, Palette.NEON_HDR, 16, 380.0, 0.35, 4.0)
		Sfx.play("shield_hit", -2.0)
		Game.vibrate(60)


func _on_dust_destroyed(a: AsteroidField.Asteroid) -> void:
	bonus_score += Tuning.SCORE_PER_DUST_HP * a.max_hp
	fx.explosion(a.pos, a.radius, Palette.DUST_FILL)
	_shake = maxf(_shake, 3.0 + a.radius * 0.04)
	# Asteroides maiores soam mais graves.
	Sfx.play("explosion", -5.0, lerpf(1.35, 0.8, clampf((a.radius - 40.0) / 45.0, 0.0, 1.0)))

	var shield_chance := Tuning.DROP_SHIELD_CHANCE
	if ship.last_chance or ship.shield_ratio() < Tuning.SHIELD_LOW_RATIO:
		shield_chance += Tuning.DROP_SHIELD_CHANCE_LOW_BONUS
	var roll := randf()
	if roll < shield_chance:
		pickups.spawn(a.pos, PickupLayer.Kind.SHIELD)
	elif roll < shield_chance + Tuning.DROP_CRYSTAL_CHANCE:
		pickups.spawn(a.pos, PickupLayer.Kind.CRYSTAL)


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
	_set_state(State.DYING)


func _on_restart() -> void:
	_new_run()
	_set_state(State.READY)
	hud.show_ready(false)


## Placeholder do "reviver com anúncio" (Fase 3 liga isto ao Rewarded Ad).
func _on_continue() -> void:
	_revive_used = true
	ship.revive()
	asteroids.clear_around(ship.position, Tuning.REVIVE_CLEAR_RADIUS)
	bullets.clear()
	_set_state(State.READY)
	hud.show_ready(false)


func _new_run() -> void:
	elapsed = 0.0
	distance = 0.0
	bonus_score = 0
	score = 0
	scroll_speed = Tuning.SCROLL_SPEED_START
	_revive_used = false
	asteroids.reset()
	bullets.clear()
	pickups.clear()
	fx.clear()
	ship.reset(Vector2(view_size.x * 0.5, view_size.y * 0.8))


func _set_state(new_state: State) -> void:
	state = new_state
	hud.set_pause_visible(new_state == State.PLAYING or new_state == State.SLOWMO)
	match new_state:
		State.PLAYING:
			hud.hide_center()
			Sfx.start_music()
		State.SLOWMO:
			_state_timer = Tuning.RELEASE_SLOWMO_TIME
		State.PAUSED:
			hud.show_paused()
		State.DYING:
			_touch_index = -1
			_state_timer = DYING_TIME
		State.GAME_OVER:
			var is_record := Game.submit_score(score)
			hud.show_game_over(score, Game.high_score, is_record, not _revive_used)


func _on_resized() -> void:
	view_size = get_viewport_rect().size
	starfield.resize(view_size)
	asteroids.resize(view_size)
	bullets.resize(view_size)
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


func _update_shake(delta: float) -> void:
	_shake *= exp(-8.0 * delta)
	if _shake < 0.3:
		_shake = 0.0
	world.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
