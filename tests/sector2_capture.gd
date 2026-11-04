extends SceneTree
## Grava o Setor 2: metálicos com propulsor, poeira blindada e um corredor (frames 1–330),
## depois a luta contra o Minerador (frames 331+), com atalho para a fase 2.
## Uso: godot --path . --script res://tests/sector2_capture.gd --write-movie frames/f.png --fixed-fps 30 --quit-after 1000

var main: Node2D
var _frame := 0


func _initialize() -> void:
	root.get_node("Game").persist = false
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_tick)


func _tick() -> void:
	_frame += 1
	if _frame == 5:
		_resume(30.0)
	if _frame == 160:
		main._on_wave_event(WaveEvent.make(0.0, WaveEvent.Kind.CORRIDOR, {"duration": 6.0}))
	if _frame == 330:
		_resume(143.5)
	if _frame > 10:
		main.ship.invuln = 1.0
		var boss = main.boss
		if boss != null:
			main.ship.move_by(Vector2(boss.aim_x() - main.ship.target.x, 0.0) * 0.08)
			if _frame == 720 and boss.phase == 1:
				boss.hp = boss.max_hp / 2 + 1
				boss.damage(1)
		else:
			main.ship.move_by(Vector2(sin(_frame * 0.04) * 10.0, 0.0))


func _resume(time: float) -> void:
	var game := root.get_node("Game")
	game.checkpoint = {"sector": 1, "time": time, "weapon": 3}
	main.go_to_menu()
	main.resume_checkpoint()
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.pressed = true
	t.position = Vector2(30, main.view_size.y - 30)
	main._input(t)
