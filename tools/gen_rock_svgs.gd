extends SceneTree
## Gera os SVGs das rochas de cada setor (PLANO_OBSTACULOS.md, O1) em art/sprites/:
##   dust_s{N}_{k}.svg (poeira destrutível) e metal_s{N}_{k}.svg (indestrutível), N = 2..8, k = 1..2.
## O Setor 1 usa os desenhos originais (dust_1..3, metal_1..3).
## Regras do desenho (para casar com a colisão, ver ArtSet.dust_fill/metal_fill):
##  - POEIRA sempre CLARA, METAL sempre ESCURO (é assim que o jogador sabe o que dá para quebrar);
##  - contorno "quase redondo": raio entre MIN_R e MAX_R em volta do centro (128,128);
##  - poeira clara/quente, metal escuro com borda de aço — a mesma leitura do Setor 1.
## Depois rode tools/gen_sprites.gd (PNG) e tools/gen_art_set.gd (ArtSet).
## Uso: godot --headless --path . --script res://tools/gen_rock_svgs.gd

const OUT := "res://art/sprites"
const MIN_R := 118.0
const MAX_R := 125.0

var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	for sector in range(2, 9):
		for k in [1, 2]:
			rng.seed = sector * 100 + k
			_save("dust_s%d_%d" % [sector, k], _dust(sector, k))
			rng.seed = sector * 100 + k + 50
			_save("metal_s%d_%d" % [sector, k], _metal(sector, k))
	print("SVGs das rochas por setor gerados em ", OUT)
	quit()


# ---------------------------------------------------------------- contornos

