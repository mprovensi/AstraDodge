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


func difficulty_at(t: float) -> float:
	return lerpf(difficulty_start, difficulty_end, clampf(t / duration, 0.0, 1.0))
