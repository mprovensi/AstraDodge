extends SceneTree
## Grava as telas de menu: menu principal com CONTINUAR (~20), opções (~45) e pausa (~110).
## Uso: godot --path . --script res://tests/ui_capture.gd --write-movie frames/f.png --fixed-fps 30 --quit-after 120

var main: Node2D
var _frame := 0


func _initialize() -> void:
	var game := root.get_node("Game")
	game.persist = false
	game.checkpoint = {"sector": 0, "time": 30.0}
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_tick)


func _tick() -> void:
	_frame += 1
	if _frame == 30:
		main.hud.open_options()
	if _frame == 60:
		main.hud.close_options()
		main.resume_checkpoint()
	if _frame == 65:
		_touch(true)
	if _frame == 80:
		_touch(false)


func _touch(pressed: bool) -> void:
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.pressed = pressed
	t.position = Vector2(30, main.view_size.y - 30)
	main._input(t)
