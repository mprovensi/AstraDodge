extends SceneTree
## Gera as FOLHAS DE QUADROS do lixo espacial indestrutível (PLANO_INDESTRUTIVEIS.md, J0).
## Cada peça é montada em 3D aqui (malhas simples + sombreamento estilizado "toon"), gira e
## balança em 3D e é fotografada em JUNK_FRAMES quadros. O jogo só troca o quadro (leve).
## Saída por peça: sprites/junk_s{setor}_{k}.png (cor) e junk_s{setor}_{k}_luz.png (só a luz
## âmbar de alerta, branca em fundo transparente; o jogo pinta de âmbar e faz piscar).
## Precisa de janela (não use --headless).
## Uso: godot --path . --script res://tools/bake_junk.gd

const OUT := "res://sprites"
const FRAME_PX := 192
const RENDER_PX := 384          # renderiza em 2x e reduz (bordas mais lisas)
const FRAMES := ArtSet.JUNK_FRAMES
const COLS := ArtSet.JUNK_COLS
const TILT := deg_to_rad(30.0)  # inclinação da peça em relação à câmera (nunca fica de lado)
const OUTLINE := Color(0.045, 0.05, 0.065)

## Peças do Setor 1 (J0): [construtor, giros próprios por volta da oscilação]
const PIECES := [["_build_plate", 1], ["_build_turbine", 2], ["_build_container", 1]]

var _viewport: SubViewport
var _holder: Node3D
var _black := StandardMaterial3D.new()
var _white := StandardMaterial3D.new()


func _initialize() -> void:
	root.get_node("Game").persist = false
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(RENDER_PX, RENDER_PX)
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)

	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.46, 0.56)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	_viewport.add_child(world_env)

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.0  # quadro = 2 unidades: a peça cabe num raio de ~0,95
	cam.position = Vector3(0, 0, 5)
	_viewport.add_child(cam)

	# Sol de cima à esquerda (igual à nave e às rochas) + contraluz fria fraca.
	var sun := DirectionalLight3D.new()
	_viewport.add_child(sun)
	sun.look_at_from_position(Vector3(-1.0, 1.0, 1.3), Vector3.ZERO)
	sun.light_energy = 1.35
	sun.light_specular = 0.6
	var rim := DirectionalLight3D.new()
	_viewport.add_child(rim)
	rim.look_at_from_position(Vector3(1.0, -0.9, 0.4), Vector3.ZERO)
	rim.light_color = Color(0.6, 0.75, 1.0)
	rim.light_energy = 0.35

	_holder = Node3D.new()
	_viewport.add_child(_holder)

	_black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_black.albedo_color = Color.BLACK
	_white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_white.albedo_color = Color.WHITE
	_bake.call_deferred()


func _bake() -> void:
	for k in PIECES.size():
		var piece: Node3D = call(PIECES[k][0])
		_holder.add_child(piece)
		await _bake_piece(piece, 1, k + 1, int(PIECES[k][1]))
		piece.queue_free()
	print("Folhas do lixo espacial geradas em ", OUT)
	quit()


func _bake_piece(piece: Node3D, sector: int, k: int, spins: int) -> void:
	var meshes: Array[MeshInstance3D] = []
	_collect(piece, meshes)
	var sheet := Image.create(FRAME_PX * COLS, FRAME_PX * (FRAMES / COLS), false, Image.FORMAT_RGBA8)
	var lights := Image.create(sheet.get_width(), sheet.get_height(), false, Image.FORMAT_RGBA8)
	for f in FRAMES:
		var t := float(f) / FRAMES
		# Balanço: o eixo da peça dá uma volta num cone de TILT em torno da câmera (a face
		# muda de luz) enquanto ela gira no próprio eixo. A silhueta nunca fica de lado.
		piece.basis = Basis(Vector3.BACK, TAU * t) * Basis(Vector3.RIGHT, TILT) * Basis(Vector3.BACK, -TAU * t * (spins + 1))
		var pos := Vector2i((f % COLS) * FRAME_PX, (f / COLS) * FRAME_PX)
		for m in meshes:
			m.material_override = null
		var color := await _shot()
		_outline(color)
		sheet.blit_rect(color, Rect2i(0, 0, FRAME_PX, FRAME_PX), pos)
		# Passe da luz: tudo preto (esconde a lâmpada atrás da peça), só a lâmpada branca.
		for m in meshes:
			m.material_override = _white if m.has_meta("lamp") else _black
		var lamp := await _shot()
		for y in FRAME_PX:
			for x in FRAME_PX:
				var l := lamp.get_pixel(x, y)
				lamp.set_pixel(x, y, Color(1, 1, 1, l.r * l.a))
		lights.blit_rect(lamp, Rect2i(0, 0, FRAME_PX, FRAME_PX), pos)
	var path := "%s/junk_s%d_%d.png" % [OUT, sector, k]
	sheet.save_png(path)
	lights.save_png("%s/junk_s%d_%d_luz.png" % [OUT, sector, k])
	print("  ", path)


