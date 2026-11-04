extends SceneTree
## Grava a tela de "SETOR COMPLETO" com as estrelas (2 de 3, para mostrar os dois estados).
## Uso: godot --path . --script res://tests/result_capture.gd --write-movie frames/f.png --fixed-fps 30 --quit-after 40

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
		main.start_mode(main.Mode.CAMPAIGN)
		main.score = 3517
		main.hud.show_sector_clear("SETOR 1", 3517, 3517, true, [true, true, false] as Array[bool])
