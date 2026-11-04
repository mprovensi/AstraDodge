class_name BulletLayer
extends Node2D
## Pool de projéteis: reaproveita objetos em vez de criar/destruir a cada tiro.

class Bullet:
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var pierce := false
	var alive := false
	var hit_ids := {}  # asteroides já atingidos por um tiro perfurante

var pool: Array[Bullet] = []
var view_size := Vector2.ZERO


func resize(size: Vector2) -> void:
	view_size = size


func spawn(pos: Vector2, angle: float, pierce: bool) -> void:
	var b := _get_free()
	b.pos = pos
	b.vel = Vector2(0, -Tuning.BULLET_SPEED).rotated(angle)
	b.pierce = pierce
	b.alive = true
	b.hit_ids.clear()


func update(dt: float) -> void:
	for b in pool:
		if not b.alive:
			continue
		b.pos += b.vel * dt
		if b.pos.y < -60.0 or b.pos.x < -60.0 or b.pos.x > view_size.x + 60.0:
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
