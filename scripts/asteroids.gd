class_name AsteroidField
extends Node2D
## Asteroides e spawner em "linhas". Cada linha mantém um corredor livre de metálicos,
## e o corredor se desloca pouco entre linhas, garantindo sempre um caminho possível.

enum Kind { DUST, METAL }

class Asteroid:
	var id := 0
	var kind := 0
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO  # velocidade própria, somada à rolagem do mundo
	var radius := 50.0
	var hp := 1
	var max_hp := 1
	var rot := 0.0
	var rot_speed := 0.0
	var shape := PackedVector2Array()
	var flash := 0.0
	var knock := Vector2.ZERO  # recuo temporário causado pelos tiros
	var punch := 0.0           # 1 logo após o impacto, decai para 0
	var alive := true

var asteroids: Array[Asteroid] = []
var view_size := Vector2.ZERO

var _next_id := 0
var _distance_to_next_row := 0.0
var _gap_x := 0.0


func resize(size: Vector2) -> void:
	view_size = size


func reset() -> void:
	asteroids.clear()
	_distance_to_next_row = Tuning.FIRST_ROW_DISTANCE
	_gap_x = view_size.x * 0.5
	queue_redraw()


func update(dt: float, scroll_speed: float, difficulty: float) -> void:
	_distance_to_next_row -= scroll_speed * dt
	if _distance_to_next_row <= 0.0:
		_spawn_row(difficulty)
		_distance_to_next_row += lerpf(Tuning.ROW_SPACING_START, Tuning.ROW_SPACING_END, difficulty)

	for a in asteroids:
		a.pos += (Vector2(a.vel.x, a.vel.y + scroll_speed) + a.knock) * dt
		a.knock *= exp(-Tuning.HIT_KNOCKBACK_DECAY * dt)
		a.punch = maxf(0.0, a.punch - dt * 8.0)
		a.rot += a.rot_speed * dt
		a.flash = maxf(0.0, a.flash - dt)
		if a.kind == Kind.METAL:
			a.vel.x = move_toward(a.vel.x, 0.0, 120.0 * dt)
		if a.pos.y - a.radius > view_size.y:
			a.alive = false

	for i in range(asteroids.size() - 1, -1, -1):
		if not asteroids[i].alive:
			asteroids.remove_at(i)
	queue_redraw()


## Primeiro asteroide vivo que contém o ponto (ignorando os ids em `exclude`).
func hit_test(p: Vector2, exclude: Dictionary = {}) -> Asteroid:
	for a in asteroids:
		if a.alive and not exclude.has(a.id) and p.distance_squared_to(a.pos) < a.radius * a.radius:
			return a
	return null


## Retorna true se o asteroide foi destruído.
func damage(a: Asteroid, amount: int) -> bool:
	a.hp -= amount
	a.flash = 0.08
	if a.hp <= 0:
		a.alive = false
		return true
	return false


## Feedback de impacto: recuo na direção do tiro, encolhida e piscada.
func impact(a: Asteroid, shot_dir: Vector2) -> void:
	var strength := Tuning.HIT_KNOCKBACK_METAL if a.kind == Kind.METAL else Tuning.HIT_KNOCKBACK_DUST
	a.knock = (a.knock + shot_dir * strength).limit_length(Tuning.HIT_KNOCKBACK_MAX)
	a.punch = 1.0
	a.flash = 0.08


func clear_around(center: Vector2, radius: float) -> void:
	for a in asteroids:
		if a.pos.distance_to(center) < radius + a.radius:
			a.alive = false


