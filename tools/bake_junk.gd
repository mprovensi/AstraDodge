extends SceneTree
## Gera as FOLHAS DE QUADROS do lixo espacial indestrutível (PLANO_INDESTRUTIVEIS.md, J0–J1).
## Cada peça é montada em 3D aqui (malhas simples + sombreamento estilizado "toon"), gira e
## balança em 3D e é fotografada em JUNK_FRAMES quadros. O jogo só troca o quadro (leve).
## Saída: sprites/junk_s{setor}_{k}.png (cor) e data/art/junk_lamps.tres (onde está a luz
## âmbar em cada quadro e quanto dela aparece; o jogo desenha o brilho por cima, piscando).
## Precisa de janela (não use --headless).
## Uso: godot --path . --script res://tools/bake_junk.gd -- [--setor=N]

const OUT := "res://sprites"
const LAMPS_PATH := "res://data/art/junk_lamps.tres"
const FRAME_PX := 192
const RENDER_PX := 384          # renderiza em 2x e reduz (bordas mais lisas)
const FRAMES := ArtSet.JUNK_FRAMES
const COLS := ArtSet.JUNK_COLS
const TILT := deg_to_rad(30.0)  # inclinação da peça em relação à câmera (nunca fica de lado)
const OUTLINE := Color(0.045, 0.05, 0.065)

## Família de cada setor: cores do metal, faixa de alerta, extra e as peças (na ordem).
## Toda peça é "redonda vista de cima" (cobre o círculo de colisão em qualquer quadro).
const FAMILIES := {
	1: {"steel": "#68707d", "dark": "#2c3038", "trim": "#8a919e", "stripe": ["#f2b81c", "#16171b"],
		"extra": "", "pieces": ["plate", "turbine", "container", "tank"]},
	2: {"steel": "#6f6849", "dark": "#2e2a1d", "trim": "#9a9068", "stripe": ["#f2b81c", "#16171b"],
		"extra": "", "pieces": ["drill", "container", "plate", "tank"]},
	3: {"steel": "#566476", "dark": "#252c38", "trim": "#8d9bb0", "stripe": ["#c9d3e0", "#1b2230"],
		"extra": "", "pieces": ["satellite", "plate", "turbine", "tank"]},
	4: {"steel": "#4e4643", "dark": "#221d1c", "trim": "#7a6d66", "stripe": ["#c8352b", "#16171b"],
		"extra": "", "pieces": ["cannon", "plate", "turbine", "container"]},
	5: {"steel": "#5d6b78", "dark": "#28313b", "trim": "#9aa9b8", "stripe": ["#f2b81c", "#16171b"],
		"extra": "ice", "pieces": ["tank", "plate", "container", "satellite"]},
	6: {"steel": "#5a5650", "dark": "#2a2622", "trim": "#857d70", "stripe": ["#f2b81c", "#16171b"],
		"extra": "resin", "pieces": ["plate", "tank", "turbine", "container"]},
	7: {"steel": "#5c6570", "dark": "#2a313a", "trim": "#8a939d", "stripe": ["#ff7a1a", "#d9dde2"],
		"extra": "", "pieces": ["container", "duct", "satellite", "plate"]},
	8: {"steel": "#463f52", "dark": "#1e1a26", "trim": "#6e6480", "stripe": ["#b8338f", "#16121c"],
		"extra": "rift", "pieces": ["plate", "turbine", "tank", "container"]},
}
## Giros próprios da peça por volta do balanço (turbina e duto giram mais: o miolo mostra o giro).
const SPINS := {"turbine": 2, "duct": 2}

