class_name Cruiser
extends Boss
## CRUZADOR FANTASMA — chefe do Setor 4 (PLANO_V2.md, Setor 4). Chefe de VÁRIAS PARTES.
##
## Partes (cada uma com vida própria; destruir uma tira o ataque dela):
##   - 2 CANHÕES laterais: leque de 3 tiros mirados; o canhão brilha antes de atirar.
##   - LANÇADOR: solta 2 mísseis teleguiados lentos (dá para abater).
##   - PONTE DE COMANDO (núcleo): a vida do chefe. Tem ESCUDO enquanto houver canhão vivo
##     — derrube os canhões primeiro (o jogador escolhe a ordem).
## Fase 2 (ponte com 50%): o casco fica "fantasma" (translúcido, piscando) e a ponte passa
##   a soltar anéis de tiros; os canhões que restarem atiram mais rápido.

const NAME := "CRUZADOR FANTASMA"
const MAX_HP := 140                    # vida da PONTE (as outras partes têm a própria)

const SPRITE_W := 900.0
const SPRITE_H := 450.0
const REST_Y_RATIO := 0.27             # abaixo do HUD e da barra de vida
const ENTER_TIME := 3.2
const SWAY := 0.05

# Partes: posição no casco (px na tela), raio e vida. Posições = encaixes do SVG.
const PARTS := [
	{"id": "cannon_l", "offset": Vector2(-257, 39), "radius": 46.0, "hp": 30},
	{"id": "cannon_r", "offset": Vector2(257, 39), "radius": 46.0, "hp": 30},
	{"id": "launcher", "offset": Vector2(0, -63), "radius": 46.0, "hp": 35},
]
const BRIDGE_OFFSET := Vector2(0, 23)
const BRIDGE_RADIUS := 50.0
# Colisão do casco (círculos ao longo do comprimento) — conferida contra o desenho no teste.
const HULL_BODIES := [
	[Vector2(-400, 0), 30.0], [Vector2(-330, 2), 55.0], [Vector2(-230, 2), 82.0], [Vector2(-115, 2), 95.0], [Vector2(0, 2), 100.0],
	[Vector2(115, 2), 95.0], [Vector2(230, 2), 82.0], [Vector2(330, 2), 55.0], [Vector2(400, 0), 30.0],
]
const HULL_BOTTOM := 105.0             # até onde os tiros "entram" pela frente do casco

const CANNON_INTERVAL := [0.0, 2.2, 1.7]
const CANNON_CHARGE := 0.6
const CANNON_SHOTS := 3
const CANNON_SPREAD_DEG := 24.0
const CANNON_SHOT_SPEED := 360.0
const MISSILE_INTERVAL := [0.0, 4.5, 3.6]
const RING_INTERVAL := 3.2             # fase 2: anel da ponte
const RING_SHOTS := 12
const RING_SPEED := 260.0

const TRANSITION_TIME := 1.2
const DYING_TIME := 2.8

var center := Vector2.ZERO
var enemies: EnemyLayer                # para lançar mísseis (o Main liga)

var _parts: Array[Dictionary] = []    # {id, offset, radius, hp, alive, flash}
var _last_part := -1                   # parte atingida pelo último hit_bullet (-1 = ponte)
var _cannon_timer := 2.0
var _cannon_side := 0
var _charge := -1.0                    # >= 0: canhão carregando
var _missile_timer := 3.0
var _ring_timer := 2.0
var _boom_timer := 0.0
var _ship_pos := Vector2.ZERO


func _init() -> void:
	display_name = NAME
	max_hp = MAX_HP


func _enter() -> void:
	center = Vector2(view_size.x * 0.5, -SPRITE_H * 0.5)
	_parts.clear()
	for p in PARTS:
		var part: Dictionary = (p as Dictionary).duplicate()
		part["alive"] = true
		part["flash"] = 0.0
		_parts.append(part)
	_set_state(State.ENTERING)


# ---------------------------------------------------------------- comportamento

