extends SceneTree
## Gera os ícones do app (PNG) a partir do desenho em art/icon/ship.svgfrag.
## Uso: godot --headless --path . --script res://tools/gen_icons.gd

const FRAG := "res://art/icon/ship.svgfrag"
const OUT := "res://icons"

const BACKGROUND := """
<defs>
  <radialGradient id="bg" cx="50%" cy="45%" r="70%">
    <stop offset="0" stop-color="#14204d"/>
    <stop offset="1" stop-color="#03030c"/>
  </radialGradient>
</defs>
<rect width="512" height="512" fill="url(#bg)"/>
<g fill="#cfe2ff">
  <circle cx="70" cy="90" r="3" opacity="0.7"/><circle cx="430" cy="60" r="2.5" opacity="0.6"/>
  <circle cx="460" cy="300" r="3" opacity="0.5"/><circle cx="50" cy="380" r="2.5" opacity="0.6"/>
  <circle cx="150" cy="470" r="2" opacity="0.5"/><circle cx="390" cy="450" r="3" opacity="0.7"/>
  <circle cx="110" cy="210" r="2" opacity="0.4"/><circle cx="410" cy="170" r="2" opacity="0.4"/>
</g>
"""


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var ship := FileAccess.get_file_as_string(FRAG)

	# Ícone completo (Play Store 512 e launcher legado 192).
	var full := _svg(512, BACKGROUND + ship)
	_render(full, 512, "icon_512.png")
	_render(full, 192, "icon_192.png")

	# Adaptativo (Android 8+): 432x432, conteúdo dentro da zona segura central (~66%).
	var inner := "<g transform=\"translate(216 216) scale(0.56) translate(-256 -256)\">%s</g>"
	_render(_svg(432, "<g transform=\"scale(0.84375)\">%s</g>" % BACKGROUND), 432, "icon_background_432.png")
	_render(_svg(432, inner % ship), 432, "icon_foreground_432.png")

	# Monocromático (ícones temáticos do Android 13+): silhueta branca.
	var mono := ship.replace("#3ff0ff", "#ffffff").replace("#9ffbff", "#ffffff") \
			.replace("#ff8a26", "#ffffff").replace("#ffd27a", "#ffffff") \
			.replace("#0a1a33", "#ffffff").replace("#c8feff", "#ffffff")
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
