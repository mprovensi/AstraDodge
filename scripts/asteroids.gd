class_name AsteroidField
extends Node2D
## Asteroides e spawner em "linhas". Cada linha mantém um corredor livre de metálicos,
## e o corredor se desloca pouco entre linhas, garantindo sempre um caminho possível.

signal row_spawned(gap_x: float)  ## uma linha nova entrou (o Main usa para nuvens/minas)
signal formation_spawned(id: String)

enum Kind { DUST, METAL }

# Texturas e o quanto a rocha ocupa da imagem vêm do ArtSet ativo (Game.art):
# a imagem é desenhada um pouco maior que o raio de colisão para o desenho casar com ele.

class Asteroid:
	var id := 0
	var kind := 0
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO  # velocidade própria, somada à rolagem do mundo
	var radius := 50.0
	var hp := 1.0
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
	var ice := false           # gelo (Setor 5): ao quebrar racha em lascas
	var material := AsteroidLook.ROCK  # guardado ao nascer: não muda com o bioma do Infinito
	var sliding := false       # parede móvel (Setor 7): desliza em volta de slide_base
	var slide_base := 0.0
	var slide_phase := 0.0
	var ported := false        # já passou por um portal (Setor 8): não teleporta de novo
	var wall := 0              # paredão/parede a que pertence (0 = peça solta): cabos e luzes
	var look := 0              # visual do setor em que nasceu (ArtSet.sector_looks)
	var spin_rate := 0.0       # giro 3D (voltas por segundo) das rochas com folha de quadros
	var spin_phase := 0.0
	var alive := true
	var formation := false     # conjunto rígido: tiro e portal não fecham sua rota

var asteroids: Array[Asteroid] = []
var dust_spawned := 0  # poeiras criadas (para a estrela de "70% da poeira")
var view_size := Vector2.ZERO

# Controlados pelo modo de jogo (campanha: SectorDirector; infinito: padrão).
var spawn_enabled := true
var metals_enabled := true
var density := 1.0
var formations := 0.0
var dust_rain := false
var moving_metals := 0.0   # chance de uma linha trazer um metálico com propulsor (Setor 2+)
var armored := 0.0         # chance de cada poeira vir blindada (Setor 2+)
var ice := 0.0             # chance de cada poeira ser de gelo (Setor 5)
var inverted := false      # INVERSÃO (Setor 8): rochas vêm de baixo e sobem
var look := 0              # setor cujo visual as rochas novas usam (o Main troca com o cenário)

var _next_id := 0
var _distance_to_next_row := 0.0
var _gap_x := 0.0
var _slide_t := 0.0  # relógio das paredes móveis
var _wall_id := 0    # numeração dos paredões (Asteroid.wall)


func resize(size: Vector2) -> void:
	view_size = size


func reset() -> void:
	asteroids.clear()
	_distance_to_next_row = Tuning.FIRST_ROW_DISTANCE
	_gap_x = view_size.x * 0.5
	spawn_enabled = true
	metals_enabled = true
	density = 1.0
	formations = 0.0
	dust_rain = false
	moving_metals = 0.0
	armored = 0.0
	ice = 0.0
	inverted = false
	dust_spawned = 0
	queue_redraw()

func update(dt: float, scroll_speed: float, difficulty: float) -> void:
	# Na inversão as rochas sobem (mais devagar) e as linhas novas nascem embaixo.
	var flow := -scroll_speed * Tuning.INVERT_SPEED_K if inverted else scroll_speed
	if spawn_enabled:
		_distance_to_next_row -= absf(flow) * dt
		if _distance_to_next_row <= 0.0:
			var made_formation := false
			if formations > 0.0 and not dust_rain and randf() < formations:
				var choices := Formations.available(look)
				made_formation = spawn_formation(choices[randi_range(0, choices.size() - 1)], difficulty)
			if not made_formation:
				_spawn_row(difficulty)
				var spacing := lerpf(Tuning.ROW_SPACING_START, Tuning.ROW_SPACING_END, difficulty)
				_distance_to_next_row += spacing / (density * (Tuning.DUST_RAIN_DENSITY if dust_rain else 1.0))

	_slide_t += dt
	for a in asteroids:
		a.pos += (Vector2(a.vel.x, a.vel.y + flow) + a.knock) * dt
		if a.sliding:
			# Parede móvel: todos os blocos da fileira deslizam juntos, a brecha vai e volta.
			a.pos.x = a.slide_base + Tuning.SLIDE_AMP * sin(TAU * _slide_t / Tuning.SLIDE_PERIOD + a.slide_phase)
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
		if a.pos.y - a.radius > view_size.y + (300.0 if inverted else 0.0) or (inverted and a.pos.y + a.radius < -60.0):
			a.alive = false

	for i in range(asteroids.size() - 1, -1, -1):
		if not asteroids[i].alive:
			asteroids.remove_at(i)
	queue_redraw()


