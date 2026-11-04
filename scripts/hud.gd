class_name Hud
extends CanvasLayer
## HUD minimalista (pontuação, recorde, nível da arma) e telas de início, pausa e fim de jogo.

signal restart_pressed
signal continue_pressed

const BAR_WIDTH := 320.0
const BAR_HEIGHT := 12.0
const BAR_LABEL_WIDTH := 150.0
const SHIELD_TRAIL_DELAY := 0.35   # o "rastro" branco espera antes de encolher
const SHIELD_TRAIL_SPEED := 0.8    # fração da barra por segundo

var _top: VBoxContainer
var _score_label: Label
var _best_label: Label
var _shield_label: Label
var _shield_bg: ColorRect
var _shield_fill: ColorRect
var _shield_trail: ColorRect
var _shield_ratio := 1.0
var _shield_trail_ratio := 1.0
var _shield_trail_wait := 0.0
var _shield_danger := false
var _blink_t := 0.0
var _weapon_label: Label
var _weapon_fill: ColorRect
var _levelup_label: Label
var _levelup_timer := 0.0

var _center: VBoxContainer
var _title: Label
var _subtitle: Label
var _info: Label
var _restart_button: Button
var _continue_button: Button


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- Topo ---
	_top = VBoxContainer.new()
	_top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top.add_theme_constant_override("separation", 6)
	root.add_child(_top)

	_score_label = _make_label("0", 72, Palette.NEON)
	_top.add_child(_score_label)
	_best_label = _make_label("RECORDE 0", 30, Palette.TEXT_DIM)
	_top.add_child(_best_label)

	_shield_label = _make_label("ESCUDO", 26, Palette.NEON)
	_shield_bg = _make_bar_row(_shield_label, Palette.NEON)
	_shield_trail = _add_fill(_shield_bg, Color(1, 1, 1, 0.55))
	_shield_fill = _add_fill(_shield_bg, Palette.NEON)

	_weapon_label = _make_label("ARMA 1", 26, Palette.MAGENTA)
	var weapon_bg := _make_bar_row(_weapon_label, Palette.MAGENTA)
	_weapon_fill = _add_fill(weapon_bg, Palette.MAGENTA)

	_levelup_label = _make_label("", 48, Palette.MAGENTA)
	_levelup_label.modulate.a = 0.0
	_top.add_child(_levelup_label)

	# --- Centro (mensagens e botões) ---
	_center = VBoxContainer.new()
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_center.alignment = BoxContainer.ALIGNMENT_CENTER
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center.add_theme_constant_override("separation", 28)
	root.add_child(_center)

	_title = _make_label("", 104, Palette.NEON)
	_center.add_child(_title)
	_subtitle = _make_label("", 40, Color.WHITE)
	_center.add_child(_subtitle)
	_info = _make_label("", 36, Palette.TEXT_DIM)
	_center.add_child(_info)
	_restart_button = _make_button("REINICIAR")
	_restart_button.pressed.connect(func() -> void: restart_pressed.emit())
	_center.add_child(_restart_button)
	_continue_button = _make_button("CONTINUAR (TESTE)")
	_continue_button.pressed.connect(func() -> void: continue_pressed.emit())
	_center.add_child(_continue_button)

	hide_center()


func _process(delta: float) -> void:
	if _levelup_timer > 0.0:
		_levelup_timer -= delta
		_levelup_label.modulate.a = clampf(_levelup_timer / 0.4, 0.0, 1.0)

	# Rastro branco: mostra o pedaço perdido num impacto e encolhe logo depois.
	if _shield_trail_ratio > _shield_ratio:
		_shield_trail_wait -= delta
		if _shield_trail_wait <= 0.0:
			_shield_trail_ratio = move_toward(_shield_trail_ratio, _shield_ratio, SHIELD_TRAIL_SPEED * delta)
	else:
		_shield_trail_ratio = _shield_ratio
	_shield_trail.size = Vector2(BAR_WIDTH * _shield_trail_ratio, BAR_HEIGHT)

	_blink_t += delta
	var color := Palette.DANGER if _shield_danger else Palette.NEON
	var dim := _shield_danger and int(_blink_t * 6.0) % 2 == 0
	_shield_fill.color = Color(color, 0.35 if dim else 1.0)
	_shield_bg.color = Color(color, 0.18)
	_shield_label.add_theme_color_override("font_color", color)


