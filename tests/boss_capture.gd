extends SceneTree
## Grava a luta contra a Rocha-Mãe para conferir o visual: ALERTA, entrada, leque de
## pedras com aviso, rachadura (fase 2), avanço de uma metade e a explosão final.
## Uso: godot --path . --script res://tests/boss_capture.gd --write-movie frames/f.png --fixed-fps 30 --quit-after 900

var main: Node2D
var _frame := 0


func _initialize() -> void:
	var game := root.get_node("Game")
	game.persist = false
	game.checkpoint = {"sector": 0, "time": 143.5, "weapon": 3}
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_tick)


func _tick() -> void:
	_frame += 1
	if _frame == 5:
		main.resume_checkpoint()
	if _frame == 10:
		var t := InputEventScreenTouch.new()
		t.index = 0
		t.pressed = true
		t.position = Vector2(30, main.view_size.y - 30)
		main._input(t)
	if _frame > 10:
		main.ship.invuln = 1.0
		var boss = main.boss
		if boss != null:
			main.ship.move_by(Vector2(boss.aim_x() - main.ship.target.x, 0.0) * 0.08)
			# Atalhos para mostrar as fases sem esperar a luta inteira.
			if _frame == 420 and boss.phase == 1:
				boss.hp = boss.max_hp / 2 + 1
				boss.damage(1)
			if _frame == 780:
				boss.hp = 1
				boss.damage(1)
