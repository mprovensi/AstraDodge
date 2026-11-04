extends SceneTree
## GALERIA DE ESTILOS (PLANO_ARTE_25D.md): mostra lado a lado a arte atual e os exemplos
## 2.5D (asteroides por shader e luz/relevo no lixo espacial), para escolher a direção.
## Uso (grava quadros): godot --path . --script res://tests/art_gallery.gd --write-movie out/f.png --fixed-fps 30 --quit-after 90

const W := 1080.0

const TYPES := [
	["ROCHOSO", {"color_light": Color(0.74, 0.74, 0.78), "color_dark": Color(0.22, 0.22, 0.26), "craters": 0.7, "bumpiness": 0.5}],
	["FERROSO", {"color_light": Color(0.78, 0.5, 0.38), "color_dark": Color(0.28, 0.14, 0.1), "craters": 0.4, "bumpiness": 0.4, "specular": 0.6}],
	["CARBONÁCEO", {"color_light": Color(0.36, 0.34, 0.36), "color_dark": Color(0.08, 0.08, 0.09), "craters": 0.5, "bumpiness": 0.7, "porosity": 0.4, "rim_color": Color(1.0, 0.95, 0.85)}],
	["GELO", {"color_light": Color(0.85, 0.95, 1.0), "color_dark": Color(0.35, 0.55, 0.78), "craters": 0.2, "bumpiness": 0.25, "specular": 1.0, "translucency": 0.8, "lumpiness": 0.14}],
	["CRISTALINO", {"color_light": Color(0.62, 0.55, 0.78), "color_dark": Color(0.2, 0.15, 0.3), "craters": 0.3, "emission": 1.0, "emission_color": Color(0.7, 0.4, 1.0)}],
	["PEDRA-POMES", {"color_light": Color(0.92, 0.88, 0.8), "color_dark": Color(0.55, 0.5, 0.45), "craters": 0.2, "bumpiness": 0.3, "porosity": 0.9}],
	["VULCÂNICO", {"color_light": Color(0.32, 0.26, 0.24), "color_dark": Color(0.08, 0.05, 0.05), "craters": 0.4, "bumpiness": 0.6, "emission": 1.0, "emission_color": Color(1.0, 0.4, 0.08)}],
]

var _light: PointLight2D
var _t := 0.0


class ShaderRock extends Node2D:
	var size := 200.0

	func _draw() -> void:
		draw_rect(Rect2(-size * 0.5, -size * 0.5, size, size), Color.WHITE)


