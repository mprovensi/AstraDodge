class_name EndlessGenerator
extends RefCounted
## Gera a linha do tempo do MODO INFINITO, trecho a trecho, com os mesmos WaveEvents da campanha
## (que já têm aviso e rota segura testados). Ver PLANO_V3.md, seção 4.
##
## - Biomas: a cada BIOME_TIME s troca de setor (nebulosa, trilha, mecânicas) entre os liberados.
## - Orçamento: cada bloco tem um custo; o orçamento do trecho cresce com a dificuldade.
## - Ritmo: depois de um bloco pesado, o próximo espaço fica leve ou vazio.
## - Chefe a cada BOSS_EVERY s (o tempo da linha para durante a luta), com calmaria antes.
## - Semente: a mesma semente gera sempre a mesma partida (Desafio do Dia, reproduzir bugs).

const CHUNK := 30.0               ## duração de um trecho
const SLOTS := [6.0, 15.0, 24.0]  ## momentos (dentro do trecho) em que um bloco pode começar
const BIOME_TIME := 90.0          ## troca de bioma (múltiplo de CHUNK)
const BOSS_EVERY := 180.0         ## chefe a cada 3 min de linha do tempo (múltiplo de CHUNK)
const BOSS_CALM := 7.0            ## calmaria antes do chefe (limpa a tela)
const DIFFICULTY_TIME := 220.0    ## s para ~63% da dificuldade máxima
const HEAVY_COST := 3
const BOSS_HP_FIRST := 0.6        ## 1ª aparição de cada chefe: 60% da vida
const BOSS_HP_STEP := 0.15        ## +15% a cada repetição do mesmo chefe (até 100%)

## Um bloco de construção: tipo de evento, custo e de quais biomas (índice do setor) ele é.
const BLOCKS := [
	{"kind": WaveEvent.Kind.DUST_RAIN, "cost": 0, "biomes": [0, 1, 2, 3, 4, 5, 6, 7]},
	{"kind": WaveEvent.Kind.METAL_WALL, "cost": 2, "biomes": [0, 1, 2, 3, 4, 5, 6, 7]},
	{"kind": WaveEvent.Kind.CORRIDOR, "cost": 3, "biomes": [1]},
	{"kind": WaveEvent.Kind.STORM, "cost": 3, "biomes": [2]},
	{"kind": WaveEvent.Kind.DRONES, "cost": 2, "biomes": [3]},
	{"kind": WaveEvent.Kind.DRONES, "cost": 4, "biomes": [3], "ambush": true},
	{"kind": WaveEvent.Kind.COMETS, "cost": 3, "biomes": [4]},
	{"kind": WaveEvent.Kind.SWARM, "cost": 2, "biomes": [5]},
	{"kind": WaveEvent.Kind.HATCH, "cost": 3, "biomes": [5]},
	{"kind": WaveEvent.Kind.GATES, "cost": 3, "biomes": [6]},
	{"kind": WaveEvent.Kind.SLIDE, "cost": 3, "biomes": [6]},
	{"kind": WaveEvent.Kind.BLACKOUT, "cost": 2, "biomes": [6]},
	{"kind": WaveEvent.Kind.INVERT, "cost": 3, "biomes": [7]},
]

var biomes: Array[int] = []       ## setores liberados (índices em SECTORS)
var bosses: Array[String] = []    ## chefes já derrotados (ids)
var sectors: Array[SectorData] = []
var rng := RandomNumberGenerator.new()
var generated_until := 0.0

var _biome := 0
var _last_boss := ""
var _boss_seen := {}  # id -> quantas vezes já apareceu nesta partida
var _last_heavy := false


func _init(seed_value: int, sector_list: Array[SectorData], biome_list: Array[int],
		boss_list: Array[String]) -> void:
	rng.seed = seed_value
	sectors = sector_list
	biomes = biome_list.duplicate()
	bosses = boss_list.duplicate()
	if biomes.is_empty():
		biomes = [0]
	_biome = biomes[0]


static func difficulty(t: float) -> float:
	return 1.0 - exp(-t / DIFFICULTY_TIME)


