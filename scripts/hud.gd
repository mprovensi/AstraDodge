class_name Hud
extends CanvasLayer
## HUD minimalista (cabeçalho compacto: pontos, recorde, escudo, arma; barra do chefe), dicas na tela
## e as telas de menu, pronto, pausa, fim de jogo, setor completo e opções.

signal resume_pressed
signal campaign_pressed
signal endless_pressed
signal daily_pressed
signal restart_pressed
signal continue_pressed
signal menu_pressed
signal quit_pressed
signal new_game_pressed
signal next_pressed
signal dev_sector_pressed(index: int, at_boss: bool)  ## seletor de fases (só build de desenvolvimento)
signal module_chosen(index: int)  ## escolheu uma das 3 cartas do contêiner de carga

const BAR_WIDTH := 300.0
const BAR_HEIGHT := 12.0
const BAR_LABEL_WIDTH := 120.0
const SHIELD_TRAIL_DELAY := 0.35   # o "rastro" branco espera antes de encolher
const SHIELD_TRAIL_SPEED := 0.8    # fração da barra por segundo
const HINT_FADE := 0.4
const PAUSE_TOP_MARGIN := 460.0
const DIM_ALPHA := 0.82              # escurecimento do jogo atrás dos menus
const BOSS_BAR_WIDTH := 560.0
const BOSS_BAR_HEIGHT := 14.0
const HEADER_MARGIN := 36          # margem lateral do cabeçalho


## Três estrelas desenhadas (a fonte padrão não tem o caractere ★).
class StarsRow extends Control:
	var earned := 0

	func _draw() -> void:
		for i in 3:
			var c := Vector2(size.x * 0.5 + (i - 1) * 130.0, size.y * 0.5)
			var pts := PackedVector2Array()
			for j in 10:
				var r := 52.0 if j % 2 == 0 else 22.0
				pts.append(c + Vector2.from_angle(-PI / 2.0 + j * PI / 5.0) * r)
			if i < earned:
				draw_colored_polygon(pts, Color(1.0, 0.82, 0.25))
				draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1.0, 0.95, 0.7), 3.0, true)
			else:
				draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1, 1, 1, 0.3), 4.0, true)
const NEW_GAME_CONFIRM_TIME := 3.0  # segundos para o 2º toque confirmar o novo jogo

var _top: VBoxContainer
var _score_label: Label
var _best_label: Label
var _mult_label: Label
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
var _weapon_cap_seen := Tuning.WEAPON_MAX_LEVEL  # teto atual (para "MÁXIMO DO SETOR!")
var _levelup_label: Label
var _levelup_timer := 0.0
var _hint_panel: PanelContainer
var _hint_label: Label
var _hint_timer := 0.0
var _boss_box: VBoxContainer
var _boss_label: Label
var _boss_fill: ColorRect
var _dim: ColorRect
var _alert_layer: Control
var _alert_bg: ColorRect
var _alert_title: Label
var _stars: StarsRow
var _star_details: RichTextLabel

var _center: VBoxContainer
var _center_spacer: Control
var _title: Label
var _subtitle: Label
var _info: Label
var _buttons := {}  # id -> Button (na ordem em que aparecem)

