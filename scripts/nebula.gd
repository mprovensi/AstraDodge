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


const FADE_TIME := 3.0  # troca de bioma no Infinito: as cores mudam devagar

var _color_a := Color.BLACK
var _color_b := Color.BLACK
var _from_a := Color.BLACK
var _from_b := Color.BLACK
var _fade := 1.0  # 0 → 1 durante a transição


func set_colors(a: Color, b: Color) -> void:
	_color_a = a
	_color_b = b
	_fade = 1.0
	_apply(a, b)


## Troca de cor suave (bioma novo).
func fade_to(a: Color, b: Color) -> void:
	_from_a = _material.get_shader_parameter("color_a")
	_from_b = _material.get_shader_parameter("color_b")
	_color_a = a
	_color_b = b
	_fade = 0.0


func _apply(a: Color, b: Color) -> void:
	_material.set_shader_parameter("color_a", a)
	_material.set_shader_parameter("color_b", b)


func update(dt: float, speed: float) -> void:
	if _fade < 1.0:
		_fade = minf(1.0, _fade + dt / FADE_TIME)
		_apply(_from_a.lerp(_color_a, _fade), _from_b.lerp(_color_b, _fade))
	_scroll += speed * SCROLL_FACTOR * dt / maxf(view_size.y, 1.0)
	_material.set_shader_parameter("scroll", _scroll)


func _draw() -> void:
	draw_rect(Rect2(-Vector2.ONE * MARGIN, view_size + Vector2.ONE * MARGIN * 2.0), Color.WHITE)


## Gráficos simples: menos camadas de ruído (celular antigo).
func set_simple(simple: bool) -> void:
	_material.set_shader_parameter("octaves", 2 if simple else 4)
