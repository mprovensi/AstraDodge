class_name Sentinel
extends Boss
## SENTINELA — chefe do Setor 7 (PLANO_V3.md, Setor 7): a IA da estação, presa ao teto.
##
## Ponto fraco: o OLHO no centro (tiros que sobem na faixa dele o alcançam).
## Fase 1:
##   - Braços: 2 canhões nas laterais que brilham e atiram mirado. Dá para destruí-los...
##   - ...mas DRONES DE REPARO saem do corpo e consertam o braço destruído. Derrube o drone
##     no caminho (prioridade!) para o braço continuar quebrado.
##   - Grade de laser: colunas e linhas avisadas; depois o feixe liga. Fique numa "célula".
## Fase 2 (50%): a arena FECHA — paredes de energia avançam pelas laterais (avisadas) e a
##   área útil fica estreita por alguns segundos; grade com mais linhas.

const NAME := "SENTINELA"
const MAX_HP := 170

const SPRITE_SIZE := 560.0
const BODY_RADIUS := 140.0
const CORE_RADIUS := 42.0
const ENTER_TIME := 3.0
const REST_Y_RATIO := 0.27
const SWAY := 0.08

const ARMS := [Vector2(-250, 60), Vector2(250, 60)]
const ARM_RADIUS := 46.0
const ARM_ART_AXIS := 0.88  # rad: na arte, o braço vai do suporte (em cima, à esquerda) ao cano (embaixo, à direita)
const ARM_HP := 28
const ARM_FIRE := [0.0, 2.2, 1.8]
const ARM_CHARGE := 0.5
const ARM_SHOT_SPEED := 360.0

const REPAIR_DELAY := 2.5        # s depois do braço cair até o drone sair
const DRONE_SPEED := 120.0
const DRONE_RADIUS := 24.0
const DRONE_HP := 3

const GRID_INTERVAL := [0.0, 5.5, 4.5]
const GRID_TELEGRAPH := 1.2
const GRID_ACTIVE := 0.7
const GRID_WIDTH := 50.0         # largura de cada feixe
const GRID_COLUMNS := [0, 3, 4]
const GRID_ROWS := [0, 1, 2]
const GRID_MIN_SPACING := 230.0  # distância mínima entre feixes paralelos (centro a centro)

const WALL_INTERVAL := 9.0
const WALL_TELEGRAPH := 1.2
const WALL_ACTIVE := 4.0
const WALL_DEPTH := 260.0        # quanto cada parede avança (sobra o meio da tela)

const TRANSITION_TIME := 1.4
const DYING_TIME := 2.4

var center := Vector2.ZERO

var _arms: Array[Dictionary] = []    # {hp, alive, flash, fire, down_t}
var _drones: Array[Dictionary] = []  # {pos, arm, hp, flash}
var _last_target := -1               # 0..1 = braço, 10+ = drone (índice + 10), -1 = olho
var _ship := Vector2.ZERO
var _grid_timer := 3.0
var _grid_t := -1.0                  # >= 0: grade avisada/ativa
var _grid_cols: Array[float] = []
var _grid_rows: Array[float] = []
var _wall_timer := 4.0
var _wall_t := -1.0
var _boom_timer := 0.0


func _init() -> void:
	display_name = NAME
	max_hp = MAX_HP


func _enter() -> void:
	center = Vector2(view_size.x * 0.5, -SPRITE_SIZE * 0.5)
	_arms.clear()
	for i in ARMS.size():
		_arms.append({"hp": ARM_HP, "alive": true, "flash": 0.0, "fire": 1.5 + i * 1.1, "down_t": 0.0})
	_set_state(State.ENTERING)


# ---------------------------------------------------------------- comportamento

