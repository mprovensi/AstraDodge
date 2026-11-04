class_name HazardLayer
extends Node2D
## Perigos do ambiente (Setor 3 — Nebulosa Iônica):
## - Nuvens iônicas: não machucam, mas dentro delas o escudo drena 3x mais rápido.
##   O contorno tracejado marca exatamente a área do efeito.
## - Raios da tempestade: aviso em coluna (TelegraphLayer) e depois o raio cai na coluna.

class Cloud:
	var pos := Vector2.ZERO
	var radius := 180.0
	var t := 0.0
	var puffs := PackedVector3Array()  # (x, y, r) relativos ao centro — o "formato" da nuvem
	var alive := true

class Strike:
	var x := 0.0
	var t := 0.0
	var struck := false
	var bolt := PackedVector2Array()  # zigue-zague do raio (gerado ao cair)

var clouds: Array[Cloud] = []
var strikes: Array[Strike] = []
var view_size := Vector2.ZERO
var _struck_now: Array[float] = []
var _t := 0.0


func resize(size: Vector2) -> void:
	view_size = size


func clear() -> void:
	clouds.clear()
	strikes.clear()
	_struck_now.clear()
	queue_redraw()


func spawn_cloud(pos: Vector2, radius: float) -> void:
	var c := Cloud.new()
	c.pos = pos
	c.radius = radius
	c.t = randf() * TAU
	for i in 7:
		var ang := TAU * i / 7.0 + randf_range(-0.3, 0.3)
		var d := radius * randf_range(0.25, 0.55)
		c.puffs.append(Vector3(cos(ang) * d, sin(ang) * d, radius * randf_range(0.45, 0.6)))
	c.puffs.append(Vector3(0, 0, radius * 0.6))
	clouds.append(c)


## A nave está dentro de alguma nuvem (área do contorno tracejado)?
func in_cloud(p: Vector2) -> bool:
	for c in clouds:
		if p.distance_to(c.pos) < c.radius * 0.85:
			return true
	return false


## Agenda um raio na coluna `x`: o aviso aparece agora e o raio cai depois do aviso.
func spawn_strike(x: float, telegraph: TelegraphLayer) -> void:
	var s := Strike.new()
	s.x = clampf(x, Tuning.STORM_WIDTH * 0.5, view_size.x - Tuning.STORM_WIDTH * 0.5)
	strikes.append(s)
	telegraph.column(s.x - Tuning.STORM_WIDTH * 0.5, s.x + Tuning.STORM_WIDTH * 0.5, Tuning.STORM_TELEGRAPH)


## Colunas (x) onde um raio caiu NESTE passo — o Main confere se a nave estava nelas.
func take_strikes() -> Array[float]:
	return _struck_now


func update(dt: float, scroll_speed: float) -> void:
	_t += dt
	for c in clouds:
		c.pos.y += scroll_speed * Tuning.CLOUD_FALL_FACTOR * dt
		c.t += dt
		if c.pos.y - c.radius > view_size.y:
			c.alive = false
	for i in range(clouds.size() - 1, -1, -1):
		if not clouds[i].alive:
			clouds.remove_at(i)

	_struck_now.clear()
	for s in strikes:
		s.t += dt
		if not s.struck and s.t >= Tuning.STORM_TELEGRAPH:
			s.struck = true
			_struck_now.append(s.x)
			s.bolt = _make_bolt(s.x)
	for i in range(strikes.size() - 1, -1, -1):
		if strikes[i].t >= Tuning.STORM_TELEGRAPH + 0.35:
			strikes.remove_at(i)
	queue_redraw()


func _make_bolt(x: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var y := 0.0
	while y < view_size.y + 40.0:
		pts.append(Vector2(x + randf_range(-Tuning.STORM_WIDTH * 0.3, Tuning.STORM_WIDTH * 0.3), y))
		y += randf_range(70.0, 130.0)
	return pts


func _draw() -> void:
	# Nuvens: névoa violeta/verde (bem suave: com HDR 2D a mistura é linear) + contorno
	# tracejado no raio do efeito + faíscas de vez em quando.
	for c in clouds:
		for puff in c.puffs:
			var pp := c.pos + Vector2(puff.x, puff.y) + Vector2(sin(c.t * 0.8 + puff.x), cos(c.t * 0.6 + puff.y)) * 6.0
			draw_circle(pp, puff.z, Color(0.55, 0.2, 0.95, 0.05))
			draw_circle(pp, puff.z * 0.6, Color(0.3, 1.0, 0.5, 0.03))
		var r := c.radius * 0.85
		var dashes := 18
		for i in dashes:
			var a0 := TAU * i / dashes + c.t * 0.15
			draw_arc(c.pos, r, a0, a0 + TAU / dashes * 0.55, 6, Color(Palette.ION, 0.55), 3.0, true)
		if int(c.t * 3.0) % 4 == 0:
			var a := c.t * 5.0
			var p0 := c.pos + Vector2.from_angle(a) * r * 0.3
			var p1 := c.pos + Vector2.from_angle(a + 0.6) * r * 0.7
			draw_line(p0, p1, Palette.ION_HDR, 2.0, true)

	# Raios: zigue-zague branco com brilho violeta, logo após cair.
	for s in strikes:
		if not s.struck or s.bolt.size() < 2:
			continue
		var k := 1.0 - (s.t - Tuning.STORM_TELEGRAPH) / 0.35
		draw_polyline(s.bolt, Color(Palette.ION, 0.35 * k), 22.0, true)
		draw_polyline(s.bolt, Palette.WHITE_HDR * k, 5.0, true)