var _viewport: SubViewport
var _holder: Node3D
var _black := StandardMaterial3D.new()
var _white := StandardMaterial3D.new()
var _f := {}   # família em uso
var _rng := RandomNumberGenerator.new()


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
	var only := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--setor="):
			only = int(arg.get_slice("=", 1))
	var lamps: JunkLamps = load(LAMPS_PATH) if ResourceLoader.exists(LAMPS_PATH) else JunkLamps.new()
	for sector: int in FAMILIES:
		if only != 0 and sector != only:
			continue
		_f = FAMILIES[sector]
		var list: Array = _f["pieces"]
		for k in list.size():
			_rng.seed = sector * 100 + k
			var piece: Node3D = call("_build_" + list[k])
			_add_extra(piece)
			_holder.add_child(piece)
			var key := "s%d_%d" % [sector, k + 1]
			lamps.frames[key] = await _bake_piece(piece, key, int(SPINS.get(list[k], 1)))
			piece.free()
	ResourceSaver.save(lamps, LAMPS_PATH)
	print("Folhas do lixo espacial geradas em ", OUT)
	quit()


## Grava a folha da peça e devolve, por quadro, (x, y, visível) da luz âmbar
## (x, y em -1..1 do quadro, y para baixo; visível 0..1 = quanto da lâmpada a peça não esconde).
func _bake_piece(piece: Node3D, key: String, spins: int) -> PackedVector3Array:
	var meshes: Array[MeshInstance3D] = []
	_collect(piece, meshes)
	var lamp_node: Node3D = null
	for m in meshes:
		if m.has_meta("lamp"):
			lamp_node = m
	var sheet := Image.create(FRAME_PX * COLS, FRAME_PX * (FRAMES / COLS), false, Image.FORMAT_RGBA8)
	var data := PackedVector3Array()
	var seen: Array[float] = []
	for f in FRAMES:
		var t := float(f) / FRAMES
		# Balanço: o eixo da peça dá uma volta num cone de TILT em torno da câmera (a face
		# muda de luz) enquanto ela gira no próprio eixo. A silhueta nunca fica de lado.
		piece.basis = Basis(Vector3.BACK, TAU * t) * Basis(Vector3.RIGHT, TILT) * Basis(Vector3.BACK, -TAU * t * (spins + 1))
		for m in meshes:
			m.material_override = null
		var color := await _shot()
		_outline(color)
		sheet.blit_rect(color, Rect2i(0, 0, FRAME_PX, FRAME_PX), Vector2i((f % COLS) * FRAME_PX, (f / COLS) * FRAME_PX))
		# Passe da luz: tudo preto (esconde a lâmpada atrás da peça), só a lâmpada branca.
		for m in meshes:
			m.material_override = _white if m.has_meta("lamp") else _black
		var lamp := await _shot()
		var sum := 0.0
		for y in FRAME_PX:
			for x in FRAME_PX:
				var l := lamp.get_pixel(x, y)
				sum += l.r * l.a
		seen.append(sum)
		var gp := piece.transform * lamp_node.position
		data.append(Vector3(gp.x, -gp.y, 0.0))
	var most := 0.0
	for v in seen:
		most = maxf(most, v)
	for f in FRAMES:
		data[f].z = clampf(seen[f] / maxf(most, 1.0) * 1.25, 0.0, 1.0)
	sheet.save_png("%s/junk_%s.png" % [OUT, key])
	print("  junk_", key)
	return data


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


## Aço da família (`shade` > 0 clareia, < 0 escurece).
func _steel(shade := 0.0, rough := 0.45) -> StandardMaterial3D:
	var c := Color(_f["steel"])
	return _metal(c.lightened(shade) if shade >= 0.0 else c.darkened(-shade), rough)


func _dark() -> StandardMaterial3D:
	return _metal(Color(_f["dark"]), 0.6)


func _trim() -> StandardMaterial3D:
	return _metal(Color(_f["trim"]), 0.3)


## Faixa de alerta nas cores da família.
func _stripes() -> StandardMaterial3D:
	var img := Image.create(64, 16, false, Image.FORMAT_RGBA8)
	var a := Color(_f["stripe"][0])
	var b := Color(_f["stripe"][1])
	for y in 16:
		for x in 64:
			img.set_pixel(x, y, a if posmod(x + y, 16) < 8 else b)
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