## Margem superior para não ficar embaixo do notch/câmera.
func set_safe_top(px: float) -> void:
	_top.offset_top = px + 24.0


func set_values(score: int, best: int, shield_ratio: float, last_chance: bool,
		weapon_level: int, weapon_progress: float) -> void:
	_score_label.text = str(score)
	_best_label.text = "RECORDE %d" % best

	shield_ratio = clampf(shield_ratio, 0.0, 1.0)
	# Queda grande de uma vez = impacto: segura o rastro branco por um instante.
	if _shield_ratio - shield_ratio > 0.02:
		_shield_trail_wait = SHIELD_TRAIL_DELAY
	_shield_ratio = shield_ratio
	_shield_danger = last_chance or shield_ratio < Tuning.SHIELD_LOW_RATIO
	_shield_fill.size = Vector2(BAR_WIDTH * shield_ratio, BAR_HEIGHT)

	_weapon_label.text = "ARMA %d" % weapon_level
	_weapon_fill.size = Vector2(BAR_WIDTH * clampf(weapon_progress, 0.0, 1.0), BAR_HEIGHT)


func on_weapon_level(level: int, went_up: bool) -> void:
	if not went_up:
		_levelup_label.text = "ARMA -1"
	elif level >= Tuning.WEAPON_MAX_LEVEL:
		_levelup_label.text = "ARMA MÁXIMA!"
	else:
		_levelup_label.text = "LEVEL UP!"
	_levelup_label.add_theme_color_override("font_color", Palette.MAGENTA if went_up else Palette.DANGER)
	_levelup_timer = 1.2


func show_ready(first_time: bool) -> void:
	_show(
		"ASTRA DODGE" if first_time else "PRONTO?",
		"Toque e arraste para pilotar",
		"Solte o dedo para pausar" if first_time else "",
		false, false)


func show_paused() -> void:
	_show("PAUSADO", "Toque para continuar", "", false, false)


func show_game_over(score: int, best: int, is_record: bool, can_continue: bool) -> void:
	_show(
		"FIM DE JOGO",
		("NOVO RECORDE! %d" if is_record else "PONTOS %d") % score,
		"RECORDE %d" % best,
		true, can_continue)


func hide_center() -> void:
	_center.visible = false


func _show(title: String, subtitle: String, info: String, show_restart: bool, show_continue: bool) -> void:
	_title.text = title
	_subtitle.text = subtitle
	_info.text = info
	_info.visible = info != ""
	_restart_button.visible = show_restart
	_continue_button.visible = show_continue
	_center.visible = true


## Linha "RÓTULO ████░░" centralizada no topo; retorna o fundo da barra.
func _make_bar_row(label: Label, color: Color) -> ColorRect:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 16)
	_top.add_child(row)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.custom_minimum_size.x = BAR_LABEL_WIDTH
	row.add_child(label)
	var bg := ColorRect.new()
	bg.color = Color(color, 0.18)
	bg.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(bg)
	# Espaço à direita do mesmo tamanho do rótulo, para a barra ficar no centro da tela.
	var spacer := Control.new()
	spacer.custom_minimum_size.x = BAR_LABEL_WIDTH
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)
	return bg


func _add_fill(bg: ColorRect, color: Color) -> ColorRect:
	var fill := ColorRect.new()
	fill.color = color
	fill.size = Vector2(0, BAR_HEIGHT)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(fill)
	return fill


func _make_label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(color, 0.25))
	l.add_theme_constant_override("outline_size", maxi(4, size / 8))
	return l


func _make_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(600, 120)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 44)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, Palette.NEON)
	for state in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.02, 0.05, 0.12, 0.85) if state != "pressed" else Color(Palette.NEON, 0.25)
		sb.border_color = Palette.NEON
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(18)
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b
