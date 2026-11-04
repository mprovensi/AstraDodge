class_name Miner
extends Boss
## MINERADOR — chefe do Setor 2 (PLANO_V2.md, Setor 2).
##
## Ponto fraco: o OLHO no centro. Ele FECHA enquanto o raio está disparando
## (aí o tiro ricocheteia) — a regra é fácil de ler: "olho aberto = atire".
## Fase 1:
##   - Raio-trator: aviso em coluna embaixo dele, depois um raio vertical que machuca.
##     Ele para de se mover enquanto isso; o resto da tela é seguro.
##   - Cargas: solta 2 minas perto de você; cada uma mostra um círculo de aviso e
##     explode em cruz (4 tiros) — saia do círculo e das 4 direções.
## Fase 2 (50%): mais rápido, cargas explodindo em 8 direções, e ARREMESSA
##   pedaços de metal: aviso em linha da broca até onde você está, depois o arremesso.

const NAME := "MINERADOR"
const MAX_HP := 170

const SPRITE_SIZE := 500.0            # lado do sprite na tela
const EYE_RADIUS := 52.0
const BODY_RADIUS := 125.0
const BODY_OFFSET := Vector2(0, -10)
const DRILL_OFFSETS := [Vector2(-172, 80), Vector2(172, 80)]
const DRILL_RADIUS := 48.0
const ENTER_TIME := 2.8
const REST_Y_RATIO := 0.3               # abaixo do HUD e da barra de vida
const SWAY := [0.0, 0.2, 0.26]        # balanço lateral (fração da largura) por fase
const SWAY_SPEED := [0.0, 0.5, 0.75]

const BEAM_INTERVAL := [0.0, 5.0, 4.2]
const BEAM_TELEGRAPH := 1.1
const BEAM_FIRE := 1.3
const BEAM_WIDTH := 140.0

const CHARGE_INTERVAL := [0.0, 3.4, 2.8]
const CHARGE_COUNT := [0, 2, 2]
const CHARGE_FLIGHT := 0.6
const CHARGE_FUSE := 1.3
const CHARGE_RADIUS := 100.0          # círculo de aviso = área da explosão
const CHARGE_SHOTS := [0, 4, 8]       # cruz na fase 1; cruz + diagonais na fase 2
const CHARGE_SHOT_SPEED := 420.0
const CHARGE_SPREAD := 180.0          # distância lateral entre as cargas e a nave

const HURL_INTERVAL := 4.6
const HURL_TELEGRAPH := 1.0
const HURL_SPEED := 950.0

const TRANSITION_TIME := 1.2
const DYING_TIME := 2.4

var center := Vector2.ZERO

var _beam_timer := 3.0
var _beam_t := -1.0                  # >= 0: raio em andamento (aviso + disparo)
var _beam_x := 0.0
var _charge_timer := 1.6
var _charges: Array[Dictionary] = [] # {from, to, t}
var _blasts: Array[Vector3] = []     # explosões deste frame (x, y, raio) para o Main checar a nave
var _hurl_timer := 2.0
var _hurl_t := -1.0
var _hurl_side := 0
var _hurl_target := Vector2.ZERO
var _boom_timer := 0.0
var _ship_pos := Vector2.ZERO
var _sway_phase := 0.0


func _init() -> void:
	display_name = NAME
	max_hp = MAX_HP


func _enter() -> void:
	center = Vector2(view_size.x * 0.5, -SPRITE_SIZE * 0.5)
	_set_state(State.ENTERING)


# ---------------------------------------------------------------- comportamento

