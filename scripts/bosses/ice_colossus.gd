class_name IceColossus
extends Boss
## COLOSSO DE GELO — chefe do Setor 5 (PLANO_V3.md, Setor 5).
##
## Ponto fraco: o NÚCLEO no centro do bloco de gelo. Em volta, um ANEL de placas de gelo
## gira devagar: tiro que bate numa placa ricocheteia (armadura). Só passa pelas FENDAS
## entre as placas — quando uma fenda gira para baixo do núcleo, os tiros entram.
## Fase 1:
##   - Estacas: leque de estacas de gelo (aviso em círculo) que RACHAM em duas no meio do caminho.
##   - Avalanche: solta 2 blocos de gelo pelos lados (atire neles: rendem orbes e cristais).
## Fase 2 (50%): as placas se afastam e giram mais rápido (a fenda passa mais vezes, mas
##   por menos tempo); leque com 4 estacas; avalanches mais frequentes.

const NAME := "COLOSSO DE GELO"
const MAX_HP := 150

const SPRITE_SIZE := 300.0
const BODY_RADIUS := 128.0         # colisão do corpo (círculo, conferido contra os pixels)
const CORE_RADIUS := 44.0
const ENTER_TIME := 3.0
const REST_Y_RATIO := 0.3  # anel da fase 2 fica abaixo da barra de vida
const SWAY := 0.16

const PLATES := 5
const PLATE_ARC := deg_to_rad(36.0)  # cada placa cobre 36°; fendas também de 36°
const PLATE_THICK := 34.0
const RING_RADIUS := [0.0, 172.0, 215.0]
const SPIN := [0.0, 0.6, 1.0]         # rad/s

const SHARD_INTERVAL := [0.0, 3.3, 2.9]
const SHARD_TELEGRAPH := 0.8
const SHARD_SPEED := 300.0
const SHARD_SPLIT_AFTER := 0.5         # s até a estaca rachar (bem acima da nave)
const SHARD_FANS := [[], [60.0, 90.0, 120.0], [50.0, 76.0, 104.0, 130.0]]  # direções (graus, 90 = para baixo)
const SHARD_SPLIT_DEG := [0.0, 14.0, 10.0]

const AVALANCHE_INTERVAL := [0.0, 6.5, 5.0]
const AVALANCHE_RADIUS := 62.0
const AVALANCHE_HP := 3

const TRANSITION_TIME := 1.4
const DYING_TIME := 2.4

var center := Vector2.ZERO

var _spin := 0.0          # ângulo atual do anel
var _ring_r := 172.0      # raio atual do anel (anima na transição)
var _shard_timer := 2.0
var _shard_pending := -1.0  # > = 0: leque avisado, dispara quando chegar a 0
var _avalanche_timer := 4.0
var _boom_timer := 0.0


func _init() -> void:
	display_name = NAME
	max_hp = MAX_HP


func _enter() -> void:
	center = Vector2(view_size.x * 0.5, -SPRITE_SIZE)
	_ring_r = RING_RADIUS[1]
	_set_state(State.ENTERING)


# ---------------------------------------------------------------- comportamento

func _update_boss(dt: float, _ship_pos: Vector2) -> void:
	_spin += SPIN[maxi(phase, 1)] * dt
	_ring_r = move_toward(_ring_r, RING_RADIUS[phase], 60.0 * dt)
	match state:
		State.ENTERING:
			center.y = lerpf(-SPRITE_SIZE, _rest_y(), smoothstep(0.0, 1.0, _state_t / ENTER_TIME))
			if _state_t >= ENTER_TIME:
				_set_state(State.FIGHT)
		State.FIGHT:
			center.x = view_size.x * 0.5 + sin(_t * 0.4) * view_size.x * SWAY
			center.y = _rest_y() + sin(_t * 0.9) * 10.0
			_update_shards(dt)
			_update_avalanche(dt)
		State.TRANSITION:
			center.x += sin(_t * 60.0) * 2.5
			if int(_state_t * 20.0) % 3 == 0:
				fx.burst(center + Vector2.from_angle(randf() * TAU) * 140.0, Color(1.6, 2.0, 2.4), 4, 260.0, 0.4, 5.0)
			if _state_t >= TRANSITION_TIME:
				phase = 2
				_shard_timer = 2.0
				_avalanche_timer = 3.0
				impact.call(18.0)
				Sfx.play("level_down", -2.0, 0.8, 0.0)
				_set_state(State.FIGHT)
				phase_changed.emit(2)
		State.DYING:
			_update_dying(dt)