var _options_layer: Control
var _dev_layer: Control  # seletor de fases: só existe em build de desenvolvimento (OS.is_debug_build)
var dev_auto := false   # seletor de fases: a fase escolhida é jogada pelo piloto automático
var _center_was_visible := false
var _music_label: Label  # volume da música (0–100%)
var _sfx_label: Label    # volume dos efeitos
var _vibration_button: Button
var _skin_button: Button
var _skin_info: Label
var _mod_button: Button
var _mod_info: Label
var _graphics_button: Button
var _fps_label: Label           # só em build de desenvolvimento
var _fps_window: Array[float] = []  # duração dos quadros dos últimos 3 s
var _module_layer: Control       # tela do contêiner de carga (escolha de módulo)
var _module_title: Label
var _module_sub: Label
var _module_hand: Label
var _module_cards: Array[Button] = []
var _sensitivity_label: Label
var _new_game_button: Button
var _new_game_armed := 0.0  # > 0: aguardando o toque de confirmação


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Escurece o jogo atrás dos menus (pausa, fim de jogo, setor completo) para o texto
	# e os botões não se misturarem com asteroides, tiros e nebulosa. Fica atrás do HUD.
	_dim = ColorRect.new()
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.0, 0.0, 0.02, DIM_ALPHA)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.visible = false
	root.add_child(_dim)

	# --- Topo ---
	_top = VBoxContainer.new()
	_top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top.add_theme_constant_override("separation", 6)
	root.add_child(_top)

	# Cabeçalho compacto numa faixa só: pontos e recorde à esquerda, escudo e arma à direita.
	# (Menos altura = a barra do chefe cabe logo abaixo sem cobrir o chefe.)
	var header_margin := MarginContainer.new()
	header_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		header_margin.add_theme_constant_override("margin_" + side, HEADER_MARGIN)
	_top.add_child(header_margin)
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_margin.add_child(header)

	var score_box := VBoxContainer.new()
	score_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_box.add_theme_constant_override("separation", -6)
	header.add_child(score_box)
	# Pontos + multiplicador (Infinito/Desafio) lado a lado.
	var score_row := HBoxContainer.new()
	score_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_row.add_theme_constant_override("separation", 14)
	score_box.add_child(score_row)
	_score_label = _make_label("0", 54, Palette.NEON)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	score_row.add_child(_score_label)
	_mult_label = _make_label("", 34, Palette.MAGENTA)
	_mult_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_mult_label.visible = false
	score_row.add_child(_mult_label)
	_best_label = _make_label("RECORDE 0", 22, Palette.TEXT_DIM)
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	score_box.add_child(_best_label)

	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(gap)

	var bars := VBoxContainer.new()
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars.alignment = BoxContainer.ALIGNMENT_CENTER
	bars.add_theme_constant_override("separation", 10)
	header.add_child(bars)
	_shield_label = _make_label("ESCUDO", 22, Palette.NEON)
	_shield_bg = _make_bar_row(bars, _shield_label, Palette.NEON)
	_shield_trail = _add_fill(_shield_bg, Color(1, 1, 1, 0.55))
	_shield_fill = _add_fill(_shield_bg, Palette.NEON)
	_weapon_label = _make_label("ARMA 1", 22, Palette.MAGENTA)
	var weapon_bg := _make_bar_row(bars, _weapon_label, Palette.MAGENTA)
	_weapon_fill = _add_fill(weapon_bg, Palette.MAGENTA)

	# Barra de vida do chefe (só durante a luta), centralizada com o nome embaixo, e marca
	# na troca de fase (50%).
	_boss_box = VBoxContainer.new()
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_boss_box.add_theme_constant_override("separation", 2)
	_boss_box.visible = false
	_top.add_child(_boss_box)
	var boss_bg := ColorRect.new()
	boss_bg.color = Color(Palette.DANGER, 0.18)
	boss_bg.custom_minimum_size = Vector2(BOSS_BAR_WIDTH, BOSS_BAR_HEIGHT)
	boss_bg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	boss_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.add_child(boss_bg)
	# Nome embaixo da barra, centralizado.
	_boss_label = _make_label("", 24, Palette.DANGER)
	_boss_box.add_child(_boss_label)
	_boss_fill = _add_fill(boss_bg, Palette.DANGER)
	_boss_fill.size = Vector2(BOSS_BAR_WIDTH, BOSS_BAR_HEIGHT)
	var mark := ColorRect.new()
	mark.color = Color(1, 1, 1, 0.7)
	mark.position = Vector2(BOSS_BAR_WIDTH * 0.5 - 1.5, -4)
	mark.size = Vector2(3, BOSS_BAR_HEIGHT + 8)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_bg.add_child(mark)

	_levelup_label = _make_label("", 48, Palette.MAGENTA)
	_levelup_label.modulate.a = 0.0
	_top.add_child(_levelup_label)

	# Dica em destaque: painel escuro com borda neon atrás do texto, fonte maior.
	_hint_panel = PanelContainer.new()
	_hint_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hint_style := StyleBoxFlat.new()
	hint_style.bg_color = Color(0.02, 0.05, 0.14, 0.82)
	hint_style.border_color = Palette.NEON
	hint_style.set_border_width_all(3)
	hint_style.set_corner_radius_all(18)
	hint_style.content_margin_left = 32
	hint_style.content_margin_right = 32
	hint_style.content_margin_top = 16
	hint_style.content_margin_bottom = 16
	_hint_panel.add_theme_stylebox_override("panel", hint_style)
	_hint_panel.modulate.a = 0.0
	_top.add_child(_hint_panel)
	_hint_label = _make_label("", 50, Color.WHITE)
	_hint_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_hint_label.add_theme_constant_override("outline_size", 10)
	_hint_panel.add_child(_hint_label)

	# --- ALERTA de chefe (tela pisca em vermelho) ---
	_alert_layer = Control.new()
	_alert_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_alert_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_alert_layer.visible = false
	root.add_child(_alert_layer)
	_alert_bg = ColorRect.new()
	_alert_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_alert_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_alert_layer.add_child(_alert_bg)
	var alert_box := VBoxContainer.new()
	alert_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	alert_box.alignment = BoxContainer.ALIGNMENT_CENTER
	alert_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_alert_layer.add_child(alert_box)
	_alert_title = _make_label("ALERTA", 150, Palette.DANGER)
	alert_box.add_child(_alert_title)
	alert_box.add_child(_make_label("CHEFE SE APROXIMANDO", 42, Color.WHITE))

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
	_stars = StarsRow.new()
	_stars.custom_minimum_size = Vector2(420, 130)
	_stars.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center.add_child(_stars)
	_star_details = RichTextLabel.new()
	_star_details.bbcode_enabled = true
	_star_details.fit_content = true
	_star_details.scroll_active = false
	_star_details.custom_minimum_size.x = 900
	_star_details.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_star_details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_star_details.add_theme_font_size_override("normal_font_size", 34)
	_center.add_child(_star_details)
	_info = _make_label("", 36, Palette.TEXT_DIM)
	_center.add_child(_info)

	_add_center_button("resume", "CONTINUAR", resume_pressed.emit)
	_add_center_button("campaign", "JOGAR", campaign_pressed.emit)
	_add_center_button("endless", "INFINITO", endless_pressed.emit)
	_add_center_button("daily", "DESAFIO DO DIA", daily_pressed.emit)
	_add_center_button("next", "PRÓXIMO SETOR", next_pressed.emit)
	_add_center_button("restart", "REINICIAR", restart_pressed.emit)
	_add_center_button("continue", "CONTINUAR (TESTE)", continue_pressed.emit)
	_add_center_button("options", "OPÇÕES", open_options, false)
	_add_center_button("dev", "FASES (DEV)", open_dev_selector, false)
	_add_center_button("menu", "MENU PRINCIPAL", menu_pressed.emit)
	_add_center_button("home", "VOLTAR AO INÍCIO", menu_pressed.emit)  # na pausa
	_add_center_button("quit", "SAIR DO JOGO", quit_pressed.emit)

	_build_options(root)

	# Contador de FPS (só no APK de desenvolvimento): FPS agora e o MÍNIMO dos últimos 3 s,
	# para comparar os celulares (ver PROXIMOS_PASSOS.md, 1.4).
	if OS.is_debug_build():
		_fps_label = _make_label("", 24, Color(0.6, 1.0, 0.6))
		_fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_fps_label.anchor_left = 1.0
		_fps_label.anchor_right = 1.0
		_fps_label.anchor_top = 1.0
		_fps_label.anchor_bottom = 1.0
		_fps_label.offset_left = -360.0
		_fps_label.offset_right = -20.0
		_fps_label.offset_top = -56.0
		_fps_label.offset_bottom = -20.0
		root.add_child(_fps_label)
	hide_center()