## Primeiro asteroide vivo que contém o ponto (ignorando os ids em `exclude`).
## Primeiro asteroide vivo que o TRAJETO do tiro neste quadro (de `from` até `p`) cruza.
## Testar o caminho inteiro (e não só o ponto final) impede o tiro de "pular" a rocha quando
## o quadro é longo (celular lento: o tiro anda 70+ px por quadro).
func hit_test(p: Vector2, exclude: Dictionary = {}, from: Variant = null) -> Asteroid:
	var a0: Vector2 = p if from == null else from
	for a in asteroids:
		if a.alive and not exclude.has(a.id) \
				and Geometry2D.get_closest_point_to_segment(a.pos, a0, p).distance_squared_to(a.pos) < a.radius * a.radius:
			return a
	return null


## Tiro na casca da poeira blindada. Retorna true se a casca acabou de quebrar.
func hit_shell(a: Asteroid) -> bool:
	a.shell -= 1
	a.flash = 0.08
	return a.shell <= 0


## Retorna true se o asteroide foi destruído.
func damage(a: Asteroid, amount: float) -> bool:
	a.hp -= amount
	a.flash = 0.08
	if a.hp <= 0:
		a.alive = false
		return true
	return false


## Feedback de impacto: recuo na direção do tiro, encolhida e piscada.
func impact(a: Asteroid, shot_dir: Vector2) -> void:
	var strength := Tuning.HIT_KNOCKBACK_METAL if a.kind == Kind.METAL else Tuning.HIT_KNOCKBACK_DUST
	if not a.formation:
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
	_wall_id += 1
	while x <= view_size.x:
		if absf(x - _gap_x) >= half_gap + r:
			_add(Kind.METAL, Vector2(x, -r), r, 1, Vector2(0.0, extra)).wall = _wall_id
		x += r * 2.0 + 6.0
	# Espaço livre depois do paredão antes da próxima linha.
	_distance_to_next_row = maxf(_distance_to_next_row, Tuning.ROW_SPACING_START)


## Próxima parede do CORREDOR: a brecha anda pouco em relação à anterior (sempre dá para seguir).
func spawn_corridor_wall() -> void:
	var half_gap := Tuning.SAFE_GAP_WIDTH * 0.5
	_gap_x = clampf(_gap_x + randf_range(-Tuning.CORRIDOR_SHIFT, Tuning.CORRIDOR_SHIFT),
			half_gap + 20.0, view_size.x - half_gap - 20.0)
	spawn_wall(false)


## PAREDE MÓVEL (Setor 7): fileira de metálicos mais larga que a tela, com uma brecha, que
## desliza de um lado para o outro enquanto desce. A brecha fica sempre dentro da tela.
func spawn_sliding_wall() -> void:
	var half_gap := Tuning.SAFE_GAP_WIDTH * 0.5
	var r := Tuning.WALL_METAL_RADIUS
	var amp := Tuning.SLIDE_AMP
	# Centro da brecha no meio do movimento: o vaivém nunca a leva para fora da tela.
	var gap := clampf(_gap_x, half_gap + amp + 20.0, view_size.x - half_gap - amp - 20.0)
	var phase := randf() * TAU
	_wall_id += 1
	var x := gap - half_gap - r
	while x > -amp - r:
		_add_slider(x, r, phase)
		x -= r * 2.0 + 6.0
	x = gap + half_gap + r
	while x < view_size.x + amp + r:
		_add_slider(x, r, phase)
		x += r * 2.0 + 6.0
	_distance_to_next_row = maxf(_distance_to_next_row, Tuning.ROW_SPACING_START)


func _add_slider(x: float, r: float, phase: float) -> void:
	var a := _add(Kind.METAL, Vector2(x, -r), r, 1, Vector2.ZERO)
	a.sliding = true
	a.wall = _wall_id
	a.slide_base = x
	a.slide_phase = phase
	a.rot_speed = 0.0