func _update_boss(dt: float, ship_pos: Vector2) -> void:
	_ship = ship_pos
	for a in _arms:
		a.flash = maxf(0.0, a.flash - dt)
	for d in _drones:
		d.flash = maxf(0.0, d.flash - dt)
	match state:
		State.ENTERING:
			center.y = lerpf(-SPRITE_SIZE * 0.5, _rest_y(), smoothstep(0.0, 1.0, _state_t / ENTER_TIME))
			if _state_t >= ENTER_TIME:
				_set_state(State.FIGHT)
		State.FIGHT:
			center.x = view_size.x * 0.5 + sin(_t * 0.5) * view_size.x * SWAY
			center.y = _rest_y() + sin(_t * 1.0) * 8.0
			_update_arms(dt)
			_update_drones(dt)
			_update_grid(dt)
			if phase == 2:
				_update_walls(dt)
		State.TRANSITION:
			center.x += sin(_t * 60.0) * 2.5
			if int(_state_t * 20.0) % 3 == 0:
				fx.burst(center + Vector2.from_angle(randf() * TAU) * 150.0, Palette.DANGER_HDR, 4, 260.0, 0.4, 5.0)
			if _state_t >= TRANSITION_TIME:
				phase = 2
				_grid_timer = 2.5
				_wall_timer = 1.5
				impact.call(18.0)
				Sfx.play("level_down", -2.0, 0.7, 0.0)
				_set_state(State.FIGHT)
				phase_changed.emit(2)
		State.DYING:
			_update_dying(dt)


func _update_arms(dt: float) -> void:
	for i in _arms.size():
		var a := _arms[i]
		if not a.alive:
			a.down_t += dt
			# Depois de um tempo, sai um drone de reparo (só um por braço).
			if a.down_t >= REPAIR_DELAY and not _drone_for(i):
				_drones.append({"pos": center, "arm": i, "hp": DRONE_HP, "flash": 0.0})
				Sfx.play("pickup_shield", -8.0, 0.7, 0.0, center)
			continue
		a.fire -= dt
		if a.fire <= 0.0:
			a.fire = ARM_FIRE[phase]
			var p := _arm_pos(i)
			shots.fire_aimed(p + (_ship - p).normalized() * ARM_RADIUS, _ship, ARM_SHOT_SPEED)
			Sfx.play("laser", -10.0, 0.6, 0.0, p)


func _drone_for(arm: int) -> bool:
	for d in _drones:
		if d.arm == arm:
			return true
	return false


func _update_drones(dt: float) -> void:
	for i in range(_drones.size() - 1, -1, -1):
		var d := _drones[i]
		var goal := _arm_pos(d.arm)
		d.pos = (d.pos as Vector2).move_toward(goal, DRONE_SPEED * dt)
		if (d.pos as Vector2).distance_to(goal) < 2.0:
			var a := _arms[d.arm]
			a.alive = true
			a.hp = ARM_HP
			a.fire = ARM_FIRE[phase]
			a.down_t = 0.0
			_drones.remove_at(i)
			fx.burst(goal, Color(0.5, 2.2, 0.8), 12, 240.0, 0.4, 4.0)
			Sfx.play("level_up", -8.0, 1.4, 0.0, goal)


func _update_grid(dt: float) -> void:
	if _grid_t >= 0.0:
		var before := _grid_t
		_grid_t += dt
		if before < GRID_TELEGRAPH and _grid_t >= GRID_TELEGRAPH:
			Sfx.play("death", -12.0, 1.8, 0.0, center)
			impact.call(6.0)
		if _grid_t >= GRID_TELEGRAPH + GRID_ACTIVE:
			_grid_t = -1.0
		return
	if _wall_t >= 0.0:
		return  # nunca grade e paredes ao mesmo tempo
	_grid_timer -= dt
	if _grid_timer > 0.0:
		return
	_grid_timer = GRID_INTERVAL[phase]
	_grid_cols = pick_lines(GRID_COLUMNS[phase], GRID_WIDTH, view_size.x - GRID_WIDTH)
	_grid_rows = pick_lines(GRID_ROWS[phase], view_size.y * 0.5, view_size.y * 0.9)
	for x in _grid_cols:
		telegraph.column(x - GRID_WIDTH * 0.5, x + GRID_WIDTH * 0.5, GRID_TELEGRAPH)
	for y in _grid_rows:
		telegraph.line(Vector2(0, y), Vector2(view_size.x, y), GRID_WIDTH, GRID_TELEGRAPH)
	_grid_t = 0.0
	Sfx.play("alarm", -8.0, 1.3, 0.0, center)


