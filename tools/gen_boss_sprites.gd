extends SceneTree
## Prepara a arte nova dos CHEFES (PLANO_CHEFES_ARTE.md) a partir dos recortes das folhas de IA
## (`tools/cut_sprites.gd` → sprite_test/cortes/chefes*). Para cada peça: máscara (apaga restos de
## outras peças grudadas), giro/espelho, recorte justo e tamanho final → sprites/ia/boss/*.png.
## Uso: godot --headless --path . --script res://tools/gen_boss_sprites.gd

const SRC := "res://sprite_test/cortes/"
const OUT := "res://sprites/ia/boss"

## [recorte, saída, lado maior em px, máscara, giro (graus), espelho]
const PIECES := [
	["chefes2/rock_metades_02", "rock_half_r", 384, "", 0, false],
	["chefes2/rock_cristal_01", "rock_crystal", 128, "", 0, false],
	["chefes2/rock_tampa_01", "rock_lid", 128, "", 0, false],
	["chefes2/miner_olho_01", "miner_eye", 160, "circle", 0, false],
	["chefes2/miner_palpebra_01", "miner_lid", 160, "circle", 0, false],
	["chefes/medusa_03", "medusa_tentacle", 192, "", 0, false],
	["chefes2/medusa_ponta_01", "medusa_tip", 192, "tip", 0, false],
	["chefes2/medusa_no_01", "medusa_node", 128, "", 0, false],
	["chefes/cruiserp_02", "cruiser_turret", 192, "", 0, false],
	["chefes/cruiserp_01", "cruiser_launcher", 192, "", 0, false],
	["chefes2/cruiser_lanc_aberto_01", "cruiser_launcher_open", 192, "", 0, false],
	["chefes/cruiserp_05", "cruiser_wreck", 192, "", 0, false],
	["chefes/ice_03", "ice_blade", 256, "", 0, false],
	["chefes/sentp2_02", "sentinel_arm", 256, "", 0, false],
	["chefes/sentp_02", "sentinel_arm_broken", 256, "", 0, false],
	["chefes2/sent_drone_01", "sentinel_drone", 96, "", 0, false],
]

## CORPOS: montados direto no quadrado que o chefe desenha na tela (SPRITE_SIZE do chefe), com o
## ponto fraco no lugar certo — o código de desenho e os testes de colisão × desenho não mudam.
## [recorte, saída, máscara, gira 180°, âncora (fração do recorte) que vai para o ponto `at` do
##  quadrado, tamanho do recorte na tela (px), lado do quadrado na tela (px), px da textura,
##  ponto `at` (px na tela, relativo ao centro do quadrado), colisões [[centro, raio], ...] para conferir]
const BODIES := [
	["chefes2/rock_inteira_01", "rock_body", "rock", false, Vector2(0.48, 0.47), 488.0, 560.0, 576,
		Vector2.ZERO, [[Vector2.ZERO, 210.0]]],
	["chefes2/rock_metades_01", "rock_half_l", "", false, Vector2(0.50, 0.50), 405.0, 413.0, 448,
		Vector2(-28, 0), [[Vector2(-28, -59), 90.0], [Vector2(-28, 59), 90.0]]],
	["chefes/miner_02", "miner_body", "", false, Vector2(0.50, 0.42), 573.0, 664.0, 640,
		Vector2.ZERO, [[Vector2(0, -10), 125.0], [Vector2.ZERO, 52.0], [Vector2(-172, 80), 48.0], [Vector2(172, 80), 48.0]]],
	["chefes2/medusa_cupula_01", "medusa_dome", "", false, Vector2(0.50, 0.52), 460.0, 440.0, 512,
		Vector2.ZERO, [[Vector2(0, -47), 108.0], [Vector2(-95, 12), 52.0], [Vector2(95, 12), 52.0]]],
	["chefes/ice_05", "ice_body", "", false, Vector2(0.46, 0.49), 300.0, 300.0, 384,
		Vector2.ZERO, [[Vector2.ZERO, 128.0]]],
	["chefes/wasp_01", "queen_body", "", false, Vector2(0.485, 0.375), 520.0, 680.0, 640,
		Vector2.ZERO, [[Vector2(0, 88), 78.0], [Vector2.ZERO, 86.0], [Vector2(0, -100), 46.0]]],
	["chefes/sent_01", "sentinel_body", "octagon", false, Vector2(0.485, 0.578), 480.0, 560.0, 512,
		Vector2.ZERO, [[Vector2.ZERO, 140.0]]],
	["chefes/cruiser_01", "cruiser_hull", "", false, Vector2(0.50, 0.43), 660.0, 780.0, 1024,
		Vector2.ZERO, CRUISER_HULL],
	["chefes/rift_02", "rift_body", "", false, Vector2(0.465, 0.465), 480.0, 480.0, 512,
		Vector2.ZERO, [[Vector2.ZERO, 130.0]]],
]

