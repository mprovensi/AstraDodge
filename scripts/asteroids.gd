class_name AsteroidField
extends Node2D
## Asteroides e spawner em "linhas". Cada linha mantém um corredor livre de metálicos,
## e o corredor se desloca pouco entre linhas, garantindo sempre um caminho possível.

signal row_spawned(gap_x: float)  ## uma linha nova entrou (o Main usa para nuvens/minas)

enum Kind { DUST, METAL }

# Texturas e o quanto a rocha ocupa da imagem vêm do ArtSet ativo (Game.art):
# a imagem é desenhada um pouco maior que o raio de colisão para o desenho casar com ele.

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
	var sprite := 0    # qual dos desenhos (dust_N / metal_N)
	var flip := 1.0    # -1 = espelhado
	var flash := 0.0
	var knock := Vector2.ZERO  # recuo temporário causado pelos tiros
	var punch := 0.0           # 1 logo após o impacto, decai para 0
	var shell := 0             # poeira blindada: tiros que a casca ainda aguenta
	var drift := 0.0           # metálico com propulsor: velocidade lateral (quica nas bordas)
	var alive := true

var asteroids: Array[Asteroid] = []
var dust_spawned := 0  # poeiras criadas (para a estrela de "70% da poeira")
var view_size := Vector2.ZERO

# Controlados pelo modo de jogo (campanha: SectorDirector; infinito: padrão).
var spawn_enabled := true
var metals_enabled := true
var density := 1.0
var dust_rain := false
var moving_metals := 0.0   # chance de uma linha trazer um metálico com propulsor (Setor 2+)
var armored := 0.0         # chance de cada poeira vir blindada (Setor 2+)

var _next_id := 0
var _distance_to_next_row := 0.0
var _gap_x := 0.0


func resize(size: Vector2) -> void:
	view_size = size


func reset() -> void:
	asteroids.clear()
	_distance_to_next_row = Tuning.FIRST_ROW_DISTANCE
	_gap_x = view_size.x * 0.5
	spawn_enabled = true
	metals_enabled = true
	density = 1.0
	dust_rain = false
	moving_metals = 0.0
	armored = 0.0
	dust_spawned = 0
	queue_redraw()


func update(dt: float, scroll_speed: float, difficulty: float) -> void:
	if spawn_enabled:
		_distance_to_next_row -= scroll_speed * dt
		if _distance_to_next_row <= 0.0:
			_spawn_row(difficulty)
			var spacing := lerpf(Tuning.ROW_SPACING_START, Tuning.ROW_SPACING_END, difficulty)
			_distance_to_next_row += spacing / (density * (Tuning.DUST_RAIN_DENSITY if dust_rain else 1.0))

	for a in asteroids:
		a.pos += (Vector2(a.vel.x, a.vel.y + scroll_speed) + a.knock) * dt
		a.knock *= exp(-Tuning.HIT_KNOCKBACK_DECAY * dt)
		a.punch = maxf(0.0, a.punch - dt * 8.0)
		a.rot += a.rot_speed * dt
		a.flash = maxf(0.0, a.flash - dt)
		if a.kind == Kind.METAL:
			a.vel.x = move_toward(a.vel.x, 0.0, 120.0 * dt)
		if a.drift != 0.0:
			a.pos.x += a.drift * dt
			if (a.pos.x < a.radius and a.drift < 0.0) or (a.pos.x > view_size.x - a.radius and a.drift > 0.0):
				a.drift = -a.drift  # quica na borda
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


## Tiro na casca da poeira blindada. Retorna true se a casca acabou de quebrar.
func hit_shell(a: Asteroid) -> bool:
	a.shell -= 1
	a.flash = 0.08
	return a.shell <= 0


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


## Faixas horizontais (x0, x1) que o próximo paredão vai bloquear — para o aviso.
func wall_spans() -> Array[Vector2]:
	var half_gap := Tuning.SAFE_GAP_WIDTH * 0.5
	return [Vector2(0.0, _gap_x - half_gap), Vector2(_gap_x + half_gap, view_size.x)]


## Fileira de metálicos cobrindo a largura toda, exceto o corredor atual.
## `fast`: paredão avisado (cai rápido). Paredes de corredor descem com a rolagem.
func spawn_wall(fast := true) -> void:
	var half_gap := Tuning.SAFE_GAP_WIDTH * 0.5
	var r := Tuning.WALL_METAL_RADIUS
	var x := r
	var extra := Tuning.WALL_EXTRA_SPEED if fast else 0.0
	while x <= view_size.x:
		if absf(x - _gap_x) >= half_gap + r:
			_add(Kind.METAL, Vector2(x, -r), r, 1, Vector2(0.0, extra))
		x += r * 2.0 + 6.0
	# Espaço livre depois do paredão antes da próxima linha.
	_distance_to_next_row = maxf(_distance_to_next_row, Tuning.ROW_SPACING_START)