func clear_around(center: Vector2, radius: float) -> void:
	for a in asteroids:
		if a.pos.distance_to(center) < radius + a.radius:
			a.alive = false


func _spawn_row(difficulty: float) -> void:
	var first := asteroids.size()
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
		var roll := randf()
		var size := 1  # M é o tamanho mais comum; P e G dão variedade sem dominar a tela.
		if roll < Tuning.DUST_SMALL_CHANCE:
			size = 0
		elif roll >= 1.0 - Tuning.DUST_LARGE_CHANCE:
			size = 2
		var radii: Vector2 = Tuning.DUST_RADIUS_RANGES[size]
		var speeds: Vector2 = Tuning.DUST_SPEED_RANGES[size]
		var r := randf_range(radii.x, radii.y)
		for attempt in 10:
			var p := Vector2(randf_range(r, w - r), -r - randf_range(0.0, 220.0))
			if _overlaps(placed, p, r):
				continue
			placed.append(Vector3(p.x, p.y, r))
			var vel := Vector2(randf_range(-40.0, 40.0), randf_range(speeds.x, speeds.y))
			_add_field_dust(p, r, vel, difficulty)
			break
	if inverted:
		# Inversão: a linha nasce espelhada embaixo da tela e sobe. Perigos do topo (minas,
		# nuvens...) não acompanham, então o sinal da linha não é emitido.
		for i in range(first, asteroids.size()):
			var a := asteroids[i]
			a.pos.y = view_size.y - a.pos.y
			a.vel.y = -a.vel.y
		return
	row_spawned.emit(_gap_x)


## Peças da formação compartilham velocidade; não emite row_spawned (perigos não tapam a rota).
func spawn_formation(id: String, difficulty := 0.0) -> bool:
	if asteroids.any(func(a: Asteroid) -> bool: return a.alive and (a.formation or a.wall > 0)):
		return false
	var layout := Formations.make(id, view_size.x, _gap_x)
	if layout == null or layout.pieces.is_empty():
		return false
	for piece in layout.pieces:
		var pos := Vector2(piece.pos.x, -Formations.LEAD - piece.pos.y)
		var velocity := Vector2(0, 60.0 if id == "rain" else 0.0)
		if inverted:
			pos.y = view_size.y - pos.y
			velocity.y = -velocity.y
		var a: Asteroid
		if piece.metal and metals_enabled:
			a = _add(Kind.METAL, pos, piece.radius, 1, velocity)
		else:
			a = _add_field_dust(pos, piece.radius, velocity, difficulty)
		a.formation = true
	_gap_x = layout.route[-1].x
	_distance_to_next_row = maxf(_distance_to_next_row, layout.depth + Formations.LEAD + Tuning.ROW_SPACING_START)
	formation_spawned.emit(id)
	queue_redraw()
	return true


## Mesmas regras de vida, gelo, armadura e material nas fileiras e formações.
func _add_field_dust(pos: Vector2, radius: float, velocity: Vector2, difficulty: float) -> Asteroid:
	var size := 0 if radius <= Tuning.DUST_RADIUS_RANGES[0].y else (1 if radius <= Tuning.DUST_RADIUS_RANGES[1].y else 2)
	var health: Vector2i = Tuning.DUST_HP_RANGES[size]
	var max_hp := health.x + roundi((health.y - health.x) * clampf(difficulty, 0.0, 1.0))
	var a := _add(Kind.DUST, pos, radius, randi_range(health.x, max_hp), velocity)
	if randf() < ice:
		a.ice = true
	elif randf() < armored:
		a.shell = Tuning.ARMOR_SHELL_HITS
	if not a.ice:
		a.material = Game.art.dust_material(a.look, a.sprite)
	return a


func _overlaps(placed: Array[Vector3], p: Vector2, r: float) -> bool:
	for o in placed:
		if p.distance_to(Vector2(o.x, o.y)) < r + o.z + 12.0:
			return true
	return false


## Solta uma poeira avulsa (ex.: o chefe soltando pedaços).
func spawn_dust(pos: Vector2, radius: float, hp: int, vel: Vector2, is_ice := false) -> void:
	var a := _add(Kind.DUST, pos, radius, hp, vel)
	a.ice = is_ice


