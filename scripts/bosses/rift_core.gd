class_name RiftCore
extends Boss
## NÚCLEO DA FENDA — chefe FINAL (Setor 8, PLANO_V3.md). Três fases que revisitam a campanha.
##
## Ponto fraco: o NÚCLEO no centro da esfera (tiros que sobem na faixa dele o alcançam).
## Fase 1: anéis concêntricos de tiros que se abrem a partir do núcleo, cada um com uma
##   BRECHA que gira de um anel para o outro (aviso em círculo antes de cada anel).
## Fase 2 (2/3 da vida): "ecos" — leque de pedras da Rocha-Mãe e raios em coluna do
##   Minerador, alternados com os anéis.
## Fase 3 (1/3): a tela inteira balança devagar; espiral de 2 braços + anéis + ecos.
## Ao cair: a Fenda se fecha e o Main toca a cena de fuga (motor de dobra restaurado).

const NAME := "NÚCLEO DA FENDA"
const MAX_HP := 360

const SPRITE_SIZE := 360.0
const BODY_RADIUS := 130.0
const CORE_RADIUS := 46.0
const ENTER_TIME := 3.5
const REST_Y_RATIO := 0.28
const SWAY := 0.12

const RING_INTERVAL := [0.0, 2.6, 3.6, 3.2]
const RING_TELEGRAPH := 0.6
const RING_COUNT := 24
const RING_GAP := 4                  # tiros que faltam em sequência (a brecha)
const RING_SPEED := 230.0

const FAN_INTERVAL := [0.0, 0.0, 4.8, 5.2]
const FAN_TELEGRAPH := 0.8
const FAN_ROCKS := 7
const FAN_SPREAD := 80.0             # graus
const FAN_SPEED := 320.0

const BEAM_INTERVAL := [0.0, 0.0, 5.4, 4.6]
const BEAM_TELEGRAPH := 1.0
const BEAM_ACTIVE := 0.8
const BEAM_WIDTH := 140.0
const BEAM_MIN_SPACING := 320.0

const SPIRAL_RATE := 0.16
const SPIRAL_STEP := 0.42
const SPIRAL_SPEED := 220.0

const TILT_MAX := 0.06               # rad (~3,4°) — a tela balança de leve na fase 3
const TILT_SPEED := 0.9

const TRANSITION_TIME := 1.6
const DYING_TIME := 3.0

var center := Vector2.ZERO

var _ring_timer := 2.0
var _ring_pending := -1.0
var _ring_gap_at := 0
var _fan_timer := 2.0
var _fan_pending := -1.0
var _beam_timer := 3.5
var _beam_t := -1.0
var _beam_cols: Array[float] = []
var _spiral_fire := 0.0
var _spiral_angle := 0.0
var _tilt := 0.0
var _ship := Vector2.ZERO
var _boom_timer := 0.0


func _init() -> void:
	display_name = NAME
	max_hp = MAX_HP


func _enter() -> void:
	center = Vector2(view_size.x * 0.5, -SPRITE_SIZE * 0.5)
	_set_state(State.ENTERING)


# ---------------------------------------------------------------- comportamento

func _update_boss(dt: float, ship_pos: Vector2) -> void:
	_ship = ship_pos
	var want_tilt := TILT_MAX * sin(_t * TILT_SPEED) if phase == 3 and state == State.FIGHT else 0.0
	_tilt = move_toward(_tilt, want_tilt, dt * 0.08)
	match state:
		State.ENTERING:
			center.y = lerpf(-SPRITE_SIZE * 0.5, _rest_y(), smoothstep(0.0, 1.0, _state_t / ENTER_TIME))
			if _state_t >= ENTER_TIME:
				_set_state(State.FIGHT)
		State.FIGHT:
			center.x = view_size.x * 0.5 + sin(_t * 0.45) * view_size.x * SWAY
			center.y = _rest_y() + sin(_t * 1.2) * 10.0
			_update_rings(dt)
			if phase >= 2:
				_update_fan(dt)
				_update_beams(dt)
			if phase == 3:
				_update_spiral(dt)
		State.TRANSITION:
			center.x += sin(_t * 60.0) * 3.0
			if int(_state_t * 20.0) % 2 == 0:
				fx.burst(center + Vector2.from_angle(randf() * TAU) * 160.0, Palette.MAGENTA_HDR, 5, 300.0, 0.4, 5.0)
			if _state_t >= TRANSITION_TIME:
				phase += 1
				_ring_timer = 2.0
				_fan_timer = 1.5
				_beam_timer = 3.0
				impact.call(20.0)
				Sfx.play("level_down", -2.0, 0.6, 0.0)
				_set_state(State.FIGHT)
				phase_changed.emit(phase)
		State.DYING:
			_update_dying(dt)


