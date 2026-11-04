class_name Starfield
extends Node2D
## Fundo de estrelas em 3 camadas (parallax). Viram "riscos" conforme a velocidade sobe.

const LAYERS := [
	{"count": 70, "factor": 0.12, "size": 1.6, "alpha": 0.35},
	{"count": 45, "factor": 0.3, "size": 2.4, "alpha": 0.55},
	{"count": 25, "factor": 0.65, "size": 3.2, "alpha": 0.85},
]

var view_size := Vector2.ZERO
var _stars: Array[PackedVector2Array] = []
var _speed := 0.0


func resize(size: Vector2) -> void:
	view_size = size
	_stars.clear()
	for layer: Dictionary in LAYERS:
		var arr := PackedVector2Array()
		for i: int in layer["count"]:
			arr.append(Vector2(randf() * size.x, randf() * size.y))
		_stars.append(arr)


func update(dt: float, speed: float) -> void:
	_speed = speed
	for li in _stars.size():
		var factor: float = LAYERS[li]["factor"]
		var arr := _stars[li]
		for i in arr.size():
			var p := arr[i]
			p.y += speed * factor * dt
			if p.y > view_size.y:
				p = Vector2(randf() * view_size.x, p.y - view_size.y)
			elif p.y < 0.0:  # fundo "subindo" (inversão do Setor 8)
				p = Vector2(randf() * view_size.x, p.y + view_size.y)
			arr[i] = p
		_stars[li] = arr
	queue_redraw()


func _draw() -> void:
	for li in _stars.size():
		var layer: Dictionary = LAYERS[li]
		var factor: float = layer["factor"]
		var size: float = layer["size"]
		var color := Color(0.75, 0.85, 1.0, layer["alpha"])
		var length := maxf(size, _speed * factor * 0.05)
		for p in _stars[li]:
			draw_line(p, p - Vector2(0, length), color, size)