## Gelo quebrado (Setor 5): racha em lascas menores que saem em diagonal, para os lados.
## Retorna quantas lascas criou (0 se o gelo era pequeno demais para rachar).
func split_ice(a: Asteroid) -> int:
	if not a.ice or a.radius < Tuning.ICE_SPLIT_MIN_RADIUS:
		return 0
	var r := a.radius * Tuning.ICE_SHARD_RADIUS_K
	for i in Tuning.ICE_SHARDS:
		var side := -1.0 if i % 2 == 0 else 1.0
		var vel := Vector2(side * Tuning.ICE_SHARD_SPEED, randf_range(60.0, 120.0))
		var shard := _add(Kind.DUST, a.pos + Vector2(side * r, 0.0), r, 1, vel)
		shard.ice = true  # pequena: não racha de novo
	return Tuning.ICE_SHARDS


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
	a.look = look
	a.spin_rate = randf_range(0.25, 0.6) * (-1.0 if randf() < 0.5 else 1.0)
	a.spin_phase = randf()
	# Índice "livre": cada desenho/folha usa `sprite % quantidade` (2 imagens, 3 folhas...).
	a.sprite = randi() % 60
	a.flip = -1.0 if randf() < 0.5 else 1.0  # espelha metade: mais variedade com 3 desenhos
	asteroids.append(a)
	if kind == Kind.DUST:
		dust_spawned += 1
	return a




func _draw() -> void:
	var art := Game.art
	var walls := wall_links()
	_draw_cables(walls)
	_draw_inverted_trails()
	for a in asteroids:
		var s := 1.0 - Tuning.HIT_PUNCH_SCALE * a.punch
		draw_set_transform(a.pos, a.rot, Vector2(s * a.flip, s))
		var fill := art.metal_fill if a.kind == Kind.METAL else art.dust_fill
		var half := a.radius / fill
		var rect := Rect2(-half, -half, half * 2.0, half * 2.0)
		var textures := _textures(a.kind, a.look)
		if a.ice and not art.ice_textures.is_empty():
			textures = art.ice_textures
		var tex := textures[a.sprite % textures.size()]
		if a.kind == Kind.METAL:
			var tint := Color(1.8, 1.8, 1.8) if a.flash > 0.0 else Color.WHITE
			var junk := art.junk_sheets(a.look)
			if junk.is_empty():
				draw_texture_rect(tex, rect, false, tint)
				_draw_lamp(a, rect)
			else:
				_draw_junk(a, junk, art.junk_lamps(a.look), rect, s, tint)
		else:
			# Mais escura conforme leva dano; pisca branco (HDR) ao ser atingida.
			var dmg := 1.0 - float(a.hp) / float(a.max_hp)
			var tint := Color.WHITE.darkened(dmg * 0.35)
			if a.flash > 0.0 and a.shell <= 0:
				tint = Color(3.0, 3.0, 3.0)
			# Gelo que racha (qualquer setor) usa as rochas de gelo do Setor 5 (as 2 primeiras folhas).
			var sheets := art.dust_sheets(a.look) if not a.ice else art.dust_sheets(4).slice(0, 2)
			if sheets.is_empty():
				draw_texture_rect(tex, rect, false, tint)
			else:
				# Giro 3D: quadro da folha conforme o tempo (cada rocha com ritmo e fase próprios).
				var sheet := sheets[a.sprite % sheets.size()]
				var frame := posmod(int(floor((_slide_t * a.spin_rate + a.spin_phase) * ArtSet.SHEET_FRAMES)), ArtSet.SHEET_FRAMES)
				var fw := sheet.get_width() / ArtSet.SHEET_COLS
				var fh := sheet.get_height() / ArtSet.SHEET_ROWS
				var src := Rect2((frame % ArtSet.SHEET_COLS) * fw, (frame / ArtSet.SHEET_COLS) * fh, fw, fh)
				draw_texture_rect_region(sheet, rect, src, tint)
			_draw_material(a)
			if a.shell > 0 and art.dust_shell_texture != null:
				var shell_tint := Color(1.8, 1.8, 1.8) if a.flash > 0.0 else Color.WHITE
				shell_tint.a = 0.55 + 0.45 * float(a.shell) / float(Tuning.ARMOR_SHELL_HITS)
				draw_texture_rect(art.dust_shell_texture, rect, false, shell_tint)
	draw_set_transform(Vector2.ZERO, 0.0)
	_draw_wall_lights(walls)

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


