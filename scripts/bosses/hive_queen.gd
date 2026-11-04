class_name HiveQueen
extends Boss
## RAINHA DA COLMEIA — chefe do Setor 6 (PLANO_V3.md, Setor 6).
##
## Ponto fraco: o CORAÇÃO no centro do tórax (tiros que sobem pela cabeça, na faixa dele,
## o alcançam). O resto do corpo é carapaça (ricochete).
## Fase 1:
##   - Chuva de ácido: 2 colunas avisadas; depois cai uma cortina de gotas em cada uma.
##   - Postura: bota 2 ovos que descem devagar. Destrua antes de eclodirem: cada ovo
##     destruído vira um orbe de escudo; ovo que eclode solta 3 insetos.
## Fase 2 (50%): o enxame forma um ESCUDO VIVO — 8 guardas giram em volta dela. Tiros
##   batem nos guardas; abra uma brecha embaixo dela para acertar o coração. Guardas mortos
##   voltam aos poucos. Ácido em 3 colunas.

const NAME := "RAINHA DA COLMEIA"
const MAX_HP := 190

const SPRITE_SIZE := 360.0
const CORE_RADIUS := 40.0
## Colisão do corpo: abdômen (em cima), tórax (centro) e cabeça (embaixo). Conferido nos pixels.
const BODIES := [[Vector2(0, -88), 78.0], [Vector2(0, 0), 86.0], [Vector2(0, 100), 46.0]]
const LANE_DEPTH := 150.0          # faixa do coração: da cabeça até o tórax
const ENTER_TIME := 3.0
const REST_Y_RATIO := 0.32  # escudo vivo da fase 2 fica abaixo da barra de vida
const SWAY := 0.18

const ACID_INTERVAL := [0.0, 4.2, 3.4]
const ACID_TELEGRAPH := 1.0
const ACID_SLOTS := 7               # a tela é dividida em 7 faixas; colunas nunca vizinhas
const ACID_COLUMNS := [0, 2, 3]
const ACID_SPEED := 1100.0
const ACID_ROWS := 6
const ACID_ROW_GAP := 120.0

const EGG_INTERVAL := [0.0, 6.0, 5.0]
const EGG_FALL := 40.0              # px/s além da rolagem (ovo do chefe desce devagar)

const GUARDS := 8
const GUARD_RADIUS := 26.0
const GUARD_HP := 2
const GUARD_RING := 210.0
const GUARD_SPIN := 0.9             # rad/s
const GUARD_RESPAWN := 2.5          # s para um guarda morto voltar

const TRANSITION_TIME := 1.4
const DYING_TIME := 2.4

var center := Vector2.ZERO
var enemies: EnemyLayer             # onde os ovos nascem (o Main liga)

var _guards: Array[Dictionary] = []  # fase 2: {hp, alive, flash}
var _last_guard := -1
var _guard_spin := 0.0
var _respawn_timer := 0.0
var _acid_timer := 2.0
var _acid_pending := -1.0
var _acid_cols: Array[int] = []
var _egg_timer := 3.5
var _boom_timer := 0.0


func _init() -> void:
	display_name = NAME
	max_hp = MAX_HP


func _enter() -> void:
	center = Vector2(view_size.x * 0.5, -SPRITE_SIZE * 0.5)
	_set_state(State.ENTERING)


# ---------------------------------------------------------------- comportamento

func _update_boss(dt: float, ship_pos: Vector2) -> void:
	_guard_spin += GUARD_SPIN * dt
	for g in _guards:
		g.flash = maxf(0.0, g.flash - dt)
	match state:
		State.ENTERING:
			center.y = lerpf(-SPRITE_SIZE * 0.5, _rest_y(), smoothstep(0.0, 1.0, _state_t / ENTER_TIME))
			if _state_t >= ENTER_TIME:
				_set_state(State.FIGHT)
		State.FIGHT:
			center.x = view_size.x * 0.5 + sin(_t * 0.5) * view_size.x * SWAY
			center.y = _rest_y() + sin(_t * 1.3) * 12.0
			_update_acid(dt, ship_pos)
			_update_eggs(dt)
			_update_guards(dt)
		State.TRANSITION:
			center.x += sin(_t * 60.0) * 2.5
			if int(_state_t * 20.0) % 3 == 0:
				fx.burst(center + Vector2.from_angle(randf() * TAU) * 150.0, Color(1.6, 1.3, 0.3), 4, 260.0, 0.4, 5.0)
			if _state_t >= TRANSITION_TIME:
				phase = 2
				_guards.clear()
				for i in GUARDS:
					_guards.append({"hp": GUARD_HP, "alive": true, "flash": 0.0})
				_acid_timer = 2.0
				_egg_timer = 3.0
				impact.call(18.0)
				Sfx.play("level_down", -2.0, 0.7, 0.0)
				_set_state(State.FIGHT)
				phase_changed.emit(2)
		State.DYING:
			_update_dying(dt)


