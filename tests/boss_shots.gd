extends SceneTree
## Uma captura de tela de cada chefe em luta (Setores 1–8), para conferir a arte.
## Uso (com janela, não headless): godot --path . --resolution 540x1170 --script res://tests/boss_shots.gd -- --out=PASTA [--fase=2]
## Saída: PASTA/boss_N.png. --fase=2 (ou 3, só o Núcleo da Fenda tem) leva o chefe a essa fase antes.

var main: Node2D
var out := "."
var target_phase := 1
var sector := 0
var wait := 0
var step := 0


func _initialize() -> void:
	var game := root.get_node("Game")
	game.persist = false
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		if a.begins_with("--fase="):
			target_phase = int(a.substr(7))
	process_frame.connect(_tick)


func _touch() -> void:
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.pressed = true
	t.position = Vector2(30, main.view_size.y - 30)
	main._input(t)


func _tick() -> void:
	wait += 1
	if wait < 5:
		return
	if step == 0:
		Engine.time_scale = 4.0
		main.start_sector_dev(sector, true)
		_touch()
		step = 1
		wait = 0
		return
	main.ship.invuln = 1.0
	if main.state == main.State.READY or main.state == main.State.PAUSED:
		_touch()
	var boss = main.boss
	if boss != null:
		main.ship.move_by(Vector2(boss.aim_x() - main.ship.target.x, 0.0) * 0.08)
	if step == 1 and boss != null and boss.state == boss.State.FIGHT:
		step = 2
		wait = 0
	# Leva à fase pedida (vida logo abaixo da troca: 50%; no Núcleo da Fenda 2/3 e 1/3).
	if step == 2 and boss != null and boss.phase < mini(target_phase, _max_phase(boss)) and boss.state == boss.State.FIGHT:
		var cut := 0.5
		if boss.display_name == "NÚCLEO DA FENDA":
			cut = 2.0 / 3.0 if boss.phase == 1 else 1.0 / 3.0
		boss.hp = boss.max_hp * cut - 1.0
		boss.damage(0.5)
		wait = 0
	if step == 2 and wait > 70 and (boss == null or boss.phase >= mini(target_phase, _max_phase(boss))):
		root.get_viewport().get_texture().get_image().save_png("%s/boss_%d.png" % [out, sector + 1])
		print("captura setor ", sector + 1)
		_next()
	elif step == 1 and wait > 60 * 60:
		print("sem chefe no setor ", sector + 1)
		_next()


func _max_phase(boss) -> int:
	return 3 if boss.display_name == "NÚCLEO DA FENDA" else 2


func _next() -> void:
	sector += 1
	step = 0
	wait = 0
	if sector >= 8:
		quit()
