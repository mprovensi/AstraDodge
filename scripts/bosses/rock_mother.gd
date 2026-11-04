class_name RockMother
extends Boss
## ROCHA-MÃE — chefe do Setor 1 (PLANO_V2.md, Setor 1).
##
## Fase 1: asteroide gigante girando devagar, com 4 núcleos na borda. Só o núcleo
##   virado para baixo fica ABERTO (leva dano); os outros e a rocha são armadura.
##   Ataques: leque de pedras (aviso em círculo antes) e poeira solta pelos lados
##   (que dá orbes/cristais para o jogador se manter vivo).
## Fase 2 (50% de vida): racha ao meio. As metades ficam nos lados e AVANÇAM
##   alternadas (aviso em coluna antes); o lado oposto é sempre seguro. Um núcleo
##   aberto por vez, trocando de lado. A metade parada continua soltando pedras.

const NAME := "ROCHA-MÃE"
const MAX_HP := 260

const RADIUS := 210.0
const CORE_RADIUS := 40.0
const CORE_DIST := 0.9                 # núcleos na borda (fração do raio)
const OPEN_ARC := PI / 4.0             # aberto quando aponta para baixo ±45°
const SPIN := 0.5                      # rad/s na fase 1
const ENTER_TIME := 3.0
const REST_Y_RATIO := 0.27             # altura de descanso (fração da tela): abaixo do HUD
const SWAY := 0.12                     # balanço lateral (fração da largura)

const FAN_INTERVAL := [0.0, 2.6, 2.1]  # por fase
const FAN_TELEGRAPH := 0.7
const FAN_COUNT := 5
const FAN_SPREAD_DEG := 60.0
const FAN_SPEED := [0.0, 360.0, 400.0]
const FAN_WARN_RADIUS := 60.0

const DUST_INTERVAL := [0.0, 6.0, 7.5]
const DUST_RADIUS := 50.0
const DUST_HP := 2

const TRANSITION_TIME := 1.6
const HALF_RADIUS := 155.0
const HALF_X := [0.27, 0.73]           # posição das metades (fração da largura)
const HALF_SPREAD_TIME := 0.8
const CORE_SWAP := 2.4                 # fase 2: troca o núcleo aberto a cada N s
const LUNGE_INTERVAL := 4.2
const LUNGE_TELEGRAPH := 1.0
const LUNGE_DROP := 0.35
const LUNGE_HOLD := 0.25
const LUNGE_RETURN := 0.8
const LUNGE_Y_RATIO := 0.62
const LUNGE_MARGIN := 20.0             # folga lateral do aviso em coluna

const DYING_TIME := 2.4

var center := Vector2.ZERO
var rot := 0.0

var _fan_timer := 1.5
var _fan_pending := -1.0
var _dust_timer := 3.0
var _lunge_timer := 2.0
var _next_half := 0
var _open_core := 0          # fase 2: 0..3 (metade = i % 2, núcleo da metade = i / 2)
var _core_timer := 0.0
var _boom_timer := 0.0
var _halves: Array[Dictionary] = []  # {pos, rest_y, lunge (-1 parada)}


func _init() -> void:
	display_name = NAME
	max_hp = MAX_HP


func _enter() -> void:
	center = Vector2(view_size.x * 0.5, -RADIUS)
	_set_state(State.ENTERING)


# ---------------------------------------------------------------- comportamento

func _update_boss(dt: float, _ship_pos: Vector2) -> void:
	match state:
		State.ENTERING:
			var k := smoothstep(0.0, 1.0, _state_t / ENTER_TIME)
			center.y = lerpf(-RADIUS, _rest_y(), k)
			rot += SPIN * dt
			if _state_t >= ENTER_TIME:
				_set_state(State.FIGHT)
		State.FIGHT:
			if phase == 1:
				_phase1(dt)
			else:
				_phase2(dt)
			_update_fan(dt)
		State.TRANSITION:
			# Treme, pisca e solta brasas antes de rachar.
			center.x += sin(_t * 60.0) * 3.0
			if int(_state_t * 20.0) % 4 == 0:
				fx.burst(center + Vector2.from_angle(randf() * TAU) * RADIUS * 0.4, Palette.FLAME_HDR, 4, 260.0, 0.4, 5.0)
			if _state_t >= TRANSITION_TIME:
				_split()
		State.DYING:
			_update_dying(dt)


