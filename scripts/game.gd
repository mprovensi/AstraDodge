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
var sector_stars := {}      # id do setor -> melhor número de estrelas (0..3)

# Modo Infinito (o recorde de pontos é o high_score)
const ENDLESS_UNLOCK_SECTOR := "sector_2"  # libera o Infinito ao completar este setor
var endless_best_time := 0.0

# Desafio do Dia: todo mundo recebe a mesma partida do Infinito no mesmo dia.
# Só a 1ª tentativa do dia "vale"; as outras são treino.
var daily_date := ""   # dia (AAAA-MM-DD) da última tentativa valendo
var daily_score := 0   # pontos da tentativa valendo desse dia
var daily_best := 0    # melhor tentativa valendo de todos os dias


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
	sector_stars = cfg.get_value("campaign", "stars", {})
	endless_best_time = cfg.get_value("endless", "best_time", 0.0)
	daily_date = cfg.get_value("daily", "date", "")
	daily_score = cfg.get_value("daily", "score", 0)
	daily_best = cfg.get_value("daily", "best", 0)


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
	cfg.set_value("campaign", "stars", sector_stars)
	cfg.set_value("endless", "best_time", endless_best_time)
	cfg.set_value("daily", "date", daily_date)
	cfg.set_value("daily", "score", daily_score)
	cfg.set_value("daily", "best", daily_best)
	cfg.save(SAVE_PATH)


func endless_unlocked() -> bool:
	return sectors_cleared.has(ENDLESS_UNLOCK_SECTOR)


## Fim de uma partida do Infinito. Retorna [recorde de pontos?, recorde de tempo?].
func submit_endless(score: int, seconds: float) -> Array[bool]:
	var time_record := seconds > endless_best_time
	if time_record:
		endless_best_time = seconds
	var score_record := submit_score(score)
	if time_record:
		save_data()
	return [score_record, time_record]


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


## Guarda o melhor número de estrelas do setor. Retorna true se melhorou.
func submit_stars(id: String, stars: int) -> bool:
	if stars <= int(sector_stars.get(id, 0)):
		return false
	sector_stars[id] = stars
	save_data()
	return true


func clear_checkpoint() -> void:
	if checkpoint.is_empty():
		return
	checkpoint = {}
	save_data()


func vibrate(duration_ms: int) -> void:
	if vibration_enabled:
		Input.vibrate_handheld(duration_ms)


# ---------------------------------------------------------------- Desafio do Dia

static func today() -> String:
	return Time.get_date_string_from_system()


## Semente do dia: a mesma em qualquer aparelho com o mesmo jogo.
static func daily_seed(date := "") -> int:
	return absi(("astra-dodge-" + (date if date != "" else today())).hash())


## A tentativa valendo de hoje ainda não foi usada?
func daily_available() -> bool:
	return daily_date != today()


## Registra a tentativa valendo de hoje. Retorna true se for o melhor desafio de todos.
func submit_daily(score: int) -> bool:
	daily_date = today()
	daily_score = score
	var record := score > daily_best
	if record:
		daily_best = score
	save_data()
	return record


## A tentativa valendo COMEÇOU: já conta como usada (sair no meio não devolve a tentativa).
func begin_daily() -> void:
	daily_date = today()
	daily_score = 0
	save_data()