## Colisão do casco do Cruzador (igual a Cruiser.HULL_BODIES; aqui só para conferir a cobertura).
const CRUISER_HULL := [
	[Vector2(0, -225), 30.0], [Vector2(0, -170), 58.0], [Vector2(0, -90), 70.0], [Vector2(0, 0), 74.0],
	[Vector2(0, 90), 70.0], [Vector2(0, 180), 58.0], [Vector2(0, 245), 36.0],
	[Vector2(-110, 40), 60.0], [Vector2(110, 40), 60.0], [Vector2(-182, 62), 58.0], [Vector2(182, 62), 58.0],
	[Vector2(-245, 110), 44.0], [Vector2(245, 110), 44.0], [Vector2(-290, 148), 22.0], [Vector2(290, 148), 22.0],
]
## Octógono da Sentinela (frações do recorte) + faixa dos cabos acima dele.
const OCTAGON := [Vector2(0.33, 0.27), Vector2(0.64, 0.27), Vector2(0.79, 0.40), Vector2(0.79, 0.76),
		Vector2(0.66, 0.89), Vector2(0.31, 0.89), Vector2(0.18, 0.76), Vector2(0.18, 0.40)]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for p: Array in PIECES:
		var img := Image.load_from_file(ProjectSettings.globalize_path(SRC + p[0] + ".png"))
		if img == null:
			push_error("faltou o recorte " + p[0])
			quit(1)
			return
		img.convert(Image.FORMAT_RGBA8)
		_mask(img, p[3])
		if p[5]:
			img.flip_x()
		match int(p[4]):
			90:
				img.rotate_90(CLOCKWISE)
			180:
				img.rotate_180()
			270:
				img.rotate_90(COUNTERCLOCKWISE)
		img = _trim(img)
		var side := float(p[2])
		var k := side / maxf(img.get_width(), img.get_height())
		img.resize(maxi(1, roundi(img.get_width() * k)), maxi(1, roundi(img.get_height() * k)), Image.INTERPOLATE_LANCZOS)
		img.save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUT, p[1]]))
		print("%-22s %dx%d" % [p[1], img.get_width(), img.get_height()])
	for b: Array in BODIES:
		var img := Image.load_from_file(ProjectSettings.globalize_path(SRC + b[0] + ".png"))
		img.convert(Image.FORMAT_RGBA8)
		_mask(img, b[2])
		var anchor: Vector2 = b[4]
		if b[3]:
			img.rotate_180()
			anchor = Vector2.ONE - anchor
		var n: int = b[7]
		var k: float = n / float(b[6])            # px da textura por px da tela
		var art_px := roundi(float(b[5]) * k)       # lado do recorte na textura
		img.resize(art_px, art_px, Image.INTERPOLATE_LANCZOS)
		var canvas := Image.create(n, n, false, Image.FORMAT_RGBA8)
		var at: Vector2 = Vector2(n, n) * 0.5 + (b[8] as Vector2) * k
		var origin := Vector2i((at - anchor * art_px).round())
		canvas.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), origin)
		canvas.save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUT, b[1]]))
		print("%-22s %dx%d  colisão fora do desenho: %.1f%%" % [b[1], n, n, _outside(canvas, float(b[6]), b[9])])
	quit()


## % da área das colisões (px na tela, relativos ao centro) que cai fora dos pixels do desenho.
func _outside(img: Image, side: float, circles: Array) -> float:
	var half := side * 0.5
	var hits := 0
	var out := 0
	for y in range(-int(half), int(half) + 1, 4):
		for x in range(-int(half), int(half) + 1, 4):
			var p := Vector2(x, y)
			var inside := false
			for c: Array in circles:
				inside = inside or p.distance_to(c[0]) < float(c[1])
			if not inside:
				continue
			hits += 1
			var u := clampi(int((x + half) / side * img.get_width()), 0, img.get_width() - 1)
			var v := clampi(int((y + half) / side * img.get_height()), 0, img.get_height() - 1)
			if img.get_pixel(u, v).a <= 0.5:
				out += 1
	return 100.0 * out / maxf(1.0, hits)


## Apaga o que não faz parte da peça (restos de outras peças que encostaram nela na folha).
func _mask(img: Image, kind: String) -> void:
	if kind == "":
		return
	var w := img.get_width()
	var h := img.get_height()
	var oct := PackedVector2Array()
	for v: Vector2 in OCTAGON:
		oct.append(v)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var u := float(x) / w
			var v := float(y) / h
			var keep := true
			match kind:
				"rock":  # corpo redondo + as 4 sondas; embaixo do corpo havia uma mancha
					keep = v < 0.86 or u < 0.27 or Vector2(u - 0.48, v - 0.47).length() < 0.43
				"circle":
					keep = Vector2(u - 0.5, v - 0.5).length() < 0.5
				"tip":  # a mancha à direita é lilás clara (pouca cor)
					keep = u < 0.5 or c.s > 0.35
				"octagon":
					keep = Geometry2D.is_point_in_polygon(Vector2(u, v), oct) or (v < 0.33 and u > 0.08 and u < 0.9)
			if not keep:
				img.set_pixel(x, y, Color(0, 0, 0, 0))


## Recorte justo (sem margem transparente) + 2 px.
func _trim(img: Image) -> Image:
	var r := img.get_used_rect()
	r = r.grow(2).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	return img.get_region(r)
