class_name TelegraphLayer
extends Node2D
## Avisos de perigo que piscam antes de um ataque: coluna, linha e círculo.
## Regra do jogo: todo ataque forte é avisado antes (ver PLANO_V2.md, 2.1).

enum Shape { COLUMN, LINE, CIRCLE }

class Warning:
	var shape := 0
	var a := Vector2.ZERO  # COLUMN: (x0, x1) · LINE: início · CIRCLE: centro
	var b := Vector2.ZERO  # LINE: fim
	var size := 0.0        # LINE: largura · CIRCLE: raio
	var time := 0.0
	var total := 1.0

var view_size := Vector2.ZERO
var _warnings: Array[Warning] = []
var _t := 0.0


func resize(size: Vector2) -> void:
	view_size = size


func column(x0: float, x1: float, duration: float) -> void:
	_add(Shape.COLUMN, Vector2(x0, x1), Vector2.ZERO, 0.0, duration)


func line(from: Vector2, to: Vector2, width: float, duration: float) -> void:
	_add(Shape.LINE, from, to, width, duration)


func circle(center: Vector2, radius: float, duration: float) -> void:
	_add(Shape.CIRCLE, center, Vector2.ZERO, radius, duration)


func clear() -> void:
	_warnings.clear()
	queue_redraw()


func update(dt: float) -> void:
	_t += dt
	for w in _warnings:
		w.time += dt
	for i in range(_warnings.size() - 1, -1, -1):
		if _warnings[i].time >= _warnings[i].total:
			_warnings.remove_at(i)
	queue_redraw()


func _add(shape: Shape, a: Vector2, b: Vector2, size: float, duration: float) -> void:
	var w := Warning.new()
	w.shape = shape
	w.a = a
	w.b = b
	w.size = size
	w.total = duration
	_warnings.append(w)


func _draw() -> void:
	var blink := 0.5 + 0.5 * sin(_t * 18.0)
	for w in _warnings:
		var k := w.time / w.total  # 0 → 1 até o ataque
		# Com HDR 2D a mistura é linear: alfas baixos já aparecem bem mais fortes na tela.
		var fill := Color(Palette.DANGER, 0.008 + 0.012 * blink)
		match w.shape:
			Shape.COLUMN:
				var rect := Rect2(w.a.x, 0.0, w.a.y - w.a.x, view_size.y)
				draw_rect(rect, fill)
				var edge := Color(Palette.DANGER_HDR, 0.3 + 0.3 * blink)
				draw_line(Vector2(w.a.x, 0), Vector2(w.a.x, view_size.y), edge, 3.0)
				draw_line(Vector2(w.a.y, 0), Vector2(w.a.y, view_size.y), edge, 3.0)
				# Setas "V" descendo pela coluna mostram de onde vem o perigo.
				var cx := (w.a.x + w.a.y) * 0.5
				for i in 3:
					var y := fmod(_t * 600.0 + i * 220.0, view_size.y * 0.6) + 60.0
					var chevron := PackedVector2Array([Vector2(cx - 36, y), Vector2(cx, y + 30), Vector2(cx + 36, y)])
					draw_polyline(chevron, Color(Palette.DANGER_HDR, 0.55), 6.0, true)
			Shape.LINE:
				draw_line(w.a, w.b, fill, w.size)
				draw_line(w.a, w.b, Color(Palette.DANGER_HDR, 0.6 + 0.4 * blink), 3.0)
			Shape.CIRCLE:
				draw_circle(w.a, w.size, fill)
				# Anel que fecha até o tamanho real: mostra quanto falta.
				draw_arc(w.a, w.size * (2.0 - k), 0.0, TAU, 48, Color(Palette.DANGER_HDR, 0.8), 4.0, true)
				draw_arc(w.a, w.size, 0.0, TAU, 48, Color(Palette.DANGER, 0.7), 2.0, true)