func _update_acid(dt: float, ship_pos: Vector2) -> void:
	if _acid_pending >= 0.0:
		_acid_pending -= dt
		if _acid_pending < 0.0:
			var slot_w := view_size.x / ACID_SLOTS
			for col in _acid_cols:
				var x0 := col * slot_w
				for row in ACID_ROWS:
					for k in 3:
						var x := x0 + slot_w * (0.2 + 0.3 * k)
						shots.fire(Vector2(x, -30.0 - row * ACID_ROW_GAP), Vector2(0, ACID_SPEED),
								EnemyBulletLayer.Kind.ACID)
			Sfx.play("explosion", -10.0, 1.8, 0.0, center)
		return
	_acid_timer -= dt
	if _acid_timer > 0.0:
		return
	_acid_timer = ACID_INTERVAL[phase]
	_acid_cols = pick_acid_slots(ACID_COLUMNS[phase], int(ship_pos.x / (view_size.x / ACID_SLOTS)))
	var slot_w := view_size.x / ACID_SLOTS
	for col in _acid_cols:
		telegraph.column(col * slot_w, (col + 1) * slot_w, ACID_TELEGRAPH)
	_acid_pending = ACID_TELEGRAPH
	Sfx.play("alarm", -10.0, 0.8, 0.0, center)


## Escolhe `count` faixas sem nenhuma vizinha (sempre sobra espaço entre colunas);
## a 1ª tenta cair onde a nave está (pressão), as outras são sorteadas.
static func pick_acid_slots(count: int, ship_slot: int) -> Array[int]:
	var cols: Array[int] = []
	var options: Array[int] = []
	for i in ACID_SLOTS:
		options.append(i)
	options.shuffle()
	if randf() < 0.6:
		options.push_front(clampi(ship_slot, 0, ACID_SLOTS - 1))
	for c in options:
		if cols.size() >= count:
			break
		if c in cols or (c - 1) in cols or (c + 1) in cols:
			continue
		cols.append(c)
	return cols


func _update_eggs(dt: float) -> void:
	_egg_timer -= dt
	if _egg_timer > 0.0 or enemies == null:
		return
	_egg_timer = EGG_INTERVAL[phase]
	for side: float in [-1.0, 1.0]:
		var p := center + Vector2(side * 120.0, 40.0)
		enemies.spawn_egg(p, EGG_FALL)
	Sfx.play("hit", -6.0, 0.5, 0.0, center)


func _update_guards(dt: float) -> void:
	if phase < 2:
		return
	_respawn_timer -= dt
	if _respawn_timer <= 0.0:
		_respawn_timer = GUARD_RESPAWN
		for g in _guards:
			if not g.alive:
				g.alive = true
				g.hp = GUARD_HP
				break


func _on_damaged() -> void:
	if phase == 1 and hp <= max_hp / 2:
		_set_state(State.TRANSITION)
		_acid_pending = -1.0
		impact.call(12.0)
		Sfx.duck(-6.0)


## Tiro num guarda tira vida do guarda, não da Rainha.
func damage(amount: int) -> void:
	if _last_guard >= 0:
		var g := _guards[_last_guard]
		var p := _guard_pos(_last_guard)
		_last_guard = -1
		if not g.alive or state != State.FIGHT:
			return
		g.hp -= amount
		g.flash = 0.06
		if g.hp <= 0:
			g.alive = false
			fx.explosion(p, 40.0, Palette.ENEMY_HDR)
			Sfx.play("hit", -6.0, 1.5, 0.0, p)
		return
	super.damage(amount)