func _process(delta: float) -> void:
	if _fps_label != null:
		_update_fps(delta)
	if _levelup_timer > 0.0:
		_levelup_timer -= delta
		_levelup_label.modulate.a = clampf(_levelup_timer / 0.4, 0.0, 1.0)

	if _new_game_armed > 0.0:
		_new_game_armed -= delta
		if _new_game_armed <= 0.0:
			_new_game_button.text = "NOVO JOGO"

	if _hint_timer > 0.0:
		_hint_timer -= delta
		_hint_panel.modulate.a = clampf(_hint_timer / HINT_FADE, 0.0, 1.0)

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
	_top.offset_top = px + 14.0


## True se o toque caiu em algum botão/tela de opções (não deve iniciar a partida).
func blocks_touch(pos: Vector2) -> bool:
	if _options_layer.visible or (_dev_layer != null and _dev_layer.visible) \
			or (_module_layer != null and _module_layer.visible):
		return true
	for b: Button in _buttons.values():
		if b.is_visible_in_tree() and b.get_global_rect().has_point(pos):
			return true
	return false


func set_values(score: int, best: int, shield_ratio: float, last_chance: bool,
		weapon_level: int, weapon_progress: float, weapon_cap := Tuning.WEAPON_MAX_LEVEL) -> void:
	_score_label.text = str(score)
	_best_label.text = "RECORDE %d" % best

	shield_ratio = clampf(shield_ratio, 0.0, 1.0)
	# Queda grande de uma vez = impacto: segura o rastro branco por um instante.
	if _shield_ratio - shield_ratio > 0.02:
		_shield_trail_wait = SHIELD_TRAIL_DELAY
	_shield_ratio = shield_ratio
	_shield_danger = last_chance or shield_ratio < Tuning.SHIELD_LOW_RATIO
	_shield_fill.size = Vector2(BAR_WIDTH * shield_ratio, BAR_HEIGHT)

	_weapon_label.text = "ARMA %d/%d" % [weapon_level, weapon_cap]
	_weapon_cap_seen = weapon_cap
	_weapon_fill.size = Vector2(BAR_WIDTH * clampf(weapon_progress, 0.0, 1.0), BAR_HEIGHT)



