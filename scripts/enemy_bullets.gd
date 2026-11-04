class_name EnemyBulletLayer
extends Node2D
## Pool de projéteis inimigos com padrões reutilizáveis (mirado, leque, anel).
## Cada tipo tem forma própria — nunca diferenciar só pela cor.

enum Kind { ORB, DIAMOND, ROCK, CHUNK, ICE }

const ROCK_RADIUS := 18.0
const CHUNK_RADIUS := 55.0  # pedaço de metal arremessado pelo Minerador
const ICE_RADIUS := 13.0    # estaca de gelo do Colosso (pode rachar em duas no meio do caminho)
## Contorno da pedra (unitário; escalado pelo raio e girando).
const ROCK_SHAPE := [Vector2(1.0, 0.0), Vector2(0.55, 0.8), Vector2(-0.2, 0.95), Vector2(-0.85, 0.45),
		Vector2(-0.9, -0.35), Vector2(-0.3, -0.9), Vector2(0.5, -0.8)]

class Shot:
	var kind := 0
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var radius := 14.0
	var t := 0.0
	var split_at := -1.0     # ICE: s até rachar em duas (-1 = não racha)
	var split_deg := 0.0     # ICE: abertura de cada metade em relação à direção atual
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
		Kind.CHUNK:
			s.radius = CHUNK_RADIUS
		Kind.ICE:
			s.radius = ICE_RADIUS
	s.t = 0.0
	s.split_at = -1.0
	s.alive = true


## Estaca de gelo que racha em duas depois de `after` s, abrindo ±`deg` graus.
func fire_splitting(pos: Vector2, vel: Vector2, after: float, deg: float) -> void:
	fire(pos, vel, Kind.ICE)
	var s := pool[_last]
	s.split_at = after
	s.split_deg = deg


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
	var splits: Array[Shot] = []
	for s in pool:
		if not s.alive:
			continue
		s.pos += s.vel * dt
		s.t += dt
		if s.split_at >= 0.0 and s.t >= s.split_at:
			splits.append(s)
		if s.pos.y > view_size.y + 40.0 or s.pos.y < -200.0 or s.pos.x < -40.0 or s.pos.x > view_size.x + 40.0:
			s.alive = false
	# Racha depois do laço (fire() reaproveita tiros mortos do pool).
	for s in splits:
		if not s.alive:
			continue
		var at := s.pos
		var vel := s.vel
		var spread := deg_to_rad(s.split_deg)
		s.alive = false  # (o fire() abaixo pode reaproveitar este mesmo tiro)
		for side: float in [-1.0, 1.0]:
			fire(at, vel.rotated(spread * side), Kind.ICE)
	queue_redraw()


var _last := 0  # índice no pool do último tiro criado


func _get_free() -> Shot:
	for i in pool.size():
		if not pool[i].alive:
			_last = i
			return pool[i]
	var ns := Shot.new()
	pool.append(ns)
	_last = pool.size() - 1
	return ns


func _draw() -> void:
	for s in pool:
		if not s.alive:
			continue
		if s.kind == Kind.ORB:
			draw_circle(s.pos, s.radius * 1.7, Color(Palette.ENEMY, 0.25))
			draw_circle(s.pos, s.radius, Palette.ENEMY_HDR)
			draw_circle(s.pos, s.radius * 0.45, Palette.WHITE_HDR)
		elif s.kind == Kind.CHUNK:
			# Bloco metálico girando, com aura de perigo.
			var tex: Texture2D = Game.art.metal_textures[0] if not Game.art.metal_textures.is_empty() else null
			draw_circle(s.pos, s.radius * 1.15, Color(Palette.ENEMY, 0.25))
			if tex != null:
				draw_set_transform(s.pos, s.t * 5.0)
				draw_texture_rect(tex, Rect2(-s.radius, -s.radius, s.radius * 2.0, s.radius * 2.0), false)
				draw_set_transform(Vector2.ZERO, 0.0)
			draw_arc(s.pos, s.radius * 1.1, 0.0, TAU, 32, Palette.ENEMY_HDR, 4.0, true)
		elif s.kind == Kind.ICE:
			# Estaca de gelo: cristal comprido, branco-gelo, contorno de perigo.
			var dir := s.vel.normalized()
			var side := dir.orthogonal()
			var r := s.radius
			var shard := PackedVector2Array([s.pos + dir * r * 2.2, s.pos + side * r * 0.7,
					s.pos - dir * r * 1.6, s.pos - side * r * 0.7])
			draw_colored_polygon(shard, Color(1.8, 2.2, 2.6))
			draw_polyline(shard + PackedVector2Array([shard[0]]), Palette.ENEMY_HDR, 3.0, true)
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
