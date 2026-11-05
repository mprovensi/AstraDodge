class_name Medusa
extends Boss
## MEDUSA — chefe do Setor 3 (PLANO_V2.md, Setor 3).
##
## Ponto fraco: o NÚCLEO no centro da cúpula (tiros que sobem na faixa dele o alcançam).
## Fase 1:
##   - Chicotada: um tentáculo atravessa a tela de cima para baixo com UMA brecha.
##     Aviso em colunas antes (igual ao paredão). Fique na brecha.
##   - Espiral: solta tiros lentos girando a partir do núcleo (2 braços).
## Fase 2 (50%): o núcleo ganha um ESCUDO. Para tirá-lo, destrua os 3 NÓDULOS brilhantes
##   nas pontas dos tentáculos. Depois o núcleo volta a levar dano. Espiral com 3 braços,
##   chicotadas mais frequentes.

const NAME := "MEDUSA"
const MAX_HP := 200

const SPRITE_SIZE := 380.0
const CORE_RADIUS := 46.0
# Colisão da cúpula (o desenho é uma cúpula, não um círculo): círculo grande em cima e
# dois menores nas laterais de baixo. Conferido contra os pixels no teste automático.
const DOME_BODIES := [[Vector2(0, -47), 108.0], [Vector2(-95, 12), 52.0], [Vector2(95, 12), 52.0]]
const ENTER_TIME := 3.0
const REST_Y_RATIO := 0.27
const SWAY := 0.18

const TENTACLE_BASES := [Vector2(-71, 47), Vector2(0, 52), Vector2(71, 47)]
const TENTACLE_LEN := 190.0
const TENTACLE_SEGMENTS := 10
const NODE_RADIUS := 34.0
const NODE_HP := 20

const SWEEP_INTERVAL := [0.0, 5.5, 4.5]
const SWEEP_TELEGRAPH := 1.1
const SWEEP_SPEED := 650.0
const SWEEP_HALF_H := 34.0             # meia-altura da faixa do tentáculo
const SWEEP_GAP := 300.0               # largura da brecha

const SPIRAL_INTERVAL := [0.0, 4.2, 3.4]
const SPIRAL_TIME := 2.4
const SPIRAL_RATE := 0.14              # s entre rajadas
const SPIRAL_STEP := 0.42              # giro (rad) por rajada
const SPIRAL_SPEED := [0.0, 220.0, 250.0]
const SPIRAL_ARMS := [0, 2, 3]

const TRANSITION_TIME := 1.4
const DYING_TIME := 2.4

var center := Vector2.ZERO

var _nodes: Array[Dictionary] = []  # fase 2: {hp, alive, flash}
var _last_node := -1                 # nódulo atingido pelo último hit_bullet (-1 = núcleo)
var _sweep := {}                     # {y, gap_x, t} enquanto a chicotada acontece
var _sweep_timer := 2.5
var _spiral_timer := 4.5
var _spiral_t := -1.0
var _spiral_angle := 0.0
var _spiral_fire := 0.0
var _boom_timer := 0.0


func _init() -> void:
	display_name = NAME
	max_hp = MAX_HP


func _enter() -> void:
	center = Vector2(view_size.x * 0.5, -SPRITE_SIZE * 0.5)
	_set_state(State.ENTERING)


# ---------------------------------------------------------------- comportamento

