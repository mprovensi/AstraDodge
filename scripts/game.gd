extends Node
## Autoload "Game": recorde e opções salvos no aparelho.

const SAVE_PATH := "user://save.cfg"

var high_score := 0
var sensitivity := Tuning.DRAG_SENSITIVITY_DEFAULT
var vibration_enabled := true
var music_enabled := true
var sfx_enabled := true
var persist := true  # os testes desligam para não sobrescrever o save real


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


func save_data() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("score", "high", high_score)
	cfg.set_value("options", "sensitivity", sensitivity)
	cfg.set_value("options", "vibration", vibration_enabled)
	cfg.set_value("options", "music", music_enabled)
	cfg.set_value("options", "sfx", sfx_enabled)
	cfg.save(SAVE_PATH)


## Retorna true se for um novo recorde.
func submit_score(score: int) -> bool:
	if score <= high_score:
		return false
	high_score = score
	save_data()
	return true


func vibrate(duration_ms: int) -> void:
	if vibration_enabled:
		Input.vibrate_handheld(duration_ms)
