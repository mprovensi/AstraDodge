extends SceneTree
## Cria os .tres iniciais dos setores. Depois de criados, a fonte da verdade são os .tres
## (edite pelo Inspetor do Godot); rode de novo só para recriar do zero.
## Uso: godot --headless --path . --script res://tools/gen_sectors.gd

const OUT := "res://data/sectors"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_save(_sector_1())
	quit()


func _sector_1() -> SectorData:
	var s := SectorData.new()
	s.id = "sector_1"
	s.number = 1
	s.title = "SETOR 1"
	s.subtitle = "Cinturão de Poeira"
	s.duration = 150.0
	s.difficulty_start = 0.0
	s.difficulty_end = 0.45
	var K := WaveEvent.Kind
	s.events.assign([
		WaveEvent.make(0.0, K.DENSITY, {"density": 0.6, "metals": false}),
		WaveEvent.make(0.5, K.MESSAGE, {"text": "SETOR 1\nCinturão de Poeira", "duration": 2.5}),
		WaveEvent.make(4.0, K.MESSAGE, {"text": "Arraste o dedo para mover a nave", "duration": 3.5}),
		WaveEvent.make(10.0, K.MESSAGE, {"text": "Atire na poeira cinza:\nela solta orbes e cristais", "duration": 4.0}),
		WaveEvent.make(18.0, K.DENSITY, {"density": 0.8, "metals": true}),
		WaveEvent.make(18.0, K.MESSAGE, {"text": "Metálicos escuros não quebram.\nDesvie!", "duration": 4.0}),
		WaveEvent.make(30.0, K.MESSAGE, {"text": "Orbes ciano recarregam o escudo", "duration": 3.5}),
		WaveEvent.make(38.0, K.MESSAGE, {"text": "Cristais magenta fortalecem a arma", "duration": 3.5}),
		WaveEvent.make(45.0, K.DUST_RAIN, {"duration": 10.0}),
		WaveEvent.make(45.0, K.MESSAGE, {"text": "CHUVA DE POEIRA!", "duration": 2.5}),
		WaveEvent.make(60.0, K.DENSITY, {"density": 1.0, "metals": true}),
		WaveEvent.make(75.0, K.METAL_WALL),
		WaveEvent.make(90.0, K.DENSITY, {"density": 1.15, "metals": true}),
		WaveEvent.make(105.0, K.METAL_WALL),
		WaveEvent.make(115.0, K.DUST_RAIN, {"duration": 8.0}),
		WaveEvent.make(115.0, K.MESSAGE, {"text": "CHUVA DE POEIRA!", "duration": 2.5}),
		WaveEvent.make(128.0, K.METAL_WALL),
		WaveEvent.make(138.0, K.CALM, {"duration": 12.0}),
		WaveEvent.make(140.0, K.MESSAGE, {"text": "Saindo do cinturão...", "duration": 3.0}),
		WaveEvent.make(150.0, K.END),
	])
	return s


func _save(s: SectorData) -> void:
	var path := "%s/%s.tres" % [OUT, s.id]
	var err := ResourceSaver.save(s, path)
	print("%s -> %s" % [path, "OK" if err == OK else "ERRO %d" % err])