func _update_boss(dt: float, ship_pos: Vector2) -> void:
	_ship_pos = ship_pos
	for p in _parts:
		p.flash = maxf(0.0, p.flash - dt)
	match state:
		State.ENTERING:
			center.y = lerpf(-SPRITE_H * 0.5, _rest_y(), smoothstep(0.0, 1.0, _state_t / ENTER_TIME))
			if _state_t >= ENTER_TIME:
				_set_state(State.FIGHT)
		State.FIGHT:
			center.x = view_size.x * 0.5 + sin(_t * 0.35) * view_size.x * SWAY
			center.y = _rest_y() + sin(_t * 0.8) * 6.0
			_update_cannons(dt)
			_update_missiles(dt)
			if phase == 2:
				_ring_timer -= dt
				if _ring_timer <= 0.0:
					_ring_timer = RING_INTERVAL
					shots.fire_ring(_bridge_pos(), RING_SHOTS, RING_SPEED, randf() * TAU, EnemyBulletLayer.Kind.ORB)
					Sfx.play("pickup_shield", -6.0, 0.6, 0.0, _bridge_pos())
		State.TRANSITION:
			if int(_state_t * 25.0) % 3 == 0:
				fx.burst(center + Vector2(randf_range(-380, 380), randf_range(-80, 80)), Palette.FLAME_HDR, 4, 280.0, 0.4, 5.0)
			if _state_t >= TRANSITION_TIME:
				phase = 2
				_ring_timer = 1.0
				impact.call(16.0)
				Sfx.play("level_down", -2.0, 0.6, 0.0)
				_set_state(State.FIGHT)
				phase_changed.emit(2)
		State.DYING:
			_update_dying(dt)


func _update_cannons(dt: float) -> void:
	if _charge >= 0.0:
		_charge += dt
		if _charge >= CANNON_CHARGE:
			_charge = -1.0
			var i := _cannon_side
			if _parts[i].alive:
				var from := _part_pos(i)
				var ang := (_ship_pos - from).angle()
				shots.fire_fan(from, ang, CANNON_SHOTS, CANNON_SPREAD_DEG, CANNON_SHOT_SPEED, EnemyBulletLayer.Kind.DIAMOND)
				Sfx.play("ricochet", -6.0, 0.6, 0.0, from)
		return
	_cannon_timer -= dt
	if _cannon_timer <= 0.0:
		_cannon_timer = CANNON_INTERVAL[phase]
		# Alterna entre os canhões vivos.
		for k in 2:
			_cannon_side = 1 - _cannon_side
			if _parts[_cannon_side].alive:
				_charge = 0.0
				break


func _update_missiles(dt: float) -> void:
	if not _parts[2].alive or enemies == null:
		return
	_missile_timer -= dt
	if _missile_timer <= 0.0:
		_missile_timer = MISSILE_INTERVAL[phase]
		var from := _part_pos(2)
		enemies.spawn_missile(from + Vector2(-30, 0), Vector2(-0.6, 1.0))
		enemies.spawn_missile(from + Vector2(30, 0), Vector2(0.6, 1.0))
		Sfx.play("laser", -4.0, 0.5, 0.0, from)


func _on_damaged() -> void:
	if phase == 1 and hp <= max_hp / 2:
		_set_state(State.TRANSITION)
		_charge = -1.0
		impact.call(12.0)
		Sfx.duck(-6.0)


## Tiro numa parte tira vida da parte; na ponte, do chefe (se o escudo caiu).
func damage(amount: int) -> void:
	if _last_part >= 0:
		var idx := _last_part
		_last_part = -1
		var p := _parts[idx]
		if not p.alive or state != State.FIGHT:
			return
		p.hp -= amount
		p.flash = 0.06
		if p.hp <= 0:
			p.alive = false
			var at := _part_pos(idx)
			fx.explosion(at, 90.0, Palette.FLAME_HDR)
			fx.explosion(at, 60.0, Palette.BLAST_HDR)
			Sfx.play("explosion", -2.0, 0.9, 0.0, at)
			impact.call(14.0)
			if not _bridge_shielded():
				Sfx.play("level_up", -4.0, 0.8, 0.0)  # escudo da ponte caiu
		return
	if _bridge_shielded():
		return
	super.damage(amount)


