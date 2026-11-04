class_name Ship
extends Node2D
## Nave do jogador: segue o arraste, escudo que se desgasta e arma automática evolutiva.

signal weapon_level_changed(level: int, went_up: bool)
signal shield_depleted
signal fired

enum HitResult { IGNORED, ABSORBED, LAST_CHANCE, DEAD }

const SHIELD_RING_RADIUS := 60.0
const BANK_SPEED := 1200.0  # px/s de movimento lateral para inclinação máxima
const FLAME_HALF_WIDTH := 6.5
const FLAME_LENGTH := 42.0
# Sprite, tamanho, brilho, motores e ponta da nave vêm do ArtSet ativo (Game.art).

var bullets: BulletLayer
var target := Vector2.ZERO
var bounds := Rect2()
var shield := Tuning.SHIELD_MAX
var last_chance := false
var weapon_level := Tuning.WEAPON_START_LEVEL
var crystals := 0
var invuln := 0.0
var alive := true
var drain_scale := 1.0  # o Main reduz durante as lutas contra chefes

var scroll_speed := 0.0  # o Main informa: o rastro dos motores escorre com o cenário

var _fire_timer := 0.0
var _bank := 0.0  # -1 (curva p/ esquerda) a 1 (direita)
var _t := 0.0
var _vel := Vector2.ZERO     # velocidade suavizada (px/s) — move chamas, rastros e inclinação
var _trail: Array = []       # rastro dos motores: [[pos no mundo, idade], ...] por motor
var _vapor: Array = []       # rastro de vapor das pontas das asas (curvas rápidas)

const TRAIL_LIFE := 0.32
const VAPOR_LIFE := 0.28
const VAPOR_SPEED := 650.0   # a partir desta velocidade as asas soltam vapor


func reset(start_pos: Vector2) -> void:
	position = _clamp(start_pos)
	target = position
	shield = Tuning.SHIELD_MAX
	last_chance = false
	weapon_level = Tuning.WEAPON_START_LEVEL
	crystals = 0
	invuln = 0.0
	alive = true
	visible = true
	modulate.a = 1.0
	_fire_timer = 0.0
	_vel = Vector2.ZERO
	_trail.clear()
	_vapor.clear()


func resize(view_size: Vector2) -> void:
	var m := Tuning.SHIP_MARGIN
	var top := view_size.y * Tuning.SHIP_MIN_Y_RATIO
	bounds = Rect2(m, top, view_size.x - 2.0 * m, view_size.y - top - m)
	target = _clamp(target)
	position = _clamp(position)


## Movimento relativo: soma o deslocamento do dedo ao alvo da nave.
func move_by(delta_px: Vector2) -> void:
	target = _clamp(target + delta_px)


func update(dt: float) -> void:
	if not alive:
		return
	_t += dt
	var prev := position
	position = position.lerp(target, 1.0 - exp(-Tuning.SHIP_FOLLOW_SHARPNESS * dt))
	var v := (position - prev) / dt
	_vel = _vel.lerp(v, 1.0 - exp(-10.0 * dt))
	_bank = lerpf(_bank, clampf(v.x / BANK_SPEED, -1.0, 1.0), 1.0 - exp(-12.0 * dt))
	_update_trails(dt)

	invuln = maxf(0.0, invuln - dt)
	modulate.a = 0.35 if invuln > 0.0 and int(_t * 20.0) % 2 == 0 else 1.0

	if not last_chance:
		shield -= Tuning.SHIELD_DRAIN_PER_SEC * drain_scale * dt
		if shield <= 0.0:
			_enter_last_chance()

	_fire_timer -= dt
	if _fire_timer <= 0.0:
		_fire()
		var interval: float = Tuning.WEAPON_FIRE_INTERVAL[weapon_level]
		_fire_timer = interval

	queue_redraw()


func take_hit(damage: float) -> HitResult:
	if not alive or invuln > 0.0:
		return HitResult.IGNORED
	if last_chance:
		die()
		return HitResult.DEAD
	shield -= damage
	invuln = Tuning.HIT_INVULN_TIME
	if shield <= 0.0:
		_enter_last_chance()
		return HitResult.LAST_CHANCE
	return HitResult.ABSORBED


## Retorna true se o orbe tirou a nave da "última chance".
func add_shield(amount: float) -> bool:
	var saved := last_chance
	last_chance = false
	shield = minf(Tuning.SHIELD_MAX, shield + amount)
	return saved


func add_crystal() -> void:
	if weapon_level >= Tuning.WEAPON_MAX_LEVEL:
		return
	crystals += 1
	var needed: int = Tuning.WEAPON_CRYSTALS_TO_NEXT[weapon_level]
	if crystals >= needed:
		_set_weapon_level(weapon_level + 1)


