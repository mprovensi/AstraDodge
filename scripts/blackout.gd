class_name Blackout
extends Node2D
## BLECAUTE (Setor 7): a tela escurece por alguns segundos e só sobra a luz em volta da nave.
## Fica acima de asteroides/inimigos e ABAIXO dos avisos vermelhos, tiros e nave — os avisos
## de perigo continuam sempre visíveis (regra do jogo).

const MARGIN := 80.0

var view_size := Vector2.ZERO
var left := 0.0   # s restantes do blecaute
var _level := 0.0  # 0 → 1 (fade)
var _material: ShaderMaterial


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = preload("res://shaders/blackout.gdshader")
	material = _material
	visible = false


func resize(size: Vector2) -> void:
	view_size = size
	queue_redraw()


func start(duration: float) -> void:
	left = duration


func clear() -> void:
	left = 0.0
	_level = 0.0
	visible = false


func active() -> bool:
	return _level > 0.01


func update(dt: float, ship_pos: Vector2) -> void:
	left = maxf(0.0, left - dt)
	var target := 1.0 if left > 0.0 else 0.0
	_level = move_toward(_level, target, dt / Tuning.BLACKOUT_FADE)
	visible = _level > 0.0
	_material.set_shader_parameter("darkness", _level * Tuning.BLACKOUT_DARKNESS)
	_material.set_shader_parameter("light_pos", ship_pos)
	_material.set_shader_parameter("light_radius", Tuning.BLACKOUT_LIGHT)


func _draw() -> void:
	draw_rect(Rect2(-Vector2.ONE * MARGIN, view_size + Vector2.ONE * MARGIN * 2.0), Color.WHITE)
