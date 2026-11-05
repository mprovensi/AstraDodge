class_name HazardLayer
extends Node2D
## Perigos do ambiente (Setor 3 — Nebulosa Iônica):
## - Nuvens iônicas: não machucam, mas dentro delas o escudo drena 3x mais rápido.
##   O contorno tracejado marca exatamente a área do efeito.
## - Raios da tempestade: aviso em coluna (TelegraphLayer) e depois o raio cai na coluna.
## - Cometas (Setor 5): aviso em linha (TelegraphLayer) e depois atravessam a tela na diagonal,
##   muito rápidos. Indestrutíveis: só desviar.
## - Portões de laser (Setor 7): feixe na largura toda que liga e desliga no compasso
##   (2 tempos ligado, 2 desligado). Piscam e fazem "tique" antes de ligar. Descem devagar:
##   subir ou descer a nave escolhe a hora de cruzar.
## - Poços gravitacionais (Setor 8): puxam a nave de leve e curvam os tiros. O contorno
##   tracejado é o alcance exato da gravidade. Não machucam.
## - Portais (Setor 8): pares ligados (entrada ciano, saída magenta). Rocha que entra num sai
##   pelo outro, na mesma altura. A saída brilha quando algo vai sair.

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

class Comet:
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var pos := Vector2.ZERO
	var t := 0.0          # < COMET_TELEGRAPH: ainda é só o aviso
	var alive := true

	func flying() -> bool:
		return t >= Tuning.COMET_TELEGRAPH

var clouds: Array[Cloud] = []
var strikes: Array[Strike] = []
var comets: Array[Comet] = []
var gates: Array[float] = []  # Setor 7: altura (y) de cada portão de laser
var wells: Array[Vector2] = []   # Setor 8: centro de cada poço gravitacional
var portals: Array[Dictionary] = []  # Setor 8: {a: Vector2 (entrada), b: Vector2 (saída), glow}
var _gate_t := 0.0             # relógio do compasso (todos os portões ligam juntos)
var _gate_was_on := false
var view_size := Vector2.ZERO
var _struck_now: Array[float] = []
var _t := 0.0


func resize(size: Vector2) -> void:
	view_size = size


func clear() -> void:
	clouds.clear()
	strikes.clear()
	comets.clear()
	gates.clear()
	wells.clear()
	portals.clear()
	_gate_t = 0.0
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


## Agenda um cometa de `from` até `to` (fora da tela): aviso em linha agora, voo depois.
## A faixa do aviso tem a largura exata do perigo (cometa + corpo da nave).
func spawn_comet(from: Vector2, to: Vector2, telegraph: TelegraphLayer) -> void:
	var c := Comet.new()
	c.from = from
	c.to = to
	c.pos = from
	comets.append(c)
	telegraph.line(from, to, Tuning.COMET_WARN_WIDTH, Tuning.COMET_TELEGRAPH)


## Poço gravitacional entrando por cima em `x`.
func spawn_well(x: float) -> void:
	wells.append(Vector2(x, -Tuning.WELL_RADIUS * 0.5))


## Par de portais entrando por cima: entrada em `xa`, saída em `xb` (mesma altura).
func spawn_portal(xa: float, xb: float) -> void:
	var y := -Tuning.PORTAL_RADIUS
	portals.append({"a": Vector2(xa, y), "b": Vector2(xb, y), "glow": 0.0})


## Puxão da gravidade (px/s) na nave em `p`: soma dos poços, mais forte perto do centro.
func well_pull(p: Vector2) -> Vector2:
	var pull := Vector2.ZERO
	for w in wells:
		var d := p.distance_to(w)
		if d < Tuning.WELL_RADIUS and d > 1.0:
			pull += (w - p) / d * Tuning.WELL_PULL * (1.0 - d / Tuning.WELL_RADIUS)
	return pull


## Aceleração (px/s²) que os poços aplicam num tiro em `p` (curva a trajetória).
func well_bend(p: Vector2) -> Vector2:
	var acc := Vector2.ZERO
	for w in wells:
		var d := p.distance_to(w)
		if d < Tuning.WELL_RADIUS and d > 1.0:
			acc += (w - p) / d * Tuning.WELL_BEND * (1.0 - d / Tuning.WELL_RADIUS)
	return acc


## Se `p` está dentro da ENTRADA de um portal, devolve o deslocamento até a saída (senão ZERO).
func portal_jump(p: Vector2) -> Vector2:
	for pt in portals:
		if p.distance_to(pt.a) < Tuning.PORTAL_RADIUS:
			pt.glow = 0.4
			return (pt.b as Vector2) - (pt.a as Vector2)
	return Vector2.ZERO


## Portão de laser entrando por cima.
func spawn_gate() -> void:
	gates.append(-40.0)


