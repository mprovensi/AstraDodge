extends SceneTree
## Renderiza os sprites de art/sprites/*.svg para res://sprites/*.png.
## Edite os SVGs (em qualquer editor vetorial ou à mão) e rode de novo.
## Uso: godot --headless --path . --script res://tools/gen_sprites.gd

const SRC := "res://art/sprites"
const OUT := "res://sprites"
const SIZE := 256
## Sprites desenhados grandes na tela são renderizados em resolução maior (nome -> px).
const SIZES := {"boss_rock_mother": 512, "boss_rock_mother_half": 384, "boss_miner": 512}


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var dir := DirAccess.open(SRC)
	for file in dir.get_files():
		if not file.ends_with(".svg"):
			continue
		var img := Image.new()
		var svg := FileAccess.get_file_as_string("%s/%s" % [SRC, file])
		var size: int = SIZES.get(file.get_basename(), SIZE)
		var err := img.load_svg_from_string(svg, float(size) / 256.0)
		if err != OK:
			push_error("falha ao renderizar " + file)
			continue
		img.generate_mipmaps()
		img.save_png("%s/%s" % [OUT, file.get_basename() + ".png"])
		print("  ", file, " -> ", file.get_basename(), ".png")
	print("Sprites gerados em ", OUT)
	quit()