func _update_boss(dt: float, _ship_pos: Vector2) -> void:
	for n in _nodes:
		n.flash = maxf(0.0, n.flash - dt)
	match state:
		State.ENTERING:
			center.y = lerpf(-SPRITE_SIZE * 0.5, _rest_y(), smoothstep(0.0, 1.0, _state_t / ENTER_TIME))
			if _state_t >= ENTER_TIME:
				_set_state(State.FIGHT)
		State.FIGHT:
			center.x = view_size.x * 0.5 + sin(_t * 0.45) * view_size.x * SWAY
			center.y = _rest_y() + sin(_t * 1.1) * 12.0
			_update_sweep(dt)
			_update_spiral(dt)
		State.TRANSITION:
			center.x += sin(_t * 60.0) * 2.5
			if int(_state_t * 20.0) % 3 == 0:
				fx.burst(center + Vector2.from_angle(randf() * TAU) * 120.0, Palette.ION_HDR, 4, 260.0, 0.4, 5.0)
			if _state_t >= TRANSITION_TIME:
				phase = 2
				_nodes.clear()
				for i in TENTACLE_BASES.size():
					_nodes.append({"hp": NODE_HP, "alive": true, "flash": 0.0})
				_sweep_timer = 2.0
				_spiral_timer = 3.0
				impact.call(18.0)
				Sfx.play("level_down", -2.0, 0.7, 0.0)
				_set_state(State.FIGHT)
				phase_changed.emit(2)
		State.DYING:
			_update_dying(dt)


func _update_sweep(dt: float) -> void:
	if not _sweep.is_empty():
		_sweep.t += dt
		if _sweep.t >= SWEEP_TELEGRAPH:
			if _sweep.t - dt < SWEEP_TELEGRAPH:
				Sfx.play("shield_hit", -4.0, 0.7, 0.0, center)
				impact.call(6.0)
			_sweep.y += SWEEP_SPEED * dt
			if _sweep.y > view_size.y + 60.0:
				_sweep = {}
		return
	_sweep_timer -= dt
	if _sweep_timer <= 0.0 and _spiral_t < 0.0:
		_sweep_timer = SWEEP_INTERVAL[phase]
		var half_gap := SWEEP_GAP * 0.5
		var gap_x := randf_range(half_gap + 40.0, view_size.x - half_gap - 40.0)
		_sweep = {"y": center.y + 80.0, "gap_x": gap_x, "t": 0.0}
		telegraph.column(0.0, gap_x - half_gap, SWEEP_TELEGRAPH)
		telegraph.column(gap_x + half_gap, view_size.x, SWEEP_TELEGRAPH)
		Sfx.play("alarm", -10.0, 1.1, 0.0, center)


func _update_spiral(dt: float) -> void:
	if _spiral_t >= 0.0:
		_spiral_t += dt
		_spiral_fire -= dt
		if _spiral_fire <= 0.0:
			_spiral_fire = SPIRAL_RATE
			var arms: int = SPIRAL_ARMS[phase]
			for a in arms:
				var ang := _spiral_angle + TAU * a / arms
				shots.fire(center, Vector2.from_angle(ang) * SPIRAL_SPEED[phase], EnemyBulletLayer.Kind.ORB)
			_spiral_angle += SPIRAL_STEP
		if _spiral_t >= SPIRAL_TIME:
			_spiral_t = -1.0
		return
	_spiral_timer -= dt
	if _spiral_timer <= 0.0 and _sweep.is_empty():
		_spiral_timer = SPIRAL_INTERVAL[phase]
		_spiral_t = 0.0
		_spiral_fire = 0.0
		Sfx.play("pickup_shield", -6.0, 0.5, 0.0, center)


func _on_damaged() -> void:
	if phase == 1 and hp <= max_hp / 2:
		_set_state(State.TRANSITION)
		_spiral_t = -1.0
		impact.call(12.0)
		Sfx.duck(-6.0)


## Fase 2: tiro num nódulo tira vida do nódulo, não do chefe.
func damage(amount: float) -> void:
	if _last_node >= 0:
		var idx := _last_node
		var n := _nodes[idx]
		_last_node = -1
		if not n.alive or state != State.FIGHT:
			return
		n.hp -= amount
		n.flash = 0.06
		if n.hp <= 0:
			n.alive = false
			var p := _node_pos(idx)
			fx.explosion(p, 70.0, Palette.ION_HDR)
			Sfx.play("explosion", -3.0, 1.2, 0.0, p)
			impact.call(10.0)
			if _alive_nodes() == 0:
				Sfx.play("level_up", -4.0, 0.8, 0.0)  # escudo do núcleo caiu
		return
	if phase == 2 and _alive_nodes() > 0:
		return  # núcleo protegido pelo escudo
	super.damage(amount)


