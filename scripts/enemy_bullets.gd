class_name EnemyBulletLayer
extends Node2D
## Pool de projéteis inimigos com padrões reutilizáveis (mirado, leque, anel).
## Cada tipo tem forma própria — nunca diferenciar só pela cor.

enum Kind { ORB, DIAMOND, ROCK }

const ROCK_RADIUS := 18.0
## Contorno da pedra (unitário; escalado pelo raio e girando).
const ROCK_SHAPE := [Vector2(1.0, 0.0), Vector2(0.55, 0.8), Vector2(-0.2, 0.95), Vector2(-0.85, 0.45),
		Vector2(-0.9, -0.35), Vector2(-0.3, -0.9), Vector2(0.5, -0.8)]

class Shot:
	var kind := 0
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var radius := 14.0
	var t := 0.0
	var alive := false

var pool: Array[Shot] = []
var view_size := Vector2.ZERO


func resize(size: Vector2) -> void:
	view_size = size


func fire(pos: Vector2, vel: Vector2, kind := Kind.ORB) -> void:
	var s := _get_free()
	s.kind = kind
	s.pos = pos
	s.vel = vel
	match kind:
		Kind.ORB:
			s.radius = 14.0
		Kind.DIAMOND:
			s.radius = 12.0
		Kind.ROCK:
			s.radius = ROCK_RADIUS
	s.t = 0.0
	s.alive = true


func fire_aimed(pos: Vector2, target: Vector2, speed: float, kind := Kind.DIAMOND) -> void:
	fire(pos, (target - pos).normalized() * speed, kind)


func fire_fan(pos: Vector2, center_angle: float, count: int, spread_deg: float, speed: float, kind := Kind.ORB) -> void:
	var spread := deg_to_rad(spread_deg)
	for i in count:
		var k := 0.5 if count == 1 else float(i) / float(count - 1)
		fire(pos, Vector2.from_angle(center_angle - spread * 0.5 + spread * k) * speed, kind)


func fire_ring(pos: Vector2, count: int, speed: float, offset_angle := 0.0, kind := Kind.ORB) -> void:
	for i in count:
		fire(pos, Vector2.from_angle(offset_angle + TAU * float(i) / float(count)) * speed, kind)


func active_count() -> int:
	var n := 0
	for s in pool:
		if s.alive:
			n += 1
	return n


## Remove e retorna true se algum projétil encostou na nave.
func hit_ship(ship_pos: Vector2, ship_radius: float) -> bool:
	for s in pool:
		if s.alive and s.pos.distance_squared_to(ship_pos) < pow(s.radius + ship_radius, 2.0):
			s.alive = false
			return true
	return false


func clear() -> void:
	for s in pool:
		s.alive = false
	queue_redraw()


func update(dt: float) -> void:
	for s in pool:
		if not s.alive:
			continue
		s.pos += s.vel * dt
		s.t += dt
		if s.pos.y > view_size.y + 40.0 or s.pos.y < -200.0 or s.pos.x < -40.0 or s.pos.x > view_size.x + 40.0:
			s.alive = false
	queue_redraw()


func _get_free() -> Shot:
	for s in pool:
		if not s.alive:
			return s
	var ns := Shot.new()
	pool.append(ns)
	return ns


func _draw() -> void:
	for s in pool:
		if not s.alive:
			continue
		if s.kind == Kind.ORB:
			draw_circle(s.pos, s.radius * 1.7, Color(Palette.ENEMY, 0.25))
			draw_circle(s.pos, s.radius, Palette.ENEMY_HDR)
			draw_circle(s.pos, s.radius * 0.45, Palette.WHITE_HDR)
		elif s.kind == Kind.ROCK:
			# Pedra girando, com contorno de perigo em brasa.
			var rock := PackedVector2Array()
			for v: Vector2 in ROCK_SHAPE:
				rock.append(s.pos + v.rotated(s.t * 4.0) * s.radius)
			draw_colored_polygon(rock, Color(0.42, 0.33, 0.3))
			draw_polyline(rock + PackedVector2Array([rock[0]]), Palette.ENEMY_HDR, 3.0, true)
		else:
			var dir := s.vel.normalized()
			var side := dir.orthogonal()
			var r := s.radius
			var diamond := PackedVector2Array([s.pos + dir * r * 1.6, s.pos + side * r * 0.8,
					s.pos - dir * r * 1.2, s.pos - side * r * 0.8])
			draw_colored_polygon(diamond, Palette.ENEMY_HDR)
			draw_polyline(diamond + PackedVector2Array([diamond[0]]), Color(Palette.ENEMY, 0.35), 8.0, true)