func _update_shards(dt: float) -> void:
	if _shard_pending >= 0.0:
		_shard_pending -= dt
		if _shard_pending < 0.0:
			for deg: float in SHARD_FANS[phase]:
				var dir := Vector2.from_angle(deg_to_rad(deg))
				shots.fire_splitting(center + dir * BODY_RADIUS, dir * SHARD_SPEED, SHARD_SPLIT_AFTER,
						SHARD_SPLIT_DEG[phase])
			Sfx.play("ricochet", -4.0, 1.6, 0.0, center)
			impact.call(5.0)
		return
	_shard_timer -= dt
	if _shard_timer <= 0.0:
		_shard_timer = SHARD_INTERVAL[phase]
		_shard_pending = SHARD_TELEGRAPH
		telegraph.circle(center + Vector2(0, BODY_RADIUS), 70.0, SHARD_TELEGRAPH)
		Sfx.play("alarm", -10.0, 1.4, 0.0, center)


func _update_avalanche(dt: float) -> void:
	_avalanche_timer -= dt
	if _avalanche_timer > 0.0:
		return
	_avalanche_timer = AVALANCHE_INTERVAL[phase]
	for side: float in [-1.0, 1.0]:
		var p := center + Vector2(side * (_ring_r + 40.0), 60.0)
		p.x = clampf(p.x, AVALANCHE_RADIUS, view_size.x - AVALANCHE_RADIUS)
		asteroids.spawn_dust(p, AVALANCHE_RADIUS, AVALANCHE_HP, Vector2(side * 40.0, 60.0), true)
	Sfx.play("explosion", -8.0, 1.5, 0.0, center)


func _on_damaged() -> void:
	if phase == 1 and hp <= max_hp / 2:
		_set_state(State.TRANSITION)
		_shard_pending = -1.0
		impact.call(12.0)
		Sfx.duck(-6.0)


func _update_dying(dt: float) -> void:
	_boom_timer -= dt
	if _boom_timer <= 0.0:
		_boom_timer = 0.15
		var p := center + Vector2.from_angle(randf() * TAU) * randf_range(0.0, _ring_r)
		fx.explosion(p, randf_range(60.0, 110.0), Color(1.6, 2.0, 2.4) if randf() < 0.6 else Palette.BLAST_HDR)
		Sfx.play("explosion", -2.0, randf_range(0.8, 1.1), 0.0, p)
		impact.call(10.0)
	if _state_t >= DYING_TIME:
		fx.explosion(center, 220.0, Color(1.6, 2.0, 2.4))
		Sfx.play("death", 0.0, 0.9, 0.0, center)
		impact.call(35.0)
		_set_state(State.DONE)
		visible = false
		defeated.emit()


# ---------------------------------------------------------------- colisão

func hit_bullet(p: Vector2) -> Hit:
	if state == State.DONE:
		return Hit.NONE
	# Margem: o tiro anda ~37 px por quadro, mais que a espessura da placa (não "atravessa").
	if _on_plate(p, 8.0):
		return Hit.ARMOR  # ricochete na placa de gelo
	var d := p.distance_to(center)
	var in_core := d < CORE_RADIUS
	# Tiros que sobem na faixa do núcleo atravessam o gelo até ele (o núcleo brilha por dentro).
	var core_lane := absf(p.x - center.x) < CORE_RADIUS and p.y > center.y and p.y < center.y + BODY_RADIUS
	if in_core or core_lane:
		return Hit.CORE if is_vulnerable() else Hit.ARMOR
	if d < BODY_RADIUS:
		return Hit.ARMOR
	return Hit.NONE


func touches(p: Vector2, radius: float) -> bool:
	if state == State.DONE:
		return false
	return p.distance_to(center) < BODY_RADIUS + radius or _on_plate(p, radius)


## O círculo (p, radius) encosta numa placa do anel?
func _on_plate(p: Vector2, radius: float) -> bool:
	var rel := p - center
	if absf(rel.length() - _ring_r) > PLATE_THICK * 0.5 + radius:
		return false
	var margin := asin(clampf(radius / _ring_r, 0.0, 1.0))
	var ang := rel.angle()
	for i in PLATES:
		var mid := _plate_angle(i)
		if absf(angle_difference(ang, mid)) < PLATE_ARC * 0.5 + margin:
			return true
	return false