func _update_dying(dt: float) -> void:
	_boom_timer -= dt
	if _boom_timer <= 0.0:
		_boom_timer = 0.15
		var p := center + Vector2(randf_range(-150, 150), randf_range(-110, 60))
		fx.explosion(p, randf_range(60.0, 110.0), Palette.ION_HDR if randf() < 0.5 else Palette.BLAST_HDR)
		Sfx.play("explosion", -2.0, randf_range(0.7, 1.0), 0.0, p)
		impact.call(10.0)
	if _state_t >= DYING_TIME:
		fx.explosion(center, 200.0, Palette.ION_HDR)
		Sfx.play("death", 0.0, 0.8, 0.0, center)
		impact.call(35.0)
		_set_state(State.DONE)
		visible = false
		defeated.emit()


# ---------------------------------------------------------------- colisão

func hit_bullet(p: Vector2) -> Hit:
	_last_node = -1
	if state == State.DONE:
		return Hit.NONE
	if phase == 2:
		for i in _nodes.size():
			if _nodes[i].alive and p.distance_squared_to(_node_pos(i)) < NODE_RADIUS * NODE_RADIUS:
				_last_node = i
				return Hit.CORE if is_vulnerable() else Hit.ARMOR
	var in_core := p.distance_squared_to(center) < CORE_RADIUS * CORE_RADIUS
	var core_lane := absf(p.x - center.x) < CORE_RADIUS and p.y > center.y and p.y < center.y + 70.0
	if in_core or core_lane:
		return Hit.CORE if _core_open() else Hit.ARMOR
	for body in DOME_BODIES:
		if p.distance_to(center + (body[0] as Vector2)) < float(body[1]):
			return Hit.ARMOR
	return Hit.NONE


func touches(p: Vector2, radius: float) -> bool:
	if state == State.DONE:
		return false
	for body in DOME_BODIES:
		if p.distance_to(center + (body[0] as Vector2)) < float(body[1]) + radius:
			return true
	return _sweep_hits(p, radius)


## A faixa do tentáculo atinge um círculo (fora da brecha)?
func _sweep_hits(p: Vector2, radius: float) -> bool:
	if _sweep.is_empty() or _sweep.t < SWEEP_TELEGRAPH:
		return false
	if absf(p.y - float(_sweep.y)) > SWEEP_HALF_H + radius * 0.6:
		return false
	return absf(p.x - float(_sweep.gap_x)) > SWEEP_GAP * 0.5 - radius * 0.6


func aim_x() -> float:
	if phase == 2:
		for i in _nodes.size():
			if _nodes[i].alive:
				return _node_pos(i).x
	return center.x


func _core_open() -> bool:
	return is_vulnerable() and (phase == 1 or _alive_nodes() == 0)


func _alive_nodes() -> int:
	var n := 0
	for node in _nodes:
		if node.alive:
			n += 1
	return n


