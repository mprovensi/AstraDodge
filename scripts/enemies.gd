class_name EnemyLayer
extends Node2D
## Inimigos com vida, tiros e drops. Base para os setores 2–5 e para as partes dos chefes.
## - DRONE: desce ondulando e atira mirado.
## - MINE (Setor 3): mina iônica que desce com o cenário. Se a nave chegar perto, ela ARMA
##   (pisca e mostra o anel da explosão) e explode em área + anel de tiros. Atire de longe!

enum Kind { DRONE, MINE }

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
	var armed := -1.0   # mina: >= 0 = segundos desde que armou
	var alive := true

const DRONE_HP := 3
const DRONE_SPEED := 170.0
const DRONE_FIRE_INTERVAL := 1.6
const DRONE_SHOT_SPEED := 430.0

var enemies: Array[Enemy] = []
var shots: EnemyBulletLayer
var view_size := Vector2.ZERO
var _next_id := 0
var _blasts: Array[Vector3] = []  # explosões deste passo (x, y, raio) — o Main confere a nave


func resize(size: Vector2) -> void:
	view_size = size


func spawn_drone(pos: Vector2) -> Enemy:
	var e := _new_enemy(Kind.DRONE, pos, DRONE_HP, 36.0)
	e.vel = Vector2(0, DRONE_SPEED)
	e.fire_timer = randf_range(0.6, DRONE_FIRE_INTERVAL)
	return e


func spawn_mine(pos: Vector2) -> Enemy:
	return _new_enemy(Kind.MINE, pos, Tuning.MINE_HP, Tuning.MINE_RADIUS)


func _new_enemy(kind: Kind, pos: Vector2, hp: int, radius: float) -> Enemy:
	var e := Enemy.new()
	_next_id += 1
	e.id = _next_id
	e.kind = kind
	e.pos = pos
	e.hp = hp
	e.max_hp = hp
	e.radius = radius
	e.t = randf() * TAU
	enemies.append(e)
	return e


## `scroll_speed`: as minas descem junto com o cenário.
func update(dt: float, target: Vector2, scroll_speed := 0.0) -> void:
	_blasts.clear()
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
			Kind.MINE:
				e.pos.y += scroll_speed * dt
				if e.armed < 0.0 and e.pos.y > 0.0 and e.pos.distance_to(target) < Tuning.MINE_TRIGGER:
					e.armed = 0.0
					Sfx.play("alarm", -12.0, 1.6, 0.0, e.pos)
				if e.armed >= 0.0:
					e.armed += dt
					if e.armed >= Tuning.MINE_FUSE:
						_explode_mine(e)
		if e.pos.y - e.radius > view_size.y:
			e.alive = false
	for i in range(enemies.size() - 1, -1, -1):
		if not enemies[i].alive:
			enemies.remove_at(i)
	queue_redraw()


func _explode_mine(e: Enemy) -> void:
	e.alive = false
	shots.fire_ring(e.pos, Tuning.MINE_SHOTS, Tuning.MINE_SHOT_SPEED, randf() * TAU, EnemyBulletLayer.Kind.ORB)
	_blasts.append(Vector3(e.pos.x, e.pos.y, Tuning.MINE_BLAST))


func take_blasts() -> Array[Vector3]:
	return _blasts


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
	_blasts.clear()
	queue_redraw()


func clear_around(center: Vector2, radius: float) -> void:
	for e in enemies:
		if e.pos.distance_to(center) < radius + e.radius:
			e.alive = false


func _draw() -> void:
	for e in enemies:
		if e.kind == Kind.MINE:
			_draw_mine(e)
			continue
		var body := PackedVector2Array()
		for i in 6:
			body.append(e.pos + Vector2.from_angle(TAU * i / 6.0 + PI / 6.0) * e.radius)
		var fill := Palette.WHITE_HDR if e.flash > 0.0 else Palette.ENEMY_FILL
		draw_colored_polygon(body, fill)
		draw_polyline(body + PackedVector2Array([body[0]]), Palette.ENEMY_HDR, 4.0, true)
		# "Olho" que pisca antes de atirar.
		var charge := 1.0 - clampf(e.fire_timer / 0.5, 0.0, 1.0)
		draw_circle(e.pos, 9.0 + 6.0 * charge, Palette.ENEMY.lerp(Palette.ENEMY_HDR, charge))


## Mina: núcleo com 8 espinhos. Calma = violeta; armada = vermelha, piscando rápido,
## com o anel mostrando o tamanho exato da explosão.
func _draw_mine(e: Enemy) -> void:
	var armed := e.armed >= 0.0
	var color := Palette.DANGER_HDR if armed else Palette.ION_HDR
	var r := e.radius
	for i in 8:
		var dir := Vector2.from_angle(TAU * i / 8.0 + e.t * 0.8)
		draw_line(e.pos + dir * r * 0.7, e.pos + dir * r * 1.35, color, 5.0, true)
	var fill := Palette.WHITE_HDR if e.flash > 0.0 else Color(0.16, 0.06, 0.26)
	draw_circle(e.pos, r, fill)
	draw_arc(e.pos, r, 0.0, TAU, 24, color, 4.0, true)
	var blink_speed := 3.0 if not armed else 18.0
	if int(e.t * blink_speed) % 2 == 0:
		draw_circle(e.pos, r * 0.35, color)
	if armed:
		var k := e.armed / Tuning.MINE_FUSE
		draw_arc(e.pos, Tuning.MINE_BLAST, 0.0, TAU, 48, Color(Palette.DANGER_HDR, 0.5 + 0.5 * k), 4.0, true)
		draw_arc(e.pos, Tuning.MINE_BLAST * (2.0 - k), 0.0, TAU, 48, Color(Palette.DANGER, 0.5), 2.0, true)