## `count` posições entre `lo` e `hi` com pelo menos GRID_MIN_SPACING entre si (sempre cabem:
## a folga que sobra é repartida ao acaso entre os vãos).
static func pick_lines(count: int, lo: float, hi: float) -> Array[float]:
	var slack := maxf(0.0, (hi - lo) - (count - 1) * GRID_MIN_SPACING)
	var cuts: Array[float] = []
	for i in count:
		cuts.append(randf() * slack)
	cuts.sort()
	var out: Array[float] = []
	for i in count:
		out.append(lo + cuts[i] + i * GRID_MIN_SPACING)
	return out


func _update_walls(dt: float) -> void:
	if _wall_t >= 0.0:
		var before := _wall_t
		_wall_t += dt
		if before < WALL_TELEGRAPH and _wall_t >= WALL_TELEGRAPH:
			Sfx.play("shield_hit", -4.0, 0.6, 0.0, center)
			impact.call(8.0)
		if _wall_t >= WALL_TELEGRAPH + WALL_ACTIVE:
			_wall_t = -1.0
		return
	if _grid_t >= 0.0:
		return
	_wall_timer -= dt
	if _wall_timer > 0.0:
		return
	_wall_timer = WALL_INTERVAL
	_wall_t = 0.0
	telegraph.column(0.0, WALL_DEPTH, WALL_TELEGRAPH)
	telegraph.column(view_size.x - WALL_DEPTH, view_size.x, WALL_TELEGRAPH)
	Sfx.play("alarm", -6.0, 0.9, 0.0, center)


func _on_damaged() -> void:
	if phase == 1 and hp <= max_hp / 2:
		_set_state(State.TRANSITION)
		_grid_t = -1.0
		impact.call(12.0)
		Sfx.duck(-6.0)


## Tiro num braço ou num drone tira vida dele, não do olho.
func damage(amount: float) -> void:
	var target := _last_target
	_last_target = -1
	if target >= 10:
		var idx := target - 10
		if idx >= _drones.size() or state != State.FIGHT:
			return
		var d := _drones[idx]
		d.hp -= amount
		d.flash = 0.06
		if d.hp <= 0:
			fx.explosion(d.pos, 40.0, Palette.ENEMY_HDR)
			Sfx.play("explosion", -6.0, 1.5, 0.0, d.pos)
			_drones.remove_at(idx)
			# O braço volta a "esperar": outro drone sai depois de REPAIR_DELAY.
			_arms[d.arm].down_t = 0.0
		return
	if target >= 0:
		var a := _arms[target]
		if not a.alive or state != State.FIGHT:
			return
		a.hp -= amount
		a.flash = 0.06
		if a.hp <= 0:
			a.alive = false
			a.down_t = 0.0
			var p := _arm_pos(target)
			fx.explosion(p, 80.0, Palette.ENEMY_HDR)
			Sfx.play("explosion", -2.0, 1.0, 0.0, p)
			impact.call(10.0)
		return
	super.damage(amount)


func _update_dying(dt: float) -> void:
	_boom_timer -= dt
	if _boom_timer <= 0.0:
		_boom_timer = 0.15
		var p := center + Vector2.from_angle(randf() * TAU) * randf() * BODY_RADIUS
		fx.explosion(p, randf_range(60.0, 110.0), Palette.DANGER_HDR if randf() < 0.5 else Palette.BLAST_HDR)
		Sfx.play("explosion", -2.0, randf_range(0.7, 1.0), 0.0, p)
		impact.call(10.0)
	if _state_t >= DYING_TIME:
		fx.explosion(center, 220.0, Palette.BLAST_HDR)
		Sfx.play("death", 0.0, 0.8, 0.0, center)
		impact.call(35.0)
		_set_state(State.DONE)
		visible = false
		defeated.emit()


# ---------------------------------------------------------------- colisão

func hit_bullet(p: Vector2) -> Hit:
	_last_target = -1
	if state == State.DONE:
		return Hit.NONE
	for i in _drones.size():
		if p.distance_to(_drones[i].pos) < DRONE_RADIUS + 8.0:
			_last_target = 10 + i
			return Hit.CORE if is_vulnerable() else Hit.ARMOR
	for i in _arms.size():
		if _arms[i].alive and p.distance_to(_arm_pos(i)) < ARM_RADIUS:
			_last_target = i
			return Hit.CORE if is_vulnerable() else Hit.ARMOR
	var d := p.distance_to(center)
	var core_lane := absf(p.x - center.x) < CORE_RADIUS and p.y > center.y and p.y < center.y + BODY_RADIUS
	if d < CORE_RADIUS or core_lane:
		return Hit.CORE if is_vulnerable() else Hit.ARMOR
	if d < BODY_RADIUS:
		return Hit.ARMOR
	return Hit.NONE


