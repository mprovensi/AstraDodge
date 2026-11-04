class_name SectorData
extends Resource
## Definição de um setor da campanha. Edite os .tres em res://data/sectors/ pelo Inspetor.

@export var id := "sector_1"
@export var number := 1
@export var title := "SETOR 1"
@export var subtitle := ""
@export var duration := 150.0         ## segundos até o evento END (referência para o progresso)
@export_range(0.0, 1.0) var difficulty_start := 0.0
@export_range(0.0, 1.0) var difficulty_end := 0.5
@export var events: Array[WaveEvent] = []
## Trilha do setor (nome em Sfx.MUSIC_TRACKS).
@export var music := "main"

@export_group("Visual")
@export var nebula_a := Color(0.06, 0.10, 0.32)  ## cor principal da nebulosa de fundo
@export var nebula_b := Color(0.16, 0.04, 0.28)  ## cor secundária


func difficulty_at(t: float) -> float:
	return lerpf(difficulty_start, difficulty_end, clampf(t / duration, 0.0, 1.0))