func _update_dying(dt: float) -> void:
	_boom_timer -= dt
	if _boom_timer <= 0.0:
		_boom_timer = 0.12
		var p := center + Vector2(randf_range(-400, 400), randf_range(-90, 90))
		fx.explosion(p, randf_range(60.0, 120.0), Palette.FLAME_HDR if randf() < 0.5 else Palette.BLAST_HDR)
		Sfx.play("explosion", -2.0, randf_range(0.6, 0.9), 0.0, p)
		impact.call(10.0)
	if _state_t >= DYING_TIME:
		for k in 3:
			fx.explosion(center + Vector2((k - 1) * 300.0, 0.0), 180.0, Palette.BLAST_HDR)
		Sfx.play("death", 0.0, 0.6, 0.0, center)
		impact.call(40.0)
		_set_state(State.DONE)
		visible = false
		defeated.emit()


# ---------------------------------------------------------------- colisão

func hit_bullet(p: Vector2) -> Hit:
	_last_part = -1
	if state == State.DONE:
		return Hit.NONE
	# As partes ficam na frente do casco: tiros que sobem na "faixa" delas as alcançam.
	for i in _parts.size():
		if _parts[i].alive and _in_lane(p, _part_pos(i), float(_parts[i].radius)):
			_last_part = i
			return Hit.CORE if is_vulnerable() else Hit.ARMOR
	if _in_lane(p, _bridge_pos(), BRIDGE_RADIUS):
		return Hit.CORE if is_vulnerable() and not _bridge_shielded() else Hit.ARMOR
	for body in HULL_BODIES:
		if p.distance_to(center + (body[0] as Vector2)) < float(body[1]):
			return Hit.ARMOR
	return Hit.NONE


func _in_lane(p: Vector2, at: Vector2, radius: float) -> bool:
	if p.distance_squared_to(at) < radius * radius:
		return true
	return absf(p.x - at.x) < radius and p.y > at.y and p.y < center.y + HULL_BOTTOM


func touches(p: Vector2, radius: float) -> bool:
	if state == State.DONE:
		return false
	for body in HULL_BODIES:
		if p.distance_to(center + (body[0] as Vector2)) < float(body[1]) + radius:
			return true
	return false


func aim_x() -> float:
	for i in [0, 1, 2]:
		if _parts[i].alive:
			return _part_pos(i).x
	return _bridge_pos().x


func alive_parts() -> int:
	var n := 0
	for p in _parts:
		if p.alive:
			n += 1
	return n


func _bridge_shielded() -> bool:
	return _parts[0].alive or _parts[1].alive


func _part_pos(i: int) -> Vector2:
	return center + (_parts[i].offset as Vector2)


func _bridge_pos() -> Vector2:
	return center + BRIDGE_OFFSET


func _rest_y() -> float:
	return view_size.y * REST_Y_RATIO


# ---------------------------------------------------------------- rota segura

## Menor vão entre os 3 tiros do leque de um canhão a `distance` px dele.
static func cannon_min_gap(distance: float) -> float:
	var step := deg_to_rad(CANNON_SPREAD_DEG) / float(CANNON_SHOTS - 1)
	return 2.0 * distance * sin(step * 0.5) - 2.0 * 12.0