## Contorno irregular quase redondo (lista de pontos).
func _outline(points: int, jitter: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var phase := rng.randf() * TAU
	for i in points:
		var a := phase + TAU * i / points + rng.randf_range(-0.12, 0.12)
		var r := rng.randf_range(MAX_R - jitter, MAX_R)
		pts.append(Vector2(128, 128) + Vector2.from_angle(a) * clampf(r, MIN_R, MAX_R))
	return pts


## Octógono "caixa" com cantos chanfrados (apótema alto para cobrir a colisão).
func _box(rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 8:
		var a := rot + TAU * i / 8.0 + PI / 8.0
		pts.append(Vector2(128, 128) + Vector2.from_angle(a) * 126.0)
	return pts


func _path(pts: PackedVector2Array) -> String:
	var s := "M%.0f %.0f" % [pts[0].x, pts[0].y]
	for i in range(1, pts.size()):
		s += " L%.0f %.0f" % [pts[i].x, pts[i].y]
	return s + " Z"


func _rand_in(r: float) -> Vector2:
	return Vector2(128, 128) + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, r)


# ---------------------------------------------------------------- poeira

func _dust(sector: int, k: int) -> String:
	var body := ""
	match sector:
		2:  # minério com veios âmbar
			body += _shape(_outline(13, 9), "#a8957e", "#5e4e3e", "#ece0cc")
			for i in 3:
				var a := _rand_in(70.0)
				var b := a + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(40, 70)
				var c := b + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(25, 45)
				body += "<path d=\"M%.0f %.0f L%.0f %.0f L%.0f %.0f\" fill=\"none\" stroke=\"#ffb02a\" stroke-width=\"6\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>" % [a.x, a.y, b.x, b.y, c.x, c.y]
			body += _craters(2, "#4d4034", "#8a7864")
		3:  # rocha escura com cristais violeta/verdes
			body += _shape(_outline(12, 10), "#9a86c8", "#4a3a6e", "#e0d4ff")
			for i in 3 + k:
				body += _crystal(_rand_in(75.0), rng.randf_range(14, 24), "#9c6bff" if i % 2 == 0 else "#5dffb0")
		4:  # caixa de carga (painel com cintas)
			var pts := _box(rng.randf_range(-0.2, 0.2))
			body += _shape(pts, "#a4824e", "#5a4321", "#e8d2a2")
			body += "<path d=\"M58 58 L198 198 M198 58 L58 198\" stroke=\"#5a4321\" stroke-width=\"12\"/>"
			body += "<rect x=\"98\" y=\"98\" width=\"60\" height=\"60\" fill=\"#c9a467\" stroke=\"#5a4321\" stroke-width=\"5\"/>"
		5:  # neve compacta
			body += _shape(_outline(16, 6), "#e9f4ff", "#9cbad6", "#ffffff")
			for i in 4:
				var p := _rand_in(70.0)
				body += "<circle cx=\"%.0f\" cy=\"%.0f\" r=\"%.0f\" fill=\"#c9dcef\" opacity=\"0.8\"/>" % [p.x, p.y, rng.randf_range(10, 22)]
		6:  # favo seco (células hexagonais)
			body += _shape(_outline(12, 8), "#c48a2a", "#6d4510", "#f3cc7a")
			for cell in [Vector2(98, 98), Vector2(146, 98), Vector2(122, 140), Vector2(74, 140), Vector2(170, 140), Vector2(98, 182), Vector2(146, 182)]:
				body += _hex(cell, 24.0, "#8a5a14", "#f3cc7a")
		7:  # contêiner pequeno com faixa
			var pts := _box(0.0)
			body += _shape(pts, "#a9bdd6", "#5f7896", "#eef4ff")
			body += "<rect x=\"30\" y=\"112\" width=\"196\" height=\"32\" fill=\"#ffc83a\"/>"
			for x in [70, 100, 130, 160, 190]:
				body += "<path d=\"M%d 40 L%d 216\" stroke=\"#3c4a5c\" stroke-width=\"5\"/>" % [x, x]
		8:  # obsidiana com rachaduras magenta
			body += _shape(_outline(11, 12), "#8e6c9e", "#3e2848", "#f0d8ff")
			for i in 3:
				var a := _rand_in(40.0)
				var b := a + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(50, 80)
				body += "<path d=\"M%.0f %.0f L%.0f %.0f\" stroke=\"#ff4fd8\" stroke-width=\"5\" stroke-linecap=\"round\"/>" % [a.x, a.y, b.x, b.y]
			body += "<path d=\"M70 80 L96 66\" stroke=\"#ffffff\" stroke-opacity=\"0.6\" stroke-width=\"5\" stroke-linecap=\"round\"/>"
	return _svg("Poeira do Setor %d (variação %d)" % [sector, k], body)


# ---------------------------------------------------------------- metal

func _metal(sector: int, k: int) -> String:
	var body := ""
	match sector:
		2:  # lingote enferrujado
			body += _shape(_box(rng.randf_range(-0.3, 0.3)), "#5a3a26", "#21130a", "#b07a52")
			body += "<path d=\"M40 100 L216 96 M40 160 L216 164\" stroke=\"#7a4e30\" stroke-width=\"8\"/>"
			body += _rivets([Vector2(60, 70), Vector2(196, 70), Vector2(60, 190), Vector2(196, 190)], "#c08a5e")
		3:  # casco escuro com brilho iônico
			body += _shape(_outline(10, 8), "#1c1f2e", "#07080e", "#6f86b8")
			body += "<path d=\"M50 128 Q128 80 206 128 Q128 176 50 128 Z\" fill=\"none\" stroke=\"#5dffb0\" stroke-width=\"4\" stroke-opacity=\"0.8\"/>"
			body += _rivets([Vector2(128, 60), Vector2(128, 196)], "#6f86b8")
		4:  # pedaço de casco de nave
			body += _shape(_outline(9, 14), "#3d3a40", "#141215", "#a39aa6")
			body += "<path d=\"M40 110 L216 110 M40 160 L216 160 M120 40 L120 216\" stroke=\"#5b5560\" stroke-width=\"6\"/>"
			body += "<path d=\"M150 120 L190 150 L170 170 Z\" fill=\"#a8351c\"/>"
		5:  # gelo azul-escuro "eterno"
			body += _shape(_outline(9, 8), "#1d3f6e", "#0a1830", "#8fc4ee")
			body += "<path d=\"M128 20 L128 236 M40 80 L216 176 M40 176 L216 80\" stroke=\"#5a8fc4\" stroke-opacity=\"0.6\" stroke-width=\"4\"/>"
		6:  # carapaça orgânica
			body += _shape(_outline(12, 7), "#26301a", "#0b0f07", "#8aa05a")
			for i in 3:
				var y := 70 + i * 50
				body += "<path d=\"M40 %d Q128 %d 216 %d\" fill=\"none\" stroke=\"#4d6030\" stroke-width=\"8\"/>" % [y, y - 30, y]
		7:  # bloco de concreto/aço com faixas de alerta
			body += _shape(_box(0.0), "#4a4d55", "#1a1c21", "#a6adbb")
			for i in 5:
				var x := 28 + i * 44
				body += "<path d=\"M%d 200 L%d 236\" stroke=\"#ffc83a\" stroke-width=\"14\"/>" % [x, x + 30]
			body += _rivets([Vector2(64, 64), Vector2(192, 64)], "#a6adbb")
		8:  # rocha "invertida": miolo vazio, contorno brilhante
			body += _shape(_outline(10, 10), "#05020a", "#05020a", "#ff8ef0")
			body += "<path d=\"%s\" fill=\"none\" stroke=\"#ff4fd8\" stroke-width=\"4\" stroke-opacity=\"0.6\" transform=\"translate(128 128) scale(0.7) translate(-128 -128)\"/>" % _path(_outline(10, 10))
	return _svg("Metálico do Setor %d (variação %d)" % [sector, k], body)


# ---------------------------------------------------------------- peças

func _shape(pts: PackedVector2Array, light: String, dark: String, edge: String) -> String:
	var id := "g%d" % rng.randi()
	return ("<defs><radialGradient id=\"%s\" cx=\"38%%\" cy=\"32%%\" r=\"75%%\"><stop offset=\"0\" stop-color=\"%s\"/>"
			+ "<stop offset=\"1\" stop-color=\"%s\"/></radialGradient></defs>"
			+ "<path d=\"%s\" fill=\"url(#%s)\" stroke=\"%s\" stroke-width=\"6\" stroke-linejoin=\"round\"/>") % [
			id, light, dark, _path(pts), id, edge]


func _craters(n: int, fill: String, edge: String) -> String:
	var s := ""
	for i in n:
		var p := _rand_in(60.0)
		s += "<circle cx=\"%.0f\" cy=\"%.0f\" r=\"%.0f\" fill=\"%s\" stroke=\"%s\" stroke-width=\"3\"/>" % [
				p.x, p.y, rng.randf_range(12, 24), fill, edge]
	return s


func _crystal(p: Vector2, size: float, color: String) -> String:
	var a := rng.randf() * TAU
	var pts := PackedVector2Array([p + Vector2.from_angle(a) * size, p + Vector2.from_angle(a + 2.2) * size * 0.5,
			p + Vector2.from_angle(a + PI) * size * 0.7, p + Vector2.from_angle(a - 2.2) * size * 0.5])
	return "<path d=\"%s\" fill=\"%s\" stroke=\"#ffffff\" stroke-width=\"2\" stroke-opacity=\"0.7\"/>" % [_path(pts), color]


func _hex(c: Vector2, r: float, fill: String, edge: String) -> String:
	var pts := PackedVector2Array()
	for i in 6:
		pts.append(c + Vector2.from_angle(TAU * i / 6.0) * r)
	return "<path d=\"%s\" fill=\"%s\" stroke=\"%s\" stroke-width=\"4\"/>" % [_path(pts), fill, edge]


func _rivets(points: Array, color: String) -> String:
	var s := ""
	for p: Vector2 in points:
		s += "<circle cx=\"%.0f\" cy=\"%.0f\" r=\"7\" fill=\"%s\"/>" % [p.x, p.y, color]
	return s


func _svg(comment: String, body: String) -> String:
	return ("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"256\" height=\"256\" viewBox=\"0 0 256 256\">\n"
			+ "  <!-- %s — gerado por tools/gen_rock_svgs.gd -->\n  %s\n</svg>\n") % [comment, body]


func _save(name: String, svg: String) -> void:
	var f := FileAccess.open("%s/%s.svg" % [OUT, name], FileAccess.WRITE)
	f.store_string(svg)
	f.close()