func _initialize() -> void:
	root.get_node("Game").persist = false
	var scene := Node2D.new()
	root.add_child(scene)
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_hdr_threshold = 1.0
	for level in 7:
		env.set_glow_level(level, [1.0, 0.55, 0.12, 0.0, 0.0, 0.0, 0.0][level])
	var we := WorldEnvironment.new()
	we.environment = env
	scene.add_child(we)

	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.09)
	bg.size = Vector2(W, 1920)
	scene.add_child(bg)

	_title(scene, "ATUAL (vetor plano)", 40)
	var art = root.get_node("Game").art
	var flat := [art.dust_textures[0], art.rock_textures(false, 2)[0], art.metal_textures[0], art.rock_textures(true, 3)[0]]
	for i in flat.size():
		var s := Sprite2D.new()
		s.texture = flat[i]
		s.scale = Vector2.ONE * (170.0 / 256.0)
		s.position = Vector2(150 + i * 260, 210)
		scene.add_child(s)

	_title(scene, "2.5D — ASTEROIDES POR SHADER (giram em 3D)", 340)
	var rock_shader := preload("res://shaders/asteroid.gdshader")
	for i in TYPES.size():
		var rock := ShaderRock.new()
		var mat := ShaderMaterial.new()
		mat.shader = rock_shader
		mat.set_shader_parameter("seed", float(i) * 1.37)
		for key: String in TYPES[i][1]:
			var v = TYPES[i][1][key]
			mat.set_shader_parameter(key, Vector3(v.r, v.g, v.b) if v is Color else v)
		rock.material = mat
		var col := i % 4
		var row := i / 4
		rock.position = Vector2(150 + col * 260, 520 + row * 300)
		scene.add_child(rock)
		_label(scene, TYPES[i][0], rock.position + Vector2(0, 125))

	_title(scene, "LIXO ESPACIAL: SEM LUZ × COM LUZ E RELEVO (luz se movendo)", 1160)
	var junk_tex: Texture2D = art.rock_textures(true, 3)[0]
	var plain := Sprite2D.new()
	plain.texture = junk_tex
	plain.scale = Vector2.ONE * 1.1
	plain.position = Vector2(280, 1450)
	scene.add_child(plain)
	var lit := Sprite2D.new()
	var ct := CanvasTexture.new()
	ct.diffuse_texture = junk_tex
	ct.normal_texture = ImageTexture.create_from_image(_normal_map(junk_tex.get_image()))
	ct.specular_color = Color(0.8, 0.8, 0.8)
	ct.specular_shininess = 0.6
	lit.texture = ct
	lit.scale = Vector2.ONE * 1.1
	lit.position = Vector2(800, 1450)
	lit.light_mask = 2
	scene.add_child(lit)
	var ambient := CanvasModulate.new()  # deixa a luz fazer diferença
	scene.add_child(ambient)
	ambient.color = Color(0.55, 0.55, 0.6)  # cena mais escura: a luz aparece
	_light = PointLight2D.new()
	var grad := GradientTexture2D.new()
	grad.fill = GradientTexture2D.FILL_RADIAL
	grad.fill_from = Vector2(0.5, 0.5)
	grad.fill_to = Vector2(1.0, 0.5)
	grad.gradient = Gradient.new()
	grad.gradient.set_color(0, Color.WHITE)
	grad.gradient.set_color(1, Color(1, 1, 1, 0))
	grad.width = 512
	grad.height = 512
	_light.texture = grad
	_light.texture_scale = 1.6
	_light.energy = 2.4
	_light.color = Color(1.0, 0.85, 0.6)
	_light.range_item_cull_mask = 2
	_light.height = 60.0
	scene.add_child(_light)
	_label(scene, "atual", Vector2(280, 1620))
	_label(scene, "com mapa de relevo + luz", Vector2(800, 1620))
	process_frame.connect(_tick)


func _tick() -> void:
	_t += 1.0 / 30.0
	_light.position = Vector2(800, 1450) + Vector2(cos(_t * 2.0), sin(_t * 2.0)) * 170.0


## Mapa de normal simples: altura = "chanfro" pela distância até a borda (alfa) + brilho.
func _normal_map(src: Image) -> Image:
	var img: Image = src.duplicate()
	if img.is_compressed():
		img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	var height := PackedFloat32Array()
	height.resize(w * h)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			height[y * w + x] = c.a * (0.6 + 0.4 * c.get_luminance())
	# Suaviza a altura (o chanfro nasce do desfoque do alfa).
	for pass_i in 6:
		var tmp := height.duplicate()
		for y in range(1, h - 1):
			for x in range(1, w - 1):
				var i := y * w + x
				tmp[i] = (height[i] * 4.0 + height[i - 1] + height[i + 1] + height[i - w] + height[i + w]) / 8.0
		height = tmp
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var i := y * w + x
			var dx := (height[i + 1] - height[i - 1]) * 6.0
			var dy := (height[i + w] - height[i - w]) * 6.0
			var n := Vector3(-dx, -dy, 1.0).normalized()
			out.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5, 1.0))
	return out


func _title(parent: Node, text: String, y: float) -> void:
	var l := Label.new()
	l.text = text
	l.position = Vector2(30, y)
	l.add_theme_font_size_override("font_size", 38)
	l.add_theme_color_override("font_color", Color(0.4, 0.95, 1.0))
	parent.add_child(l)


func _label(parent: Node, text: String, at: Vector2) -> void:
	var l := Label.new()
	l.text = text
	l.size = Vector2(240, 40)
	l.position = at - Vector2(120, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	parent.add_child(l)