## Os portões estão ligados agora? (todos seguem o mesmo compasso)
func gates_on() -> bool:
	return fmod(_gate_t, Tuning.GATE_PERIOD) < Tuning.GATE_PERIOD * Tuning.GATE_ON_FRACTION


## Faltam menos de GATE_WARN s para ligar (pisca + tique)?
func gates_warning() -> bool:
	return fmod(_gate_t, Tuning.GATE_PERIOD) >= Tuning.GATE_PERIOD - Tuning.GATE_WARN


## Algum portão LIGADO encosta na nave?
func gate_hits(p: Vector2, radius: float) -> bool:
	if not gates_on():
		return false
	for y in gates:
		if absf(p.y - y) < Tuning.GATE_HALF + radius * 0.6:
			return true
	return false


## Algum cometa em voo encosta no círculo (nave)?
func comet_hits(p: Vector2, radius: float) -> bool:
	for c in comets:
		if c.flying() and p.distance_to(c.pos) < Tuning.COMET_RADIUS + radius:
			return true
	return false


## Colunas (x) onde um raio caiu NESTE passo — o Main confere se a nave estava nelas.
func take_strikes() -> Array[float]:
	return _struck_now


func update(dt: float, scroll_speed: float) -> void:
	_t += dt
	# Portões: descem devagar; o relógio do compasso só anda enquanto há portão na tela.
	if not gates.is_empty():
		var was_warning := gates_warning()
		var was_on := gates_on()
		_gate_t += dt
		if gates_warning() and not was_warning:
			Sfx.play("click", -4.0, 1.6, 0.0)
		if gates_on() and not was_on:
			Sfx.play("alarm", -12.0, 2.0, 0.0)
		for i in gates.size():
			gates[i] += minf(scroll_speed, Tuning.GATE_SPEED) * dt
		for i in range(gates.size() - 1, -1, -1):
			if gates[i] > view_size.y + 40.0:
				gates.remove_at(i)
	for i in wells.size():
		wells[i] = wells[i] + Vector2(0, scroll_speed * Tuning.WELL_FALL_FACTOR * dt)
	for i in range(wells.size() - 1, -1, -1):
		if wells[i].y - Tuning.WELL_RADIUS > view_size.y:
			wells.remove_at(i)
	for pt in portals:
		var fall := scroll_speed * Tuning.PORTAL_FALL_FACTOR * dt
		pt.a = (pt.a as Vector2) + Vector2(0, fall)
		pt.b = (pt.b as Vector2) + Vector2(0, fall)
		pt.glow = maxf(0.0, pt.glow - dt)
	for i in range(portals.size() - 1, -1, -1):
		if (portals[i].a as Vector2).y - Tuning.PORTAL_RADIUS > view_size.y:
			portals.remove_at(i)
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

	for c in comets:
		c.t += dt
		if c.flying():
			var dir := (c.to - c.from).normalized()
			c.pos += dir * Tuning.COMET_SPEED * dt
			if (c.pos - c.from).length() >= (c.to - c.from).length():
				c.alive = false
	for i in range(comets.size() - 1, -1, -1):
		if not comets[i].alive:
			comets.remove_at(i)
	queue_redraw()


