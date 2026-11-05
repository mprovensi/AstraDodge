extends SceneTree
## Transforma os recortes das folhas de IA (sprite_test/cortes, feitos por tools/cut_sprites.gd)
## nas rochas e no lixo do jogo (PLANO_SPRITES_IA.md):
## - furos fechados (miolo de engrenagem) viram metal escuro (colisão = desenho);
## - regra de leitura: rocha (quebra) CLARA, lixo (não quebra) ESCURO — o brilho é ajustado;
## - lixo ganha o ponto da luz âmbar (data/art/junk_lamps.tres, chave "ia_s{setor}_{k}");
## - saída: sprites/ia/rock_s{setor}_{k}.png e sprites/ia/junk_s{setor}_{k}.png (256 px).
## Uso: godot --headless --path . --script res://tools/gen_ia_sprites.gd [-- --relatorio]

const SRC := "res://sprite_test/cortes"
const OUT := "res://sprites/ia"
const LAMPS_PATH := "res://data/art/junk_lamps.tres"
const PX := 256
const ROCK_LUM := 0.5     # brilho médio alvo da rocha (o teste exige > 0.36)
const JUNK_LUM := 0.27    # brilho médio alvo do lixo (o teste exige < 0.36)
const HURT_DUST := 0.92 * 0.85   # raio que machuca a nave, em fração da metade da imagem
const HURT_METAL := 0.94 * 0.85

## Rochas de cada setor (recortes). Cores parecidas com o cenário do setor.
const ROCKS := {
	1: ["a_01", "a_10", "a_24", "b_09"],
	2: ["a_07", "a_17", "b_08", "b_10"],
	3: ["a_04", "a_08", "b_01", "a_25"],
	4: ["b_02", "b_03", "a_16", "a_18"],
	5: ["a_15", "a_25", "b_04", "a_24"],
	6: ["b_02", "b_04", "a_02", "a_06"],
	7: ["b_03", "b_09", "a_10", "b_01"],
	8: ["a_04", "a_18", "a_17", "b_08"],
}
## Lixo de cada setor: só peças que cobrem o círculo de colisão (ver --relatorio).
const JUNK := {
	1: ["b_33", "b_23", "b_29", "b_30"],
	2: ["b_30", "b_32", "b_33", "b_26"],
	3: ["b_15", "b_37", "b_29", "b_23"],
	4: ["b_23", "b_26", "b_33", "b_29"],
	5: ["b_29", "b_33", "b_37", "b_15"],
	6: ["b_37", "b_23", "b_29", "b_32"],
	7: ["b_32", "b_33", "b_26", "b_15"],
	8: ["b_26", "b_30", "b_37", "b_23"],
}
## Ampliação por peça (corta um pouco das pontas para a peça cobrir o círculo de colisão).
const ZOOM := {"b_15": 1.1, "b_33": 1.25, "b_37": 1.25, "b_26": 1.3, "b_23": 1.3}


func _initialize() -> void:
	if "--relatorio" in OS.get_cmdline_user_args():
		_report()
		quit()
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var lamps: JunkLamps = load(LAMPS_PATH) if ResourceLoader.exists(LAMPS_PATH) else JunkLamps.new()
	for sector: int in ROCKS:
		for k in ROCKS[sector].size():
			var img := _prepare(ROCKS[sector][k], ROCK_LUM)
			img.save_png(ProjectSettings.globalize_path("%s/rock_s%d_%d.png" % [OUT, sector, k + 1]))
	for sector: int in JUNK:
		for k in JUNK[sector].size():
			var name: String = JUNK[sector][k]
			var img := _zoomed(_prepare(name, JUNK_LUM), ZOOM.get(name, 1.0))
			img.save_png(ProjectSettings.globalize_path("%s/junk_s%d_%d.png" % [OUT, sector, k + 1]))
			var p := _lamp_point(img)
			lamps.frames["ia_s%d_%d" % [sector, k + 1]] = PackedVector3Array([Vector3(p.x, p.y, 1.0)])
	ResourceSaver.save(lamps, LAMPS_PATH)
	print("Sprites de IA gerados em ", OUT)
	quit()


