extends SceneTree
## Cria os .tres iniciais dos setores. Depois de criados, a fonte da verdade são os .tres
## (edite pelo Inspetor do Godot); rode de novo só para recriar do zero.
## Uso: godot --headless --path . --script res://tools/gen_sectors.gd

const OUT := "res://data/sectors"
const MOTHERSHIP_AT := 60.0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_save(_sector_1())
	_save(_sector_2())
	_save(_sector_3())
	_save(_sector_4())
	_save(_sector_5())
	_save(_sector_6())
	_save(_sector_7())
	_save(_sector_8())
	quit()


## Setor 8 — Fenda Gravitacional (FINAL): poços, portais, inversão; chefe Núcleo da Fenda.
func _sector_8() -> SectorData:
	var s := SectorData.new()
	s.id = "sector_8"
	s.number = 8
	s.title = "SETOR 8"
	s.subtitle = "Fenda Gravitacional"
	s.duration = 150.0
	s.difficulty_start = 0.7
	s.difficulty_end = 1.0
	s.music = "sector8"
	s.nebula_a = Color(0.03, 0.02, 0.05)  # preto
	s.nebula_b = Color(0.30, 0.05, 0.26)  # magenta
	var K := WaveEvent.Kind
	s.events.assign([
		WaveEvent.make(0.0, K.DENSITY, {"density": 0.8, "metals": true}),
		WaveEvent.make(0.5, K.MESSAGE, {"text": "SETOR 8\nFenda Gravitacional", "duration": 2.5}),
		WaveEvent.make(5.0, K.DENSITY, {"density": 0.8, "metals": true, "wells": 0.15}),
		WaveEvent.make(5.0, K.MESSAGE, {"text": "Poços gravitacionais puxam a nave\ne curvam os seus tiros", "duration": 4.0}),
		WaveEvent.make(25.0, K.DENSITY, {"density": 0.85, "metals": true, "wells": 0.12, "portals": 0.15}),
		WaveEvent.make(25.0, K.MESSAGE, {"text": "Portais: a rocha que entra no ciano\nsai pelo magenta!", "duration": 4.0}),
		WaveEvent.make(45.0, K.INVERT, {"duration": 8.0}),
		WaveEvent.make(62.0, K.DENSITY, {"density": 0.95, "metals": true, "wells": 0.12, "portals": 0.12,
				"moving": 0.2, "ice": 0.2, "swarm": 0.1}),
		WaveEvent.make(72.0, K.METAL_WALL),
		WaveEvent.make(82.0, K.COMETS, {"count": 3}),
		WaveEvent.make(92.0, K.DUST_RAIN, {"duration": 8.0}),
		WaveEvent.make(92.0, K.MESSAGE, {"text": "CHUVA DE POEIRA!", "duration": 2.5}),
		WaveEvent.make(104.0, K.INVERT, {"duration": 8.0}),
		WaveEvent.make(118.0, K.DENSITY, {"density": 1.05, "metals": true, "wells": 0.15, "portals": 0.15,
				"moving": 0.25, "turrets": 0.15, "mines": 0.1}),
		WaveEvent.make(126.0, K.GATES, {"count": 2}),
		WaveEvent.make(138.0, K.CALM, {"duration": 9999.0}),
		WaveEvent.make(140.0, K.MESSAGE, {"text": "O centro da Fenda desperta...", "duration": 3.0}),
		WaveEvent.make(144.0, K.BOSS, {"text": "rift_core"}),
	])
	return s


