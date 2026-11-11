class_name Formations
extends RefCounted
## Geometria em (x, profundidade): todas as peças ficam fora de uma rota contínua.
## O campo transforma a profundidade em altura e move o conjunto sem deformá-lo.

const IDS := ["v", "stair", "zigzag", "ring", "checker", "funnel", "rain"]
const NAMES := {"v": "V", "stair": "ESCADA", "zigzag": "ZIGUE-ZAGUE", "ring": "ANEL ABERTO",
		"checker": "TABULEIRO", "funnel": "FUNIL", "rain": "CHUVA FINA"}
const LEAD := 160.0
const MAX_DEPTH := 660.0

class Piece:
	var pos: Vector2
	var radius: float
	var metal: bool

class Layout:
	var pieces: Array[Piece] = []
	var route := PackedVector2Array()
	var depth := 0.0
	var width := 0.0


static func available(sector: int) -> Array:
	# Introduções: V/chuva no 1; escada no 2; zigue no 3; anel no 4; tabuleiro no 5; funil no 6.
	var unlocked := ["v", "rain", "stair", "zigzag", "ring", "checker", "funnel"]
	return unlocked.slice(0, mini(unlocked.size(), maxi(2, sector + 2)))


static func make(id: String, width: float, entry_x: float) -> Layout:
	if not id in IDS or width < Tuning.SAFE_GAP_WIDTH + 2.0 * (Tuning.WALL_METAL_RADIUS + 20.0):
		return null
	var layout := Layout.new()
	layout.width = width
	var edge := Tuning.SAFE_GAP_WIDTH * 0.5 + 20.0
	var center := clampf(entry_x, edge, width - edge)
	var amplitude := minf(90.0, (width - 2.0 * edge) * 0.25)
	layout.depth = 480.0 if id in ["v", "ring", "checker"] else MAX_DEPTH
	if id == "rain":
		layout.depth = 360.0
	elif id == "ring":
		layout.depth = 600.0
	layout.route.append(Vector2(center, -LEAD))
	for row in 4:
		var x := center
		if id == "stair":
			x += amplitude * (float(row) / 3.0 * 2.0 - 1.0)
		elif id == "zigzag":
			x += amplitude * (-1.0 if row % 2 == 0 else 1.0)
		layout.route.append(Vector2(clampf(x, edge, width - edge), layout.depth * row / 3.0))
	layout.route.append(Vector2(layout.route[-1].x, layout.depth + LEAD))
	match id:
		"v":
			for side in [-1.0, 1.0]:
				for step in 5:
					_add(layout, Vector2(center + side * (190.0 + step * 110.0), 480.0 - step * 110.0), 50.0, false)
		"stair", "zigzag":
			for row in 4:
				_grid_row(layout, row * 220.0, Tuning.WALL_METAL_RADIUS, true)
		"ring":
			# Duas aberturas alinhadas: entrar E sair, sem ficar preso num círculo fechado.
			var rx := minf(410.0, width * 0.5 - Tuning.WALL_METAL_RADIUS - 20.0)
			for step in 12:
				var angle := TAU * step / 12.0
				_add(layout, Vector2(center + cos(angle) * rx, 300.0 + sin(angle) * 300.0), Tuning.WALL_METAL_RADIUS, true)
		"checker":
			for row in 4:
				_grid_row(layout, row * 160.0, 50.0, false, row % 2)
		"funnel":
			for row in 4:
				var spread := lerpf(width * 0.48, Tuning.SAFE_GAP_WIDTH * 0.5 + Tuning.WALL_METAL_RADIUS + 12.0, row / 3.0)
				for side in [-1.0, 1.0]:
					_add(layout, Vector2(center + side * spread, row * 220.0), Tuning.WALL_METAL_RADIUS, true)
		"rain":
			for row in 4:
				_grid_row(layout, row * 120.0, 38.0, false)
	return layout


static func _grid_row(layout: Layout, depth: float, radius: float, metal: bool, parity := -1) -> void:
	var margin := radius + 20.0
	var count := mini(8, floori((layout.width - 2.0 * margin) / (radius * 2.0 + 20.0)) + 1)
	for col in count:
		if parity >= 0 and col % 2 != parity:
			continue
		var x := lerpf(margin, layout.width - margin, float(col) / (count - 1))
		_add(layout, Vector2(x, depth), radius, metal)


static func _add(layout: Layout, pos: Vector2, radius: float, metal: bool) -> void:
	if pos.x - radius < 20.0 or pos.x + radius > layout.width - 20.0 or pos.y < 0.0:
		return
	for i in range(1, layout.route.size()):
		var closest := Geometry2D.get_closest_point_to_segment(pos, layout.route[i - 1], layout.route[i])
		if closest.distance_to(pos) < Tuning.SAFE_GAP_WIDTH * 0.5 + radius:
			return
	for other in layout.pieces:
		if pos.distance_to(other.pos) < radius + other.radius + 8.0:
			return
	var piece := Piece.new()
	piece.pos = pos
	piece.radius = radius
	piece.metal = metal
	layout.pieces.append(piece)
