extends SceneTree
## Gera as FOLHAS DE QUADROS dos asteroides estilizados que giram em 3D (ESPEC_ASTEROIDES.md, seção 8).
## Para cada rocha: FRAMES quadros de FRAME_PX, em uma grade COLS x ROWS, salvos em
## sprites/rock_s{setor}_{k}.png. Usa shaders/rock_bake.gdshader (só aqui, nunca no jogo).
## Precisa de janela (não use --headless: o modo sem tela não desenha nada).
## Uso: godot --path . --script res://tools/bake_rocks.gd -- [--setor=1]

const OUT := "res://sprites"
const FRAME_PX := 192
const FRAMES := 12
const COLS := 4
const ROWS := 3

## Paletas estilizadas: [claro, médio, escuro, contorno, borda de luz, brilho dos veios, crateras, veios]
const STYLES := {
	"rochoso": [Color("#cfd2da"), Color("#8f95a3"), Color("#555b68"), Color("#1a1d24"), Color("#f2f6ff"), Color("#ff8a26"), 0.7, 0.0],
	"pomes": [Color("#f1e7d2"), Color("#c8b89a"), Color("#8c7d66"), Color("#2a241b"), Color("#fffaf0"), Color("#ff8a26"), 0.25, 0.0],
	"ferroso": [Color("#e0a27e"), Color("#a8644a"), Color("#6a3a2a"), Color("#21120d"), Color("#ffe2cc"), Color("#ff8a26"), 0.5, 0.0],
	"cristalino": [Color("#c9b8ee"), Color("#9078c4"), Color("#5a4686"), Color("#1c1430"), Color("#f2eaff"), Color("#d08cff"), 0.35, 1.0],
	"gelo": [Color("#eef8ff"), Color("#a9d4f2"), Color("#6a9cc8"), Color("#183049"), Color("#ffffff"), Color("#9fe8ff"), 0.2, 0.0],
	"carbonaceo": [Color("#a3a0a4"), Color("#6c696e"), Color("#3c3a3e"), Color("#121113"), Color("#fff4e2"), Color("#ff8a26"), 0.5, 0.0],
	"vulcanico": [Color("#8a7570"), Color("#5a4844"), Color("#33261f"), Color("#120b08"), Color("#ffd2b0"), Color("#ff6a14"), 0.4, 1.0],
}

## Rochas de cada setor: lista de estilos (uma folha por item). Setor 1 = protótipo.
const SECTORS := {
	1: ["rochoso", "rochoso", "pomes"],
	2: ["ferroso", "ferroso", "rochoso"],
	3: ["carbonaceo", "cristalino", "cristalino"],
	4: ["rochoso", "ferroso", "carbonaceo"],
	5: ["gelo", "gelo", "rochoso"],
	6: ["pomes", "ferroso", "pomes"],
	7: ["rochoso", "ferroso", "carbonaceo"],
	8: ["carbonaceo", "vulcanico", "vulcanico"],
}

var _viewport: SubViewport
var _rect: ColorRect
var _mat: ShaderMaterial


func _initialize() -> void:
	root.get_node("Game").persist = false
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(FRAME_PX, FRAME_PX)
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	_rect = ColorRect.new()
	_rect.size = Vector2(FRAME_PX, FRAME_PX)
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/rock_bake.gdshader")
	_rect.material = _mat
	_viewport.add_child(_rect)
	_bake.call_deferred()


func _bake() -> void:
	var only := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--setor="):
			only = int(arg.get_slice("=", 1))
	for sector: int in SECTORS:
		if only != 0 and sector != only:
			continue
		var list: Array = SECTORS[sector]
		for k in list.size():
			await _bake_rock(sector, k + 1, STYLES[list[k]], float(sector * 10 + k) * 1.37)
	print("Folhas de quadros geradas em ", OUT)
	quit()


func _bake_rock(sector: int, k: int, style: Array, seed_value: float) -> void:
	for i in 6:
		var key: String = ["c_light", "c_mid", "c_dark", "c_outline", "c_rim", "c_glow"][i]
		var c: Color = style[i]
		_mat.set_shader_parameter(key, Vector3(c.r, c.g, c.b))
	_mat.set_shader_parameter("craters", style[6])
	_mat.set_shader_parameter("glow", style[7])
	_mat.set_shader_parameter("seed", seed_value)
	_mat.set_shader_parameter("tilt", 0.35 + fmod(seed_value, 0.6))
	var sheet := Image.create(FRAME_PX * COLS, FRAME_PX * ROWS, false, Image.FORMAT_RGBA8)
	for f in FRAMES:
		_mat.set_shader_parameter("spin", float(f) / FRAMES)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := _viewport.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(img, Rect2i(0, 0, FRAME_PX, FRAME_PX), Vector2i((f % COLS) * FRAME_PX, (f / COLS) * FRAME_PX))
	var path := "%s/rock_s%d_%d.png" % [OUT, sector, k]
	sheet.save_png(path)
	print("  ", path)