func show_hint(text: String, duration: float) -> void:
	_hint_label.text = text
	_hint_timer = duration
	_hint_panel.modulate.a = 1.0


func clear_hint() -> void:
	_hint_timer = 0.0
	_hint_panel.modulate.a = 0.0


func on_weapon_level(level: int, went_up: bool) -> void:
	if not went_up:
		_levelup_label.text = "ARMA -1"
	elif level >= Tuning.WEAPON_MAX_LEVEL:
		_levelup_label.text = "ARMA MÁXIMA!"
	elif level >= _weapon_cap_seen:
		_levelup_label.text = "MÁXIMO DO SETOR!"
	else:
		_levelup_label.text = "LEVEL UP!"
	_levelup_label.add_theme_color_override("font_color", Palette.MAGENTA if went_up else Palette.DANGER)
	_levelup_timer = 1.2


# ---------------------------------------------------------------- telas

## `can_resume`: existe um ponto salvo. Com ponto salvo o 1º botão é CONTINUAR;
## sem ele, JOGAR (começa do Setor 1). NOVO JOGO fica em Opções.
## Multiplicador do Infinito/Desafio ao lado dos pontos (some em x1).
func set_multiplier(m: float) -> void:
	_mult_label.visible = m > 1.0
	_mult_label.text = "x%.1f" % m


func on_multiplier_up(m: float) -> void:
	_levelup_label.text = "MULTIPLICADOR x%.1f!" % m
	_levelup_label.add_theme_color_override("font_color", Palette.NEON)
	_levelup_timer = 1.2