## Pontos do tentáculo i (da base à ponta), ondulando.
func _tentacle_points(i: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var base: Vector2 = center + (TENTACLE_BASES[i] as Vector2)
	for s in TENTACLE_SEGMENTS + 1:
		var k := float(s) / TENTACLE_SEGMENTS
		var wave := sin(_t * 2.2 + i * 1.7 - k * 4.0) * 26.0 * k
		pts.append(base + Vector2(wave + (i - 1) * 30.0 * k, TENTACLE_LEN * k))
	return pts


func _node_pos(i: int) -> Vector2:
	var pts := _tentacle_points(i)
	return pts[pts.size() - 1]


func _rest_y() -> float:
	return view_size.y * REST_Y_RATIO


# ---------------------------------------------------------------- rota segura

## Largura da brecha da chicotada (sempre a mesma; cabe a nave com folga?).
static func sweep_gap() -> float:
	return SWEEP_GAP


## Menor vão entre tiros vizinhos da espiral a `distance` px do núcleo.
static func spiral_min_gap(distance: float) -> float:
	# Entre rajadas a espiral gira SPIRAL_STEP; entre braços, TAU/braços. O menor manda.
	var step := minf(SPIRAL_STEP, TAU / 3.0)
	return 2.0 * distance * sin(step * 0.5) - 2.0 * 14.0


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var art := Game.art
	var pulse := 0.85 + 0.15 * sin(_t * 7.0)

	# Tentáculos (atrás da cúpula): linhas brilhantes que ondulam; nódulos na ponta (fase 2).
	for i in TENTACLE_BASES.size():
		var pts := _tentacle_points(i)
		draw_polyline(pts, Color(Palette.ION, 0.35), 16.0, true)
		draw_polyline(pts, Palette.ION_HDR * 0.8, 5.0, true)
		if phase == 2 and i < _nodes.size():
			var tip := pts[pts.size() - 1]
			if _nodes[i].alive:
				var c: Color = Palette.WHITE_HDR if _nodes[i].flash > 0.0 else Palette.BLAST_HDR
				draw_circle(tip, NODE_RADIUS * 1.5, Color(Palette.ENEMY, 0.2))
				draw_circle(tip, NODE_RADIUS * pulse, c)
			else:
				draw_circle(tip, NODE_RADIUS * 0.5, Color(0.25, 0.1, 0.3))

	var tint := Color(1.6, 1.5, 1.8) if _flash > 0.0 else Color.WHITE
	if state == State.TRANSITION and int(_state_t * 12.0) % 2 == 0:
		tint = Color(1.4, 0.9, 1.8)
	if art.medusa_body != null:
		var half := SPRITE_SIZE * 0.5
		draw_texture_rect(art.medusa_body, Rect2(center - Vector2(half, half), Vector2(SPRITE_SIZE, SPRITE_SIZE)),
				false, tint)

	# Núcleo: aberto (brilha laranja) ou com escudo (bolha violeta) na fase 2.
	if _core_open() or state == State.ENTERING:
		draw_circle(center, CORE_RADIUS * 1.5, Color(Palette.ENEMY, 0.22))
		draw_circle(center, CORE_RADIUS * pulse, Palette.BLAST_HDR)
		draw_circle(center, CORE_RADIUS * 0.4, Palette.WHITE_HDR)
	else:
		draw_circle(center, CORE_RADIUS * 0.7, Color(0.5, 0.25, 0.2))
		draw_arc(center, CORE_RADIUS * 1.05, 0.0, TAU, 40, Palette.ION_HDR, 5.0, true)
		draw_arc(center, CORE_RADIUS * 1.25, _t * 2.0, _t * 2.0 + PI, 24, Color(Palette.ION, 0.6), 3.0, true)

	# Chicotada: faixa ondulada atravessando a tela, com a brecha.
	if not _sweep.is_empty() and _sweep.t >= SWEEP_TELEGRAPH:
		var y: float = _sweep.y
		var half_gap := SWEEP_GAP * 0.5
		for side in 2:
			var x0: float = 0.0 if side == 0 else float(_sweep.gap_x) + half_gap
			var x1: float = float(_sweep.gap_x) - half_gap if side == 0 else view_size.x
			var band := PackedVector2Array()
			var x := x0
			while x <= x1:
				band.append(Vector2(x, y + sin(x * 0.03 + _t * 12.0) * 10.0))
				x += 24.0
			band.append(Vector2(x1, y))
			if band.size() >= 2:
				draw_polyline(band, Color(Palette.ION, 0.4), SWEEP_HALF_H * 2.0, true)
				draw_polyline(band, Palette.ION_HDR, 8.0, true)