func _phase1(dt: float) -> void:
	rot += SPIN * dt
	center.x = view_size.x * 0.5 + sin(_t * 0.4) * view_size.x * SWAY
	center.y = _rest_y() + sin(_t * 0.9) * 10.0
	_dust_timer -= dt
	if _dust_timer <= 0.0:
		_dust_timer = DUST_INTERVAL[1]
		for side: float in [-1.0, 1.0]:
			asteroids.spawn_dust(center + Vector2(side * RADIUS * 0.85, RADIUS * 0.2), DUST_RADIUS, DUST_HP,
					Vector2(side * 70.0, 140.0))


func _phase2(dt: float) -> void:
	# Metades se afastam até os lados logo após rachar.
	var spread := clampf(_state_t / HALF_SPREAD_TIME, 0.0, 1.0)
	for i in _halves.size():
		var h := _halves[i]
		var target_x: float = view_size.x * HALF_X[i]
		var start_x := center.x + (-1.0 if i == 0 else 1.0) * RADIUS * 0.5
		h.pos.x = lerpf(start_x, target_x, smoothstep(0.0, 1.0, spread))
		_update_lunge(h, dt)

	_core_timer += dt
	if _core_timer >= CORE_SWAP:
		_core_timer = 0.0
		_open_core = (_open_core + 1) % 4

	_lunge_timer -= dt
	if _lunge_timer <= 0.0 and spread >= 1.0 and not _any_lunging():
		_lunge_timer = LUNGE_INTERVAL
		var h := _halves[_next_half]
		_next_half = 1 - _next_half
		h.lunge = 0.0
		var x0: float = h.pos.x - HALF_RADIUS - LUNGE_MARGIN
		var x1: float = h.pos.x + HALF_RADIUS + LUNGE_MARGIN
		telegraph.column(x0, x1, LUNGE_TELEGRAPH)
		Sfx.play("alarm", -10.0, 0.8, 0.0)

	_dust_timer -= dt
	if _dust_timer <= 0.0:
		_dust_timer = DUST_INTERVAL[2]
		var rest := _resting_half()
		asteroids.spawn_dust(rest.pos + Vector2(0.0, HALF_RADIUS), DUST_RADIUS, DUST_HP, Vector2(0.0, 120.0))


func _update_lunge(h: Dictionary, dt: float) -> void:
	if h.lunge < 0.0:
		h.pos.y = h.rest_y + sin(_t * 1.1 + h.rest_y) * 8.0
		return
	h.lunge += dt
	var t: float = h.lunge - LUNGE_TELEGRAPH
	var low := view_size.y * LUNGE_Y_RATIO
	if t < 0.0:
		h.pos.y = h.rest_y + sin(_t * 50.0) * 4.0  # treme enquanto o aviso pisca
	elif t < LUNGE_DROP:
		h.pos.y = lerpf(h.rest_y, low, ease(t / LUNGE_DROP, 2.5))
	elif t < LUNGE_DROP + LUNGE_HOLD:
		if h.pos.y < low:
			impact.call(16.0)
			Sfx.play("explosion", -2.0, 0.6, 0.0, h.pos)
			fx.burst(h.pos + Vector2(0, HALF_RADIUS * 0.8), Palette.DUST_FILL, 16, 420.0, 0.5, 6.0)
		h.pos.y = low
	elif t < LUNGE_DROP + LUNGE_HOLD + LUNGE_RETURN:
		var k := (t - LUNGE_DROP - LUNGE_HOLD) / LUNGE_RETURN
		h.pos.y = lerpf(low, h.rest_y, smoothstep(0.0, 1.0, k))
	else:
		h.pos.y = h.rest_y
		h.lunge = -1.0