## Setor 7 — Estação Abandonada: portões de laser no compasso, paredes móveis, blecaute; chefe Sentinela.
func _sector_7() -> SectorData:
	var s := SectorData.new()
	s.id = "sector_7"
	s.number = 7
	s.title = "SETOR 7"
	s.subtitle = "Estação Abandonada"
	s.duration = 150.0
	s.difficulty_start = 0.65
	s.difficulty_end = 0.95
	s.music = "sector7"
	s.nebula_a = Color(0.08, 0.08, 0.10)  # grafite
	s.nebula_b = Color(0.30, 0.04, 0.04)  # vermelho de alarme
	var K := WaveEvent.Kind
	s.events.assign([
		WaveEvent.make(0.0, K.DENSITY, {"density": 0.8, "metals": true}),
		WaveEvent.make(0.5, K.MESSAGE, {"text": "SETOR 7\nEstação Abandonada", "duration": 2.5}),
		WaveEvent.make(6.0, K.GATES, {"count": 3}),
		WaveEvent.make(22.0, K.DENSITY, {"density": 0.85, "metals": true, "moving": 0.2, "turrets": 0.15}),
		WaveEvent.make(32.0, K.SLIDE, {"count": 3}),
		WaveEvent.make(48.0, K.DENSITY, {"density": 0.9, "metals": true, "moving": 0.2, "turrets": 0.2,
				"swarm": 0.1}),
		WaveEvent.make(58.0, K.BLACKOUT, {"duration": 8.0}),
		WaveEvent.make(58.0, K.DENSITY, {"density": 0.7, "metals": true}),
		WaveEvent.make(70.0, K.DENSITY, {"density": 1.0, "metals": true, "moving": 0.25, "turrets": 0.2,
				"ice": 0.2}),
		WaveEvent.make(78.0, K.GATES, {"count": 4}),
		WaveEvent.make(98.0, K.DUST_RAIN, {"duration": 8.0}),
		WaveEvent.make(98.0, K.MESSAGE, {"text": "CHUVA DE POEIRA!", "duration": 2.5}),
		WaveEvent.make(110.0, K.SLIDE, {"count": 4}),
		WaveEvent.make(122.0, K.DENSITY, {"density": 1.05, "metals": true, "moving": 0.3, "turrets": 0.25,
				"swarm": 0.15, "comets": 0.05}),
		WaveEvent.make(128.0, K.BLACKOUT, {"duration": 6.0}),
		WaveEvent.make(138.0, K.CALM, {"duration": 9999.0}),
		WaveEvent.make(140.0, K.MESSAGE, {"text": "SISTEMA DE DEFESA REATIVADO.", "duration": 3.0}),
		WaveEvent.make(144.0, K.BOSS, {"text": "sentinel"}),
	])
	return s


## Setor 6 — Colmeia: enxame, ovos que eclodem, eclosão em massa; chefe Rainha da Colmeia.
func _sector_6() -> SectorData:
	var s := SectorData.new()
	s.id = "sector_6"
	s.number = 6
	s.title = "SETOR 6"
	s.subtitle = "Colmeia"
	s.duration = 150.0
	s.difficulty_start = 0.6
	s.difficulty_end = 0.92
	s.music = "sector6"
	s.nebula_a = Color(0.10, 0.18, 0.05)  # verde-musgo
	s.nebula_b = Color(0.30, 0.20, 0.04)  # âmbar orgânico
	var K := WaveEvent.Kind
	s.events.assign([
		WaveEvent.make(0.0, K.DENSITY, {"density": 0.8, "metals": true}),
		WaveEvent.make(0.5, K.MESSAGE, {"text": "SETOR 6\nColmeia", "duration": 2.5}),
		WaveEvent.make(5.0, K.SWARM, {"count": 6, "text": "ENXAME! Um tiro derruba cada inseto"}),
		WaveEvent.make(14.0, K.SWARM, {"count": 8}),
		WaveEvent.make(20.0, K.DENSITY, {"density": 0.8, "metals": true, "swarm": 0.15, "eggs": 0.2}),
		WaveEvent.make(20.0, K.MESSAGE, {"text": "Ovos eclodem quando o anel fecha.\nDestrua antes!", "duration": 4.0}),
		WaveEvent.make(40.0, K.HATCH, {"count": 5}),
		WaveEvent.make(55.0, K.METAL_WALL),
		WaveEvent.make(62.0, K.DENSITY, {"density": 0.95, "metals": true, "swarm": 0.2, "eggs": 0.2,
				"moving": 0.2, "ice": 0.2}),
		WaveEvent.make(75.0, K.SWARM, {"count": 10}),
		WaveEvent.make(88.0, K.DUST_RAIN, {"duration": 8.0}),
		WaveEvent.make(88.0, K.MESSAGE, {"text": "CHUVA DE POEIRA!", "duration": 2.5}),
		WaveEvent.make(100.0, K.HATCH, {"count": 6}),
		WaveEvent.make(108.0, K.DENSITY, {"density": 1.05, "metals": true, "swarm": 0.22, "eggs": 0.25,
				"moving": 0.25, "turrets": 0.15, "comets": 0.06}),
		WaveEvent.make(118.0, K.SWARM, {"count": 12}),
		WaveEvent.make(128.0, K.METAL_WALL),
		WaveEvent.make(138.0, K.CALM, {"duration": 9999.0}),
		WaveEvent.make(140.0, K.MESSAGE, {"text": "Um zumbido enorme vem do fundo da colmeia...", "duration": 3.0}),
		WaveEvent.make(144.0, K.BOSS, {"text": "hive_queen"}),
	])
	return s


