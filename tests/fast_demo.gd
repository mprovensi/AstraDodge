extends SceneTree
## DEMONSTRAÇÃO EM MODO RÁPIDO: abre o jogo numa janela e joga sozinho, acelerado,
## para acompanhar o jogo funcionando. Feche a janela (ou Ctrl+C no terminal) para parar.
##
## Uso:
##   godot --path . --script res://tests/fast_demo.gd -- [opções]
## Opções (todas opcionais):
##   --velocidade=3     multiplicador de velocidade (1 = normal; padrão 3)
##   --setor=1          setor da campanha (1 ou 2)
##   --inicio=0         segundo do setor onde começar (ex.: 120)
##   --chefe            começa direto no ALERTA do chefe do setor
##   --mortal           sem escudo infinito (a nave pode morrer; recomeça sozinha)
##   --arma=2           nível inicial da arma (1–5)
##   --infinito         Modo Infinito procedural (todos os biomas e chefes liberados)
##
## O piloto automático foge de metálicos, tiros, avisos vermelhos e do corpo do chefe,
## e procura poeira para atirar (ou o ponto fraco do chefe).

const LANE_STEP := 45.0
const LOOK_AHEAD := 760.0
const MAX_STEP := 26.0  # px por frame que o piloto move a nave (antes da aceleração)

var main: Node2D
var speed := 3.0
var sector := 1
var start_time := 0.0
var mortal := false
var weapon := 2
var endless := false
var _frame := 0
var _clear_wait := 0.0
var _label: Label


func _initialize() -> void:
	_parse_args()
	root.get_node("Game").persist = false  # a demo nunca mexe no save real
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_add_overlay()
	process_frame.connect(_tick)


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=")
		match kv[0]:
			"velocidade":
				speed = clampf(float(kv[1]), 0.25, 8.0)
			"setor":
				sector = clampi(int(kv[1]), 1, 9)
			"inicio":
				start_time = maxf(0.0, float(kv[1]))
			"chefe":
				start_time = -1.0
			"mortal":
				mortal = true
			"infinito":
				endless = true
			"arma":
				weapon = clampi(int(kv[1]), 1, 5)


func _add_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	root.add_child(layer)
	_label = Label.new()
	# Embaixo à esquerda: o cabeçalho do jogo (pontos, barras, chefe) fica livre.
	_label.anchor_top = 1.0
	_label.anchor_bottom = 1.0
	_label.offset_left = 24.0
	_label.offset_top = -90.0
	_label.offset_bottom = -40.0
	_label.add_theme_font_size_override("font_size", 34)
	_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("outline_size", 8)
	layer.add_child(_label)


func _tick() -> void:
	_frame += 1
	if _frame == 3:
		_start_sector(sector)
		return
	if _frame < 3:
		return
	_label.text = "DEMO %sx · %s · %s" % [str(speed), _sector_title(), _state_name()]

	match main.state:
		main.State.GAME_OVER:
			main._on_restart()
			_touch()
		main.State.SECTOR_CLEAR:
			# Mostra o resultado um pouco e segue para o próximo setor (ou recomeça).
			_clear_wait += 1.0 / 60.0
			if _clear_wait > 2.5:
				_clear_wait = 0.0
				if main._has_next_sector():
					var lvl: int = main.ship.weapon_level
					main._on_next_sector()
					main.ship.weapon_level = lvl
				else:
					main.start_mode(main.Mode.CAMPAIGN, 0)
				_touch()
		main.State.READY, main.State.PAUSED:
			_touch()
		_:
			_autopilot()


func _start_sector(number: int) -> void:
	Engine.time_scale = speed
	if endless:
		main.endless_biomes.assign([0, 1, 2, 3, 4, 5, 6])
		main.endless_bosses.assign(["rock_mother", "miner", "medusa", "cruiser", "ice_colossus", "hive_queen", "sentinel"])
		main.start_endless()
		main.ship.weapon_level = weapon
		_touch()
		return
	var index := clampi(number - 1, 0, main.SECTORS.size() - 1)
	var t := start_time
	if t < 0.0:
		t = _boss_time(index)
	var game := root.get_node("Game")
	game.checkpoint = {"sector": index, "time": t, "weapon": weapon}
	main.go_to_menu()
	main.resume_checkpoint()
	_touch()


## Segundo do evento BOSS do setor, um pouco antes (para ver o "Algo enorme..." e o ALERTA).
func _boss_time(index: int) -> float:
	for e in main.SECTORS[index].events:
		if e.kind == WaveEvent.Kind.BOSS:
			return maxf(0.0, e.at - 4.0)
	return 0.0


func _autopilot() -> void:
	var ship = main.ship
	if not mortal:
		ship.shield = maxf(ship.shield, 60.0)  # "escudo infinito": a demo não para
		ship.last_chance = false
	var w: float = main.view_size.x
	var h: float = main.view_size.y
	var ship_y := h * 0.76
	var best_x: float = ship.target.x
	var best_score := -INF
	var x := 70.0
	while x <= w - 70.0:
		var score := -_danger(x, ship_y) + _attraction(x, ship_y)
		score -= absf(x - ship.target.x) * 0.02  # prefere não ficar "pulando"
		if score > best_score:
			best_score = score
			best_x = x
		x += LANE_STEP
	var dx := clampf(best_x - ship.target.x, -MAX_STEP, MAX_STEP)
	var dy := clampf(ship_y - ship.target.y, -MAX_STEP, MAX_STEP)
	ship.move_by(Vector2(dx, dy))