func _update_boss(dt: float, ship_pos: Vector2) -> void:
	_ship_pos = ship_pos
	match state:
		State.ENTERING:
			center.y = lerpf(-SPRITE_SIZE * 0.5, _rest_y(), smoothstep(0.0, 1.0, _state_t / ENTER_TIME))
			if _state_t >= ENTER_TIME:
				_set_state(State.FIGHT)
		State.FIGHT:
			_fight(dt)
		State.TRANSITION:
			center.x += sin(_t * 70.0) * 3.0
			if int(_state_t * 25.0) % 3 == 0:
				fx.spark(center + Vector2(randf_range(-120, 120), randf_range(-80, 80)), Palette.FLAME_HDR)
			_update_charges(dt)
			if _state_t >= TRANSITION_TIME:
				phase = 2
				_beam_timer = 2.0
				_hurl_timer = 1.5
				impact.call(20.0)
				Sfx.play("level_down", -2.0, 0.6, 0.0)
				_set_state(State.FIGHT)
				phase_changed.emit(2)
		State.DYING:
			_update_charges(dt)
			_update_dying(dt)


func _fight(dt: float) -> void:
	# Move de um lado para o outro, menos enquanto o raio está ativo.
	if _beam_t < 0.0:
		_sway_phase += dt * SWAY_SPEED[phase]
		center.x = view_size.x * 0.5 + sin(_sway_phase) * view_size.x * SWAY[phase]
	center.y = _rest_y() + sin(_t * 1.3) * 8.0

	_update_beam(dt)
	_update_charges(dt)
	if phase == 2:
		_update_hurl(dt)

	_charge_timer -= dt
	if _charge_timer <= 0.0:
		_charge_timer = CHARGE_INTERVAL[phase]
		_drop_charges()


func _update_beam(dt: float) -> void:
	if _beam_t >= 0.0:
		_beam_t += dt
		if _beam_t >= BEAM_TELEGRAPH and _beam_t - dt < BEAM_TELEGRAPH:
			impact.call(8.0)
			Sfx.play("shield_hit", -4.0, 0.5, 0.0, Vector2(_beam_x, center.y))
		if _beam_t >= BEAM_TELEGRAPH + BEAM_FIRE:
			_beam_t = -1.0
		return
	_beam_timer -= dt
	if _beam_timer <= 0.0 and _hurl_t < 0.0:
		_beam_timer = BEAM_INTERVAL[phase]
		_beam_t = 0.0
		_beam_x = center.x
		telegraph.column(_beam_x - BEAM_WIDTH * 0.5, _beam_x + BEAM_WIDTH * 0.5, BEAM_TELEGRAPH)
		Sfx.play("alarm", -10.0, 1.4, 0.0, Vector2(_beam_x, center.y))


func _beam_firing() -> bool:
	return _beam_t >= BEAM_TELEGRAPH


func _eye_open() -> bool:
	return is_vulnerable() and not _beam_firing()


func _drop_charges() -> void:
	var n: int = CHARGE_COUNT[phase]
	for i in n:
		var offset := (i - (n - 1) * 0.5) * CHARGE_SPREAD * 2.0 / maxf(1.0, n - 1.0) if n > 1 else 0.0
		var to := Vector2(
				clampf(_ship_pos.x + offset, 80.0, view_size.x - 80.0),
				randf_range(view_size.y * 0.5, view_size.y * 0.72))
		_charges.append({"from": center + Vector2(0, 60), "to": to, "t": 0.0})
	Sfx.play("click", -6.0, 0.5, 0.0, center)


func _update_charges(dt: float) -> void:
	_blasts.clear()
	for i in range(_charges.size() - 1, -1, -1):
		var c := _charges[i]
		var before: float = c.t
		c.t += dt
		if before < CHARGE_FLIGHT and c.t >= CHARGE_FLIGHT:
			telegraph.circle(c.to, CHARGE_RADIUS, CHARGE_FUSE)
		if c.t >= CHARGE_FLIGHT + CHARGE_FUSE:
			_explode(c.to)
			_charges.remove_at(i)


func _explode(pos: Vector2) -> void:
	var count: int = CHARGE_SHOTS[maxi(phase, 1)]
	shots.fire_ring(pos, count, CHARGE_SHOT_SPEED, 0.0, EnemyBulletLayer.Kind.ORB)
	_blasts.append(Vector3(pos.x, pos.y, CHARGE_RADIUS))
	fx.explosion(pos, 70.0, Palette.ENEMY_HDR)
	Sfx.play("explosion", -4.0, 1.2, 0.05, pos)
	impact.call(6.0)