func _update_rings(dt: float) -> void:
	if _ring_pending >= 0.0:
		_ring_pending -= dt
		if _ring_pending < 0.0:
			var step := TAU / RING_COUNT
			for i in RING_COUNT:
				var k := (i - _ring_gap_at + RING_COUNT) % RING_COUNT
				if k < RING_GAP:
					continue  # a brecha
				shots.fire(center, Vector2.from_angle(step * i) * RING_SPEED, EnemyBulletLayer.Kind.ORB)
			# A brecha do próximo anel gira: sempre dá para passar, mas é preciso se mexer.
			_ring_gap_at = (_ring_gap_at + 3 + randi() % 3) % RING_COUNT
			Sfx.play("pickup_shield", -8.0, 0.4, 0.0, center)
		return
	_ring_timer -= dt
	if _ring_timer <= 0.0:
		_ring_timer = RING_INTERVAL[phase]
		_ring_pending = RING_TELEGRAPH
		telegraph.circle(center, BODY_RADIUS * 0.8, RING_TELEGRAPH)


func _update_fan(dt: float) -> void:
	if _fan_pending >= 0.0:
		_fan_pending -= dt
		if _fan_pending < 0.0:
			var origin := center + Vector2(0, BODY_RADIUS)
			shots.fire_fan(origin, PI * 0.5, FAN_ROCKS, FAN_SPREAD, FAN_SPEED, EnemyBulletLayer.Kind.ROCK)
			Sfx.play("explosion", -8.0, 0.7, 0.0, origin)
		return
	if _beam_t >= 0.0:
		return  # um eco por vez
	_fan_timer -= dt
	if _fan_timer <= 0.0:
		_fan_timer = FAN_INTERVAL[phase]
		_fan_pending = FAN_TELEGRAPH
		telegraph.circle(center + Vector2(0, BODY_RADIUS), 80.0, FAN_TELEGRAPH)
		Sfx.play("alarm", -10.0, 0.9, 0.0, center)


func _update_beams(dt: float) -> void:
	if _beam_t >= 0.0:
		var before := _beam_t
		_beam_t += dt
		if before < BEAM_TELEGRAPH and _beam_t >= BEAM_TELEGRAPH:
			Sfx.play("death", -10.0, 1.6, 0.0, center)
			impact.call(8.0)
		if _beam_t >= BEAM_TELEGRAPH + BEAM_ACTIVE:
			_beam_t = -1.0
		return
	if _fan_pending >= 0.0:
		return
	_beam_timer -= dt
	if _beam_timer > 0.0:
		return
	_beam_timer = BEAM_INTERVAL[phase]
	# Um raio onde a nave está (pressão) e outro longe dele.
	var half := BEAM_WIDTH * 0.5
	var a := clampf(_ship.x, half, view_size.x - half)
	var b := a
	for attempt in 12:
		b = randf_range(half, view_size.x - half)
		if absf(b - a) >= BEAM_MIN_SPACING:
			break
	_beam_cols = [a]
	if absf(b - a) >= BEAM_MIN_SPACING:
		_beam_cols.append(b)
	for x in _beam_cols:
		telegraph.column(x - half, x + half, BEAM_TELEGRAPH)
	_beam_t = 0.0
	Sfx.play("alarm", -8.0, 1.1, 0.0, center)


func _update_spiral(dt: float) -> void:
	_spiral_fire -= dt
	if _spiral_fire > 0.0:
		return
	_spiral_fire = SPIRAL_RATE
	for arm in 2:
		shots.fire(center, Vector2.from_angle(_spiral_angle + PI * arm) * SPIRAL_SPEED, EnemyBulletLayer.Kind.ORB)
	_spiral_angle += SPIRAL_STEP


func _on_damaged() -> void:
	var next_at := max_hp * 2 / 3 if phase == 1 else (max_hp / 3 if phase == 2 else -1)
	if hp <= next_at:
		_set_state(State.TRANSITION)
		_ring_pending = -1.0
		_fan_pending = -1.0
		_beam_t = -1.0
		impact.call(14.0)
		Sfx.duck(-6.0)