## Setor 5 — Anel Glacial: gelo que racha em lascas, cometas; chefe Colosso de Gelo.
func _sector_5() -> SectorData:
	var s := SectorData.new()
	s.id = "sector_5"
	s.number = 5
	s.title = "SETOR 5"
	s.subtitle = "Anel Glacial"
	s.duration = 150.0
	s.difficulty_start = 0.55
	s.difficulty_end = 0.9
	s.music = "sector5"
	s.nebula_a = Color(0.06, 0.14, 0.30)  # azul-cobalto
	s.nebula_b = Color(0.20, 0.27, 0.34)  # branco-gelo acinzentado
	var K := WaveEvent.Kind
	s.events.assign([
		WaveEvent.make(0.0, K.DENSITY, {"density": 0.85, "metals": true}),
		WaveEvent.make(0.5, K.MESSAGE, {"text": "SETOR 5\nAnel Glacial", "duration": 2.5}),
		WaveEvent.make(5.0, K.DENSITY, {"density": 0.85, "metals": true, "ice": 0.5}),
		WaveEvent.make(5.0, K.MESSAGE, {"text": "Gelo racha em lascas ao quebrar.\nAtire cedo, de longe!", "duration": 4.0}),
		WaveEvent.make(25.0, K.MESSAGE, {"text": "Cometas cruzam na diagonal.\nSaia da faixa vermelha!", "duration": 4.0}),
		WaveEvent.make(26.0, K.COMETS, {"count": 2}),
		WaveEvent.make(35.0, K.DENSITY, {"density": 0.9, "metals": true, "ice": 0.45, "comets": 0.08}),
		WaveEvent.make(50.0, K.METAL_WALL),
		WaveEvent.make(62.0, K.DENSITY, {"density": 1.0, "metals": true, "ice": 0.45, "comets": 0.1,
				"moving": 0.2, "armored": 0.15}),
		WaveEvent.make(72.0, K.COMETS, {"count": 5}),
		WaveEvent.make(88.0, K.DUST_RAIN, {"duration": 8.0}),
		WaveEvent.make(88.0, K.MESSAGE, {"text": "CHUVA DE POEIRA!", "duration": 2.5}),
		WaveEvent.make(100.0, K.DRONES, {"count": 5}),
		WaveEvent.make(108.0, K.DENSITY, {"density": 1.1, "metals": true, "ice": 0.5, "comets": 0.12,
				"moving": 0.25, "armored": 0.2, "clouds": 0.15}),
		WaveEvent.make(118.0, K.COMETS, {"count": 6}),
		WaveEvent.make(130.0, K.METAL_WALL),
		WaveEvent.make(138.0, K.CALM, {"duration": 9999.0}),
		WaveEvent.make(140.0, K.MESSAGE, {"text": "O gelo à frente... está se mexendo.", "duration": 3.0}),
		WaveEvent.make(144.0, K.BOSS, {"text": "ice_colossus"}),
	])
	return s


