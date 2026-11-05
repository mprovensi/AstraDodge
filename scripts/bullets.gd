class_name BulletLayer
extends Node2D
## Pool de projéteis: reaproveita objetos em vez de criar/destruir a cada tiro.

class Bullet:
	var pos := Vector2.ZERO
	var prev := Vector2.ZERO  # posição no quadro anterior (o teste de acerto usa o trajeto)
	var vel := Vector2.ZERO
	var pierce := false
	var alive := false
	var hit_ids := {}  # asteroides já atingidos por um tiro perfurante
	var bounces_left := 0
	var pierce_left := 0
	var base_damage := 1.0  # dano no chefe (a vida dele já conta com a potência do setor)
	var damage := 1.0       # dano em poeira e inimigos (base × potência)
	var type := Weapons.PULSE

var pool: Array[Bullet] = []
var view_size := Vector2.ZERO
var bounces := 0  # módulo RICOCHETE: quiques por tiro novo
var pierces := 0  # módulo PERFURANTE: poeiras atravessadas por tiro novo
## Míssil: o Main informa o X do alvo mais próximo à frente (NAN = sem alvo).
var seek_x: Callable = func(_p: Vector2) -> float: return NAN


func resize(size: Vector2) -> void:
	view_size = size


func spawn(pos: Vector2, angle: float, pierce: bool, base_damage := 1.0, damage := 1.0,
		type := Weapons.PULSE) -> void:
	var b := _get_free()
	b.pos = pos
	b.prev = pos
	b.type = type
	b.base_damage = base_damage
	b.damage = damage
	b.vel = Vector2(0, -Tuning.BULLET_SPEED * float(Weapons.info(type).speed)).rotated(angle)
	b.pierce = pierce
	b.alive = true
	b.hit_ids.clear()
	b.bounces_left = bounces
	b.pierce_left = pierces


func update(dt: float) -> void:
	for b in pool:
		if not b.alive:
			continue
		b.prev = b.pos
		if b.type == Weapons.MISSILE:
			_steer(b, dt)
		b.pos += b.vel * dt
		# RICOCHETE: quica nas bordas da tela enquanto ainda tiver quiques.
		if b.bounces_left > 0 and (b.pos.x < 0.0 or b.pos.x > view_size.x):
			b.bounces_left -= 1
			b.vel.x = -b.vel.x
			b.pos.x = clampf(b.pos.x, 0.0, view_size.x)
		if b.pos.y < -60.0 or b.pos.y > view_size.y + 60.0 or b.pos.x < -60.0 or b.pos.x > view_size.x + 60.0:
			b.alive = false
	queue_redraw()


## Míssil: corrige o rumo para a coluna do alvo (sem curvar para trás).
func _steer(b: Bullet, dt: float) -> void:
	var tx: float = seek_x.call(b.pos)
	if is_nan(tx):
		return
	var speed := b.vel.length()
	var want := clampf((tx - b.pos.x) * 4.0, -speed * 0.6, speed * 0.6)
	b.vel.x = move_toward(b.vel.x, want, Tuning.SHIP_MISSILE_TURN * dt)
	b.vel.y = -sqrt(maxf(speed * speed - b.vel.x * b.vel.x, speed * speed * 0.3))


func clear() -> void:
	for b in pool:
		b.alive = false
	queue_redraw()


func _get_free() -> Bullet:
	for b in pool:
		if not b.alive:
			return b
	var nb := Bullet.new()
	pool.append(nb)
	return nb


func _draw() -> void:
	for b in pool:
		if not b.alive:
			continue
		var dir := b.vel.normalized()
		var color: Color = Weapons.info(b.type).color
		var core := Color(color.r * 2.2, color.g * 2.2, color.b * 2.2).lerp(Palette.WHITE_HDR, 0.4)
		if b.pierce and b.type != Weapons.LASER:
			color = Palette.MAGENTA
			core = Palette.MAGENTA_HDR.lerp(Palette.WHITE_HDR, 0.5)
		match b.type:
			Weapons.LASER:  # feixe longo e fino
				var tail := b.pos - dir * 70.0
				draw_line(tail, b.pos, Color(color, 0.3), 9.0)
				draw_line(tail, b.pos, core, 3.0)
			Weapons.SPREAD:  # bolinha curta
				draw_circle(b.pos, 9.0, Color(color, 0.3))
				draw_line(b.pos - dir * 14.0, b.pos, core, 6.0)
			Weapons.MISSILE:  # corpo grosso + chama atrás
				draw_line(b.pos - dir * 40.0, b.pos - dir * 18.0, Color(Palette.FLAME_HDR, 0.5), 8.0)
				draw_line(b.pos - dir * 20.0, b.pos, Color(color, 0.45), 16.0)
				draw_line(b.pos - dir * 20.0, b.pos, core, 7.0)
			_:
				var length := 52.0 if b.pierce else 36.0
				var tail := b.pos - dir * length
				draw_line(tail, b.pos, Color(color, 0.3), 16.0 if b.pierce else 12.0)
				draw_line(tail, b.pos, core, 5.0)
