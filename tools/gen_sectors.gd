extends SceneTree
## Cria os .tres iniciais dos setores. Depois de criados, a fonte da verdade são os .tres
## (edite pelo Inspetor do Godot); rode de novo só para recriar do zero.
## Uso: godot --headless --path . --script res://tools/gen_sectors.gd

const OUT := "res://data/sectors"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_save(_sector_1())
	_save(_sector_2())
	_save(_sector_3())
	quit()


## Setor 3 — Nebulosa Iônica: nuvens que drenam o escudo, minas, tempestade; chefe Medusa.
func _sector_3() -> SectorData:
	var s := SectorData.new()
	s.id = "sector_3"
	s.number = 3
	s.title = "SETOR 3"
	s.subtitle = "Nebulosa Iônica"
	s.duration = 150.0
	s.difficulty_start = 0.45
	s.difficulty_end = 0.8
	s.music = "sector3"
	s.nebula_a = Color(0.22, 0.06, 0.34)  # violeta
	s.nebula_b = Color(0.05, 0.26, 0.12)  # verde-ácido
	var K := WaveEvent.Kind
	s.events.assign([
		WaveEvent.make(0.0, K.DENSITY, {"density": 0.85, "metals": true}),
		WaveEvent.make(0.5, K.MESSAGE, {"text": "SETOR 3\nNebulosa Iônica", "duration": 2.5}),
		WaveEvent.make(5.0, K.DENSITY, {"density": 0.85, "metals": true, "clouds": 0.45}),
		WaveEvent.make(5.0, K.MESSAGE, {"text": "Nuvens iônicas drenam o escudo\n3x mais rápido. Evite!", "duration": 4.0}),
		WaveEvent.make(25.0, K.DENSITY, {"density": 0.9, "metals": true, "clouds": 0.35, "mines": 0.3}),
		WaveEvent.make(25.0, K.MESSAGE, {"text": "Minas iônicas explodem se você\nchegar perto. Atire de longe!", "duration": 4.0}),
		WaveEvent.make(45.0, K.STORM, {"duration": 10.0}),
		WaveEvent.make(60.0, K.DENSITY, {"density": 1.0, "metals": true, "moving": 0.2, "armored": 0.2,
				"clouds": 0.4, "mines": 0.3}),
		WaveEvent.make(75.0, K.METAL_WALL),
		WaveEvent.make(88.0, K.DUST_RAIN, {"duration": 8.0}),
		WaveEvent.make(88.0, K.MESSAGE, {"text": "CHUVA DE POEIRA!", "duration": 2.5}),
		WaveEvent.make(100.0, K.STORM, {"duration": 12.0}),
		WaveEvent.make(118.0, K.DENSITY, {"density": 1.1, "metals": true, "moving": 0.25, "armored": 0.25,
				"clouds": 0.45, "mines": 0.35}),
		WaveEvent.make(128.0, K.CORRIDOR, {"duration": 7.0}),
		WaveEvent.make(138.0, K.CALM, {"duration": 9999.0}),
		WaveEvent.make(140.0, K.MESSAGE, {"text": "Um brilho estranho pulsa na névoa...", "duration": 3.0}),
		WaveEvent.make(144.0, K.BOSS, {"text": "medusa"}),
	])
	return s


## Setor 2 — Campo Metálico: metálicos com propulsor, poeira blindada, corredores; chefe Minerador.
func _sector_2() -> SectorData:
	var s := SectorData.new()
	s.id = "sector_2"
	s.number = 2
	s.title = "SETOR 2"
	s.subtitle = "Campo Metálico"
	s.duration = 150.0
	s.difficulty_start = 0.3
	s.difficulty_end = 0.7
	s.music = "sector2"
	s.nebula_a = Color(0.08, 0.11, 0.18)  # aço
	s.nebula_b = Color(0.32, 0.17, 0.04)  # âmbar
	var K := WaveEvent.Kind
	s.events.assign([
		WaveEvent.make(0.0, K.DENSITY, {"density": 0.8, "metals": true}),
		WaveEvent.make(0.5, K.MESSAGE, {"text": "SETOR 2\nCampo Metálico", "duration": 2.5}),
		WaveEvent.make(5.0, K.DENSITY, {"density": 0.8, "metals": true, "moving": 0.35}),
		WaveEvent.make(5.0, K.MESSAGE, {"text": "Metálicos com propulsor\nandam de lado!", "duration": 3.5}),
		WaveEvent.make(25.0, K.DENSITY, {"density": 0.9, "metals": true, "moving": 0.3, "armored": 0.3}),
		WaveEvent.make(25.0, K.MESSAGE, {"text": "Poeira blindada:\nos primeiros tiros arrancam a casca", "duration": 4.0}),
		WaveEvent.make(45.0, K.CORRIDOR, {"duration": 8.0}),
		WaveEvent.make(60.0, K.DENSITY, {"density": 1.0, "metals": true, "moving": 0.4, "armored": 0.35}),
		WaveEvent.make(75.0, K.METAL_WALL),
		WaveEvent.make(88.0, K.DUST_RAIN, {"duration": 8.0}),
		WaveEvent.make(88.0, K.MESSAGE, {"text": "CHUVA DE POEIRA!", "duration": 2.5}),
		WaveEvent.make(102.0, K.CORRIDOR, {"duration": 10.0}),
		WaveEvent.make(118.0, K.DENSITY, {"density": 1.15, "metals": true, "moving": 0.5, "armored": 0.4}),
		WaveEvent.make(128.0, K.METAL_WALL),
		WaveEvent.make(138.0, K.CALM, {"duration": 9999.0}),
		WaveEvent.make(140.0, K.MESSAGE, {"text": "Sinais de mineração à frente...", "duration": 3.0}),
		WaveEvent.make(144.0, K.BOSS, {"text": "miner"}),
	])
	return s


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
		# Calmaria até o fim: limpa a tela para o chefe (o setor acaba quando ele cai).
		WaveEvent.make(138.0, K.CALM, {"duration": 9999.0}),
		WaveEvent.make(140.0, K.MESSAGE, {"text": "Algo enorme se aproxima...", "duration": 3.0}),
		WaveEvent.make(144.0, K.BOSS, {"text": "rock_mother"}),
	])
	return s


func _save(s: SectorData) -> void:
	var path := "%s/%s.tres" % [OUT, s.id]
	var err := ResourceSaver.save(s, path)
	print("%s -> %s" % [path, "OK" if err == OK else "ERRO %d" % err])