func on_multiplier_lost() -> void:
	_levelup_label.text = "MULTIPLICADOR PERDIDO"
	_levelup_label.add_theme_color_override("font_color", Palette.DANGER)
	_levelup_timer = 1.0


## `daily_label`: texto do botão do Desafio do Dia (valendo ou treino).
func show_menu(can_resume: bool, endless_unlocked := false, daily_label := "") -> void:
	var buttons := ["resume" if can_resume else "campaign", "options", "quit"]
	if endless_unlocked:
		buttons.append("endless")  # liberado ao completar o Setor 2
		buttons.append("daily")
		_buttons["daily"].text = daily_label if daily_label != "" else "DESAFIO DO DIA"
	if OS.is_debug_build():
		buttons.append("dev")  # seletor de fases: nunca aparece no APK de release
	_show("ASTRA DODGE", "", "", buttons)
	_top.visible = false  # pontuação/barras só fazem sentido durante uma partida


func show_ready(title: String) -> void:
	_show(title, "Toque e arraste para pilotar", "Solte o dedo para pausar", [])


func show_paused() -> void:
	_show("PAUSADO", "Toque na tela para continuar", "", ["options", "home", "quit"])
	_center.alignment = BoxContainer.ALIGNMENT_BEGIN
	_center_spacer.visible = true
	_dim.visible = true


## `info`: linha de baixo (o Infinito mostra tempo, chefes e recordes); vazio = "RECORDE n".
func show_game_over(score: int, best: int, is_record: bool, can_continue: bool, info := "") -> void:
	var buttons := ["restart", "continue", "menu"] if can_continue else ["restart", "menu"]
	_show(
		"FIM DE JOGO",
		("NOVO RECORDE! %d" if is_record else "PONTOS %d") % score,
		info if info != "" else "RECORDE %d" % best,
		buttons)
	_dim.visible = true


## `checks`: [setor completo, chefe sem "última chance", ≥ 70% da poeira] — uma estrela cada.
func show_sector_clear(title: String, score: int, best: int, is_record: bool, checks: Array[bool],
		has_next := false) -> void:
	_show(
		title if title.ends_with("!") else "%s COMPLETO!" % title,  # o fim da campanha vem pronto
		("NOVO RECORDE! %d" if is_record else "PONTOS %d") % score,
		"RECORDE DO SETOR %d" % best,
		["next", "restart", "menu"] if has_next else ["restart", "menu"])
	_stars.earned = checks.count(true)
	_stars.queue_redraw()
	_stars.visible = true
	var lines := ["Setor completo", "Chefe sem \"última chance\"", "70% da poeira destruída"]
	var text := "[center]"
	for i in lines.size():
		var color := "#3ff0ff" if i < checks.size() and checks[i] else "#ffffff55"
		text += "[color=%s]• %s[/color]\n" % [color, lines[i]]
	_star_details.text = text + "[/center]"
	_star_details.visible = true
	_dim.visible = true


## Tela "ALERTA" antes do chefe. `time_left` < 0 esconde.
func set_alert(time_left: float) -> void:
	_alert_layer.visible = time_left >= 0.0
	if not _alert_layer.visible:
		return
	var blink := 0.5 + 0.5 * sin(_blink_t * 12.0)
	# Com HDR 2D a mistura é linear: alfas baixos já aparecem bem fortes na tela.
	_alert_bg.color = Color(Palette.DANGER, 0.012 + 0.025 * blink)
	_alert_title.modulate.a = 0.55 + 0.45 * blink


func show_boss_bar(boss_name: String) -> void:
	_boss_label.text = boss_name
	_boss_box.visible = true
	set_boss_hp(1.0)


func hide_boss_bar() -> void:
	_boss_box.visible = false


func set_boss_hp(ratio: float) -> void:
	_boss_fill.size = Vector2(BOSS_BAR_WIDTH * clampf(ratio, 0.0, 1.0), BOSS_BAR_HEIGHT)


func hide_center() -> void:
	_center.visible = false
	_dim.visible = false


