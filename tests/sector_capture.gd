extends SceneTree
## Grava trechos do Setor 1 para conferir o visual: menu, dica de início,
## aviso + paredão e drones atirando. Nave invencível.
## Uso: godot --path . --script res://tests/sector_capture.gd --write-movie frames/f.png --fixed-fps 30 --quit-after 330

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
		main.start_mode(main.Mode.CAMPAIGN)
	if _frame == 45:
		_touch()
	if _frame > 45:
		main.ship.invuln = 0.0 if _frame < 120 else 1.0
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.relative = Vector2(sin(_frame * 0.05) * 14.0, 0)
		main._input(drag)
	if _frame == 150:
		main.director.metals = true
		main._on_wave_event(WaveEvent.make(0.0, WaveEvent.Kind.METAL_WALL))
	if _frame == 230:
		for i in 3:
			main.enemies.spawn_drone(Vector2(300 + i * 240, -40 - i * 60))


func _touch() -> void:
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.pressed = true
	t.position = Vector2(30, main.view_size.y - 30)
	main._input(t)
