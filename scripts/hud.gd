class_name Hud
extends CanvasLayer
## HUD minimalista (pontuação, recorde, escudo, arma, progresso do setor), dicas na tela
## e as telas de menu, pronto, pausa, fim de jogo, setor completo e opções.

signal resume_pressed
signal campaign_pressed
signal restart_pressed
signal continue_pressed
signal menu_pressed
signal quit_pressed

const BAR_WIDTH := 320.0
const BAR_HEIGHT := 12.0
const BAR_LABEL_WIDTH := 150.0
const SHIELD_TRAIL_DELAY := 0.35   # o "rastro" branco espera antes de encolher
const SHIELD_TRAIL_SPEED := 0.8    # fração da barra por segundo
const HINT_FADE := 0.4
const PAUSE_TOP_MARGIN := 460.0

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
var _hint_label: Label
var _hint_timer := 0.0

var _center: VBoxContainer
var _center_spacer: Control
var _title: Label
var _subtitle: Label
var _info: Label
var _buttons := {}  # id -> Button (na ordem em que aparecem)

var _options_layer: Control
var _center_was_visible := false
var _music_button: Button
var _sfx_button: Button
var _vibration_button: Button
var _sensitivity_label: Label


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

	_hint_label = _make_label("", 40, Color.WHITE)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.modulate.a = 0.0
	_top.add_child(_hint_label)

	# --- Centro (mensagens e botões) ---
	_center = VBoxContainer.new()
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_center.alignment = BoxContainer.ALIGNMENT_CENTER
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center.add_theme_constant_override("separation", 28)
	root.add_child(_center)

	# Na pausa o menu sobe e deixa a parte de baixo livre para tocar e voltar a jogar.
	_center_spacer = Control.new()
	_center_spacer.custom_minimum_size.y = PAUSE_TOP_MARGIN
	_center_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center.add_child(_center_spacer)

	_title = _make_label("", 104, Palette.NEON)
	_center.add_child(_title)
	_subtitle = _make_label("", 40, Color.WHITE)
	_center.add_child(_subtitle)
	_info = _make_label("", 36, Palette.TEXT_DIM)
	_center.add_child(_info)

	_add_center_button("resume", "CONTINUAR", resume_pressed.emit)
	_add_center_button("campaign", "NOVO JOGO", campaign_pressed.emit)
	_add_center_button("restart", "REINICIAR", restart_pressed.emit)
	_add_center_button("continue", "CONTINUAR (TESTE)", continue_pressed.emit)
	_add_center_button("options", "OPÇÕES", open_options, false)
	_add_center_button("menu", "MENU PRINCIPAL", menu_pressed.emit)
	_add_center_button("quit", "SAIR DO JOGO", quit_pressed.emit)

	_build_options(root)
	hide_center()


func _process(delta: float) -> void:
	if _levelup_timer > 0.0:
		_levelup_timer -= delta
		_levelup_label.modulate.a = clampf(_levelup_timer / 0.4, 0.0, 1.0)

	if _hint_timer > 0.0:
		_hint_timer -= delta
		_hint_label.modulate.a = clampf(_hint_timer / HINT_FADE, 0.0, 1.0)

	# Rastro branco: mostra o pedaço perdido num impacto e encolhe logo depois.
	if _shield_trail_ratio > _shield_ratio:
		_shield_trail_wait -= delta
		if _shield_trail_wait <= 0.0:
			_shield_trail_ratio = move_toward(_shield_trail_ratio, _shield_ratio, SHIELD_TRAIL_SPEED * delta)
	else:
		_shield_trail_ratio = _shield_ratio
	_shield_trail.size = Vector2(BAR_WIDTH * _shield_trail_ratio, BAR_HEIGHT)

	# A barra fica sempre ciano; com escudo baixo ela só pisca.
	_blink_t += delta
	var dim := _shield_danger and int(_blink_t * 6.0) % 2 == 0
	_shield_fill.color = Color(Palette.NEON, 0.35 if dim else 1.0)


## Margem superior para não ficar embaixo do notch/câmera.
func set_safe_top(px: float) -> void:
	_top.offset_top = px + 24.0


## True se o toque caiu em algum botão/tela de opções (não deve iniciar a partida).
func blocks_touch(pos: Vector2) -> bool:
	if _options_layer.visible:
		return true
	for b: Button in _buttons.values():
		if b.is_visible_in_tree() and b.get_global_rect().has_point(pos):
			return true
	return false


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



func show_hint(text: String, duration: float) -> void:
	_hint_label.text = text
	_hint_timer = duration
	_hint_label.modulate.a = 1.0


func clear_hint() -> void:
	_hint_timer = 0.0
	_hint_label.modulate.a = 0.0


func on_weapon_level(level: int, went_up: bool) -> void:
	if not went_up:
		_levelup_label.text = "ARMA -1"
	elif level >= Tuning.WEAPON_MAX_LEVEL:
		_levelup_label.text = "ARMA MÁXIMA!"
	else:
		_levelup_label.text = "LEVEL UP!"
	_levelup_label.add_theme_color_override("font_color", Palette.MAGENTA if went_up else Palette.DANGER)
	_levelup_timer = 1.2


# ---------------------------------------------------------------- telas

## `can_resume`: existe um ponto salvo para o botão CONTINUAR.
func show_menu(can_resume: bool) -> void:
	var buttons := ["resume", "campaign", "options", "quit"] if can_resume else ["campaign", "options", "quit"]
	_show("ASTRA DODGE", "", "", buttons)
	_top.visible = false  # pontuação/barras só fazem sentido durante uma partida