## Quanto perigo há na faixa vertical acima de x (metálicos, tiros, avisos, chefe).
func _danger(x: float, ship_y: float) -> float:
	var d := 0.0
	for a in main.asteroids.asteroids:
		var above: float = ship_y - a.pos.y
		if above < -60.0 or above > LOOK_AHEAD:
			continue
		var reach: float = a.radius + 60.0
		var gap := absf(x - a.pos.x)
		if gap < reach:
			var weight := 3.0 if a.kind == 1 else 0.6  # metálico pesa muito mais
			d += (reach - gap) * weight * (1.0 - above / LOOK_AHEAD * 0.6)
	for s in main.enemy_shots.pool:
		if not s.alive:
			continue
		# Projeta o tiro até a altura da nave.
		var t: float = (ship_y - s.pos.y) / maxf(s.vel.y, 1.0)
		if t < 0.0 or t > 2.0:
			continue
		var px: float = s.pos.x + s.vel.x * t
		var reach: float = s.radius + 70.0
		if absf(x - px) < reach:
			d += (reach - absf(x - px)) * 4.0 * (1.0 - t * 0.4)
	for wn in main.telegraph._warnings:
		if wn.shape == 0 and x > wn.a.x - 40.0 and x < wn.a.y + 40.0:  # coluna
			d += 900.0
		elif wn.shape == 2 and absf(x - wn.a.x) < wn.size + 60.0 and absf(ship_y - wn.a.y) < wn.size + 200.0:
			d += 700.0  # círculo (cargas, leque)
		elif wn.shape == 1:  # linha (arremesso): distância do ponto até a reta
			var seg: Vector2 = wn.b - wn.a
			var k: float = clampf((Vector2(x, ship_y) - wn.a).dot(seg) / seg.length_squared(), 0.0, 1.0)
			if Vector2(x, ship_y).distance_to(wn.a + seg * k) < wn.size * 0.5 + 60.0:
				d += 900.0
	# Setor 3: nuvens iônicas (drenam o escudo) e minas (explodem se chegar perto).
	for c in main.hazards.clouds:
		var above_c: float = ship_y - c.pos.y
		if above_c > -c.radius and above_c < LOOK_AHEAD and absf(x - c.pos.x) < c.radius * 0.85 + 40.0:
			d += 250.0
	# Setor 5: cometas em voo — onde a reta dele cruza a altura da nave.
	for cm in main.hazards.comets:
		if not cm.flying():
			continue
		var dir: Vector2 = (cm.to - cm.from).normalized()
		if dir.y <= 0.01 or cm.pos.y > ship_y + 80.0:
			continue
		var cross_x: float = cm.pos.x + dir.x * (ship_y - cm.pos.y) / dir.y
		if absf(x - cross_x) < Tuning.COMET_WARN_WIDTH * 0.5 + 40.0:
			d += 900.0
	for e in main.enemies.enemies:
		var above_e: float = ship_y - e.pos.y
		if e.kind == 1:  # mina
			if above_e > -80.0 and above_e < LOOK_AHEAD and absf(x - e.pos.x) < Tuning.MINE_TRIGGER + 20.0:
				d += 500.0 * (1.0 - above_e / LOOK_AHEAD * 0.5)
		elif above_e > -60.0 and above_e < LOOK_AHEAD:  # drone, torreta, míssil: não encostar
			var reach_e: float = e.radius + 80.0
			if absf(x - e.pos.x) < reach_e:
				d += (reach_e - absf(x - e.pos.x)) * 5.0
	if main.boss != null:
		for yy in [ship_y, ship_y - 150.0, ship_y - 300.0]:
			if main.boss.touches(Vector2(x, yy), 70.0):
				d += 1200.0
	return d


## Para onde vale a pena ir: embaixo do ponto fraco do chefe, ou de poeira para atirar.
func _attraction(x: float, ship_y: float) -> float:
	if main.boss != null:
		return 300.0 - absf(x - main.boss.aim_x()) * 0.8
	var best := 0.0
	for a in main.asteroids.asteroids:
		if a.kind != 0:
			continue
		var above: float = ship_y - a.pos.y
		if above < 100.0 or above > 1200.0:
			continue
		best = maxf(best, 200.0 - absf(x - a.pos.x) * 0.6)
	for p in main.pickups.pickups:
		var above_p: float = ship_y - p.pos.y
		if above_p > 0.0 and above_p < 700.0:
			best = maxf(best, 260.0 - absf(x - p.pos.x) * 0.7)
	return best


func _touch() -> void:
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.pressed = true
	t.position = Vector2(30, main.view_size.y - 30)
	main._input(t)


func _sector_title() -> String:
	return main.director.sector.title if main.director != null else "MENU"


func _state_name() -> String:
	if main.boss != null:
		return "CHEFE %s %d%%" % [main.boss.display_name, int(main.boss.hp_ratio() * 100.0)]
	if main.director != null:
		return "%ds" % int(main.director.time)
	return ""
