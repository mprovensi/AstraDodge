class_name Autopilot
extends RefCounted
## Piloto automático: desvia de metálicos, tiros, avisos, nuvens, cometas, minas e chefes,
## e vai atrás de poeira, orbes e do ponto fraco do chefe. Usado pela demo do PC
## (tests/fast_demo.gd) e pelo JOGO AUTOMÁTICO do seletor de fases (só build de desenvolvimento).

const LANE_STEP := 45.0
const LOOK_AHEAD := 760.0
const MAX_STEP := 26.0  # px por frame que o piloto move a nave (antes da aceleração)

var main: Node


func _init(game_main: Node) -> void:
	main = game_main


## Um quadro de pilotagem (só com a partida rodando). `infinite_shield`: o escudo nunca acaba.
func step(infinite_shield: bool) -> void:
	var ship = main.ship
	if infinite_shield:
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