func _update_dying(dt: float) -> void:
	_boom_timer -= dt
	if _boom_timer <= 0.0:
		_boom_timer = 0.12
		var p := center + Vector2.from_angle(randf() * TAU) * randf() * BODY_RADIUS * 1.2
		fx.explosion(p, randf_range(70.0, 130.0), Palette.MAGENTA_HDR if randf() < 0.5 else Palette.WHITE_HDR)
		Sfx.play("explosion", -2.0, randf_range(0.6, 0.9), 0.0, p)
		impact.call(12.0)
	if _state_t >= DYING_TIME:
		fx.explosion(center, 260.0, Palette.WHITE_HDR)
		Sfx.play("death", 0.0, 0.6, 0.0, center)
		impact.call(40.0)
		_set_state(State.DONE)
		visible = false
		defeated.emit()


# ---------------------------------------------------------------- colisão

func hit_bullet(p: Vector2) -> Hit:
	if state == State.DONE:
		return Hit.NONE
	var d := p.distance_to(center)
	var core_lane := absf(p.x - center.x) < CORE_RADIUS and p.y > center.y and p.y < center.y + BODY_RADIUS
	if d < CORE_RADIUS or core_lane:
		return Hit.CORE if is_vulnerable() else Hit.ARMOR
	if d < BODY_RADIUS:
		return Hit.ARMOR
	return Hit.NONE


func touches(p: Vector2, radius: float) -> bool:
	if state == State.DONE:
		return false
	return p.distance_to(center) < BODY_RADIUS + radius


func beam_hits(p: Vector2, radius: float) -> bool:
	if state != State.FIGHT or _beam_t < BEAM_TELEGRAPH:
		return false
	for x in _beam_cols:
		if absf(p.x - x) < BEAM_WIDTH * 0.5 + radius * 0.6 and p.y > center.y:
			return true
	return false


## Inclinação da tela (rad) que o Main aplica ao mundo — só na fase 3.
func screen_tilt() -> float:
	return _tilt


func aim_x() -> float:
	return center.x


func _rest_y() -> float:
	return view_size.y * REST_Y_RATIO


# ---------------------------------------------------------------- rota segura

## Largura da brecha de um anel a `distance` px do núcleo, descontando o tamanho dos tiros.
static func ring_gap(distance: float) -> float:
	return 2.0 * distance * sin(TAU / RING_COUNT * (RING_GAP + 1) * 0.5) - 2.0 * 14.0


## Menor vão entre pedras vizinhas do leque a `distance` px da origem.
static func fan_min_gap(distance: float) -> float:
	var step := deg_to_rad(FAN_SPREAD / (FAN_ROCKS - 1))
	return 2.0 * distance * sin(step * 0.5) - 2.0 * EnemyBulletLayer.ROCK_RADIUS


## Largura livre da tela com os dois raios ativos.
static func beams_free_width(view_w: float) -> float:
	return view_w - 2.0 * BEAM_WIDTH


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var art := Game.art
	var pulse := 0.85 + 0.15 * sin(_t * 6.0)
	# Halo da fenda girando atrás da esfera.
	for k in 4:
		var r := BODY_RADIUS * (1.15 + k * 0.12)
		var a0 := _t * (0.8 + k * 0.3) * (1.0 if k % 2 == 0 else -1.0)
		draw_arc(center, r, a0, a0 + PI * 1.3, 40, Color(Palette.MAGENTA, 0.5 - k * 0.1), 4.0, true)
	var tint := Color(1.7, 1.5, 1.8) if _flash > 0.0 else Color.WHITE
	if state == State.TRANSITION and int(_state_t * 12.0) % 2 == 0:
		tint = Color(2.0, 1.2, 2.0)
	if art.rift_core_body != null:
		var half := SPRITE_SIZE * 0.5
		draw_texture_rect(art.rift_core_body, Rect2(center - Vector2(half, half), Vector2(SPRITE_SIZE, SPRITE_SIZE)),
				false, tint)
	draw_circle(center, CORE_RADIUS * 1.6, Color(Palette.MAGENTA, 0.2))
	draw_circle(center, CORE_RADIUS * pulse, Palette.MAGENTA_HDR)
	draw_circle(center, CORE_RADIUS * 0.45, Palette.WHITE_HDR)

	# Raios do "eco do Minerador".
	if _beam_t >= BEAM_TELEGRAPH:
		for x in _beam_cols:
			draw_rect(Rect2(x - BEAM_WIDTH * 0.5, center.y, BEAM_WIDTH, view_size.y), Color(Palette.MAGENTA, 0.12))
			draw_line(Vector2(x, center.y), Vector2(x, view_size.y), Palette.MAGENTA_HDR, BEAM_WIDTH * 0.35)
			draw_line(Vector2(x, center.y), Vector2(x, view_size.y), Palette.WHITE_HDR, 6.0)
