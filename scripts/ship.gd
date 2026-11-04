class_name Ship
extends Node2D
## Nave do jogador: segue o arraste, escudo que se desgasta e arma automática evolutiva.

signal weapon_level_changed(level: int, went_up: bool)
signal shield_depleted

enum HitResult { IGNORED, ABSORBED, LAST_CHANCE, DEAD }

const SHIELD_RING_RADIUS := 60.0
const BODY := [Vector2(0, -44), Vector2(32, 30), Vector2(0, 16), Vector2(-32, 30)]

var bullets: BulletLayer
var target := Vector2.ZERO
var bounds := Rect2()
var shield := Tuning.SHIELD_MAX
var last_chance := false
var weapon_level := Tuning.WEAPON_START_LEVEL
var crystals := 0
var invuln := 0.0
var alive := true

var _fire_timer := 0.0
var _t := 0.0


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
	position = position.lerp(target, 1.0 - exp(-Tuning.SHIP_FOLLOW_SHARPNESS * dt))

	invuln = maxf(0.0, invuln - dt)
	modulate.a = 0.35 if invuln > 0.0 and int(_t * 20.0) % 2 == 0 else 1.0

	if not last_chance:
		shield -= Tuning.SHIELD_DRAIN_PER_SEC * dt
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
	var muzzle := position + Vector2(0, -44)
	var off := Vector2(Tuning.DOUBLE_SHOT_OFFSET, 0)
	var fan := deg_to_rad(Tuning.FAN_ANGLE_DEG)
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


func _draw() -> void:
	# Chama do propulsor
	var flick := 0.75 + 0.25 * sin(_t * 40.0)
	var flame := PackedVector2Array([Vector2(-12, 24), Vector2(12, 24), Vector2(0, 24 + 34 * flick)])
	draw_colored_polygon(flame, Color(Palette.FLAME, 0.85))

	# Corpo com contorno "neon" (traço largo translúcido + traço fino)
	var body := PackedVector2Array(BODY)
	draw_colored_polygon(body, Palette.NEON_DARK)
	var outline := body + PackedVector2Array([body[0]])
	draw_polyline(outline, Color(Palette.NEON, 0.3), 12.0, true)
	draw_polyline(outline, Palette.NEON, 4.0, true)

	# Anel do escudo: espessura e brilho proporcionais à energia
	if last_chance:
		if int(_t * 8.0) % 2 == 0:
			draw_arc(Vector2.ZERO, SHIELD_RING_RADIUS, 0.0, TAU, 48, Color(Palette.DANGER, 0.9), 4.0, true)
		return
	var ratio := shield_ratio()
	var alpha := 0.25 + 0.55 * ratio
	if ratio < Tuning.SHIELD_LOW_RATIO and int(_t * 6.0) % 2 == 0:
		alpha *= 0.3
	draw_arc(Vector2.ZERO, SHIELD_RING_RADIUS, 0.0, TAU, 48, Color(Palette.NEON, alpha * 0.35), 4.0 + 10.0 * ratio, true)
	draw_arc(Vector2.ZERO, SHIELD_RING_RADIUS, 0.0, TAU, 48, Color(Palette.NEON, alpha), 2.0 + 3.0 * ratio, true)