func weapon_progress() -> float:
	if weapon_level >= Tuning.WEAPON_MAX_LEVEL:
		return 1.0
	var needed: int = Tuning.WEAPON_CRYSTALS_TO_NEXT[weapon_level]
	return float(crystals) / float(needed)


func shield_ratio() -> float:
	return shield / Tuning.SHIELD_MAX


func revive() -> void:
	alive = true
	visible = true
	shield = Tuning.SHIELD_MAX
	last_chance = false
	invuln = Tuning.REVIVE_INVULN_TIME
	target = position


func die() -> void:
	alive = false
	visible = false


func _enter_last_chance() -> void:
	shield = 0.0
	last_chance = true
	_set_weapon_level(weapon_level - 1)
	shield_depleted.emit()


func _set_weapon_level(level: int) -> void:
	level = clampi(level, 1, Tuning.WEAPON_MAX_LEVEL)
	crystals = 0
	if level == weapon_level:
		return
	var went_up := level > weapon_level
	weapon_level = level
	weapon_level_changed.emit(level, went_up)


func _fire() -> void:
	var muzzle := position + Game.art.ship_point(Game.art.ship_muzzle_px)
	var off := Vector2(Tuning.DOUBLE_SHOT_OFFSET, 0)
	var fan := deg_to_rad(Tuning.FAN_ANGLE_DEG)
	fired.emit()
	match weapon_level:
		1:
			bullets.spawn(muzzle, 0.0, false)
		2, 3:
			bullets.spawn(muzzle - off, 0.0, false)
			bullets.spawn(muzzle + off, 0.0, false)
		4:
			bullets.spawn(muzzle, -fan, false)
			bullets.spawn(muzzle, 0.0, false)
			bullets.spawn(muzzle, fan, false)
		_:
			bullets.spawn(muzzle, -fan, false)
			bullets.spawn(muzzle, fan, false)
			bullets.spawn(muzzle, 0.0, true)


func _clamp(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, bounds.position.x, bounds.end.x), clampf(p.y, bounds.position.y, bounds.end.y))


## Rastros (no espaço do MUNDO): um ponto por motor/asa a cada quadro; envelhecem e
## escorrem para baixo com o cenário — a nave "deixa a trilha para trás".
func _update_trails(dt: float) -> void:
	var art := Game.art
	var flow := Vector2(0, scroll_speed * 0.9 * dt)
	for list in [_trail, _vapor]:
		for p in list:
			p[0] += flow
			p[1] += dt
	while not _trail.is_empty() and _trail[0][1] > TRAIL_LIFE:
		_trail.pop_front()
	while not _vapor.is_empty() and _vapor[0][1] > VAPOR_LIFE:
		_vapor.pop_front()
	for e in art.ship_engines_px:
		_trail.append([to_global(_tilted(art.ship_point(e))) + Vector2(0, 14), 0.0])
	# Vapor nas pontas das asas só nas manobras rápidas.
	if _vel.length() > VAPOR_SPEED:
		for w in art.ship_wingtips_px:
			_vapor.append([to_global(_tilted(art.ship_point(w))), 0.0])


## Ponto do sprite com a inclinação aplicada (o mesmo transform do desenho).
func _tilted(p: Vector2) -> Vector2:
	return (p * _roll_scale()).rotated(_bank * 0.15)


## "Rolar" em 3D: na curva a nave afina (vira de lado); subindo, estica de leve (velocidade).
func _roll_scale() -> Vector2:
	var pitch := clampf(-_vel.y / 2500.0, -0.04, 0.05)
	return Vector2(1.0 - 0.28 * absf(_bank), 1.0 + pitch)