## Marcas dentro da silhueta: cristais em losango e fissuras vulcânicas. Não alteram colisões.
func _draw_material(a: Asteroid) -> void:
	if a.material == AsteroidLook.CRYSTAL:
		for offset: Vector2 in [Vector2(-0.3, 0.1), Vector2(0.1, -0.3), Vector2(0.35, 0.2)]:
			var p := offset * a.radius
			var r := a.radius * 0.16
			var crystal := PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.65, 0),
					p + Vector2(0, r), p - Vector2(r * 0.65, 0)])
			draw_colored_polygon(crystal, Palette.NEON_HDR)
			draw_line(p + Vector2(0, -r), p, Palette.WHITE_HDR, 2.0, true)
	elif a.material == AsteroidLook.VOLCANIC:
		for angle in [0.0, 2.2, 4.4]:
			var crack := PackedVector2Array()
			for point: Vector2 in [Vector2(0.1, 0), Vector2(0.3, 0.08), Vector2(0.42, -0.04), Vector2(0.65, 0.05)]:
				crack.append(point.rotated(angle) * a.radius)
			draw_polyline(crack, Palette.FLAME_HDR, 3.0, true)


## Peças de cada paredão, em ordem da esquerda para a direita, e onde fica a brecha:
## [{ "pieces": [Asteroid...], "links": [[a, b]...], "edges": [esquerda, direita] }].
## `links` liga só vizinhas encostadas (cabo) — nunca atravessa a brecha. `edges` são as
## duas peças que ladeiam a brecha (luzes de pista); null se a brecha encosta na borda.
func wall_links() -> Array[Dictionary]:
	var groups := {}
	for a in asteroids:
		if a.wall != 0 and a.alive:
			if not groups.has(a.wall):
				groups[a.wall] = []
			groups[a.wall].append(a)
	var out: Array[Dictionary] = []
	for id in groups:
		var list: Array = groups[id]
		list.sort_custom(func(p: Asteroid, q: Asteroid) -> bool: return p.pos.x < q.pos.x)
		var links := []
		var edges := [null, null]
		for i in range(1, list.size()):
			var p: Asteroid = list[i - 1]
			var q: Asteroid = list[i]
			if q.pos.x - p.pos.x <= p.radius + q.radius + 12.0:
				links.append([p, q])
			elif edges[0] == null:
				edges = [p, q]
		out.append({"pieces": list, "links": links, "edges": edges})
	return out


## Cabos entre as peças do paredão: parece uma barreira montada, não blocos soltos.
func _draw_cables(walls: Array[Dictionary]) -> void:
	for w in walls:
		for pair: Array in w["links"]:
			var p: Asteroid = pair[0]
			var q: Asteroid = pair[1]
			for k: float in [-0.35, 0.3]:
				var a := p.pos + Vector2(0, p.radius * k)
				var b := q.pos + Vector2(0, q.radius * k)
				var mid := (a + b) * 0.5 + Vector2(0, 7.0)  # cabo cede um pouco no meio
				var pts := PackedVector2Array([a, a.lerp(mid, 0.5) + Vector2(0, 2.0), mid, b.lerp(mid, 0.5) + Vector2(0, 2.0), b])
				draw_polyline(pts, Color(0.05, 0.055, 0.07), 7.0, true)
				draw_polyline(pts, Color(0.32, 0.35, 0.4), 3.0, true)


## Luzes de pista verdes nas bordas da brecha (piscam em sequência para dentro) e, nas
## paredes móveis, setas âmbar mostrando para que lado a parede está indo.
func _draw_wall_lights(walls: Array[Dictionary]) -> void:
	var simple := Game.graphics_simple()
	for w in walls:
		var edges: Array = w["edges"]
		for side in 2:
			var a: Asteroid = edges[side]
			if a == null:
				continue
			var dir := 1.0 if side == 0 else -1.0  # aponta para dentro da brecha
			for k in 3:
				var on := simple or posmod(int(_slide_t * 6.0) - k, 3) == 0
				var at := a.pos + Vector2(dir * a.radius * 0.95, (k - 1) * a.radius * 0.45)
				draw_circle(at, 9.0, Color(Palette.RUNWAY_HDR, 0.18 if on else 0.06))
				draw_circle(at, 4.5, Color(Palette.RUNWAY_HDR, 1.0 if on else 0.35))
		var first: Asteroid = w["pieces"][0]
		if first.sliding:
			var v := cos(TAU * _slide_t / Tuning.SLIDE_PERIOD + first.slide_phase)
			if absf(v) > 0.15:
				for a: Asteroid in edges:
					if a != null:
						_draw_chevrons(a.pos + Vector2(0, -a.radius - 20.0), signf(v))