func _make_bolt(x: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var y := 0.0
	while y < view_size.y + 40.0:
		pts.append(Vector2(x + randf_range(-Tuning.STORM_WIDTH * 0.3, Tuning.STORM_WIDTH * 0.3), y))
		y += randf_range(70.0, 130.0)
	return pts


## Cometa: cauda de partículas que ondula (curva), cabeleira e núcleo girando.
func _draw_comet(c: Comet) -> void:
	var back := (c.from - c.to).normalized()
	var side := back.orthogonal()
	var r := Tuning.COMET_RADIUS
	var tail := PackedVector2Array([c.pos + side * r * 1.1, c.pos - side * r * 1.1, c.pos + back * r * 9.0])
	draw_colored_polygon(tail, Color(0.45, 0.8, 1.0, 0.1))
	for i in 16:
		var k := float(i) / 16.0
		var wave := sin(c.t * 9.0 + k * 7.0) * r * 0.5 * k
		var p := c.pos + back * r * (1.0 + k * 8.0) + side * wave
		draw_circle(p, r * (0.55 - 0.45 * k), Color(0.75, 0.92, 1.0, 0.45 * (1.0 - k)))
	draw_circle(c.pos, r * 1.6, Color(0.7, 0.9, 1.0, 0.12))   # cabeleira
	draw_circle(c.pos, r * 1.25, Color(0.85, 0.95, 1.0, 0.18))
	var sheets := Game.art.dust_sheets(4)  # gelo do Setor 5
	if sheets.is_empty():
		draw_circle(c.pos, r, Color(2.2, 2.6, 3.0))
	else:
		var sheet := sheets[0]
		var frame := posmod(int(c.t * 14.0), ArtSet.SHEET_FRAMES)
		var fw := sheet.get_width() / ArtSet.SHEET_COLS
		var fh := sheet.get_height() / ArtSet.SHEET_ROWS
		var half := r / Game.art.dust_fill
		draw_texture_rect_region(sheet, Rect2(c.pos - Vector2(half, half), Vector2(half, half) * 2.0),
				Rect2((frame % ArtSet.SHEET_COLS) * fw, (frame / ArtSet.SHEET_COLS) * fh, fw, fh), Color(1.5, 1.7, 1.9))
	draw_arc(c.pos, r * 1.08, 0.0, TAU, 32, Palette.ENEMY_HDR, 3.0, true)


## Emissor do portão: caixa de metal com 3 bobinas que acendem no aviso e ficam vermelhas ligadas.
func _draw_emitter(x: float, y: float, on: bool, warn: bool) -> void:
	var body := Rect2(x - 20.0, y - 40.0, 40.0, 80.0)
	draw_rect(body, Color(0.16, 0.17, 0.21))
	draw_rect(Rect2(body.position + Vector2(4, 4), Vector2(14, 72)), Color(0.27, 0.29, 0.34))  # luz na face
	draw_rect(body, Color(0.05, 0.055, 0.07), false, 3.0)
	for k in 3:
		var coil := Rect2(x - 23.0, y - 26.0 + k * 20.0, 46.0, 10.0)
		var hot := Palette.DANGER_HDR if on else (Palette.FLAME_HDR if warn else Color(0.45, 0.32, 0.22))
		draw_rect(coil, Color(0.3, 0.2, 0.14))
		draw_rect(coil.grow(-2.0), hot)
	draw_circle(Vector2(x, y), 7.0, Palette.WHITE_HDR if on else Color(0.3, 0.1, 0.1))


func _draw() -> void:
	# Nuvens: névoa violeta/verde (bem suave: com HDR 2D a mistura é linear) + contorno
	# tracejado no raio do efeito + faíscas de vez em quando.
	for c in clouds:
		for puff in c.puffs:
			var pp := c.pos + Vector2(puff.x, puff.y) + Vector2(sin(c.t * 0.8 + puff.x), cos(c.t * 0.6 + puff.y)) * 6.0
			draw_circle(pp, puff.z, Color(0.55, 0.2, 0.95, 0.05))
			draw_circle(pp, puff.z * 0.6, Color(0.3, 1.0, 0.5, 0.03))
			# 3ª camada: miolo mais denso que deriva ao contrário (dá volume à nuvem).
			var core := c.pos + Vector2(puff.x, puff.y) * 0.55 - Vector2(sin(c.t * 0.5 + puff.y), cos(c.t * 0.7 + puff.x)) * 9.0
			draw_circle(core, puff.z * 0.45, Color(0.75, 0.45, 1.0, 0.04))
		# Faíscas presas na nuvem (pontinhos que acendem e apagam).
		for i in 6:
			var ang := float(i) * 2.4 + c.t * 0.4
			var sp := c.pos + Vector2.from_angle(ang) * c.radius * (0.25 + 0.1 * i)
			var flick := maxf(0.0, sin(c.t * 7.0 + i * 1.7))
			draw_circle(sp, 2.5 + flick * 2.0, Color(Palette.ION_HDR, 0.6 * flick))
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

	# Poços: disco escuro com anel de acreção girando e contorno tracejado do alcance.
	for w in wells:
		var spin := _t * 1.6
		draw_circle(w, Tuning.WELL_RADIUS * 0.45, Color(0.0, 0.0, 0.0, 0.25))
		# Estrelas sendo puxadas: pontos em espiral que caem para o centro e somem no olho.
		for i in 14:
			var k := fmod(_t * 0.35 + float(i) / 14.0, 1.0)  # 0 = longe, 1 = chegando
			var rr := lerpf(Tuning.WELL_RADIUS * 0.9, Tuning.WELL_CORE, k * k)
			var ang := float(i) * 2.399 + k * 5.0
			var star := w + Vector2.from_angle(ang) * rr
			var trail := w + Vector2.from_angle(ang - 0.25) * minf(rr + 14.0, Tuning.WELL_RADIUS)
			draw_line(trail, star, Color(1.0, 0.85, 1.0, 0.25 * k), 2.0, true)
			draw_circle(star, 1.5 + k * 1.5, Color(1.4, 1.1, 1.6, 0.35 + 0.5 * k))
		for k in 3:
			var r := Tuning.WELL_CORE * (1.4 + k * 0.7)
			draw_arc(w, r, spin * (1.0 + k * 0.3), spin * (1.0 + k * 0.3) + PI * 1.2, 24,
					Color(1.6, 0.5, 1.8, 0.7 - k * 0.2), 4.0 - k, true)
		draw_circle(w, Tuning.WELL_CORE, Color(0.02, 0.0, 0.04))
		draw_arc(w, Tuning.WELL_CORE, 0.0, TAU, 32, Palette.MAGENTA_HDR, 3.0, true)
		var dashes := 24
		for i in dashes:
			var a0 := TAU * i / dashes - _t * 0.3
			draw_arc(w, Tuning.WELL_RADIUS, a0, a0 + TAU / dashes * 0.5, 6, Color(Palette.MAGENTA, 0.45), 3.0, true)

	# Portais: entrada ciano, saída magenta, ligados por uma linha pontilhada.
	for pt in portals:
		var a: Vector2 = pt.a
		var b: Vector2 = pt.b
		var x := 0.0
		var dir := (b - a).normalized()
		var length := a.distance_to(b)
		while x < length:
			draw_line(a + dir * x, a + dir * minf(x + 14.0, length), Color(1, 1, 1, 0.18), 2.0)
			x += 30.0
		for side in 2:
			var c: Vector2 = a if side == 0 else b
			var col: Color = Palette.NEON_HDR if side == 0 else Palette.MAGENTA_HDR
			var r := Tuning.PORTAL_RADIUS
			draw_circle(c, r, Color(col, 0.08 + (0.25 * pt.glow if side == 1 else 0.0)))
			# Miolo em espiral (entrada gira para dentro, saída para fora).
			var turn := _t * (3.0 if side == 0 else -3.0)
			for k in 3:
				draw_arc(c, r * (0.25 + 0.2 * k), turn + k * 1.3, turn + k * 1.3 + PI * 0.9, 16,
						Color(col, 0.45 - k * 0.1), 3.0, true)
			# Anel de metal com 4 travas: dá corpo ao portal (lê "máquina", não "mancha").
			draw_arc(c, r + 4.0, 0.0, TAU, 40, Color(0.12, 0.13, 0.17), 12.0, true)
			draw_arc(c, r + 4.0, 0.0, TAU, 40, Color(0.42, 0.45, 0.52), 3.0, true)
			for k in 4:
				var lock_at := c + Vector2.from_angle(TAU * k / 4.0 + PI * 0.25) * (r + 4.0)
				draw_set_transform(lock_at, TAU * k / 4.0 + PI * 0.25)
				draw_rect(Rect2(-9, -7, 18, 14), Color(0.22, 0.24, 0.3))
				draw_rect(Rect2(-9, -7, 18, 14), Color(col, 0.9), false, 2.0)
				draw_set_transform(Vector2.ZERO, 0.0)
			draw_arc(c, r * 0.92, _t * 3.0, _t * 3.0 + PI * 1.5, 32, col, 4.0, true)

	# Portões: pilares nas bordas; feixe vermelho forte ligado, tracejado apagado desligado,
	# piscando nos instantes antes de ligar.
	var on := gates_on()
	var warn := gates_warning() and int(_gate_t * 14.0) % 2 == 0
	for y in gates:
		for x: float in [0.0, view_size.x]:
			_draw_emitter(x, y, on, warn)
		if on:
			draw_line(Vector2(0, y), Vector2(view_size.x, y), Color(Palette.DANGER, 0.25), Tuning.GATE_HALF * 3.0)
			draw_line(Vector2(0, y), Vector2(view_size.x, y), Palette.DANGER_HDR, Tuning.GATE_HALF * 1.2)
			draw_line(Vector2(0, y), Vector2(view_size.x, y), Palette.WHITE_HDR, 3.0)
		else:
			var c := Color(Palette.DANGER_HDR, 0.8) if warn else Color(Palette.DANGER, 0.35)
			var x := 20.0
			while x < view_size.x - 20.0:
				draw_line(Vector2(x, y), Vector2(minf(x + 26.0, view_size.x - 20.0), y), c, 3.0)
				x += 46.0

	# Cometas: núcleo de gelo e rocha girando (folha do Setor 5), cabeleira clara e cauda curva
	# de partículas; contorno quente = perigo (indestrutível, só desviar).
	for c in comets:
		if not c.flying():
			continue
		_draw_comet(c)

	# Raios: zigue-zague branco com brilho violeta, logo após cair.
	for s in strikes:
		if not s.struck or s.bolt.size() < 2:
			continue
		var k := 1.0 - (s.t - Tuning.STORM_TELEGRAPH) / 0.35
		draw_polyline(s.bolt, Color(Palette.ION, 0.35 * k), 22.0, true)
		draw_polyline(s.bolt, Palette.WHITE_HDR * k, 5.0, true)