func _draw() -> void:
	var art := Game.art
	var flame_col := Game.skin_flame()
	var speed := _vel.length()

	# 1. Rastro dos motores: fita que afina e esmaece, na cor da chama.
	var per := art.ship_engines_px.size()
	for k in per:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for i in range(k, _trail.size(), per):
			var age: float = _trail[i][1] / TRAIL_LIFE
			pts.append(to_local(_trail[i][0]))
			cols.append(Color(flame_col, 0.55 * (1.0 - age)))
		if pts.size() >= 2:
			pts.reverse()
			cols.reverse()
			draw_polyline_colors(pts, cols, 5.0, true)
	# 2. Vapor das asas: linhas brancas finas que somem rápido.
	for k in art.ship_wingtips_px.size():
		var pts := PackedVector2Array()
		for i in range(k, _vapor.size(), art.ship_wingtips_px.size()):
			pts.append(to_local(_vapor[i][0]))
		if pts.size() >= 2:
			draw_polyline(pts, Color(0.85, 0.95, 1.0, 0.35), 2.0, true)

	# 3. Clarão dos motores atrás da nave (ilumina o espaço em volta; cresce com a aceleração).
	var half := art.ship_size * 0.5
	var glow_at := art.ship_point(Vector2(128, 205))
	var soft := Color(minf(flame_col.r, 1.0), minf(flame_col.g, 1.0), minf(flame_col.b, 1.0), 0.025)  # sem HDR: luz suave (mistura linear: alfa baixo)
	draw_circle(glow_at, 30.0 + 12.0 * clampf(-_vel.y / 1400.0, 0.0, 1.0), soft)

	# 4. Chamas: núcleo branco-quente + chama colorida + brilho no bocal. Subindo (acelerando)
	#    as chamas crescem; descendo (freando) encolhem. Tremulam o tempo todo.
	draw_set_transform(Vector2.ZERO, _bank * 0.15, _roll_scale())
	var thrust := clampf(1.0 - _vel.y / 1400.0, 0.55, 1.9)
	for i in per:
		var e := art.ship_point(art.ship_engines_px[i])
		var flick := 0.8 + 0.2 * sin(_t * 47.0 + i * 2.1) + 0.08 * sin(_t * 113.0 + i)
		var length := FLAME_LENGTH * thrust * flick
		var w := FLAME_HALF_WIDTH * (1.0 + 0.25 * (thrust - 1.0))
		draw_colored_polygon(PackedVector2Array([e + Vector2(-w * 1.5, 0), e + Vector2(w * 1.5, 0),
				e + Vector2(0, length * 1.25)]), Color(flame_col, 0.35))
		draw_colored_polygon(PackedVector2Array([e + Vector2(-w, 0), e + Vector2(w, 0),
				e + Vector2(0, length)]), Color(flame_col, 0.9))
		draw_colored_polygon(PackedVector2Array([e + Vector2(-w * 0.45, 0), e + Vector2(w * 0.45, 0),
				e + Vector2(0, length * 0.55)]), Color(3.0, 3.0, 2.6))
		draw_circle(e + Vector2(0, 2), w * 1.3, Color(flame_col, 0.5))

	# 5. Propulsores laterais (RCS): um jatinho ciano do lado oposto da curva.
	if absf(_bank) > 0.3:
		var side := -signf(_bank)
		var base := art.ship_point(Vector2(128 + side * 26.0, 110))
		var puff := 12.0 + 26.0 * (absf(_bank) - 0.3) + 5.0 * sin(_t * 60.0)
		draw_colored_polygon(PackedVector2Array([base + Vector2(0, -4), base + Vector2(0, 4),
				base + Vector2(side * puff, 0)]), Color(Palette.NEON_HDR, 0.85))
		draw_circle(base + Vector2(side * puff * 0.3, 0), 3.0, Color(2.6, 2.8, 3.0))

	# 6. Casco. O "glow" > 1 faz só as linhas claras (neon) passarem do limiar do glow.
	#    Skin: a cor do casco multiplica o sprite (o padrão é o próprio brilho do ArtSet).
	var hull := art.ship_glow if Game.skin == 0 else Game.skin_hull()
	draw_texture_rect(art.ship_texture, Rect2(-half, -half, art.ship_size, art.ship_size), false, hull)
	# Luz deslizando pela cabine conforme a nave inclina (reflexo 2.5D).
	var glint := art.ship_point(Vector2(128 - _bank * 10.0, 72))
	draw_circle(glint, 4.0 + 1.5 * absf(_bank), Color(2.4, 2.6, 2.8, 0.5 + 0.4 * absf(_bank)))
	draw_set_transform(Vector2.ZERO, 0.0)

	# 7. Linhas de velocidade nas manobras muito rápidas.
	if speed > 1100.0:
		var dir := -_vel.normalized()
		var k := clampf((speed - 1100.0) / 1500.0, 0.0, 1.0)
		for j in 3:
			var off := dir.orthogonal() * (j - 1) * 26.0
			draw_line(off + dir * 70.0, off + dir * (70.0 + 50.0 * k), Color(0.8, 0.95, 1.0, 0.35 * k), 2.0, true)

	# Anel do escudo: espessura e brilho proporcionais à energia
	if last_chance:
		if int(_t * 8.0) % 2 == 0:
			draw_arc(Vector2.ZERO, SHIELD_RING_RADIUS, 0.0, TAU, 48, Color(Palette.DANGER_HDR, 0.9), 4.0, true)
		return
	var ratio := shield_ratio()
	var alpha := 0.25 + 0.55 * ratio
	if ratio < Tuning.SHIELD_LOW_RATIO and int(_t * 6.0) % 2 == 0:
		alpha *= 0.3
	draw_arc(Vector2.ZERO, SHIELD_RING_RADIUS, 0.0, TAU, 48, Color(Palette.NEON, alpha * 0.35), 4.0 + 10.0 * ratio, true)
	var ring := Palette.NEON.lerp(Palette.NEON_HDR, ratio * 0.6)  # escudo cheio brilha mais
	draw_arc(Vector2.ZERO, SHIELD_RING_RADIUS, 0.0, TAU, 48, Color(ring, alpha), 2.0 + 3.0 * ratio, true)