func _draw_chevrons(at: Vector2, dir: float) -> void:
	for k in 2:
		var c := at + Vector2(dir * (k * 18.0 - 9.0), 0)
		draw_polyline(PackedVector2Array([c + Vector2(-dir * 7.0, -9.0), c + Vector2(dir * 5.0, 0), c + Vector2(-dir * 7.0, 9.0)]),
				Color(Palette.FLAME_HDR, 0.9), 4.0, true)


## Inversão (Setor 8): rastro magenta fraco embaixo de cada rocha — lê "vem de baixo".
func _draw_inverted_trails() -> void:
	if not inverted:
		return
	for a in asteroids:
		var w := a.radius * 0.6
		var top := a.pos
		var length := a.radius * 1.9
		draw_polygon(PackedVector2Array([top + Vector2(-w, 0), top + Vector2(w, 0), top + Vector2(w * 0.25, length), top + Vector2(-w * 0.25, length)]),
				PackedColorArray([Color(Palette.MAGENTA, 0.13), Color(Palette.MAGENTA, 0.13), Color(Palette.MAGENTA, 0.0), Color(Palette.MAGENTA, 0.0)]))


## Lixo espacial (folha de giro 3D): sem giro no plano nem espelho, para a luz pintada ficar
## sempre de cima à esquerda; a luz âmbar de alerta pisca por cima (só ela brilha).
func _draw_junk(a: Asteroid, sheets: Array[Texture2D], lamps: Array[PackedVector3Array], rect: Rect2, s: float, tint: Color) -> void:
	draw_set_transform(a.pos, 0.0, Vector2(s, s))
	var i := a.sprite % sheets.size()
	var sheet := sheets[i]
	var t := _slide_t * a.spin_rate * 0.5 + a.spin_phase
	var frame := posmod(int(floor(t * ArtSet.JUNK_FRAMES)), ArtSet.JUNK_FRAMES)
	var fw := sheet.get_width() / ArtSet.JUNK_COLS
	var fh := sheet.get_height() / ArtSet.JUNK_ROWS
	var src := Rect2((frame % ArtSet.JUNK_COLS) * fw, (frame / ArtSet.JUNK_COLS) * fh, fw, fh)
	draw_texture_rect_region(sheet, rect, src, tint)
	if i < lamps.size() and frame < lamps[i].size():
		var lamp := lamps[i][frame]
		if lamp.z > 0.05:
			var blink := 0.35 + 0.65 * float(fmod(_slide_t * 1.2 + a.spin_phase, 1.0) < 0.5)
			var at := Vector2(lamp.x, lamp.y) * rect.size.x * 0.5
			var r := rect.size.x * 0.045
			draw_circle(at, r * 2.2, Color(Palette.FLAME_HDR, 0.18 * blink * lamp.z))
			draw_circle(at, r, Color(Palette.FLAME_HDR, blink * lamp.z))


## Luz âmbar do lixo desenhado: ponto fixo na peça (gira junto, transformação já aplicada).
func _draw_lamp(a: Asteroid, rect: Rect2) -> void:
	var look := Game.art.sector_looks[a.look] if a.look < Game.art.sector_looks.size() else null
	if look == null or look.metal_lamps.is_empty():
		return
	var count := look.metal_textures.size()
	var p := look.metal_lamps[(a.sprite % count) % look.metal_lamps.size()]
	var blink := 0.35 + 0.65 * float(fmod(_slide_t * 1.2 + a.spin_phase, 1.0) < 0.5)
	var at := p * rect.size.x * 0.5
	var r := rect.size.x * 0.045
	draw_circle(at, r * 2.2, Color(Palette.FLAME_HDR, 0.18 * blink))
	draw_circle(at, r, Color(Palette.FLAME_HDR, blink))


func _textures(kind: Kind, from_look: int) -> Array[Texture2D]:
	return Game.art.rock_textures(kind == Kind.METAL, from_look)
