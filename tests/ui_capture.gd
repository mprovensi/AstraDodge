extends SceneTree
## Grava as telas de menu: início (frame ~20) e opções (frame ~50).
## Uso: godot --path . --script res://tests/ui_capture.gd --write-movie frames/f.png --fixed-fps 30 --quit-after 60

var main: Node2D
var _frame := 0


func _initialize() -> void:
	root.get_node("Game").persist = false
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	process_frame.connect(_tick)


func _tick() -> void:
	_frame += 1
	if _frame == 30:
		main.hud.open_options()