func _plate_angle(i: int) -> float:
	return _spin + TAU * i / PLATES


## Tem fenda embaixo do núcleo agora (os tiros entram)?
func gap_below() -> bool:
	return not _on_plate(center + Vector2(0, _ring_r), 0.0)


func aim_x() -> float:
	return center.x


func _rest_y() -> float:
	return view_size.y * REST_Y_RATIO


# ---------------------------------------------------------------- rota segura

## Menor vão (px) entre as estacas (já rachadas) numa faixa de alturas da nave.
## Logo depois de rachar as duas metades ainda estão se separando (vão estreito, mas é
## perto do chefe); por isso a faixa testada é a zona onde a nave fica (60%–92% da tela).
## Simula a geometria: estaca sai da borda do corpo, racha depois de SHARD_SPLIT_AFTER.
static func shard_min_gap(boss_phase: int, from_y: float, to_y: float) -> float:
	var worst := INF
	var y := from_y
	while y <= to_y:
		var xs: Array[float] = []
		for deg: float in SHARD_FANS[boss_phase]:
			var dir := Vector2.from_angle(deg_to_rad(deg))
			var split := dir * (BODY_RADIUS + SHARD_SPEED * SHARD_SPLIT_AFTER)
			for side: float in [-1.0, 1.0]:
				var d2 := dir.rotated(deg_to_rad(SHARD_SPLIT_DEG[boss_phase]) * side)
				if y < split.y:
					continue
				xs.append(split.x + d2.x * (y - split.y) / d2.y)
		xs.sort()
		# Estacas encostadas viram um bloco só; o que conta é o vão entre blocos vizinhos.
		var blocks: Array[Vector2] = []
		for x in xs:
			if blocks.is_empty() or x - EnemyBulletLayer.ICE_RADIUS > blocks[-1].y:
				blocks.append(Vector2(x - EnemyBulletLayer.ICE_RADIUS, x + EnemyBulletLayer.ICE_RADIUS))
			else:
				blocks[-1].y = maxf(blocks[-1].y, x + EnemyBulletLayer.ICE_RADIUS)
		for i in range(1, blocks.size()):
			worst = minf(worst, blocks[i].x - blocks[i - 1].y)
		y += 20.0
	return worst


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var art := Game.art
	var pulse := 0.85 + 0.15 * sin(_t * 7.0)
	var tint := Color(1.6, 1.7, 1.9) if _flash > 0.0 else Color.WHITE
	if state == State.TRANSITION and int(_state_t * 12.0) % 2 == 0:
		tint = Color(1.4, 1.8, 2.2)
	if art.ice_colossus_body != null:
		var half := SPRITE_SIZE * 0.5
		draw_texture_rect(art.ice_colossus_body, Rect2(center - Vector2(half, half), Vector2(SPRITE_SIZE, SPRITE_SIZE)),
				false, tint)

	# Núcleo frio e brilhante; fica mais forte quando há fenda embaixo (hora de atirar).
	var open := gap_below() and is_vulnerable()
	if open:
		_weak_glow(center, CORE_RADIUS)
	else:
		draw_circle(center, CORE_RADIUS * 1.5, Color(Palette.ENEMY, 0.1 * pulse))

	# Anel de placas de gelo: lâminas de gelo (arte) ao longo do arco; sem a arte, faixa em arco.
	var blade := art.boss_part("ice_blade")
	if blade != null:
		for i in PLATES:
			var mid := _plate_angle(i)
			var at := center + Vector2.from_angle(mid) * _ring_r
			# A lâmina é comprida na vertical: deitada ao longo do arco (tangente).
			_draw_part(blade, at, _ring_r * PLATE_ARC * 1.15, mid, tint)
		return
	for i in PLATES:
		var mid := _plate_angle(i)
		var a0 := mid - PLATE_ARC * 0.5
		var pts := PackedVector2Array()
		var steps := 8
		for s in steps + 1:
			pts.append(center + Vector2.from_angle(a0 + PLATE_ARC * s / steps) * (_ring_r + PLATE_THICK * 0.5))
		for s in range(steps, -1, -1):
			pts.append(center + Vector2.from_angle(a0 + PLATE_ARC * s / steps) * (_ring_r - PLATE_THICK * 0.5))
		draw_colored_polygon(pts, Color(0.55, 0.8, 0.98, 0.9))
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1.6, 2.0, 2.4), 3.0, true)
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(Palette.ENEMY, 0.35), 8.0, true)