func _update_dying(dt: float) -> void:
	_boom_timer -= dt
	if _boom_timer <= 0.0:
		_boom_timer = 0.15
		var body: Array = BODIES[randi() % BODIES.size()]
		var p: Vector2 = center + (body[0] as Vector2) + Vector2.from_angle(randf() * TAU) * randf() * float(body[1])
		fx.explosion(p, randf_range(60.0, 110.0), Color(1.6, 1.3, 0.3) if randf() < 0.5 else Palette.BLAST_HDR)
		Sfx.play("explosion", -2.0, randf_range(0.7, 1.0), 0.0, p)
		impact.call(10.0)
	if _state_t >= DYING_TIME:
		fx.explosion(center, 220.0, Color(1.6, 1.3, 0.3))
		Sfx.play("death", 0.0, 0.8, 0.0, center)
		impact.call(35.0)
		_set_state(State.DONE)
		visible = false
		defeated.emit()


# ---------------------------------------------------------------- colisão

func hit_bullet(p: Vector2) -> Hit:
	_last_guard = -1
	if state == State.DONE:
		return Hit.NONE
	for i in _guards.size():
		if _guards[i].alive and p.distance_squared_to(_guard_pos(i)) < pow(GUARD_RADIUS + 8.0, 2.0):
			_last_guard = i
			return Hit.CORE if is_vulnerable() else Hit.ARMOR
	var in_core := p.distance_to(center) < CORE_RADIUS
	var core_lane := absf(p.x - center.x) < CORE_RADIUS and p.y > center.y and p.y < center.y + LANE_DEPTH
	if in_core or core_lane:
		return Hit.CORE if is_vulnerable() else Hit.ARMOR
	for body in BODIES:
		if p.distance_to(center + (body[0] as Vector2)) < float(body[1]):
			return Hit.ARMOR
	return Hit.NONE


func touches(p: Vector2, radius: float) -> bool:
	if state == State.DONE:
		return false
	for body in BODIES:
		if p.distance_to(center + (body[0] as Vector2)) < float(body[1]) + radius:
			return true
	for i in _guards.size():
		if _guards[i].alive and p.distance_to(_guard_pos(i)) < GUARD_RADIUS + radius:
			return true
	return false


func _guard_pos(i: int) -> Vector2:
	return center + Vector2.from_angle(_guard_spin + TAU * i / GUARDS) * GUARD_RING


func alive_guards() -> int:
	var n := 0
	for g in _guards:
		if g.alive:
			n += 1
	return n


func aim_x() -> float:
	return center.x


func _rest_y() -> float:
	return view_size.y * REST_Y_RATIO


# ---------------------------------------------------------------- rota segura

## Menor espaço livre entre colunas de ácido (faixas nunca vizinhas = pelo menos 1 faixa livre).
static func acid_min_gap(view_w: float) -> float:
	return view_w / ACID_SLOTS


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var art := Game.art
	var pulse := 0.85 + 0.15 * sin(_t * 7.0)
	var tint := Color(1.6, 1.5, 1.2) if _flash > 0.0 else Color.WHITE
	if state == State.TRANSITION and int(_state_t * 12.0) % 2 == 0:
		tint = Color(1.8, 1.5, 0.6)
	if art.hive_queen_body != null:
		var half := SPRITE_SIZE * 0.5
		draw_texture_rect(art.hive_queen_body, Rect2(center - Vector2(half, half), Vector2(SPRITE_SIZE, SPRITE_SIZE)),
				false, tint)

	# Coração: pulsa como um órgão.
	draw_circle(center, CORE_RADIUS * 1.5, Color(Palette.ENEMY, 0.22))
	draw_circle(center, CORE_RADIUS * pulse, Palette.BLAST_HDR)
	draw_circle(center, CORE_RADIUS * 0.4, Palette.WHITE_HDR)

	# Guardas (fase 2): insetos maiores girando em volta.
	for i in _guards.size():
		if not _guards[i].alive:
			continue
		var p := _guard_pos(i)
		var r := GUARD_RADIUS
		var flap := absf(sin(_t * 26.0 + i))
		for side: float in [-1.0, 1.0]:
			draw_colored_polygon(PackedVector2Array([p + Vector2(side * r * 0.3, -r * 0.2),
					p + Vector2(side * r * (1.3 + 0.4 * flap), -r * (0.9 - 0.5 * flap)),
					p + Vector2(side * r * 1.4, r * 0.1)]), Color(0.8, 0.95, 0.7, 0.35))
		draw_circle(p, r, Palette.WHITE_HDR if _guards[i].flash > 0.0 else Color(0.55, 0.36, 0.06))
		draw_arc(p, r, 0.0, TAU, 24, Palette.ENEMY_HDR, 3.0, true)
		draw_circle(p + Vector2(0, r * 0.4), r * 0.25, Palette.ENEMY_HDR)