func _show(title: String, subtitle: String, info: String, buttons: Array) -> void:
	_title.text = title
	_subtitle.text = subtitle
	_subtitle.visible = subtitle != ""
	_info.text = info
	_info.visible = info != ""
	for id: String in _buttons:
		_buttons[id].visible = id in buttons
	_stars.visible = false
	_dim.visible = false
	_star_details.visible = false
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

## SELETOR DE FASES (modo dev): uma linha por setor — começar do início ou direto no chefe.
## Só é montado e mostrado em build de desenvolvimento (APK debug / editor).
## `sectors`: [[título, subtítulo], ...] na ordem da campanha.
## CONTÊINER DE CARGA: escolha 1 de 3 módulos (cartas). `cards`: [[título, categoria, descrição], ...].
## `hand_text`: o que já está na nave. `first`: primeira vez (explica o que são módulos).
func show_module_pick(cards: Array, hand_text: String, first: bool) -> void:
	if _module_layer == null:
		_build_module_layer()
	_module_title.text = "CONTÊINER DE CARGA"
	_module_sub.text = ("MÓDULOS mudam o jeito de jogar e continuam\nnos próximos setores. Escolha um:"
			if first else "Escolha um módulo:")
	for i in 3:
		var c: Array = cards[i]
		var color: Color = Modules.CATEGORY_COLORS.get(c[1], Color.WHITE)
		var b: Button = _module_cards[i]
		b.text = "%s\n%s · %s" % [c[0], c[1], c[2]]
		for state in ["normal", "hover", "pressed"]:
			var sb: StyleBoxFlat = b.get_theme_stylebox(state)
			sb.border_color = color
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(state, color.lerp(Color.WHITE, 0.35))
	_module_hand.text = hand_text
	_center.visible = false
	_module_layer.visible = true


func hide_module_pick() -> void:
	if _module_layer != null:
		_module_layer.visible = false


func _build_module_layer() -> void:
	_module_layer = Control.new()
	_module_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_module_layer.visible = false
	_options_layer.get_parent().add_child(_module_layer)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.03, 0.88)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_module_layer.add_child(backdrop)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 26)
	_module_layer.add_child(box)
	_module_title = _make_label("", 64, Color(1.0, 0.82, 0.3))
	box.add_child(_module_title)
	_module_sub = _make_label("", 32, Color.WHITE)
	box.add_child(_module_sub)
	_module_cards.clear()
	for i in 3:
		var b := _make_button("")
		b.custom_minimum_size = Vector2(920, 190)
		b.add_theme_font_size_override("font_size", 36)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(func() -> void:
			Sfx.play("level_up", -4.0, 1.2, 0.0)
			module_chosen.emit(i))
		box.add_child(b)
		_module_cards.append(b)
	_module_hand = _make_label("", 28, Palette.TEXT_DIM)
	box.add_child(_module_hand)


func setup_dev_selector(sectors: Array) -> void:
	if not OS.is_debug_build() or _dev_layer != null:
		return
	_dev_layer = Control.new()
	_dev_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dev_layer.visible = false
	_options_layer.get_parent().add_child(_dev_layer)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.03, 0.92)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dev_layer.add_child(backdrop)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 18)
	_dev_layer.add_child(box)
	box.add_child(_make_label("FASES (DEV)", 70, Palette.MAGENTA))
	box.add_child(_make_label("Só no APK de desenvolvimento", 26, Palette.TEXT_DIM))
	var auto := _make_button("")
	auto.custom_minimum_size = Vector2(816, 96)
	auto.add_theme_font_size_override("font_size", 34)
	var paint := func() -> void:
		auto.text = "JOGO AUTOMÁTICO: %s" % ("SIM" if dev_auto else "NÃO")
		auto.modulate = Palette.NEON if dev_auto else Color.WHITE
	paint.call()
	auto.pressed.connect(func() -> void:
		Sfx.play("click", -4.0, 1.0, 0.0)
		dev_auto = not dev_auto
		paint.call())
	box.add_child(auto)

	for i in sectors.size():
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 16)
		box.add_child(row)
		var start := _make_button("%d · %s" % [i + 1, str(sectors[i][1]).to_upper()])
		start.custom_minimum_size = Vector2(600, 96)
		start.add_theme_font_size_override("font_size", 34)
		start.pressed.connect(_pick_dev_sector.bind(i, false))
		row.add_child(start)
		var boss := _make_button("CHEFE")
		boss.custom_minimum_size = Vector2(200, 96)
		boss.add_theme_font_size_override("font_size", 34)
		boss.pressed.connect(_pick_dev_sector.bind(i, true))
		row.add_child(boss)

	var back := _make_button("VOLTAR")
	back.pressed.connect(func() -> void:
		Sfx.play("click", -4.0, 1.0, 0.0)
		_dev_layer.visible = false
		_center.visible = true)
	box.add_child(back)