## Fração da vida com que o chefe `id` entra agora (e conta a aparição).
func boss_hp_scale(id: String) -> float:
	var seen: int = _boss_seen.get(id, 0)
	_boss_seen[id] = seen + 1
	return minf(1.0, BOSS_HP_FIRST + BOSS_HP_STEP * seen)


## Gera os trechos que faltam para cobrir até `t + CHUNK` e devolve os eventos novos.
func generate_until(t: float) -> Array[WaveEvent]:
	var out: Array[WaveEvent] = []
	while generated_until < t + CHUNK:
		out.append_array(_chunk(generated_until))
		generated_until += CHUNK
	return out


func _chunk(t0: float) -> Array[WaveEvent]:
	var K := WaveEvent.Kind
	var ev: Array[WaveEvent] = []
	var d := difficulty(t0)

	# Começo de ciclo de bioma: troca de cenário (o 1º trecho já começa no bioma inicial).
	if is_zero_approx(fmod(t0, BIOME_TIME)):
		if t0 > 0.0:
			_biome = _pick_biome()
		var s := sectors[_biome]
		ev.append(WaveEvent.make(t0 + 0.5, K.MESSAGE, {"text": s.subtitle.to_upper(), "duration": 2.5}))
		ev.append(WaveEvent.make(t0 + 0.5, K.BIOME, {"count": _biome}))

	# Clima do trecho (densidade + mecânicas do bioma, misturando outro bioma no fim do jogo).
	if t0 == 0.0:
		ev.append(WaveEvent.make(0.0, K.DENSITY, {"density": 0.6, "metals": false}))
		ev.append(WaveEvent.make(12.0, K.DENSITY, _climate(_biome, d, -1)))
	else:
		var mix := -1
		if d > 0.5 and biomes.size() > 1 and rng.randf() < d:
			mix = biomes[rng.randi_range(0, biomes.size() - 1)]
		ev.append(WaveEvent.make(t0, K.DENSITY, _climate(_biome, d, mix)))

	# Chefe no fim do ciclo: calmaria + aviso + chefe no último espaço do trecho.
	var boss_chunk := not bosses.is_empty() and is_zero_approx(fmod(t0 + CHUNK, BOSS_EVERY))
	var slots: Array = SLOTS
	if boss_chunk:
		slots = [SLOTS[0]]

	var budget := 2.0 + 6.0 * d
	for slot: float in slots:
		var block := _pick_block(budget)
		if block.is_empty():
			_last_heavy = false
			continue
		budget -= block.cost
		_last_heavy = block.cost >= HEAVY_COST
		ev.append_array(_block_events(block, t0 + slot, d))

	if boss_chunk:
		var at := t0 + CHUNK - 0.5
		ev.append(WaveEvent.make(at - BOSS_CALM, K.CALM, {"duration": BOSS_CALM + 2.0}))
		ev.append(WaveEvent.make(at - 4.0, K.MESSAGE, {"text": "Algo enorme se aproxima...", "duration": 3.0}))
		ev.append(WaveEvent.make(at, K.BOSS, {"text": _pick_boss()}))
		_last_heavy = true
	return ev


func _climate(biome: int, d: float, mix: int) -> Dictionary:
	var c := {"density": lerpf(0.8, 1.25, d), "metals": true}
	for b in [biome, mix]:
		if b < 0:
			continue
		var k := 1.0 if b == biome else 0.5  # o bioma misturado entra pela metade
		match b:
			1:
				c["moving"] = maxf(c.get("moving", 0.0), (0.25 + 0.25 * d) * k)
				c["armored"] = maxf(c.get("armored", 0.0), (0.2 + 0.2 * d) * k)
			2:
				c["clouds"] = maxf(c.get("clouds", 0.0), (0.3 + 0.15 * d) * k)
				c["mines"] = maxf(c.get("mines", 0.0), (0.2 + 0.15 * d) * k)
			3:
				c["turrets"] = maxf(c.get("turrets", 0.0), (0.25 + 0.15 * d) * k)
			4:
				c["ice"] = maxf(c.get("ice", 0.0), (0.35 + 0.2 * d) * k)
				c["comets"] = maxf(c.get("comets", 0.0), (0.06 + 0.06 * d) * k)
			5:
				c["swarm"] = maxf(c.get("swarm", 0.0), (0.15 + 0.12 * d) * k)
				c["eggs"] = maxf(c.get("eggs", 0.0), (0.2 + 0.12 * d) * k)
			6:
				c["moving"] = maxf(c.get("moving", 0.0), (0.2 + 0.15 * d) * k)
				c["turrets"] = maxf(c.get("turrets", 0.0), (0.15 + 0.1 * d) * k)
			7:
				c["wells"] = maxf(c.get("wells", 0.0), (0.15 + 0.1 * d) * k)
				c["portals"] = maxf(c.get("portals", 0.0), (0.15 + 0.1 * d) * k)
	return c


