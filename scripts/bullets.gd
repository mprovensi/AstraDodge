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

var pool: Array[Bullet] = []
var view_size := Vector2.ZERO
var bounces := 0  # módulo RICOCHETE: quiques por tiro novo
var pierces := 0  # módulo PERFURANTE: poeiras atravessadas por tiro novo


func resize(size: Vector2) -> void:
	view_size = size


func spawn(pos: Vector2, angle: float, pierce: bool) -> void:
	var b := _get_free()
	b.pos = pos
	b.prev = pos
	b.vel = Vector2(0, -Tuning.BULLET_SPEED).rotated(angle)
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
		b.pos += b.vel * dt
		# RICOCHETE: quica nas bordas da tela enquanto ainda tiver quiques.
		if b.bounces_left > 0 and (b.pos.x < 0.0 or b.pos.x > view_size.x):
			b.bounces_left -= 1
			b.vel.x = -b.vel.x
			b.pos.x = clampf(b.pos.x, 0.0, view_size.x)
		if b.pos.y < -60.0 or b.pos.y > view_size.y + 60.0 or b.pos.x < -60.0 or b.pos.x > view_size.x + 60.0:
			b.alive = false
	queue_redraw()


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
		var color := Palette.MAGENTA if b.pierce else Palette.NEON
		var length := 52.0 if b.pierce else 36.0
		var tail := b.pos - b.vel.normalized() * length
		draw_line(tail, b.pos, Color(color, 0.3), 16.0 if b.pierce else 12.0)
		var core := Palette.MAGENTA_HDR if b.pierce else Palette.NEON_HDR
		draw_line(tail, b.pos, core.lerp(Palette.WHITE_HDR, 0.5), 5.0)