func open_dev_selector() -> void:
	if _dev_layer == null:
		return
	Sfx.play("click", -4.0, 1.0, 0.0)
	_center.visible = false
	_dev_layer.visible = true


func _pick_dev_sector(index: int, at_boss: bool) -> void:
	Sfx.play("click", -4.0, 1.0, 0.0)
	_dev_layer.visible = false
	_center.visible = true
	dev_sector_pressed.emit(index, at_boss)


func open_options() -> void:
	Sfx.play("click", -4.0, 1.0, 0.0)
	_refresh_options()
	_new_game_armed = 0.0
	_new_game_button.text = "NOVO JOGO"
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

	# Volumes de 0 a 100%, de 10 em 10.
	_music_label = _make_volume_row(box, "MÚSICA", func(step: float) -> void:
		Game.music_volume = clampf(snappedf(Game.music_volume + step, 0.1), 0.0, 1.0)
		_on_option_changed())
	_sfx_label = _make_volume_row(box, "EFEITOS", func(step: float) -> void:
		Game.sfx_volume = clampf(snappedf(Game.sfx_volume + step, 0.1), 0.0, 1.0)
		_on_option_changed())

	# Skin da nave: cada toque passa para a próxima liberada (estrelas da campanha).
	_skin_button = _make_button("")
	_skin_button.pressed.connect(func() -> void:
		Game.next_skin()
		_on_option_changed())
	box.add_child(_skin_button)
	_skin_info = _make_label("", 26, Palette.TEXT_DIM)
	box.add_child(_skin_info)

	# Modificador do Modo Infinito (também liberado por estrelas).
	_mod_button = _make_button("")
	_mod_button.pressed.connect(func() -> void:
		Game.next_mod()
		_on_option_changed())
	box.add_child(_mod_button)
	_mod_info = _make_label("", 26, Palette.TEXT_DIM)
	box.add_child(_mod_info)

	# Gráficos: Automático (simples em celular antigo) / Completo / Simples.
	_graphics_button = _make_button("")
	_graphics_button.pressed.connect(func() -> void:
		Game.next_graphics()
		_on_option_changed())
	box.add_child(_graphics_button)

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

	# Novo jogo apaga o progresso salvo: pede um 2º toque para confirmar.
	_new_game_button = _make_button("NOVO JOGO")
	_new_game_button.pressed.connect(func() -> void:
		Sfx.play("click", -4.0, 1.0, 0.0)
		if _new_game_armed > 0.0:
			_new_game_armed = 0.0
			_new_game_button.text = "NOVO JOGO"
			_options_layer.visible = false
			Game.save_data()
			new_game_pressed.emit()
		else:
			_new_game_armed = NEW_GAME_CONFIRM_TIME
			_new_game_button.text = "TOQUE P/ CONFIRMAR")
	box.add_child(_new_game_button)

	var back := _make_button("VOLTAR")
	back.pressed.connect(close_options)
	box.add_child(back)


func _on_option_changed() -> void:
	Sfx.apply_volumes()
	Sfx.play("click", -4.0, 1.0, 0.0)
	_refresh_options()


