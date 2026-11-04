class_name Ship
extends Node2D
## Nave do jogador: segue o arraste, escudo que se desgasta e arma automática evolutiva.

signal weapon_level_changed(level: int, went_up: bool)
signal shield_depleted
signal fired

enum HitResult { IGNORED, ABSORBED, LAST_CHANCE, DEAD }

const SHIELD_RING_RADIUS := 60.0
const BANK_SPEED := 1200.0  # px/s de movimento lateral para inclinação máxima
const FLAME_HALF_WIDTH := 5.0
const FLAME_LENGTH := 30.0
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

var _fire_timer := 0.0
var _bank := 0.0  # -1 (curva p/ esquerda) a 1 (direita)
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
	var prev_x := position.x
	position = position.lerp(target, 1.0 - exp(-Tuning.SHIP_FOLLOW_SHARPNESS * dt))
	var vx := (position.x - prev_x) / dt
	_bank = lerpf(_bank, clampf(vx / BANK_SPEED, -1.0, 1.0), 1.0 - exp(-12.0 * dt))

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


func _draw() -> void:
	# Inclinação nas curvas: gira um pouco e "afina" (a nave vira de lado).
	draw_set_transform(Vector2.ZERO, _bank * 0.15, Vector2(1.0 - 0.2 * absf(_bank), 1.0))

	var art := Game.art

	# Uma chama por motor definido no ArtSet.
	for i in art.ship_engines_px.size():
		var e := art.ship_point(art.ship_engines_px[i])
		var flick := 0.75 + 0.25 * sin(_t * 40.0 + i)
		var flame := PackedVector2Array([e + Vector2(-FLAME_HALF_WIDTH, 0), e + Vector2(FLAME_HALF_WIDTH, 0),
				e + Vector2(0, FLAME_LENGTH * flick)])
		draw_colored_polygon(flame, Color(Palette.FLAME_HDR, 0.85))

	# Sprite: o "glow" > 1 faz só as linhas claras (neon) passarem do limiar do glow.
	var half := art.ship_size * 0.5
	draw_texture_rect(art.ship_texture, Rect2(-half, -half, art.ship_size, art.ship_size), false, art.ship_glow)
	draw_set_transform(Vector2.ZERO, 0.0)

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
