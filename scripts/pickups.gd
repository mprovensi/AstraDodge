class_name PickupLayer
extends Node2D
## Orbes de escudo (ciano, círculo), cristais de arma (magenta, losango) e o contêiner de
## carga dourado dos chefes (sempre puxado até a nave: é a recompensa da luta). Com ímã.

enum Kind { SHIELD, CRYSTAL, CARGO }  ## CARGO: contêiner de carga dos chefes (escolha de módulo)

class Pickup:
	var kind := 0
	var pos := Vector2.ZERO
	var t := 0.0
	var alive := true

var pickups: Array[Pickup] = []
var view_size := Vector2.ZERO
var magnet_scale := 1.0  # módulo ÍMÃ aumenta o alcance


func resize(size: Vector2) -> void:
	view_size = size


func spawn(pos: Vector2, kind: Kind) -> void:
	var p := Pickup.new()
	p.kind = kind
	p.pos = pos
	p.t = 0.0 if kind == Kind.CARGO else randf() * TAU
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
		var reach := Tuning.PICKUP_MAGNET_RADIUS * magnet_scale
		if p.kind == Kind.CARGO and p.t > 1.0:
			reach = 99999.0  # o contêiner sempre vem até a nave (depois de 1 s caindo)
		if ship_alive and d < reach:
			var pull := (900.0 + maxf(0.0, reach - d) * 10.0) * dt if p.kind != Kind.CARGO else 700.0 * dt
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
		if p.kind == Kind.CARGO:
			_draw_cargo(p, pulse)
		elif p.kind == Kind.SHIELD:
			draw_circle(p.pos, 26.0 * pulse, Color(Palette.NEON, 0.25))
			draw_circle(p.pos, 13.0, Palette.NEON_HDR)
			draw_circle(p.pos, 6.0, Palette.WHITE_HDR)
		else:
			var s := 18.0 * pulse
			var diamond := PackedVector2Array([p.pos + Vector2(0, -s * 1.3), p.pos + Vector2(s, 0), p.pos + Vector2(0, s * 1.3), p.pos + Vector2(-s, 0)])
			draw_colored_polygon(diamond, Palette.MAGENTA_HDR)
			draw_polyline(diamond + PackedVector2Array([diamond[0]]), Color(Palette.MAGENTA, 0.3), 10.0, true)


## Contêiner de carga: caixa dourada com faixas e brilho pulsando.
func _draw_cargo(p: Pickup, pulse: float) -> void:
	var s := 30.0
	draw_circle(p.pos, s * 1.9 * pulse, Color(1.0, 0.8, 0.2, 0.18))
	draw_set_transform(p.pos, sin(p.t * 2.0) * 0.2)
	draw_rect(Rect2(-s, -s * 0.8, s * 2.0, s * 1.6), Color(0.55, 0.38, 0.08))
	draw_rect(Rect2(-s, -s * 0.8, s * 2.0, s * 1.6), Color(2.4, 1.9, 0.6), false, 4.0)
	draw_rect(Rect2(-s * 0.2, -s * 0.8, s * 0.4, s * 1.6), Color(2.0, 1.6, 0.5))
	draw_rect(Rect2(-s, -s * 0.12, s * 2.0, s * 0.24), Color(1.6, 1.2, 0.4))
	draw_set_transform(Vector2.ZERO, 0.0)
