class_name Nebula
extends Node2D
## Fundo de nebulosa (shader). Cores por setor; rola bem mais devagar que as estrelas.

const SCROLL_FACTOR := 0.03  # fração da velocidade do mundo (parallax bem distante)
const MARGIN := 60.0         # sobra nas bordas para o tremor de tela não mostrar o vazio

var view_size := Vector2.ZERO
var _scroll := 0.0
var _material: ShaderMaterial


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = preload("res://shaders/nebula.gdshader")
	material = _material


func resize(size: Vector2) -> void:
	view_size = size
	_material.set_shader_parameter("aspect", Vector2(1.0, size.y / maxf(size.x, 1.0)))
	queue_redraw()


func set_colors(a: Color, b: Color) -> void:
	_material.set_shader_parameter("color_a", a)
	_material.set_shader_parameter("color_b", b)


func update(dt: float, speed: float) -> void:
	_scroll += speed * SCROLL_FACTOR * dt / maxf(view_size.y, 1.0)
	_material.set_shader_parameter("scroll", _scroll)


func _draw() -> void:
	draw_rect(Rect2(-Vector2.ONE * MARGIN, view_size + Vector2.ONE * MARGIN * 2.0), Color.WHITE)
