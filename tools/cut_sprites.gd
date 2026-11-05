extends SceneTree
## Recorta os objetos de uma folha de sprites com FUNDO BRANCO (ex.: imagens geradas por IA em
## sprite_test/). Passos: apaga o branco a partir das bordas (o branco dentro do contorno fica),
## separa cada objeto (pedaços ligados), descarta pedacinhos soltos, tira 1 px da borda (o
## "halo" claro do JPG), recorta num quadrado centrado e salva PNG transparente.
## Saída: {out}/{prefixo}_{n}.png, numerados de cima para baixo, da esquerda para a direita.
## Uso: godot --headless --path . --script res://tools/cut_sprites.gd -- --in=CAMINHO --out=PASTA --prefixo=a [--min=6000] [--px=256]

const WHITE := 0.86      # mais claro que isso (e pouco colorido) é fundo
const SAT := 0.12
const HOLE_WHITE := 0.95  # furo fechado: branco quase puro...
const HOLE_MIN := 900     # ...e grande (px) — brilho de pintura é menor


func _initialize() -> void:
	var args := {"min": "6000", "px": "256", "prefixo": "s"}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			args[a.substr(2, a.find("=") - 2)] = a.get_slice("=", 1)
	var img := Image.load_from_file(args["in"])
	if img == null:
		push_error("não abriu %s (nomes com '…' falham: copie com nome simples)" % args["in"])
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	DirAccess.make_dir_recursive_absolute(args["out"])

	# 1. Fundo: inundação a partir das bordas por pixels quase brancos.
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
		if minf(c.r, minf(c.g, c.b)) < WHITE or c.s > SAT:
			continue
		bg[i] = 1
		var x := i % w
		var y := i / w
		if x > 0: stack.append(i - 1)
		if x < w - 1: stack.append(i + 1)
		if y > 0: stack.append(i - w)
		if y < h - 1: stack.append(i + w)

	# 1b. Furos: áreas grandes de branco puro FECHADAS pelo objeto (miolo da engrenagem, janelas
	# da treliça) também são fundo. Brilhos pequenos da pintura ficam (área < HOLE_MIN).
	var seen := PackedByteArray()
	seen.resize(w * h)
	for start in w * h:
		if bg[start] == 1 or seen[start] == 1:
			continue
		var c0 := img.get_pixel(start % w, start / w)
		if minf(c0.r, minf(c0.g, c0.b)) < HOLE_WHITE:
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
				var c := img.get_pixel(nb % w, nb / w)
				if minf(c.r, minf(c.g, c.b)) >= HOLE_WHITE - 0.06:
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
		out.resize(px, px, Image.INTERPOLATE_LANCZOS)
		var path := "%s/%s_%02d.png" % [args["out"], args["prefixo"], n]
		out.save_png(path)
		print("%s_%02d  area=%d  caixa=%dx%d  em (%d,%d)" % [args["prefixo"], n, f["area"], bw, bh, f["x0"], f["y0"]])
	quit()
