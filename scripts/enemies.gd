class_name EnemyLayer
extends Node2D
## Inimigos com vida, tiros e drops. Base para os setores 2–5 (drones, torretas) e
## para as partes dos chefes. Hoje: DRONE (desce ondulando e atira mirado).

enum Kind { DRONE }

class Enemy:
	var id := 0
	var kind := 0
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var hp := 1
	var max_hp := 1
	var radius := 36.0
	var fire_timer := 0.0
	var t := 0.0
	var flash := 0.0
	var alive := true

const DRONE_HP := 3
const DRONE_SPEED := 170.0
const DRONE_FIRE_INTERVAL := 1.6
const DRONE_SHOT_SPEED := 430.0

var enemies: Array[Enemy] = []
var shots: EnemyBulletLayer
var view_size := Vector2.ZERO
var _next_id := 0


func resize(size: Vector2) -> void:
	view_size = size


func spawn_drone(pos: Vector2) -> Enemy:
	var e := Enemy.new()
	_next_id += 1
	e.id = _next_id
	e.kind = Kind.DRONE
	e.pos = pos
	e.vel = Vector2(0, DRONE_SPEED)
	e.hp = DRONE_HP
	e.max_hp = DRONE_HP
	e.fire_timer = randf_range(0.6, DRONE_FIRE_INTERVAL)
	enemies.append(e)
	return e


func update(dt: float, target: Vector2) -> void:
	for e in enemies:
		e.t += dt
		e.flash = maxf(0.0, e.flash - dt)
		match e.kind:
			Kind.DRONE:
				e.pos.y += e.vel.y * dt
				e.pos.x += sin(e.t * 2.2) * 90.0 * dt
				e.fire_timer -= dt
				# Só atira na parte de cima da tela: dá tempo de reagir.
				if e.fire_timer <= 0.0 and e.pos.y > 0.0 and e.pos.y < view_size.y * 0.55:
					shots.fire_aimed(e.pos + Vector2(0, e.radius), target, DRONE_SHOT_SPEED)
					e.fire_timer = DRONE_FIRE_INTERVAL
		if e.pos.y - e.radius > view_size.y:
			e.alive = false
	for i in range(enemies.size() - 1, -1, -1):
		if not enemies[i].alive:
			enemies.remove_at(i)
	queue_redraw()


func hit_test(p: Vector2, exclude: Dictionary = {}) -> Enemy:
	for e in enemies:
		if e.alive and not exclude.has(-e.id) and p.distance_squared_to(e.pos) < e.radius * e.radius:
			return e
	return null


## Retorna true se o inimigo foi destruído.
func damage(e: Enemy, amount: int) -> bool:
	e.hp -= amount
	e.flash = 0.08
	if e.hp <= 0:
		e.alive = false
		return true
	return false


func clear() -> void:
	enemies.clear()
	queue_redraw()


func clear_around(center: Vector2, radius: float) -> void:
	for e in enemies:
		if e.pos.distance_to(center) < radius + e.radius:
			e.alive = false


func _draw() -> void:
	for e in enemies:
		var body := PackedVector2Array()
		for i in 6:
			body.append(e.pos + Vector2.from_angle(TAU * i / 6.0 + PI / 6.0) * e.radius)
		var fill := Palette.WHITE_HDR if e.flash > 0.0 else Palette.ENEMY_FILL
		draw_colored_polygon(body, fill)
		draw_polyline(body + PackedVector2Array([body[0]]), Palette.ENEMY_HDR, 4.0, true)
		# "Olho" que pisca antes de atirar.
		var charge := 1.0 - clampf(e.fire_timer / 0.5, 0.0, 1.0)
		draw_circle(e.pos, 9.0 + 6.0 * charge, Palette.ENEMY.lerp(Palette.ENEMY_HDR, charge))