func touches(p: Vector2, radius: float) -> bool:
	if state == State.DONE:
		return false
	if p.distance_to(center) < BODY_RADIUS + radius:
		return true
	for i in _arms.size():
		if _arms[i].alive and p.distance_to(_arm_pos(i)) < ARM_RADIUS + radius:
			return true
	return false


func beam_hits(p: Vector2, radius: float) -> bool:
	if state != State.FIGHT:
		return false
	var reach := GRID_WIDTH * 0.5 + radius * 0.6
	if _grid_t >= GRID_TELEGRAPH:
		for x in _grid_cols:
			if absf(p.x - x) < reach:
				return true
		for y in _grid_rows:
			if absf(p.y - y) < reach:
				return true
	if _wall_t >= WALL_TELEGRAPH:
		if p.x < WALL_DEPTH + radius * 0.6 or p.x > view_size.x - WALL_DEPTH - radius * 0.6:
			return true
	return false


func _arm_pos(i: int) -> Vector2:
	var p: Vector2 = center + (ARMS[i] as Vector2)
	p.x = clampf(p.x, ARM_RADIUS + 10.0, view_size.x - ARM_RADIUS - 10.0)
	return p


func alive_arms() -> int:
	var n := 0
	for a in _arms:
		if a.alive:
			n += 1
	return n


func drones_out() -> int:
	return _drones.size()


func aim_x() -> float:
	# Drone de reparo a caminho é a prioridade; senão, o olho.
	if not _drones.is_empty():
		return (_drones[0].pos as Vector2).x
	return center.x


func _rest_y() -> float:
	return view_size.y * REST_Y_RATIO


# ---------------------------------------------------------------- rota segura

## Menor vão livre (px) entre feixes paralelos da grade (centro a centro menos a largura).
static func grid_min_gap() -> float:
	return GRID_MIN_SPACING - GRID_WIDTH


