extends Node
## Autoload "Game": recorde e opções salvos no aparelho.

const SAVE_PATH := "user://save.cfg"
## Conjunto de arte ativo. Para outra arte/skin: crie outro .tres de ArtSet e aponte aqui.
const ART_SET_PATH := "res://data/art/default.tres"

var art: ArtSet = load(ART_SET_PATH)

var high_score := 0
var sensitivity := Tuning.DRAG_SENSITIVITY_DEFAULT
var vibration_enabled := true
var music_enabled := true
var sfx_enabled := true
var persist := true  # os testes desligam para não sobrescrever o save real

# Campanha
var sector_best := {}       # id do setor -> melhor pontuação
var sectors_cleared := {}   # id do setor -> true
var checkpoint := {}        # ponto onde o jogador parou (vazio = nada para continuar)


func _ready() -> void:
	load_data()


func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	high_score = cfg.get_value("score", "high", 0)
	sensitivity = cfg.get_value("options", "sensitivity", Tuning.DRAG_SENSITIVITY_DEFAULT)
	vibration_enabled = cfg.get_value("options", "vibration", true)
	var legacy_sound: bool = cfg.get_value("options", "sound", true)  # saves antigos: um único "som"
	music_enabled = cfg.get_value("options", "music", legacy_sound)
	sfx_enabled = cfg.get_value("options", "sfx", legacy_sound)
	sector_best = cfg.get_value("campaign", "best", {})
	sectors_cleared = cfg.get_value("campaign", "cleared", {})
	checkpoint = cfg.get_value("campaign", "checkpoint", {})


func save_data() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("score", "high", high_score)
	cfg.set_value("options", "sensitivity", sensitivity)
	cfg.set_value("options", "vibration", vibration_enabled)
	cfg.set_value("options", "music", music_enabled)
	cfg.set_value("options", "sfx", sfx_enabled)
	cfg.set_value("campaign", "best", sector_best)
	cfg.set_value("campaign", "cleared", sectors_cleared)
	cfg.set_value("campaign", "checkpoint", checkpoint)
	cfg.save(SAVE_PATH)


## Retorna true se for um novo recorde.
func submit_score(score: int) -> bool:
	if score <= high_score:
		return false
	high_score = score
	save_data()
	return true


func get_sector_best(id: String) -> int:
	return int(sector_best.get(id, 0))


## Registra o resultado de um setor. Retorna true se for novo recorde do setor.
func submit_sector(id: String, score: int, cleared: bool) -> bool:
	var is_record := score > get_sector_best(id)
	if is_record:
		sector_best[id] = score
	if cleared:
		sectors_cleared[id] = true
	if is_record or cleared:
		save_data()
	return is_record


func set_checkpoint(data: Dictionary) -> void:
	checkpoint = data
	save_data()


func clear_checkpoint() -> void:
	if checkpoint.is_empty():
		return
	checkpoint = {}
	save_data()


func vibrate(duration_ms: int) -> void:
	if vibration_enabled:
		Input.vibrate_handheld(duration_ms)
