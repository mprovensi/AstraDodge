extends SceneTree
## Uma captura de tela de cada chefe em luta (Setores 1–8), para conferir a arte.
## Uso (com janela, não headless): godot --path . --resolution 540x1170 --script res://tests/boss_shots.gd -- --out=PASTA [--fase=2]
## Saída: PASTA/boss_N.png. --fase=2 leva cada chefe à fase 2 antes de capturar.

var main: Node2D
var out := "."
var phase2 := false
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
		if a == "--fase=2":
			phase2 = true
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
		if phase2 and boss.phase == 1:
			boss.hp = boss.max_hp * 0.5 - 1.0
			boss.damage(0.5)
		step = 2
		wait = 0
	if step == 2 and wait > 50:
		root.get_viewport().get_texture().get_image().save_png("%s/boss_%d.png" % [out, sector + 1])
		print("captura setor ", sector + 1)
		_next()
	elif step == 1 and wait > 60 * 60:
		print("sem chefe no setor ", sector + 1)
		_next()


func _next() -> void:
	sector += 1
	step = 0
	wait = 0
	if sector >= 8:
		quit()
