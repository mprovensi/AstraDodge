extends SceneTree
## Gera a NAVE DO JOGADOR (v3, visual realista) em 5 poses de rolagem (art/sprites/ship*.svg):
##   ship_roll_l2, ship_roll_l1, ship (reta), ship_roll_r1, ship_roll_r2
## Metal com volume (luz da esquerda), painéis, rebites, cabine com moldura, canhões nas asas,
## naceles com anéis e bocais com metal "queimado". O neon fica só nos detalhes (faixas e luzes).
## Na rolagem para a direita a asa direita "afunda" (mais curta e escura) e a esquerda sobe.
## O jogo troca o quadro conforme a nave vai para os lados (Ship._draw) e usa ArtSet.roll_x()
## para os pontos de encaixe (motores, asas). Depois rode gen_sprites.gd e gen_art_set.gd.
## Uso: godot --headless --path . --script res://tools/gen_ship.gd

const OUT := "res://art/sprites"
const POSES := {"ship_roll_l2": -1.0, "ship_roll_l1": -0.5, "ship": 0.0, "ship_roll_r1": 0.5, "ship_roll_r2": 1.0}

var roll := 0.0


func _initialize() -> void:
	for name: String in POSES:
		roll = POSES[name]
		var f := FileAccess.open("%s/%s.svg" % [OUT, name], FileAccess.WRITE)
		f.store_string(_ship())
		f.close()
	print("Nave gerada em 5 poses em ", OUT)
	quit()


# ---------------------------------------------------------------- geometria com rolagem

func _x(x: float) -> float:
	return ArtSet.roll_x(x, roll)  # a mesma conta que o jogo usa


func _p(v: Vector2) -> String:
	return "%.1f %.1f" % [_x(v.x), v.y]


func _poly(points: Array) -> String:
	var s := "M" + _p(points[0])
	for i in range(1, points.size()):
		s += " L" + _p(points[i])
	return s + " Z"


func _line(a: Vector2, b: Vector2) -> String:
	return "M%s L%s" % [_p(a), _p(b)]


## Espelha um ponto do lado esquerdo para o direito (desenho simétrico na pose reta).
static func _m(v: Vector2) -> Vector2:
	return Vector2(256.0 - v.x, v.y)


static func _mirror(points: Array) -> Array:
	var out := []
	for v: Vector2 in points:
		out.append(_m(v))
	return out


## Lado que sobe fica claro; o que afunda, escuro. side: -1 esquerda, +1 direita.
func _tone(side: float, light: Color, dark: Color) -> String:
	var t := clampf(0.55 - side * roll * 0.45, 0.0, 1.0)
	return "#" + dark.lerp(light, t).to_html(false)


func _path(d: String, attrs: String) -> String:
	return "  <path d=\"%s\" %s/>\n" % [d, attrs]


# ---------------------------------------------------------------- desenho

