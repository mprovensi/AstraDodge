class_name PickupLayer
extends Node2D
## Orbes de escudo (ciano, círculo) e cristais de arma (magenta, losango) com ímã.

enum Kind { SHIELD, CRYSTAL }

class Pickup:
	var kind := 0
	var pos := Vector2.ZERO
	var t := 0.0
	var alive := true

var pickups: Array[Pickup] = []
var view_size := Vector2.ZERO


func resize(size: Vector2) -> void:
	view_size = size


func spawn(pos: Vector2, kind: Kind) -> void:
	var p := Pickup.new()
	p.kind = kind
	p.pos = pos
	p.t = randf() * TAU
	pickups.append(p)


func clear() -> void:
	pickups.clear()
	queue_redraw()


## Move os itens e retorna a lista de tipos coletados neste frame.
func update(dt: float, scroll_speed: float, ship_pos: Vector2, ship_alive: bool) -> Array[int]:
	var collected: Array[int] = []
	for p in pickups:
		p.t += dt
		var to_ship := ship_pos - p.pos
		var d := to_ship.length()
		if ship_alive and d < Tuning.PICKUP_COLLECT_RADIUS:
			collected.append(p.kind)
			p.alive = false
			continue
		if ship_alive and d < Tuning.PICKUP_MAGNET_RADIUS:
			var pull := (900.0 + (Tuning.PICKUP_MAGNET_RADIUS - d) * 10.0) * dt
			p.pos += to_ship.normalized() * minf(d, pull)
		else:
			p.pos.y += scroll_speed * Tuning.PICKUP_FALL_FACTOR * dt
		if p.pos.y > view_size.y + 50.0:
			p.alive = false

	for i in range(pickups.size() - 1, -1, -1):
		if not pickups[i].alive:
			pickups.remove_at(i)
	queue_redraw()
	return collected


func _draw() -> void:
	for p in pickups:
		var pulse := 1.0 + 0.15 * sin(p.t * 8.0)
		if p.kind == Kind.SHIELD:
			draw_circle(p.pos, 26.0 * pulse, Color(Palette.NEON, 0.25))
			draw_circle(p.pos, 13.0, Palette.NEON)
			draw_circle(p.pos, 6.0, Color.WHITE)
		else:
			var s := 18.0 * pulse
			var diamond := PackedVector2Array([p.pos + Vector2(0, -s * 1.3), p.pos + Vector2(s, 0), p.pos + Vector2(0, s * 1.3), p.pos + Vector2(-s, 0)])
			draw_colored_polygon(diamond, Color(Palette.MAGENTA, 0.9))
			draw_polyline(diamond + PackedVector2Array([diamond[0]]), Color(Palette.MAGENTA, 0.3), 10.0, true)
