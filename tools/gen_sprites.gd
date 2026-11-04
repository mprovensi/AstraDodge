extends SceneTree
## Renderiza os sprites de art/sprites/*.svg para res://sprites/*.png.
## Edite os SVGs (em qualquer editor vetorial ou à mão) e rode de novo.
## Só regenera PNGs cujo SVG é mais novo (ou que não existem) — ver SPRITES.md.
## Uso: godot --headless --path . --script res://tools/gen_sprites.gd

const SRC := "res://art/sprites"
const OUT := "res://sprites"
const SIZE := 256
## Sprites desenhados grandes na tela são renderizados em resolução maior (nome -> px).
const SIZES := {"boss_rock_mother": 512, "boss_rock_mother_half": 384, "boss_miner": 512, "boss_medusa": 512, "boss_cruiser": 512, "boss_ice_colossus": 512, "boss_hive_queen": 512, "boss_sentinel": 512, "boss_rift_core": 512}


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var dir := DirAccess.open(SRC)
	for file in dir.get_files():
		if not file.ends_with(".svg"):
			continue
		var svg_path := "%s/%s" % [SRC, file]
		var png_path := "%s/%s.png" % [OUT, file.get_basename()]
		# PNG trocado à mão (ex.: arte de outra IA) não é sobrescrito: só regenera se o SVG for mais novo.
		if FileAccess.file_exists(png_path) and FileAccess.get_modified_time(svg_path) <= FileAccess.get_modified_time(png_path):
			print("  ", file, " (PNG atual mantido)")
			continue
		var img := Image.new()
		var svg := FileAccess.get_file_as_string(svg_path)
		var size: int = SIZES.get(file.get_basename(), SIZE)
		var err := img.load_svg_from_string(svg, float(size) / 256.0)
		if err != OK:
			push_error("falha ao renderizar " + file)
			continue
		img.generate_mipmaps()
		img.save_png(png_path)
		print("  ", file, " -> ", file.get_basename(), ".png")
	print("Sprites gerados em ", OUT)
	quit()