## Cobertura (quanto do círculo que machuca a nave cai em pixel transparente) de todos os recortes.
func _report() -> void:
	for f in DirAccess.get_files_at(ProjectSettings.globalize_path(SRC)):
		if not f.ends_with(".png"):
			continue
		var img := _prepare(f.get_basename(), -1.0)
		var need := 0.0
		for z in [1.0, 1.05, 1.1, 1.15, 1.2, 1.25, 1.3, 1.4, 1.5]:
			if _outside(_zoomed(img, z), HURT_METAL) <= 4.0:
				need = z
				break
		print("%s  fora(rocha)=%4.1f%%  fora(metal)=%4.1f%%  brilho=%.2f  zoom p/ metal=%s" % [f.get_basename(),
				_outside(img, HURT_DUST), _outside(img, HURT_METAL), _lum(img), str(need) if need > 0.0 else "-"])


## Recorte pronto: furos fechados preenchidos e brilho levado a `target` (< 0: sem ajuste).
func _prepare(name: String, target: float) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path("%s/%s.png" % [SRC, name]))
	img.convert(Image.FORMAT_RGBA8)
	if img.get_width() != PX:
		img.resize(PX, PX, Image.INTERPOLATE_LANCZOS)
	_fill_holes(img)
	if target > 0.0:
		var gain := target / maxf(_lum(img), 0.05)
		for y in PX:
			for x in PX:
				var c := img.get_pixel(x, y)
				if c.a > 0.0:
					img.set_pixel(x, y, Color(minf(c.r * gain, 1.0), minf(c.g * gain, 1.0), minf(c.b * gain, 1.0), c.a))
	return img


## Transparente que NÃO se liga à borda da imagem é furo: vira metal bem escuro (eixo/vão).
func _fill_holes(img: Image) -> void:
	var outside := PackedByteArray()
	outside.resize(PX * PX)
	var stack := PackedInt32Array()
	for i in PX:
		stack.append_array([i, (PX - 1) * PX + i, i * PX, i * PX + PX - 1])
	while not stack.is_empty():
		var i := stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		if outside[i] == 1 or img.get_pixel(i % PX, i / PX).a > 0.5:
			continue
		outside[i] = 1
		var x := i % PX
		var y := i / PX
		if x > 0: stack.append(i - 1)
		if x < PX - 1: stack.append(i + 1)
		if y > 0: stack.append(i - PX)
		if y < PX - 1: stack.append(i + PX)
	for i in PX * PX:
		var c := img.get_pixel(i % PX, i / PX)
		if outside[i] == 0 and c.a <= 0.5:
			img.set_pixel(i % PX, i / PX, Color(0.07, 0.075, 0.09, 1.0))


## Ponto da luz âmbar: perto de cima-direita, num lugar bem dentro da peça (-1..1 da imagem).
func _lamp_point(img: Image) -> Vector2:
	var half := PX * 0.5
	var best := Vector2.ZERO
	var best_d := INF
	for y in range(8, PX - 8, 4):
		for x in range(8, PX - 8, 4):
			var solid := true
			for d: Vector2i in [Vector2i(0, 0), Vector2i(7, 0), Vector2i(-7, 0), Vector2i(0, 7), Vector2i(0, -7)]:
				if img.get_pixel(x + d.x, y + d.y).a < 0.9:
					solid = false
					break
			if not solid:
				continue
			var p := Vector2(x - half, y - half) / half
			var dist := p.distance_to(Vector2(0.45, -0.45))
			if dist < best_d:
				best_d = dist
				best = p
	return best


## Amplia `z` vezes em volta do centro, cortando o que sai do quadro (pontas da peça).
func _zoomed(img: Image, z: float) -> Image:
	if z <= 1.0:
		return img
	var big := img.duplicate() as Image
	var side := int(PX * z)
	big.resize(side, side, Image.INTERPOLATE_LANCZOS)
	return big.get_region(Rect2i((side - PX) / 2, (side - PX) / 2, PX, PX))


func _outside(img: Image, frac: float) -> float:
	var half := PX * 0.5
	var r := half * frac
	var hits := 0
	var out := 0
	for y in range(-int(r), int(r) + 1, 4):
		for x in range(-int(r), int(r) + 1, 4):
			if Vector2(x, y).length() >= r:
				continue
			hits += 1
			if img.get_pixel(int(half + x), int(half + y)).a <= 0.5:
				out += 1
	return 100.0 * out / maxf(1.0, hits)


func _lum(img: Image) -> float:
	var total := 0.0
	var n := 0
	for y in range(0, PX, 4):
		for x in range(0, PX, 4):
			var c := img.get_pixel(x, y)
			if c.a > 0.5:
				total += c.get_luminance()
				n += 1
	return total / maxf(1.0, n)