func _ship() -> String:
	var hull_mid := clampf(0.45 + roll * 0.2, 0.15, 0.85)  # o "meio" da luz do casco anda com a rolagem
	var svg := "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"256\" height=\"256\" viewBox=\"0 0 256 256\">\n"
	svg += "  <!-- Nave do jogador v3 (realista), rolagem %.1f — gerada por tools/gen_ship.gd. Bocais em (104,214)/(152,214) na pose reta. -->\n" % roll
	svg += """  <defs>
    <linearGradient id="hull" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#dbe3ec"/><stop offset="%.2f" stop-color="#8592a4"/><stop offset="1" stop-color="#2b323d"/>
    </linearGradient>
    <linearGradient id="spine" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#5a6678"/><stop offset="1" stop-color="#2a313c"/>
    </linearGradient>
    <linearGradient id="wingL" x1="1" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="%s"/><stop offset="1" stop-color="#1c222b"/>
    </linearGradient>
    <linearGradient id="wingR" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="%s"/><stop offset="1" stop-color="#151a21"/>
    </linearGradient>
    <linearGradient id="glass" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#b8e8ff"/><stop offset="0.3" stop-color="#2f6f98"/><stop offset="1" stop-color="#06131f"/>
    </linearGradient>
    <linearGradient id="nacelle" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#b9c4d2"/><stop offset="0.45" stop-color="#5c6878"/><stop offset="1" stop-color="#1b2129"/>
    </linearGradient>
    <linearGradient id="pod" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#9aa6b6"/><stop offset="1" stop-color="#262d37"/>
    </linearGradient>
    <radialGradient id="nozzle" cx="50%%" cy="38%%" r="62%%">
      <stop offset="0" stop-color="#fff3cf"/><stop offset="0.3" stop-color="#ff9a3c"/><stop offset="0.62" stop-color="#6a2a12"/><stop offset="1" stop-color="#140a07"/>
    </radialGradient>
    <linearGradient id="heat" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#8f7fb8"/><stop offset="0.5" stop-color="#c79a5a"/><stop offset="1" stop-color="#4a3e66"/>
    </linearGradient>
  </defs>
""" % [hull_mid, _tone(-1.0, Color("#aab6c6"), Color("#3a4350")), _tone(1.0, Color("#aab6c6"), Color("#3a4350"))]

	var outline := "stroke=\"#0a0f17\" stroke-width=\"2.5\" stroke-linejoin=\"round\""
	# --- Asas (enflechadas, com flap e canhão) ---
	var wing_l := [Vector2(112, 96), Vector2(30, 170), Vector2(32, 186), Vector2(106, 168)]
	svg += _path(_poly(wing_l), "fill=\"url(#wingL)\" " + outline)
	svg += _path(_poly(_mirror(wing_l)), "fill=\"url(#wingR)\" " + outline)
	for side in [-1.0, 1.0]:
		var f := func(v: Vector2) -> Vector2: return v if side < 0.0 else _m(v)
		# Flap (borda de fuga) e linhas de painel.
		svg += _path(_line(f.call(Vector2(42, 178)), f.call(Vector2(102, 162))), "stroke=\"#0a0f17\" stroke-width=\"1.5\" opacity=\"0.8\"")
		svg += _path(_line(f.call(Vector2(66, 146)), f.call(Vector2(104, 140))), "stroke=\"#0a0f17\" stroke-width=\"1.2\" opacity=\"0.6\"")
		# Bordo de ataque: luz só na asa que sobe (ou nas duas, de leve, na pose reta).
		var lead_a: float = 0.85 if side * roll < 0.0 else (0.5 if is_zero_approx(roll) else 0.15)
		svg += _path(_line(f.call(Vector2(109, 101)), f.call(Vector2(35, 168))), "stroke=\"#eef6ff\" stroke-width=\"2\" stroke-linecap=\"round\" opacity=\"%.2f\"" % lead_a)
		# Canhão sob a asa.
		var pod := [f.call(Vector2(66, 130)), f.call(Vector2(72, 130)), f.call(Vector2(73, 172)), f.call(Vector2(65, 172))]
		svg += _path(_poly(pod), "fill=\"url(#pod)\" " + outline)
		svg += _path(_line(f.call(Vector2(69, 124)), f.call(Vector2(69, 132))), "stroke=\"#1b2129\" stroke-width=\"3\" stroke-linecap=\"round\"")
		# Faixa neon fina perto da raiz (identidade do jogo) e luz de navegação na ponta.
		svg += _path(_line(f.call(Vector2(82, 156)), f.call(Vector2(102, 150))), "stroke=\"#ff4fd8\" stroke-width=\"3\" stroke-linecap=\"round\"")
	svg += "  <circle cx=\"%.1f\" cy=\"178\" r=\"3.5\" fill=\"#ff4a4a\"/>\n" % _x(33)
	svg += "  <circle cx=\"%.1f\" cy=\"178\" r=\"3.5\" fill=\"#4aff8a\"/>\n" % _x(223)

	# --- Naceles dos motores (cilindros com anéis) ---
	for x0: float in [90.0, 138.0]:
		var nac := [Vector2(x0, 146), Vector2(x0 + 28, 146), Vector2(x0 + 27, 210), Vector2(x0 + 1, 210)]
		svg += _path(_poly(nac), "fill=\"url(#nacelle)\" " + outline)
		for y in [168.0, 188.0]:
			svg += _path(_line(Vector2(x0 + 1, y), Vector2(x0 + 27, y)), "stroke=\"#1a2029\" stroke-width=\"2\" opacity=\"0.8\"")
		svg += _path(_line(Vector2(x0 + 5, 154), Vector2(x0 + 23, 154)), "stroke=\"#06090e\" stroke-width=\"5\"")
		# Anel de metal "queimado" (titânio azulado/dourado) antes do bocal.
		svg += _path(_poly([Vector2(x0 + 1, 202), Vector2(x0 + 27, 202), Vector2(x0 + 27, 210), Vector2(x0 + 1, 210)]),
				"fill=\"url(#heat)\" opacity=\"0.9\"")

	# --- Fuselagem ---
	var hull := [Vector2(128, 8), Vector2(137, 26), Vector2(145, 54), Vector2(150, 88), Vector2(153, 120),
			Vector2(156, 186), Vector2(147, 200), Vector2(128, 207), Vector2(109, 200), Vector2(100, 186),
			Vector2(103, 120), Vector2(106, 88), Vector2(111, 54), Vector2(119, 26)]
	svg += _path(_poly(hull), "fill=\"url(#hull)\" " + outline)
	# Espinha central escura (dá volume) e painéis.
	svg += _path(_poly([Vector2(124, 104), Vector2(132, 104), Vector2(134, 196), Vector2(122, 196)]), "fill=\"url(#spine)\" opacity=\"0.85\"")
	var panels := [[Vector2(108, 118), Vector2(148, 118)], [Vector2(106, 146), Vector2(150, 146)],
			[Vector2(104, 172), Vector2(152, 172)], [Vector2(116, 40), Vector2(140, 40)]]
	for seg in panels:
		svg += _path(_line(seg[0], seg[1]), "stroke=\"#0a0f17\" stroke-width=\"1.3\" opacity=\"0.7\"")
	# Rebites.
	for v: Vector2 in [Vector2(110, 124), Vector2(110, 152), Vector2(108, 178), Vector2(146, 124), Vector2(146, 152), Vector2(148, 178)]:
		svg += "  <circle cx=\"%.1f\" cy=\"%.0f\" r=\"1.4\" fill=\"#1a2029\"/>\n" % [_x(v.x), v.y]
	# Respiros laterais.
	for y in [128.0, 134.0, 140.0]:
		svg += _path(_line(Vector2(112, y), Vector2(118, y)), "stroke=\"#0a0f17\" stroke-width=\"2\"")
		svg += _path(_line(Vector2(138, y), Vector2(144, y)), "stroke=\"#0a0f17\" stroke-width=\"2\"")
	# Lateral aparecendo na rolagem (sombra do lado que afunda).
	if absf(roll) > 0.1:
		var sx := 154.0 if roll > 0.0 else 102.0
		var d := signf(roll)
		svg += _path(_poly([Vector2(sx - d * 8.0, 92), Vector2(sx, 92), Vector2(sx + d * 2.0, 186), Vector2(sx - d * 8.0, 190)]),
				"fill=\"#05080d\" opacity=\"%.2f\"" % (0.55 * absf(roll)))
	# Luz rasante no lado iluminado (borda).
	svg += _path(_line(Vector2(118, 30), Vector2(104, 120)), "stroke=\"#f4f8ff\" stroke-width=\"2\" opacity=\"%.2f\" stroke-linecap=\"round\"" % (0.7 - roll * 0.4))
	# Faixa neon central curta (identidade).
	svg += _path(_line(Vector2(128, 150), Vector2(128, 194)), "stroke=\"#3ff0ff\" stroke-width=\"2.5\" opacity=\"0.9\"")

	# --- Cabine: moldura metálica + vidro escuro + reflexo ---
	var frame := [Vector2(128, 32), Vector2(137, 48), Vector2(141, 70), Vector2(140, 92), Vector2(133, 102),
			Vector2(123, 102), Vector2(116, 92), Vector2(115, 70), Vector2(119, 48)]
	svg += _path(_poly(frame), "fill=\"#2a323e\" " + outline)
	var glass := [Vector2(128, 38), Vector2(135, 52), Vector2(138, 70), Vector2(137, 89), Vector2(131, 97),
			Vector2(125, 97), Vector2(119, 89), Vector2(118, 70), Vector2(121, 52)]
	svg += _path(_poly(glass), "fill=\"url(#glass)\"")
	svg += _path(_line(Vector2(118, 74), Vector2(138, 74)), "stroke=\"#2a323e\" stroke-width=\"2.5\"")
	svg += _path(_line(Vector2(124 - roll * 4.0, 50), Vector2(121 - roll * 4.0, 70)), "stroke=\"#ffffff\" stroke-width=\"3\" stroke-linecap=\"round\" opacity=\"0.85\"")
	svg += _path(_line(Vector2(123 - roll * 4.0, 80), Vector2(122 - roll * 4.0, 90)), "stroke=\"#ffffff\" stroke-width=\"2\" stroke-linecap=\"round\" opacity=\"0.5\"")

	# --- Bocais redondos (ovais no lado que afunda) ---
	for nx: float in [104.0, 152.0]:
		var sink := (nx - 128.0) * roll > 0.0
		var rx := 12.5 * (1.0 - 0.35 * absf(roll) if sink else 1.0)
		svg += "  <ellipse cx=\"%.1f\" cy=\"214\" rx=\"%.1f\" ry=\"8.5\" fill=\"url(#nozzle)\" stroke=\"#2a2f38\" stroke-width=\"3\"/>\n" % [_x(nx), rx]
		svg += "  <ellipse cx=\"%.1f\" cy=\"214\" rx=\"%.1f\" ry=\"3.5\" fill=\"#fff6d8\"/>\n" % [_x(nx), rx * 0.42]
	return svg + "</svg>\n"