## Próxima parede do CORREDOR: a brecha anda pouco em relação à anterior (sempre dá para seguir).
func spawn_corridor_wall() -> void:
	var half_gap := Tuning.SAFE_GAP_WIDTH * 0.5
	_gap_x = clampf(_gap_x + randf_range(-Tuning.CORRIDOR_SHIFT, Tuning.CORRIDOR_SHIFT),
			half_gap + 20.0, view_size.x - half_gap - 20.0)
	spawn_wall(false)


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
	if not metals_enabled or dust_rain:
		metal_count = 0
	# Linha com metálico de propulsor: ele é o ÚNICO metálico da linha (atravessa a tela
	# de lado, então o resto da linha fica livre para desviar dele).
	if metal_count > 0 and randf() < moving_metals:
		var r := randf_range(70.0, 85.0)
		var p := Vector2(randf_range(r, w - r), -r)
		placed.append(Vector3(p.x, p.y, r))
		var a := _add(Kind.METAL, p, r, 1, Vector2.ZERO)
		a.drift = randf_range(Tuning.MOVING_METAL_SPEED_MIN, Tuning.MOVING_METAL_SPEED_MAX) * (-1.0 if randf() < 0.5 else 1.0)
		a.rot_speed = 0.0
		metal_count = 0
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

	var dust_count := randi_range(1, 2 + int(difficulty * 2.0)) + (2 if dust_rain else 0)
	for i in dust_count:
		var r := randf_range(40.0, 85.0)
		for attempt in 10:
			var p := Vector2(randf_range(r, w - r), -r - randf_range(0.0, 220.0))
			if _overlaps(placed, p, r):
				continue
			placed.append(Vector3(p.x, p.y, r))
			var hp := clampi(1 + int(r > 65.0) + randi_range(0, int(difficulty * 2.5)), 1, 5)
			var vel := Vector2(randf_range(-40.0, 40.0), randf_range(0.0, 80.0))
			var a := _add(Kind.DUST, p, r, hp, vel)
			if randf() < armored:
				a.shell = Tuning.ARMOR_SHELL_HITS
			break
	row_spawned.emit(_gap_x)


func _overlaps(placed: Array[Vector3], p: Vector2, r: float) -> bool:
	for o in placed:
		if p.distance_to(Vector2(o.x, o.y)) < r + o.z + 12.0:
			return true
	return false


## Solta uma poeira avulsa (ex.: o chefe soltando pedaços).
func spawn_dust(pos: Vector2, radius: float, hp: int, vel: Vector2) -> void:
	_add(Kind.DUST, pos, radius, hp, vel)


func _add(kind: Kind, pos: Vector2, radius: float, hp: int, vel: Vector2) -> Asteroid:
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
	a.sprite = randi() % maxi(1, _textures(kind).size())
	a.flip = -1.0 if randf() < 0.5 else 1.0  # espelha metade: mais variedade com 3 desenhos
	asteroids.append(a)
	if kind == Kind.DUST:
		dust_spawned += 1
	return a


func _textures(kind: Kind) -> Array[Texture2D]:
	return Game.art.dust_textures if kind == Kind.DUST else Game.art.metal_textures


func _draw() -> void:
	var art := Game.art
	for a in asteroids:
		var s := 1.0 - Tuning.HIT_PUNCH_SCALE * a.punch
		draw_set_transform(a.pos, a.rot, Vector2(s * a.flip, s))
		var fill := art.metal_fill if a.kind == Kind.METAL else art.dust_fill
		var half := a.radius / fill
		var rect := Rect2(-half, -half, half * 2.0, half * 2.0)
		var textures := _textures(a.kind)
		var tex := textures[a.sprite % textures.size()]
		if a.kind == Kind.METAL:
			var tint := Color(1.8, 1.8, 1.8) if a.flash > 0.0 else Color.WHITE
			draw_texture_rect(tex, rect, false, tint)
		else:
			# Mais escura conforme leva dano; pisca branco (HDR) ao ser atingida.
			var dmg := 1.0 - float(a.hp) / float(a.max_hp)
			var tint := Color.WHITE.darkened(dmg * 0.35)
			if a.flash > 0.0 and a.shell <= 0:
				tint = Color(3.0, 3.0, 3.0)
			draw_texture_rect(tex, rect, false, tint)
			if a.shell > 0 and art.dust_shell_texture != null:
				var shell_tint := Color(1.8, 1.8, 1.8) if a.flash > 0.0 else Color.WHITE
				shell_tint.a = 0.55 + 0.45 * float(a.shell) / float(Tuning.ARMOR_SHELL_HITS)
				draw_texture_rect(art.dust_shell_texture, rect, false, shell_tint)
	draw_set_transform(Vector2.ZERO, 0.0)

	# Propulsores dos metálicos móveis: chama do lado oposto ao movimento (lê-se "vai para lá").
	for a in asteroids:
		if a.drift == 0.0:
			continue
		var back := -signf(a.drift)
		var base := a.pos + Vector2(back * a.radius * 0.95, 0.0)
		var flick := 0.75 + 0.25 * sin(Time.get_ticks_msec() * 0.04 + a.id)
		var flame := PackedVector2Array([base + Vector2(0, -12), base + Vector2(0, 12),
				base + Vector2(back * 46.0 * flick, 0)])
		draw_colored_polygon(flame, Color(Palette.FLAME_HDR, 0.9))