## Largura livre no meio quando as paredes fecham a arena.
static func walls_free_width(view_w: float) -> float:
	return view_w - 2.0 * WALL_DEPTH


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var art := Game.art
	var arm_tex := art.boss_part("sentinel_arm")
	var broken_tex := art.boss_part("sentinel_arm_broken")
	var drone_tex := art.boss_part("sentinel_drone")

	# Paredes de energia da fase 2 (atrás do corpo).
	if _wall_t >= WALL_TELEGRAPH:
		for side in 2:
			var x0 := 0.0 if side == 0 else view_size.x - WALL_DEPTH
			draw_rect(Rect2(x0, 0, WALL_DEPTH, view_size.y), Color(Palette.DANGER, 0.06))
			var edge := WALL_DEPTH if side == 0 else view_size.x - WALL_DEPTH
			draw_line(Vector2(edge, 0), Vector2(edge, view_size.y), Palette.DANGER_HDR, 8.0)
			var y := fmod(_t * 400.0, 120.0)
			while y < view_size.y:
				draw_line(Vector2(x0, y), Vector2(x0 + WALL_DEPTH, y + 60.0), Color(Palette.DANGER, 0.25), 3.0)
				y += 120.0

	# Braços (canhões) — destruídos ficam como toco soltando faísca.
	for i in _arms.size():
		var p := _arm_pos(i)
		draw_line(center + Vector2(signf(p.x - center.x) * BODY_RADIUS * 0.8, 20.0), p, Color(0.3, 0.3, 0.36), 22.0)
		var left := p.x < center.x
		if _arms[i].alive:
			var dir := (_ship - p).normalized()
			var charge := 1.0 - clampf(float(_arms[i].fire) / ARM_CHARGE, 0.0, 1.0)
			if arm_tex != null:
				# Arte: do suporte (em cima, junto do corpo) ao cano (embaixo, mirando a nave).
				var flash := Color(1.8, 1.7, 1.7) if _arms[i].flash > 0.0 else Color.WHITE
				var axis := ARM_ART_AXIS if not left else PI - ARM_ART_AXIS  # o braço esquerdo é espelhado
				_draw_part(arm_tex, p, ARM_RADIUS * 4.4, dir.angle() - axis, flash, left)
				draw_circle(p + dir * ARM_RADIUS * 1.5, 6.0 + 10.0 * charge, Palette.ENEMY.lerp(Palette.ENEMY_HDR, charge))
				continue
			draw_circle(p, ARM_RADIUS, Palette.WHITE_HDR if _arms[i].flash > 0.0 else Color(0.26, 0.26, 0.32))
			draw_arc(p, ARM_RADIUS, 0.0, TAU, 28, Palette.ENEMY_HDR, 4.0, true)
			draw_line(p, p + dir * ARM_RADIUS * 1.4, Color(0.4, 0.4, 0.46), 16.0)
			draw_line(p, p + dir * ARM_RADIUS * 1.4, Palette.ENEMY.lerp(Palette.ENEMY_HDR, charge), 5.0)
			draw_circle(p, 10.0 + 10.0 * charge, Palette.ENEMY.lerp(Palette.ENEMY_HDR, charge))
		else:
			if broken_tex != null:
				_draw_part(broken_tex, p, ARM_RADIUS * 4.0, 0.0, Color(0.8, 0.8, 0.8), left)
			else:
				draw_circle(p, ARM_RADIUS * 0.55, Color(0.15, 0.15, 0.18))
			if int(_t * 10.0) % 3 == 0:
				draw_circle(p + Vector2(randf_range(-12, 12), randf_range(-12, 12)), 5.0, Palette.FLAME_HDR)

	var tint := Color(1.6, 1.5, 1.5) if _flash > 0.0 else Color.WHITE
	if state == State.TRANSITION and int(_state_t * 12.0) % 2 == 0:
		tint = Color(1.8, 0.8, 0.8)
	if art.sentinel_body != null:
		var half := SPRITE_SIZE * 0.5
		draw_texture_rect(art.sentinel_body, Rect2(center - Vector2(half, half), Vector2(SPRITE_SIZE, SPRITE_SIZE)),
				false, tint)

	# Olho (o da arte), com a pupila clara seguindo a nave.
	_weak_glow(center, CORE_RADIUS)
	draw_circle(center + (_ship - center).normalized() * 10.0, CORE_RADIUS * 0.22, Palette.WHITE_HDR)

	# Drones de reparo: cruz com luz verde e um raio fino ligando ao braço.
	for d in _drones:
		var dp: Vector2 = d.pos
		draw_line(dp, _arm_pos(d.arm), Color(0.4, 1.0, 0.5, 0.35), 2.0)
		if drone_tex != null:
			_draw_part(drone_tex, dp, DRONE_RADIUS * 2.6, 0.0, Color(2.0, 2.0, 2.0) if d.flash > 0.0 else Color.WHITE)
			draw_circle(dp + Vector2(DRONE_RADIUS * 0.9, 0), 4.0, Color(0.5, 2.2, 0.8))  # solda
			continue
		draw_rect(Rect2(dp - Vector2(DRONE_RADIUS, 7), Vector2(DRONE_RADIUS * 2.0, 14)), Color(0.35, 0.36, 0.4))
		draw_rect(Rect2(dp - Vector2(7, DRONE_RADIUS), Vector2(14, DRONE_RADIUS * 2.0)), Color(0.35, 0.36, 0.4))
		draw_circle(dp, 11.0, Palette.WHITE_HDR if d.flash > 0.0 else Color(0.5, 2.2, 0.8))
		draw_arc(dp, DRONE_RADIUS, 0.0, TAU, 20, Palette.ENEMY_HDR, 3.0, true)

	# Grade de laser ativa.
	if _grid_t >= GRID_TELEGRAPH:
		for x in _grid_cols:
			draw_line(Vector2(x, 0), Vector2(x, view_size.y), Color(Palette.DANGER, 0.3), GRID_WIDTH)
			draw_line(Vector2(x, 0), Vector2(x, view_size.y), Palette.DANGER_HDR, GRID_WIDTH * 0.35)
		for y in _grid_rows:
			draw_line(Vector2(0, y), Vector2(view_size.x, y), Color(Palette.DANGER, 0.3), GRID_WIDTH)
			draw_line(Vector2(0, y), Vector2(view_size.x, y), Palette.DANGER_HDR, GRID_WIDTH * 0.35)
