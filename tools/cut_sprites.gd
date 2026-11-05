extends SceneTree
## Recorta os objetos de uma folha de sprites com FUNDO LISO (branco ou cinza; ex.: imagens geradas
## por IA em sprite_test/). Passos: apaga o fundo a partir das bordas (a cor do fundo é medida nas
## bordas da imagem; o que tem essa cor dentro do contorno fica),
## separa cada objeto (pedaços ligados), descarta pedacinhos soltos, tira 1 px da borda (o
## "halo" claro do JPG), recorta num quadrado centrado e salva PNG transparente.
## Saída: {out}/{prefixo}_{n}.png, numerados de cima para baixo, da esquerda para a direita.
## Uso: godot --headless --path . --script res://tools/cut_sprites.gd -- --in=CAMINHO --out=PASTA --prefixo=a [--min=6000] [--px=256]
##      --px=0 mantém o tamanho original do recorte; --tol=0.14 tolerância de cor do fundo;
##      --rect=x0,y0,x1,y1 recorta só esse retângulo da folha antes (peças muito próximas);
##      --halo=1 apaga o halo claro de brilho em volta do contorno (cristais, bolhas, faíscas).

const SAT := 0.12        # fundo é pouco colorido
const HOLE_TOL := 0.5     # furo fechado: cor do fundo quase exata (fração da tolerância)...
const HOLE_MIN := 900     # ...e grande (px) — brilho de pintura é menor