## Sorteia um bloco do bioma que caiba no orçamento (ou nada). Depois de um pesado, só leve.
func _pick_block(budget: float) -> Dictionary:
	var options: Array = []
	for b: Dictionary in BLOCKS:
		if not _biome in b.biomes or b.cost > budget:
			continue
		if _last_heavy and b.cost >= HEAVY_COST:
			continue
		options.append(b)
	# Espaço vazio também é opção (respiro), mais comum no começo.
	if options.is_empty() or rng.randf() < 0.25:
		return {}
	return options[rng.randi_range(0, options.size() - 1)]


func _block_events(block: Dictionary, at: float, d: float) -> Array[WaveEvent]:
	var K := WaveEvent.Kind
	var ev: Array[WaveEvent] = []
	match block.kind:
		K.DUST_RAIN:
			ev.append(WaveEvent.make(at, K.DUST_RAIN, {"duration": 7.0}))
			ev.append(WaveEvent.make(at, K.MESSAGE, {"text": "CHUVA DE POEIRA!", "duration": 2.5}))
		K.METAL_WALL:
			ev.append(WaveEvent.make(at, K.METAL_WALL))
		K.CORRIDOR:
			ev.append(WaveEvent.make(at, K.CORRIDOR, {"duration": lerpf(6.0, 8.0, d)}))
		K.STORM:
			ev.append(WaveEvent.make(at, K.STORM, {"duration": lerpf(7.0, 8.0, d)}))
		K.COMETS:
			ev.append(WaveEvent.make(at, K.COMETS, {"count": 3 if d < 0.5 else 5}))
		K.SWARM:
			ev.append(WaveEvent.make(at, K.SWARM, {"count": 6 if d < 0.5 else 10}))
		K.HATCH:
			ev.append(WaveEvent.make(at, K.HATCH, {"count": 4 if d < 0.5 else 6}))
		K.GATES:
			ev.append(WaveEvent.make(at, K.GATES, {"count": 2 if d < 0.5 else 3}))
		K.SLIDE:
			ev.append(WaveEvent.make(at, K.SLIDE, {"count": 2 if d < 0.5 else 3}))
		K.BLACKOUT:
			ev.append(WaveEvent.make(at, K.BLACKOUT, {"duration": 6.0}))
		K.INVERT:
			ev.append(WaveEvent.make(at, K.INVERT, {"duration": 6.0}))
		K.DRONES:
			if block.get("ambush", false):
				ev.append(WaveEvent.make(at, K.DRONES, {"count": 5, "text": "EMBOSCADA!"}))
				ev.append(WaveEvent.make(at + 2.0, K.DRONES, {"count": 3}))
			else:
				ev.append(WaveEvent.make(at, K.DRONES, {"count": 3 if d < 0.4 else 5}))
	return ev


func _pick_biome() -> int:
	if biomes.size() == 1:
		return biomes[0]
	var b := _biome
	while b == _biome:
		b = biomes[rng.randi_range(0, biomes.size() - 1)]
	return b


func _pick_boss() -> String:
	var b := bosses[rng.randi_range(0, bosses.size() - 1)]
	if bosses.size() > 1:
		while b == _last_boss:
			b = bosses[rng.randi_range(0, bosses.size() - 1)]
	_last_boss = b
	return b