static func ring_min_gap(distance: float) -> float:
	return 2.0 * distance * sin(PI / RING_SHOTS) - 2.0 * 14.0


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var art := Game.art
	var tint := Color(1.6, 1.4, 1.3) if _flash > 0.0 else Color.WHITE
	if phase == 2 or state == State.TRANSITION:
		# Casco "fantasma": translúcido e tremeluzindo em verde-água.
		var ghost := 0.6 + 0.25 * sin(_t * 9.0) + (0.15 if int(_t * 7.0) % 5 == 0 else 0.0)
		tint = Color(0.75, 1.15, 1.1, ghost)
	if art.cruiser_body != null:
		draw_texture_rect(art.cruiser_body,
				Rect2(center - Vector2(SPRITE_W, SPRITE_H) * 0.5, Vector2(SPRITE_W, SPRITE_H)), false, tint)

	var pulse := 0.85 + 0.15 * sin(_t * 8.0)
	# Canhões: base + cano mirando a nave; brilham enquanto carregam.
	for i in 2:
		var at := _part_pos(i)
		if not _parts[i].alive:
			_draw_wreck(at, 34.0)
			continue
		var charging := _charge >= 0.0 and _cannon_side == i
		var k := clampf(_charge / CANNON_CHARGE, 0.0, 1.0) if charging else 0.0
		var dir := (_ship_pos - at).normalized()
		draw_line(at, at + dir * 70.0, Color(0.32, 0.34, 0.4), 18.0)
		draw_line(at, at + dir * 70.0, Palette.ENEMY.lerp(Palette.ENEMY_HDR, k), 6.0)
		var fill: Color = Palette.WHITE_HDR if _parts[i].flash > 0.0 else Palette.ENEMY_FILL
		draw_circle(at, 36.0, fill)
		draw_arc(at, 36.0, 0.0, TAU, 32, Palette.BLAST_HDR * pulse, 5.0, true)
		draw_circle(at, 12.0 + 10.0 * k, Palette.ENEMY.lerp(Palette.BLAST_HDR, k))

	# Lançador: caixa com dois tubos.
	var la := _part_pos(2)
	if _parts[2].alive:
		var lf: Color = Palette.WHITE_HDR if _parts[2].flash > 0.0 else Palette.ENEMY_FILL
		draw_rect(Rect2(la - Vector2(44, 30), Vector2(88, 60)), lf)
		draw_rect(Rect2(la - Vector2(44, 30), Vector2(88, 60)), Palette.BLAST_HDR * pulse, false, 4.0)
		for sx in [-20.0, 20.0]:
			draw_circle(la + Vector2(sx, 6), 11.0, Color(0.1, 0.1, 0.12))
			draw_arc(la + Vector2(sx, 6), 11.0, 0.0, TAU, 16, Palette.ENEMY_HDR, 3.0, true)
	else:
		_draw_wreck(la, 34.0)

	# Ponte: janela que brilha quando vulnerável; escudo (bolha) enquanto houver canhão.
	var br := _bridge_pos()
	draw_rect(Rect2(br - Vector2(64, 24), Vector2(128, 48)), Color(0.08, 0.09, 0.12))
	if _bridge_shielded():
		draw_rect(Rect2(br - Vector2(54, 12), Vector2(108, 24)), Color(0.3, 0.6, 0.6))
		draw_arc(br, BRIDGE_RADIUS * 1.25, 0.0, TAU, 40, Color(Palette.NEON, 0.7), 5.0, true)
		draw_arc(br, BRIDGE_RADIUS * 1.45, _t * 2.0, _t * 2.0 + PI, 24, Color(Palette.NEON, 0.4), 3.0, true)
	else:
		var c: Color = Palette.BLAST_HDR if _flash <= 0.0 else Palette.WHITE_HDR
		draw_circle(br, BRIDGE_RADIUS * 1.3, Color(Palette.ENEMY, 0.2))
		draw_rect(Rect2(br - Vector2(54, 14), Vector2(108, 28)), c * pulse)


func _draw_wreck(at: Vector2, r: float) -> void:
	draw_circle(at, r, Color(0.07, 0.07, 0.08))
	draw_arc(at, r, 0.0, TAU, 20, Color(Palette.FLAME, 0.6), 3.0, true)
	if int(_t * 10.0 + at.x) % 3 == 0:
		draw_circle(at + Vector2(randf_range(-10, 10), randf_range(-10, 10)), 6.0, Palette.FLAME_HDR)