func _initialize() -> void:
	var args := {"min": "6000", "px": "256", "prefixo": "s", "tol": "0.14"}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			args[a.substr(2, a.find("=") - 2)] = a.get_slice("=", 1)
	var img := Image.load_from_file(args["in"])
	if img == null:
		push_error("não abriu %s (nomes com '…' falham: copie com nome simples)" % args["in"])
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)
	if args.has("rect"):
		var v := (args["rect"] as String).split(",")
		img = img.get_region(Rect2i(int(v[0]), int(v[1]), int(v[2]) - int(v[0]), int(v[3]) - int(v[1])))
	var w := img.get_width()
	var h := img.get_height()
	DirAccess.make_dir_recursive_absolute(args["out"])

	# 1. Fundo: cor média das bordas; inundação a partir delas por pixels parecidos com ela.
	var bgc := _border_color(img)
	var tol := float(args["tol"])
	var bg := PackedByteArray()
	bg.resize(w * h)
	var stack := PackedInt32Array()
	for x in w:
		stack.append(x)
		stack.append((h - 1) * w + x)
	for y in h:
		stack.append(y * w)
		stack.append(y * w + w - 1)
	while not stack.is_empty():
		var i := stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		if bg[i] == 1:
			continue
		var c := img.get_pixel(i % w, i / w)
		if maxf(absf(c.r - bgc.r), maxf(absf(c.g - bgc.g), absf(c.b - bgc.b))) > tol or c.s > SAT:
			continue
		bg[i] = 1
		var x := i % w
		var y := i / w
		if x > 0: stack.append(i - 1)
		if x < w - 1: stack.append(i + 1)
		if y > 0: stack.append(i - w)
		if y < h - 1: stack.append(i + w)

	# 1a. Halo de brilho: a partir do fundo, avança por pixels claros (o contorno escuro para).
	if args.get("halo", "0") == "1":
		for i in w * h:
			if bg[i] == 1:
				stack.append(i)
		while not stack.is_empty():
			var i := stack[stack.size() - 1]
			stack.resize(stack.size() - 1)
			var x := i % w
			var y := i / w
			for nb: int in [i - 1 if x > 0 else -1, i + 1 if x < w - 1 else -1, i - w, i + w]:
				if nb < 0 or nb >= w * h or bg[nb] == 1:
					continue
				var c := img.get_pixel(nb % w, nb / w)
				if c.v > 0.72 and c.s < 0.55:
					bg[nb] = 1
					stack.append(nb)

	# 1b. Furos: áreas grandes da cor do fundo FECHADAS pelo objeto (miolo da engrenagem, janelas
	# da treliça, vão entre os anéis) também são fundo. Brilhos pequenos da pintura ficam (< HOLE_MIN).
	var hole_tol := tol * HOLE_TOL
	var seen := PackedByteArray()
	seen.resize(w * h)
	for start in w * h:
		if bg[start] == 1 or seen[start] == 1:
			continue
		if not _near(img.get_pixel(start % w, start / w), bgc, hole_tol):
			continue
		var region := PackedInt32Array()
		stack.append(start)
		seen[start] = 1
		while not stack.is_empty():
			var i := stack[stack.size() - 1]
			stack.resize(stack.size() - 1)
			region.append(i)
			var x := i % w
			var y := i / w
			for nb: int in [i - 1 if x > 0 else -1, i + 1 if x < w - 1 else -1, i - w, i + w]:
				if nb < 0 or nb >= w * h or seen[nb] == 1 or bg[nb] == 1:
					continue
				if _near(img.get_pixel(nb % w, nb / w), bgc, hole_tol * 1.6):
					seen[nb] = 1
					stack.append(nb)
		if region.size() >= HOLE_MIN:
			for i in region:
				bg[i] = 1

	# 2. Tira 1 px de borda do objeto (halo claro do JPG vira fundo).
	var fg := PackedByteArray()
	fg.resize(w * h)
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var i := y * w + x
			if bg[i] == 0 and bg[i - 1] == 0 and bg[i + 1] == 0 and bg[i - w] == 0 and bg[i + w] == 0:
				fg[i] = 1

	# 3. Objetos = pedaços ligados do que sobrou.
	var label := PackedInt32Array()
	label.resize(w * h)
	var found: Array[Dictionary] = []
	for start in w * h:
		if fg[start] == 0 or label[start] != 0:
			continue
		var id := found.size() + 1
		var info := {"id": id, "area": 0, "x0": w, "y0": h, "x1": 0, "y1": 0}
		stack.append(start)
		label[start] = id
		while not stack.is_empty():
			var i := stack[stack.size() - 1]
			stack.resize(stack.size() - 1)
			var x := i % w
			var y := i / w
			info["area"] += 1
			info["x0"] = mini(info["x0"], x)
			info["y0"] = mini(info["y0"], y)
			info["x1"] = maxi(info["x1"], x)
			info["y1"] = maxi(info["y1"], y)
			for n: int in [i - 1, i + 1, i - w, i + w]:
				if n >= 0 and n < w * h and fg[n] == 1 and label[n] == 0:
					label[n] = id
					stack.append(n)
		found.append(info)

	# 4. Só os grandes, em ordem de leitura (linhas de ~ altura média).
	var keep: Array[Dictionary] = []
	for f in found:
		if f["area"] >= int(args["min"]):
			keep.append(f)
	keep.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ra := int((a["y0"] + a["y1"]) / 2 / 160)
		var rb := int((b["y0"] + b["y1"]) / 2 / 160)
		return ra < rb if ra != rb else a["x0"] < b["x0"])

	var px := int(args["px"])
	var n := 0
	for f in keep:
		n += 1
		var bw: int = f["x1"] - f["x0"] + 1
		var bh: int = f["y1"] - f["y0"] + 1
		var side := maxi(bw, bh) + 8
		var out := Image.create(side, side, false, Image.FORMAT_RGBA8)
		var ox := (side - bw) / 2
		var oy := (side - bh) / 2
		for y in bh:
			for x in bw:
				var sx: int = f["x0"] + x
				var sy: int = f["y0"] + y
				if label[sy * w + sx] == f["id"]:
					out.set_pixel(ox + x, oy + y, img.get_pixel(sx, sy))
		if px > 0:
			out.resize(px, px, Image.INTERPOLATE_LANCZOS)
		var path := "%s/%s_%02d.png" % [args["out"], args["prefixo"], n]
		out.save_png(path)
		print("%s_%02d  area=%d  caixa=%dx%d  em (%d,%d)" % [args["prefixo"], n, f["area"], bw, bh, f["x0"], f["y0"]])
	quit()


## Cor do fundo: mediana (por canal) dos pixels da borda da imagem.
func _border_color(img: Image) -> Color:
	var rs: Array[float] = []
	var gs: Array[float] = []
	var bs: Array[float] = []
	var w := img.get_width()
	var h := img.get_height()
	for k in 200:
		for p: Vector2i in [Vector2i(k * w / 200, 2), Vector2i(k * w / 200, h - 3),
				Vector2i(2, k * h / 200), Vector2i(w - 3, k * h / 200)]:
			var c := img.get_pixelv(p)
			rs.append(c.r)
			gs.append(c.g)
			bs.append(c.b)
	rs.sort()
	gs.sort()
	bs.sort()
	return Color(rs[rs.size() / 2], gs[gs.size() / 2], bs[bs.size() / 2])


func _near(c: Color, ref: Color, tol: float) -> bool:
	return maxf(absf(c.r - ref.r), maxf(absf(c.g - ref.g), absf(c.b - ref.b))) <= tol and c.s <= SAT