func show_ready(title: String) -> void:
	_show(title, "Toque e arraste para pilotar", "Solte o dedo para pausar", [])


func show_paused() -> void:
	_show("PAUSADO", "Toque na tela para continuar", "", ["options", "quit"])
	_center.alignment = BoxContainer.ALIGNMENT_BEGIN
	_center_spacer.visible = true


func show_game_over(score: int, best: int, is_record: bool, can_continue: bool) -> void:
	var buttons := ["restart", "continue", "menu"] if can_continue else ["restart", "menu"]
	_show(
		"FIM DE JOGO",
		("NOVO RECORDE! %d" if is_record else "PONTOS %d") % score,
		"RECORDE %d" % best,
		buttons)


func show_sector_clear(title: String, score: int, best: int, is_record: bool) -> void:
	_show(
		"%s COMPLETO!" % title,
		("NOVO RECORDE! %d" if is_record else "PONTOS %d") % score,
		"RECORDE DO SETOR %d" % best,
		["restart", "menu"])


func hide_center() -> void:
	_center.visible = false


func _show(title: String, subtitle: String, info: String, buttons: Array) -> void:
	_title.text = title
	_subtitle.text = subtitle
	_subtitle.visible = subtitle != ""
	_info.text = info
	_info.visible = info != ""
	for id: String in _buttons:
		_buttons[id].visible = id in buttons
	_center.alignment = BoxContainer.ALIGNMENT_CENTER
	_center_spacer.visible = false
	_top.visible = true
	_center.visible = true


func _add_center_button(id: String, text: String, action: Callable, click := true) -> void:
	var b := _make_button(text)
	b.pressed.connect(func() -> void:
		if click:
			Sfx.play("click", -4.0, 1.0, 0.0)
		action.call())
	_center.add_child(b)
	_buttons[id] = b


# ---------------------------------------------------------------- opções

func open_options() -> void:
	Sfx.play("click", -4.0, 1.0, 0.0)
	_refresh_options()
	_center_was_visible = _center.visible
	_center.visible = false  # evita texto "vazando" atrás das opções
	_options_layer.visible = true


func close_options() -> void:
	Sfx.play("click", -4.0, 1.0, 0.0)
	_options_layer.visible = false
	_center.visible = _center_was_visible
	Game.save_data()


func _build_options(root: Control) -> void:
	_options_layer = Control.new()
	_options_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_options_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_options_layer.visible = false
	root.add_child(_options_layer)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.03, 0.9)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_options_layer.add_child(backdrop)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 26)
	_options_layer.add_child(box)

	box.add_child(_make_label("OPÇÕES", 80, Palette.NEON))

	_music_button = _make_button("")
	_music_button.pressed.connect(func() -> void:
		Game.music_enabled = not Game.music_enabled
		_on_option_changed())
	box.add_child(_music_button)

	_sfx_button = _make_button("")
	_sfx_button.pressed.connect(func() -> void:
		Game.sfx_enabled = not Game.sfx_enabled
		_on_option_changed())
	box.add_child(_sfx_button)

	_vibration_button = _make_button("")
	_vibration_button.pressed.connect(func() -> void:
		Game.vibration_enabled = not Game.vibration_enabled
		Game.vibrate(40)  # só vibra se acabou de ligar
		_on_option_changed())
	box.add_child(_vibration_button)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 10
	box.add_child(spacer)
	box.add_child(_make_label("SENSIBILIDADE DO ARRASTE", 30, Palette.TEXT_DIM))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	var minus := _make_button("-")
	minus.custom_minimum_size = Vector2(120, 120)
	minus.pressed.connect(_change_sensitivity.bind(-0.1))
	row.add_child(minus)
	_sensitivity_label = _make_label("", 48, Color.WHITE)
	_sensitivity_label.custom_minimum_size.x = 300
	row.add_child(_sensitivity_label)
	var plus := _make_button("+")
	plus.custom_minimum_size = Vector2(120, 120)
	plus.pressed.connect(_change_sensitivity.bind(0.1))
	row.add_child(plus)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size.y = 20
	box.add_child(spacer2)
	var back := _make_button("VOLTAR")
	back.pressed.connect(close_options)
	box.add_child(back)


func _on_option_changed() -> void:
	Sfx.apply_enabled()
	Sfx.play("click", -4.0, 1.0, 0.0)
	_refresh_options()


func _change_sensitivity(step: float) -> void:
	Game.sensitivity = clampf(snappedf(Game.sensitivity + step, 0.1), 0.8, 1.6)
	Sfx.play("click", -4.0, 1.0, 0.0)
	_refresh_options()


func _refresh_options() -> void:
	_set_toggle(_music_button, "MÚSICA", Game.music_enabled, "LIGADA", "DESLIGADA")
	_set_toggle(_sfx_button, "EFEITOS", Game.sfx_enabled, "LIGADOS", "DESLIGADOS")
	_set_toggle(_vibration_button, "VIBRAÇÃO", Game.vibration_enabled, "LIGADA", "DESLIGADA")
	_sensitivity_label.text = ("%.1fx" % Game.sensitivity).replace(".", ",")


func _set_toggle(b: Button, title: String, on: bool, on_text: String, off_text: String) -> void:
	b.text = "%s: %s" % [title, on_text if on else off_text]
	b.modulate.a = 1.0 if on else 0.5


# ---------------------------------------------------------------- construção

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