func _spawn_row(difficulty: float) -> void:
	var w := view_size.x
	var half_gap := Tuning.SAFE_GAP_WIDTH * 0.5
	_gap_x = clampf(_gap_x + randf_range(-Tuning.SAFE_GAP_MAX_SHIFT, Tuning.SAFE_GAP_MAX_SHIFT),
			half_gap + 20.0, w - half_gap - 20.0)

	var placed: Array[Vector3] = []  # x, y, raio (para evitar sobreposição na linha)

	var metal_count := randi_range(0, 1 + int(round(difficulty * 2.0)))
	for i in metal_count:
		var r := randf_range(70.0, 90.0 + 40.0 * difficulty)
		for attempt in 10:
			var x := randf_range(r, w - r)
			if absf(x - _gap_x) < half_gap + r:
				continue
			var p := Vector2(x, -r - randf_range(0.0, 60.0))
			if _overlaps(placed, p, r):
				continue
			placed.append(Vector3(p.x, p.y, r))
			_add(Kind.METAL, p, r, 1, Vector2.ZERO)
			break

	var dust_count := randi_range(1, 2 + int(difficulty * 2.0))
	for i in dust_count:
		var r := randf_range(40.0, 85.0)
		for attempt in 10:
			var p := Vector2(randf_range(r, w - r), -r - randf_range(0.0, 220.0))
			if _overlaps(placed, p, r):
				continue
			placed.append(Vector3(p.x, p.y, r))
			var hp := clampi(1 + int(r > 65.0) + randi_range(0, int(difficulty * 2.5)), 1, 5)
			var vel := Vector2(randf_range(-40.0, 40.0), randf_range(0.0, 80.0))
			_add(Kind.DUST, p, r, hp, vel)
			break


func _overlaps(placed: Array[Vector3], p: Vector2, r: float) -> bool:
	for o in placed:
		if p.distance_to(Vector2(o.x, o.y)) < r + o.z + 12.0:
			return true
	return false


func _add(kind: Kind, pos: Vector2, radius: float, hp: int, vel: Vector2) -> void:
	var a := Asteroid.new()
	_next_id += 1
	a.id = _next_id
	a.kind = kind
	a.pos = pos
	a.vel = vel
	a.radius = radius
	a.hp = hp
	a.max_hp = hp
	a.rot = randf() * TAU
	a.rot_speed = randf_range(-1.2, 1.2) if kind == Kind.DUST else randf_range(-0.3, 0.3)
	a.shape = _make_shape(radius, kind)
	asteroids.append(a)


func _make_shape(radius: float, kind: Kind) -> PackedVector2Array:
	var points := PackedVector2Array()
	var n := randi_range(9, 13) if kind == Kind.DUST else randi_range(7, 9)
	var jitter := 0.22 if kind == Kind.DUST else 0.1
	for i in n:
		var ang := TAU * float(i) / float(n)
		points.append(Vector2.from_angle(ang) * radius * randf_range(1.0 - jitter, 1.0))
	return points


func _draw() -> void:
	for a in asteroids:
		var s := 1.0 - Tuning.HIT_PUNCH_SCALE * a.punch
		draw_set_transform(a.pos, a.rot, Vector2(s, s))
		var outline := a.shape + PackedVector2Array([a.shape[0]])
		if a.kind == Kind.METAL:
			var line := Palette.METAL_LINE.lerp(Color.WHITE, 0.7) if a.flash > 0.0 else Palette.METAL_LINE
			draw_colored_polygon(a.shape, Palette.METAL_FILL)
			draw_polyline(outline, Color(line, 0.35), 10.0, true)
			draw_polyline(outline, line, 3.0, true)
			# "Placas" metálicas
			draw_line(Vector2(-a.radius * 0.5, -a.radius * 0.2), Vector2(a.radius * 0.5, -a.radius * 0.2), Color(Palette.METAL_LINE, 0.4), 2.0)
			draw_line(Vector2(-a.radius * 0.35, a.radius * 0.3), Vector2(a.radius * 0.4, a.radius * 0.3), Color(Palette.METAL_LINE, 0.4), 2.0)
		else:
			var dmg := 1.0 - float(a.hp) / float(a.max_hp)
			var fill := Palette.DUST_FILL.darkened(dmg * 0.35)
			if a.flash > 0.0:
				fill = Color.WHITE
			draw_colored_polygon(a.shape, fill)
			draw_polyline(outline, Palette.DUST_LINE, 3.0, true)
	draw_set_transform(Vector2.ZERO, 0.0)
