extends SceneTree
## Gera os ícones do app (PNG) a partir dos desenhos em art/icon/:
##  - scene.svgfrag: fundo (espaço, nebulosa, rochas do jogo)
##  - ship.svgfrag: a nave do jogo com chamas, anel do escudo e tiros
##  - ship_mono.svgfrag: silhueta branca (ícone temático do Android 13+)
## Uso: godot --headless --path . --script res://tools/gen_icons.gd

const OUT := "res://icons"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var scene := FileAccess.get_file_as_string("res://art/icon/scene.svgfrag")
	var ship := FileAccess.get_file_as_string("res://art/icon/ship.svgfrag")
	var mono := FileAccess.get_file_as_string("res://art/icon/ship_mono.svgfrag")

	# Ícone completo (Play Store 512 e launcher legado 192).
	var full := _svg(512, scene + ship)
	_render(full, 512, "icon_512.png")
	_render(full, 192, "icon_192.png")

	# Adaptativo (Android 8+): 432x432. Fundo = cenário inteiro; frente = nave dentro da
	# zona segura central (~66%), para nenhuma máscara (círculo, gota...) cortar a nave.
	var inner := "<g transform=\"translate(216 216) scale(0.6) translate(-256 -256)\">%s</g>"
	# Fundo na mesma escala da nave: o ícone adaptativo fica igual ao completo (rochas à vista);
	# a sobra nas bordas (máscaras quadradas) é preenchida com o azul-escuro do espaço.
	_render(_svg(432, "<rect width=\"432\" height=\"432\" fill=\"#0a0b26\"/>" + inner % scene), 432,
			"icon_background_432.png")
	_render(_svg(432, inner % ship), 432, "icon_foreground_432.png")
	_render(_svg(432, inner % mono), 432, "icon_monochrome_432.png")

	# Ícone do projeto (editor/janela).
	var f := FileAccess.open("res://icon.svg", FileAccess.WRITE)
	f.store_string(full)
	f.close()
	print("Ícones gerados em ", OUT)
	quit()


func _svg(size: int, body: String) -> String:
	return "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"%d\" height=\"%d\" viewBox=\"0 0 %d %d\">%s</svg>" % [
		size, size, size, size, body]


func _render(svg: String, size: int, file: String) -> void:
	var img := Image.new()
	var native := int(svg.get_slice("width=\"", 1).get_slice("\"", 0))
	var err := img.load_svg_from_string(svg, float(size) / float(native))
	assert(err == OK, "falha ao renderizar " + file)
	img.save_png("%s/%s" % [OUT, file])
