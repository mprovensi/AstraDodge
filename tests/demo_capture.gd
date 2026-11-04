extends SceneTree
## Demo automática para gravar frames e conferir o visual (sem input real).
## Uso: godot --path . --script res://tests/demo_capture.gd --write-movie frames/f.png --fixed-fps 30 --quit-after 900

var main: Node2D
var _frame := 0


func _initialize() -> void:
	var game := root.get_node("Game")
	game.persist = false
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_tick)


func _tick() -> void:
	_frame += 1
	if _frame < 45:
		return  # mostra o menu principal
	if _frame == 45:
		main.start_mode(main.Mode.ENDLESS)
	if _frame == 45 or main.state == main.State.READY:
		_touch(true)
	if main.state == main.State.GAME_OVER and _frame % 60 == 0:
		main._on_continue()
	# Vai buscando cristais quando der, para mostrar a arma evoluindo.
	main.ship.add_crystal() if _frame % 40 == 0 else null
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.relative = Vector2(sin(_frame * 0.05) * 22.0, cos(_frame * 0.031) * 6.0)
	main._input(drag)


func _touch(pressed: bool) -> void:
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.pressed = pressed
	t.position = Vector2(30, main.view_size.y - 30)  # longe dos botões
	main._input(t)