func _update_hurl(dt: float) -> void:
	if _hurl_t >= 0.0:
		_hurl_t += dt
		if _hurl_t >= HURL_TELEGRAPH:
			var from := _drill_pos(_hurl_side)
			shots.fire(from, (_hurl_target - from).normalized() * HURL_SPEED, EnemyBulletLayer.Kind.CHUNK)
			Sfx.play("ricochet", 0.0, 0.5, 0.0, from)
			_hurl_t = -1.0
		return
	_hurl_timer -= dt
	if _hurl_timer <= 0.0 and _beam_t < 0.0:
		_hurl_timer = HURL_INTERVAL
		_hurl_t = 0.0
		_hurl_side = 1 - _hurl_side
		var from := _drill_pos(_hurl_side)
		# Mira onde a nave ESTÁ agora e avisa a linha inteira até a borda da tela.
		var dir := (_ship_pos - from).normalized()
		_hurl_target = from + dir * view_size.length()
		telegraph.line(from, _hurl_target, EnemyBulletLayer.CHUNK_RADIUS * 2.0 + 20.0, HURL_TELEGRAPH)


func _on_damaged() -> void:
	if phase == 1 and hp <= max_hp / 2:
		_set_state(State.TRANSITION)
		_beam_t = -1.0
		impact.call(12.0)
		Sfx.duck(-6.0)


func _update_dying(dt: float) -> void:
	_boom_timer -= dt
	if _boom_timer <= 0.0:
		_boom_timer = 0.15
		var p := center + Vector2(randf_range(-200, 200), randf_range(-110, 110))
		fx.explosion(p, randf_range(60.0, 110.0), Palette.BLAST_HDR if randf() < 0.5 else Palette.FLAME_HDR)
		Sfx.play("explosion", -2.0, randf_range(0.6, 0.9), 0.0, p)
		impact.call(10.0)
	if _state_t >= DYING_TIME:
		fx.explosion(center, 200.0, Palette.BLAST_HDR)
		Sfx.play("death", 0.0, 0.7, 0.0, center)
		impact.call(35.0)
		_set_state(State.DONE)
		visible = false
		defeated.emit()


func take_blasts() -> Array[Vector3]:
	return _blasts


# ---------------------------------------------------------------- colisão

func hit_bullet(p: Vector2) -> Hit:
	if state == State.DONE:
		return Hit.NONE
	# O olho fica no meio do casco: tiros que sobem na faixa dele (vindos de baixo) chegam
	# até ele "pela frente" do casco, em vez de baterem na blindagem antes.
	var in_eye := p.distance_squared_to(center) < EYE_RADIUS * EYE_RADIUS
	var eye_lane := absf(p.x - center.x) < EYE_RADIUS and p.y > center.y \
			and p.distance_squared_to(center + BODY_OFFSET) < BODY_RADIUS * BODY_RADIUS
	if in_eye or eye_lane:
		return Hit.CORE if _eye_open() else Hit.ARMOR
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
	if _beam_firing():
		return absf(p.x - _beam_x) < BEAM_WIDTH * 0.5 + radius * 0.6 and p.y > center.y
	return false


func aim_x() -> float:
	return center.x


func _bodies() -> Array[Dictionary]:
	var list: Array[Dictionary] = [{"pos": center + BODY_OFFSET, "radius": BODY_RADIUS}]
	for i in 2:
		list.append({"pos": _drill_pos(i), "radius": DRILL_RADIUS})
	return list


func _drill_pos(i: int) -> Vector2:
	return center + (DRILL_OFFSETS[i] as Vector2)


func _rest_y() -> float:
	return view_size.y * REST_Y_RATIO


# ---------------------------------------------------------------- rota segura