func _shot() -> Image:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := _viewport.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	img.resize(FRAME_PX, FRAME_PX, Image.INTERPOLATE_CUBIC)
	return img


## Contorno escuro de 1–2 px em volta da silhueta (igual às rochas: destaca do fundo).
func _outline(img: Image) -> void:
	var src := img.duplicate() as Image
	for y in FRAME_PX:
		for x in FRAME_PX:
			var a := src.get_pixel(x, y).a
			if a >= 0.95:
				continue
			var near := 0.0
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
					Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2),
					Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
				var p := Vector2i(x, y) + d
				if p.x >= 0 and p.y >= 0 and p.x < FRAME_PX and p.y < FRAME_PX:
					near = maxf(near, src.get_pixel(p.x, p.y).a)
			if near > a:
				var c := src.get_pixel(x, y)
				img.set_pixel(x, y, Color(OUTLINE, 1.0).lerp(c, a) if a > 0.0 else Color(OUTLINE, near))


func _collect(n: Node, out: Array[MeshInstance3D]) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_collect(c, out)


# --- Materiais ---------------------------------------------------------------------------

func _metal(color: Color, rough := 0.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = 0.55
	m.roughness = rough
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _stripes() -> StandardMaterial3D:
	var img := Image.create(64, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 64:
			var band := posmod(x + y, 16) < 8
			img.set_pixel(x, y, Color("#f2b81c") if band else Color("#16171b"))
	var m := _metal(Color.WHITE, 0.7)
	m.metallic = 0.1
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	return m


func _lamp_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("#ffb347")
	m.emission_enabled = true
	m.emission = Color("#ff9a1f")
	m.emission_energy_multiplier = 0.6
	return m


# --- Peças (eixo da peça = +Z, virado para a câmera) -------------------------------------

func _mesh(mesh: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = null
	mesh.surface_set_material(0, mat)
	mi.position = pos
	mi.rotation = rot
	return mi


## Cilindro deitado no eixo Z (o CylinderMesh nasce no eixo Y).
func _disc(radius: float, height: float, mat: Material, z: float, segments := 32) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = height
	c.radial_segments = segments
	c.rings = 1
	return _mesh(c, mat, Vector3(0, 0, z), Vector3(PI * 0.5, 0, 0))


func _box(size: Vector3, mat: Material, pos: Vector3, rot_z := 0.0) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return _mesh(b, mat, pos, Vector3(0, 0, rot_z))


func _lamp(pos: Vector3) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = 0.075
	s.height = 0.15
	var mi := _mesh(s, _lamp_material(), pos)
	mi.set_meta("lamp", true)
	return mi


func _rivets(parent: Node3D, radius: float, count: int, z: float, mat: Material, skip := -1) -> void:
	for i in count:
		if i == skip:
			continue
		var a := TAU * (i + 0.5) / count
		var r := _disc(0.035, 0.03, mat, z, 8)
		r.position = Vector3(cos(a) * radius, sin(a) * radius, z)
		parent.add_child(r)


## Prisma com a base `pts` (polígono no plano XY), espessura `h`, centrado em z = 0.
func _prism(pts: PackedVector2Array, h: float, mat: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tris := Geometry2D.triangulate_polygon(pts)
	for side: float in [1.0, -1.0]:
		for i in tris:
			st.set_normal(Vector3(0, 0, side))
			st.add_vertex(Vector3(pts[i].x, pts[i].y, side * h * 0.5))
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		var n := Vector3(b.y - a.y, -(b.x - a.x), 0).normalized()
		if n.dot(Vector3(a.x + b.x, a.y + b.y, 0)) < 0.0:
			n = -n
		for v: Vector3 in [Vector3(a.x, a.y, h * 0.5), Vector3(b.x, b.y, h * 0.5), Vector3(b.x, b.y, -h * 0.5),
				Vector3(a.x, a.y, h * 0.5), Vector3(b.x, b.y, -h * 0.5), Vector3(a.x, a.y, -h * 0.5)]:
			st.set_normal(n)
			st.add_vertex(v)
	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = null
	mesh.surface_set_material(0, mat)
	return mi


## Placa de casco: chapa grossa de borda rasgada, emendas, rebites e faixa de alerta.
func _build_plate() -> Node3D:
	var root_node := Node3D.new()
	var steel := _metal(Color("#68707d"), 0.4)
	var dark := _metal(Color("#2c3038"), 0.6)
	var pts := PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 13:
		var a := TAU * i / 13.0
		var r := rng.randf_range(0.88, 0.95)
		if i == 4 or i == 9:
			r = 0.86  # dentes do rasgo
		pts.append(Vector2(cos(a), sin(a)) * r)
	root_node.add_child(_prism(pts, 0.16, steel))
	# Emendas das chapas (sulcos escuros) e chapa de reforço.
	root_node.add_child(_box(Vector3(1.6, 0.035, 0.02), dark, Vector3(0, 0.18, 0.085), 0.08))
	root_node.add_child(_box(Vector3(0.035, 1.5, 0.02), dark, Vector3(-0.25, 0, 0.085), 0.08))
	root_node.add_child(_box(Vector3(0.5, 0.42, 0.05), _metal(Color("#6c7380"), 0.4), Vector3(0.28, -0.3, 0.1), 0.08))
	root_node.add_child(_box(Vector3(0.95, 0.16, 0.03), _stripes(), Vector3(-0.1, 0.55, 0.09), 0.08))
	_rivets(root_node, 0.74, 14, 0.09, _metal(Color("#8a919e"), 0.3), 3)
	root_node.add_child(_lamp(Vector3(0.52, 0.48, 0.12)))
	return root_node


## Turbina: carcaça cilíndrica, bocal escuro com pás (o giro aparece nas pás) e cubo.
func _build_turbine() -> Node3D:
	var root_node := Node3D.new()
	root_node.add_child(_disc(0.9, 0.5, _metal(Color("#4f5560"), 0.45), 0.0))
	root_node.add_child(_disc(0.66, 0.04, _metal(Color("#15161a"), 0.9), 0.24))  # bocal (fuligem)
	var lip := TorusMesh.new()
	lip.inner_radius = 0.64
	lip.outer_radius = 0.8
	lip.rings = 32
	root_node.add_child(_mesh(lip, _metal(Color("#7a818d"), 0.35), Vector3(0, 0, 0.25), Vector3(PI * 0.5, 0, 0)))
	var blade := _metal(Color("#8d939c"), 0.35)
	for i in 9:
		var a := TAU * i / 9.0
		var b := _box(Vector3(0.5, 0.11, 0.03), blade, Vector3(cos(a) * 0.37, sin(a) * 0.37, 0.27), a)
		b.rotate_object_local(Vector3.RIGHT, 0.5)
		root_node.add_child(b)
	root_node.add_child(_disc(0.17, 0.1, _metal(Color("#a0a6ae"), 0.3), 0.3))
	_rivets(root_node, 0.86, 12, 0.26, _metal(Color("#9aa0aa"), 0.3), 2)
	root_node.add_child(_lamp(Vector3(-0.58, 0.6, 0.27)))
	return root_node


## Contêiner de carga octogonal: tampa com faixas de alerta, travas e alças.
func _build_container() -> Node3D:
	var root_node := Node3D.new()
	var body := _disc(0.94, 0.5, _metal(Color("#3e4a52"), 0.55), 0.0, 8)
	body.basis = Basis(Vector3.RIGHT, PI * 0.5) * Basis(Vector3.UP, PI / 8.0)
	root_node.add_child(body)
	var lid := _disc(0.78, 0.06, _metal(Color("#4d5b64"), 0.45), 0.26, 8)
	lid.basis = Basis(Vector3.RIGHT, PI * 0.5) * Basis(Vector3.UP, PI / 8.0)
	root_node.add_child(lid)
	root_node.add_child(_box(Vector3(1.4, 0.2, 0.04), _stripes(), Vector3(0, 0.0, 0.3)))
	var lock := _metal(Color("#8a919e"), 0.3)
	for x: float in [-0.5, 0.5]:
		root_node.add_child(_box(Vector3(0.14, 0.3, 0.06), lock, Vector3(x, -0.42, 0.3)))
	root_node.add_child(_box(Vector3(0.5, 0.08, 0.06), lock, Vector3(0, 0.45, 0.3)))
	root_node.add_child(_lamp(Vector3(0.45, 0.45, 0.32)))
	return root_node