func _update_fan(dt: float) -> void:
	if _fan_pending >= 0.0:
		_fan_pending -= dt
		if _fan_pending < 0.0:
			var origin := _fan_origin()
			shots.fire_fan(origin, PI / 2.0, FAN_COUNT, FAN_SPREAD_DEG, FAN_SPEED[phase], EnemyBulletLayer.Kind.ROCK)
			Sfx.play("hit", -6.0, 0.6, 0.05, origin)
		return
	_fan_timer -= dt
	if _fan_timer <= 0.0:
		_fan_timer = FAN_INTERVAL[phase]
		_fan_pending = FAN_TELEGRAPH
		telegraph.circle(_fan_origin(), FAN_WARN_RADIUS, FAN_TELEGRAPH)


func _on_damaged() -> void:
	if phase == 1 and hp <= max_hp / 2:
		_set_state(State.TRANSITION)
		_fan_pending = -1.0
		impact.call(12.0)
		Sfx.play("shield_hit", 0.0, 0.6, 0.0, center)
		Sfx.duck(-6.0)


func _split() -> void:
	phase = 2
	_halves.clear()
	for i in 2:
		_halves.append({"pos": center + Vector2((-1.0 if i == 0 else 1.0) * RADIUS * 0.5, 0.0),
				"rest_y": _rest_y(), "lunge": -1.0})
	_fan_timer = 1.5
	_dust_timer = 3.0
	_lunge_timer = 1.5
	_core_timer = 0.0
	_open_core = 0
	impact.call(28.0)
	fx.explosion(center, 140.0, Palette.FLAME_HDR)
	fx.explosion(center, 100.0, Palette.DUST_FILL)
	Sfx.play("death", -3.0, 0.8, 0.0, center)
	Sfx.duck(-10.0)
	_set_state(State.FIGHT)
	phase_changed.emit(2)


func _update_dying(dt: float) -> void:
	_boom_timer -= dt
	if _boom_timer <= 0.0:
		_boom_timer = 0.15
		var c: Vector2 = center if phase == 1 else (_halves[randi() % 2].pos as Vector2)
		var r: float = RADIUS if phase == 1 else HALF_RADIUS
		var p := c + Vector2.from_angle(randf() * TAU) * randf() * r * 0.8
		fx.explosion(p, randf_range(60.0, 110.0), Palette.BLAST_HDR if randf() < 0.5 else Palette.DUST_FILL)
		Sfx.play("explosion", -2.0, randf_range(0.6, 0.9), 0.0, p)
		impact.call(10.0)
	if _state_t >= DYING_TIME:
		var c: Vector2 = center if phase == 1 else (_halves[0].pos + _halves[1].pos) * 0.5
		fx.explosion(c, 200.0, Palette.BLAST_HDR)
		Sfx.play("death", 0.0, 0.7, 0.0, c)
		impact.call(35.0)
		_set_state(State.DONE)
		visible = false
		defeated.emit()


# ---------------------------------------------------------------- colisão

func hit_bullet(p: Vector2) -> Hit:
	if state == State.DONE:
		return Hit.NONE
	for core in _cores():
		if p.distance_squared_to(core.pos) < CORE_RADIUS * CORE_RADIUS:
			return Hit.CORE if core.open and is_vulnerable() else Hit.ARMOR
	for body in _bodies():
		if p.distance_squared_to(body.pos) < pow(body.radius, 2.0):
			return Hit.ARMOR
	return Hit.NONE


func touches(p: Vector2, radius: float) -> bool:
	if state == State.DONE:
		return false
	for body in _bodies():
		if p.distance_to(body.pos) < body.radius * 0.9 + radius:
			return true
	return false


func aim_x() -> float:
	for core in _cores():
		if core.open:
			return core.pos.x
	return center.x


func open_core_count() -> int:
	var n := 0
	for core in _cores():
		if core.open:
			n += 1
	return n