# --- Montagem ----------------------------------------------------------------------------

func _mesh(mesh: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
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
	mesh.surface_set_material(0, mat)
	return mi


# --- Peças (eixo da peça = +Z, virado para a câmera; tudo dentro do raio 0,95) -------------

## Placa de casco: chapa grossa de borda rasgada, emendas, rebites e faixa de alerta.
func _build_plate() -> Node3D:
	var n := Node3D.new()
	var pts := PackedVector2Array()
	var teeth := [_rng.randi_range(0, 6), _rng.randi_range(7, 12)]
	for i in 13:
		var a := TAU * i / 13.0
		var r := _rng.randf_range(0.88, 0.95)
		if i in teeth:
			r = 0.86  # dentes do rasgo
		pts.append(Vector2(cos(a), sin(a)) * r)
	n.add_child(_prism(pts, 0.16, _steel()))
	var tilt := _rng.randf_range(-0.4, 0.4)
	n.add_child(_box(Vector3(1.6, 0.035, 0.02), _dark(), Vector3(0, 0.18, 0.085), tilt))
	n.add_child(_box(Vector3(0.035, 1.5, 0.02), _dark(), Vector3(-0.25, 0, 0.085), tilt))
	n.add_child(_box(Vector3(0.5, 0.42, 0.05), _steel(0.08, 0.4), Vector3(0.28, -0.3, 0.1), tilt))
	n.add_child(_box(Vector3(0.95, 0.16, 0.03), _stripes(), Vector3(-0.1, 0.55, 0.09), tilt))
	_rivets(n, 0.74, 14, 0.09, _trim(), 3)
	n.add_child(_lamp(Vector3(0.52, 0.48, 0.12)))
	return n


## Turbina: carcaça cilíndrica, bocal escuro com pás (o giro aparece nas pás) e cubo.
func _build_turbine() -> Node3D:
	var n := Node3D.new()
	n.add_child(_disc(0.9, 0.5, _steel(-0.1), 0.0))
	n.add_child(_disc(0.66, 0.04, _metal(Color("#15161a"), 0.9), 0.24))  # bocal (fuligem)
	var lip := TorusMesh.new()
	lip.inner_radius = 0.64
	lip.outer_radius = 0.8
	lip.rings = 32
	n.add_child(_mesh(lip, _trim(), Vector3(0, 0, 0.25), Vector3(PI * 0.5, 0, 0)))
	var blade := _steel(0.25, 0.35)
	for i in 9:
		var a := TAU * i / 9.0
		var b := _box(Vector3(0.5, 0.11, 0.03), blade, Vector3(cos(a) * 0.37, sin(a) * 0.37, 0.27), a)
		b.rotate_object_local(Vector3.RIGHT, 0.5)
		n.add_child(b)
	n.add_child(_disc(0.17, 0.1, _trim(), 0.3))
	_rivets(n, 0.86, 12, 0.26, _trim(), 2)
	n.add_child(_lamp(Vector3(-0.58, 0.6, 0.27)))
	return n


## Contêiner de carga octogonal: tampa com faixas de alerta, travas e alça.
func _build_container() -> Node3D:
	var n := Node3D.new()
	var body := _disc(0.94, 0.5, _steel(-0.3, 0.55), 0.0, 8)
	body.basis = Basis(Vector3.RIGHT, PI * 0.5) * Basis(Vector3.UP, PI / 8.0)
	n.add_child(body)
	var lid := _disc(0.78, 0.06, _steel(-0.15), 0.26, 8)
	lid.basis = Basis(Vector3.RIGHT, PI * 0.5) * Basis(Vector3.UP, PI / 8.0)
	n.add_child(lid)
	n.add_child(_box(Vector3(1.4, 0.2, 0.04), _stripes(), Vector3(0, 0.0, 0.3)))
	for x: float in [-0.5, 0.5]:
		n.add_child(_box(Vector3(0.14, 0.3, 0.06), _trim(), Vector3(x, -0.42, 0.3)))
	n.add_child(_box(Vector3(0.5, 0.08, 0.06), _trim(), Vector3(0, 0.45, 0.3)))
	n.add_child(_lamp(Vector3(0.45, 0.45, 0.32)))
	return n


## Tanque esférico: esfera com cintas e válvula com volante.
func _build_tank() -> Node3D:
	var n := Node3D.new()
	var s := SphereMesh.new()
	s.radius = 0.88
	s.height = 1.76
	n.add_child(_mesh(s, _steel(-0.05, 0.35), Vector3.ZERO))
	for rot: Vector3 in [Vector3(PI * 0.5, 0, 0), Vector3(0, 0, PI * 0.5)]:
		var strap := TorusMesh.new()
		strap.inner_radius = 0.86
		strap.outer_radius = 0.93
		strap.rings = 48
		n.add_child(_mesh(strap, _dark(), Vector3.ZERO, rot))
	var band := _box(Vector3(0.7, 0.14, 0.05), _stripes(), Vector3(-0.2, -0.38, 0.8))
	band.rotate_object_local(Vector3.RIGHT, 0.45)
	n.add_child(band)
	n.add_child(_disc(0.1, 0.25, _trim(), 0.9, 12))
	var wheel := TorusMesh.new()
	wheel.inner_radius = 0.12
	wheel.outer_radius = 0.18
	n.add_child(_mesh(wheel, _metal(Color(_f["stripe"][0]), 0.5), Vector3(0, 0, 1.0), Vector3(PI * 0.5, 0, 0)))
	n.add_child(_lamp(Vector3(0.48, 0.48, 0.58)))
	return n


## Satélite morto: corpo redondo, antena parabólica e dois tocos de painel solar.
func _build_satellite() -> Node3D:
	var n := Node3D.new()
	n.add_child(_disc(0.82, 0.4, _steel(-0.25), 0.0, 12))
	n.add_child(_disc(0.66, 0.05, _dark(), 0.21, 12))
	var dish := CylinderMesh.new()
	dish.top_radius = 0.5
	dish.bottom_radius = 0.14
	dish.height = 0.22
	dish.radial_segments = 24
	n.add_child(_mesh(dish, _steel(-0.05, 0.3), Vector3(0.05, 0.05, 0.36), Vector3(PI * 0.5, 0, 0)))
	n.add_child(_disc(0.04, 0.4, _dark(), 0.6, 8))
	var panel := _metal(Color("#34528a"), 0.25)
	for side: float in [-1.0, 1.0]:
		n.add_child(_box(Vector3(0.32, 0.72, 0.04), panel, Vector3(side * 0.8, -0.05, 0.05), side * 0.15))
		n.add_child(_box(Vector3(0.31, 0.03, 0.05), _trim(), Vector3(side * 0.8, -0.05, 0.06), side * 0.15))
	n.add_child(_box(Vector3(0.5, 0.12, 0.03), _stripes(), Vector3(0, -0.6, 0.22)))
	n.add_child(_lamp(Vector3(-0.42, 0.5, 0.25)))
	return n


## Broca de mineração (Setor 2): base com dentes e uma broca cônica apontada para cima.
func _build_drill() -> Node3D:
	var n := Node3D.new()
	n.add_child(_disc(0.9, 0.45, _steel(-0.15), 0.0, 10))
	for i in 10:
		var a := TAU * (i + 0.5) / 10.0
		n.add_child(_box(Vector3(0.12, 0.16, 0.08), _dark(), Vector3(cos(a) * 0.78, sin(a) * 0.78, 0.24), a))
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.5
	cone.height = 0.75
	cone.radial_segments = 6
	n.add_child(_mesh(cone, _steel(0.0, 0.3), Vector3(0, 0, 0.6), Vector3(PI * 0.5, 0, 0)))
	n.add_child(_box(Vector3(1.1, 0.14, 0.04), _stripes(), Vector3(0, -0.55, 0.24)))
	n.add_child(_lamp(Vector3(0.55, 0.45, 0.27)))
	return n


## Canhão morto do cruzador (Setor 4): torre redonda com cúpula e cano partido.
func _build_cannon() -> Node3D:
	var n := Node3D.new()
	n.add_child(_disc(0.9, 0.4, _steel(), 0.0, 16))
	var dome := SphereMesh.new()
	dome.radius = 0.45
	dome.height = 0.9
	n.add_child(_mesh(dome, _steel(0.06, 0.35), Vector3(0, 0, 0.2)))
	n.add_child(_box(Vector3(0.82, 0.17, 0.17), _dark(), Vector3(0.45, 0.0, 0.42)))
	n.add_child(_box(Vector3(0.1, 0.22, 0.22), _trim(), Vector3(0.86, 0.0, 0.42)))
	n.add_child(_box(Vector3(0.9, 0.12, 0.03), _stripes(), Vector3(-0.15, -0.62, 0.21)))
	_rivets(n, 0.8, 12, 0.21, _trim(), 0)
	n.add_child(_lamp(Vector3(-0.5, 0.5, 0.25)))
	return n


## Duto da estação (Setor 7): tubo curto com flanges e boca escura com grade.
func _build_duct() -> Node3D:
	var n := Node3D.new()
	n.add_child(_disc(0.9, 0.55, _steel(), 0.0, 24))
	for z: float in [0.28, 0.12]:
		var ring := TorusMesh.new()
		ring.inner_radius = 0.82 if z > 0.2 else 0.86
		ring.outer_radius = 0.92
		n.add_child(_mesh(ring, _trim(), Vector3(0, 0, z), Vector3(PI * 0.5, 0, 0)))
	n.add_child(_disc(0.45, 0.04, _metal(Color("#101216"), 0.9), 0.28))
	for i in 3:
		n.add_child(_box(Vector3(0.9, 0.05, 0.03), _dark(), Vector3(0, (i - 1) * 0.2, 0.3)))
	n.add_child(_box(Vector3(0.55, 0.13, 0.03), _stripes(), Vector3(0, 0.6, 0.29)))
	n.add_child(_lamp(Vector3(-0.6, -0.5, 0.3)))
	return n


## Extra do setor: gelo (5), resina da colmeia (6) ou veios da Fenda (8).
func _add_extra(n: Node3D) -> void:
	match _f["extra"]:
		"ice":
			var ice := _metal(Color("#a8c8e0"), 0.1)
			ice.metallic = 0.0
			for i in 3:
				var s := SphereMesh.new()
				s.radius = _rng.randf_range(0.16, 0.26)
				s.height = s.radius * 1.4
				var a := _rng.randf() * TAU
				n.add_child(_mesh(s, ice, Vector3(cos(a), sin(a), 0.0) * 0.55 + Vector3(0, 0, 0.3)))
		"resin":
			var resin := _metal(Color("#6b4417"), 0.2)
			resin.metallic = 0.0
			for i in 4:
				var s := SphereMesh.new()
				s.radius = _rng.randf_range(0.12, 0.2)
				s.height = s.radius
				var a := _rng.randf() * TAU
				n.add_child(_mesh(s, resin, Vector3(cos(a), sin(a), 0.0) * _rng.randf_range(0.4, 0.7) + Vector3(0, 0, 0.28)))
		"rift":
			var vein := _metal(Color("#7a2a6a"), 0.3)
			for i in 3:
				n.add_child(_box(Vector3(_rng.randf_range(0.4, 0.8), 0.04, 0.03), vein,
						Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf_range(-0.4, 0.4), 0.3), _rng.randf() * PI))