## Setor 4 — Destroços da Frota: torretas, drones em V, emboscada; chefe Cruzador Fantasma.
func _sector_4() -> SectorData:
	var s := SectorData.new()
	s.id = "sector_4"
	s.number = 4
	s.title = "SETOR 4"
	s.subtitle = "Destroços da Frota"
	s.duration = 150.0
	s.difficulty_start = 0.5
	s.difficulty_end = 0.85
	s.music = "sector4"
	s.nebula_a = Color(0.30, 0.09, 0.04)  # ferrugem
	s.nebula_b = Color(0.32, 0.19, 0.05)  # laranja queimado
	var K := WaveEvent.Kind
	s.events.assign([
		WaveEvent.make(0.0, K.DENSITY, {"density": 0.85, "metals": true}),
		WaveEvent.make(0.5, K.MESSAGE, {"text": "SETOR 4\nDestroços da Frota", "duration": 2.5}),
		WaveEvent.make(5.0, K.DENSITY, {"density": 0.85, "metals": true, "turrets": 0.3}),
		WaveEvent.make(5.0, K.MESSAGE, {"text": "Torretas nos destroços atiram em você.\nO cano brilha antes do tiro!", "duration": 4.0}),
		WaveEvent.make(20.0, K.DRONES, {"count": 3, "text": "Drones à frente!"}),
		WaveEvent.make(32.0, K.DRONES, {"count": 5}),
		WaveEvent.make(45.0, K.METAL_WALL),
		WaveEvent.make(55.0, K.DENSITY, {"density": 1.0, "metals": true, "moving": 0.25, "armored": 0.25,
				"turrets": 0.35}),
		WaveEvent.make(62.0, K.DRONES, {"count": 5, "text": "EMBOSCADA!"}),
		WaveEvent.make(64.0, K.DRONES, {"count": 3}),
		WaveEvent.make(80.0, K.DUST_RAIN, {"duration": 8.0}),
		WaveEvent.make(80.0, K.MESSAGE, {"text": "CHUVA DE POEIRA!", "duration": 2.5}),
		WaveEvent.make(95.0, K.CORRIDOR, {"duration": 8.0}),
		WaveEvent.make(108.0, K.DRONES, {"count": 5}),
		WaveEvent.make(115.0, K.DENSITY, {"density": 1.1, "metals": true, "moving": 0.3, "armored": 0.3,
				"turrets": 0.4, "mines": 0.15}),
		WaveEvent.make(128.0, K.METAL_WALL),
		WaveEvent.make(138.0, K.CALM, {"duration": 9999.0}),
		WaveEvent.make(140.0, K.MESSAGE, {"text": "Uma nave enorme surge dos destroços...", "duration": 3.0}),
		WaveEvent.make(144.0, K.BOSS, {"text": "cruiser"}),
	])
	return s


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
	# Cada padrão tem uma introdução antes de entrar no sorteio das fileiras.
	var intros := {1: [[24.0, "v"], [64.0, "rain"]], 2: [[14.0, "stair"]],
			3: [[32.0, "zigzag"]], 4: [[36.0, "ring"]], 5: [[38.0, "checker"]],
			6: [[24.0, "funnel"]], 7: [[52.0, "funnel"]], 8: [[32.0, "ring"]]}
	for intro: Array in intros[s.number]:
		s.events.append(WaveEvent.make(intro[0], WaveEvent.Kind.FORMATION, {"text": intro[1]}))
	for event in s.events:
		if event.kind == WaveEvent.Kind.DENSITY and event.at >= 55.0:
			event.formations = minf(0.22, 0.1 + s.number * 0.02)
	# Nave-mãe no meio de todo setor (PLANO_CARTAS.md C3); o diretor ordena por tempo.
	s.events.append(WaveEvent.make(MOTHERSHIP_AT, WaveEvent.Kind.MOTHERSHIP))
	var path := "%s/%s.tres" % [OUT, s.id]
	var err := ResourceSaver.save(s, path)
	print("%s -> %s" % [path, "OK" if err == OK else "ERRO %d" % err])