## Núcleos com posição e se estão abertos agora.
func _cores() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	if phase == 1:
		for i in 4:
			var ang := rot + i * PI / 2.0
			list.append({"pos": center + Vector2.from_angle(ang) * RADIUS * CORE_DIST,
					"open": absf(angle_difference(ang, PI / 2.0)) < OPEN_ARC})
	else:
		for i in 4:
			var half := _halves[i % 2]
			var side := -0.45 if i / 2 == 0 else 0.45
			var dir := Vector2.from_angle(PI / 2.0 + side)
			list.append({"pos": (half.pos as Vector2) + dir * HALF_RADIUS * 0.88, "open": i == _open_core})
	return list


func _bodies() -> Array[Dictionary]:
	if phase == 1:
		return [{"pos": center, "radius": RADIUS}]
	return [{"pos": _halves[0].pos, "radius": HALF_RADIUS}, {"pos": _halves[1].pos, "radius": HALF_RADIUS}]


func _rest_y() -> float:
	return view_size.y * REST_Y_RATIO


func _any_lunging() -> bool:
	for h in _halves:
		if h.lunge >= 0.0:
			return true
	return false


func _resting_half() -> Dictionary:
	for h in _halves:
		if h.lunge < 0.0:
			return h
	return _halves[0]


func _fan_origin() -> Vector2:
	if phase == 1:
		return center + Vector2(0.0, RADIUS)
	var rest := _resting_half()
	return (rest.pos as Vector2) + Vector2(0.0, HALF_RADIUS)


# ---------------------------------------------------------------- rota segura
# Usados pelo teste automático para garantir que sempre dá para escapar.

## Menor vão entre pedras vizinhas do leque, a `distance` px da origem.
static func fan_min_gap(distance: float) -> float:
	var step := deg_to_rad(FAN_SPREAD_DEG) / float(FAN_COUNT - 1)
	return 2.0 * distance * sin(step * 0.5) - 2.0 * EnemyBulletLayer.ROCK_RADIUS


## Largura livre da tela enquanto uma metade avança (o aviso cobre só aquela metade).
static func lunge_free_width(view_width: float) -> float:
	return view_width - 2.0 * (HALF_RADIUS + LUNGE_MARGIN)


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var art := Game.art
	var tint := Color(1.8, 1.5, 1.5) if _flash > 0.0 else Color.WHITE
	if state == State.TRANSITION and int(_state_t * 12.0) % 2 == 0:
		tint = Color(1.6, 0.7, 0.6)
	if phase == 1:
		var half := RADIUS / art.boss_fill
		draw_set_transform(center, rot)
		draw_texture_rect(art.rock_mother_body, Rect2(-half, -half, half * 2.0, half * 2.0), false, tint)
		draw_set_transform(Vector2.ZERO, 0.0)
	else:
		for i in _halves.size():
			var half := HALF_RADIUS / art.boss_fill
			var flip := 1.0 if i == 0 else -1.0  # a metade direita é a esquerda espelhada
			draw_set_transform(_halves[i].pos, 0.0, Vector2(flip, 1.0))
			draw_texture_rect(art.rock_mother_half, Rect2(-half, -half, half * 2.0, half * 2.0), false, tint)
		draw_set_transform(Vector2.ZERO, 0.0)

	var pulse := 0.85 + 0.15 * sin(_t * 8.0)
	for core in _cores():
		var pos: Vector2 = core.pos
		if core.open:
			draw_circle(pos, CORE_RADIUS * 1.6, Color(Palette.ENEMY, 0.22))
			draw_circle(pos, CORE_RADIUS * pulse, Palette.BLAST_HDR)
			draw_circle(pos, CORE_RADIUS * 0.45, Palette.WHITE_HDR)
		else:
			draw_circle(pos, CORE_RADIUS * 0.9, Color(0.22, 0.07, 0.05))
			draw_arc(pos, CORE_RADIUS * 0.9, 0.0, TAU, 32, Color(0.55, 0.32, 0.28), 4.0, true)