## Largura livre enquanto o raio dispara (só a coluna dele é perigosa).
static func beam_free_width(view_width: float) -> float:
	return view_width - BEAM_WIDTH


## Menor vão entre os tiros da explosão de uma carga, a `distance` px do centro.
static func blast_min_gap(distance: float, shots_count: int) -> float:
	return 2.0 * distance * sin(PI / float(shots_count)) - 2.0 * 14.0


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var art := Game.art

	# Raio-trator (atrás do corpo).
	if _beam_firing():
		var flick := 0.8 + 0.2 * sin(_t * 60.0)
		var top := center.y + 40.0
		var h := view_size.y - top
		draw_rect(Rect2(_beam_x - BEAM_WIDTH * 0.5, top, BEAM_WIDTH, h), Color(Palette.ENEMY, 0.35 * flick))
		draw_rect(Rect2(_beam_x - BEAM_WIDTH * 0.18, top, BEAM_WIDTH * 0.36, h), Palette.ENEMY_HDR * flick)
		draw_rect(Rect2(_beam_x - BEAM_WIDTH * 0.06, top, BEAM_WIDTH * 0.12, h), Palette.WHITE_HDR)

	var tint := Color(1.8, 1.6, 1.4) if _flash > 0.0 else Color.WHITE
	if state == State.TRANSITION and int(_state_t * 12.0) % 2 == 0:
		tint = Color(1.6, 0.8, 0.6)
	if art.miner_body != null:
		var half := SPRITE_SIZE * 0.5
		draw_texture_rect(art.miner_body, Rect2(center - Vector2(half, half), Vector2(SPRITE_SIZE, SPRITE_SIZE)),
				false, tint)

	# Olho: aberto (brilha, a pupila segue a nave) ou fechado (placas de aço).
	if _eye_open():
		var pulse := 0.88 + 0.12 * sin(_t * 9.0)
		var color := Palette.BLAST_HDR if phase == 1 else Palette.DANGER_HDR
		draw_circle(center, EYE_RADIUS * 1.5, Color(Palette.ENEMY, 0.22))
		draw_circle(center, EYE_RADIUS * pulse, color)
		var look := (_ship_pos - center).limit_length(EYE_RADIUS * 0.35)
		draw_circle(center + look, EYE_RADIUS * 0.35, Color(0.1, 0.02, 0.02))
	else:
		draw_circle(center, EYE_RADIUS, Color(0.16, 0.18, 0.22))
		draw_line(center + Vector2(-EYE_RADIUS, 0), center + Vector2(EYE_RADIUS, 0), Color(0.6, 0.66, 0.78), 6.0)
		draw_arc(center, EYE_RADIUS, 0.0, TAU, 32, Color(0.6, 0.66, 0.78), 4.0, true)

	# Pedaço de metal na broca antes do arremesso.
	if _hurl_t >= 0.0 and not art.metal_textures.is_empty():
		var p := _drill_pos(_hurl_side)
		var r := EnemyBulletLayer.CHUNK_RADIUS
		draw_texture_rect(art.metal_textures[0], Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), false,
				Color(1.4, 1.2, 1.2))

	# Cargas (minas): voando até o alvo, depois piscando cada vez mais rápido.
	for c in _charges:
		var k := clampf(c.t / CHARGE_FLIGHT, 0.0, 1.0)
		var pos: Vector2 = (c.from as Vector2).lerp(c.to, smoothstep(0.0, 1.0, k))
		draw_circle(pos, 22.0, Palette.ENEMY_FILL)
		draw_arc(pos, 22.0, 0.0, TAU, 24, Palette.ENEMY_HDR, 4.0, true)
		var fuse: float = (c.t - CHARGE_FLIGHT) / CHARGE_FUSE
		var blink_speed := 6.0 + 20.0 * clampf(fuse, 0.0, 1.0)
		if int(_t * blink_speed) % 2 == 0:
			draw_circle(pos, 8.0, Palette.WHITE_HDR)