func _change_sensitivity(step: float) -> void:
	Game.sensitivity = clampf(snappedf(Game.sensitivity + step, 0.1), 0.8, 1.6)
	Sfx.play("click", -4.0, 1.0, 0.0)
	_refresh_options()


## Linha "RÓTULO  [-]  80%  [+]"; `change` recebe -0,1 ou +0,1. Devolve o rótulo do valor.
func _make_volume_row(box: Container, title: String, change: Callable) -> Label:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 20)
	box.add_child(row)
	var name_label := _make_label(title, 38, Palette.TEXT_DIM)
	name_label.custom_minimum_size.x = 230
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(name_label)
	var minus := _make_button("-")
	minus.custom_minimum_size = Vector2(110, 110)
	minus.pressed.connect(change.bind(-0.1))
	row.add_child(minus)
	var value := _make_label("", 44, Color.WHITE)
	value.custom_minimum_size.x = 170
	row.add_child(value)
	var plus := _make_button("+")
	plus.custom_minimum_size = Vector2(110, 110)
	plus.pressed.connect(change.bind(0.1))
	row.add_child(plus)
	return value


static func _percent(v: float) -> String:
	return "DESL." if v <= 0.001 else "%d%%" % roundi(v * 100.0)


func _refresh_options() -> void:
	_music_label.text = _percent(Game.music_volume)
	_sfx_label.text = _percent(Game.sfx_volume)
	_skin_button.text = "NAVE: %s" % Game.SKINS[Game.skin][0]
	var stars := Game.total_stars()
	var next_locked := ""
	for s in Game.SKINS:
		if stars < int(s[1]):
			next_locked = "próxima: %s com %d" % [s[0], s[1]]
			break
	_skin_info.text = "Estrelas %d/24 · %s" % [stars, next_locked if next_locked != "" else "todas liberadas!"]
	var m: Array = Game.MODS[Game.mod]
	_mod_button.text = "INFINITO: %s" % m[1]
	var next_mod := ""
	for x in Game.MODS:
		if stars < int(x[2]):
			next_mod = " · próximo com %d" % x[2]
			break
	_mod_info.text = "%s%s" % [m[4], next_mod]
	var gname: String = Game.GRAPHICS_NAMES[Game.graphics]
	if Game.graphics == 0:
		gname += " (%s)" % ("SIMPLES" if Game.graphics_simple() else "COMPLETO")
	_graphics_button.text = "GRÁFICOS: %s" % gname
	_set_toggle(_vibration_button, "VIBRAÇÃO", Game.vibration_enabled, "LIGADA", "DESLIGADA")
	_sensitivity_label.text = ("%.1fx" % Game.sensitivity).replace(".", ",")


func _set_toggle(b: Button, title: String, on: bool, on_text: String, off_text: String) -> void:
	b.text = "%s: %s" % [title, on_text if on else off_text]
	b.modulate.a = 1.0 if on else 0.5


# ---------------------------------------------------------------- construção

## Linha "RÓTULO ████░░" centralizada no topo; retorna o fundo da barra.
## Linha "RÓTULO ▬▬▬▬" dentro de `parent`; devolve o fundo da barra (o preenchimento vai nele).
func _make_bar_row(parent: Container, label: Label, color: Color) -> ColorRect:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.custom_minimum_size.x = BAR_LABEL_WIDTH
	row.add_child(label)
	var bg := ColorRect.new()
	bg.color = Color(color, 0.18)
	bg.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(bg)
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


## "FPS 58 · mín 41" — o mínimo pega os engasgos (o que a média esconde).
func _update_fps(delta: float) -> void:
	_fps_window.append(delta)
	var total := 0.0
	for d in _fps_window:
		total += d
	while total > 3.0 and _fps_window.size() > 1:
		total -= _fps_window.pop_front()
	var worst := 0.0
	for d in _fps_window:
		worst = maxf(worst, d)
	_fps_label.text = "FPS %d · mín %d" % [Engine.get_frames_per_second(), roundi(1.0 / maxf(worst, 0.001))]
