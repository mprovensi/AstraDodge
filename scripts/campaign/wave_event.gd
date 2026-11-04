class_name WaveEvent
extends Resource
## Um evento na linha do tempo de um setor (ver SectorData).

enum Kind {
	MESSAGE,     ## mostra `text` por `duration` segundos
	DENSITY,     ## muda a densidade do preenchimento aleatório e libera/bloqueia metálicos
	DUST_RAIN,   ## `duration` s de muita poeira e nenhum metálico
	METAL_WALL,  ## aviso + fileira de metálicos com uma única brecha
	CALM,        ## `duration` s sem novos asteroides (respiro / limpar a tela)
	END,         ## fim do setor (quando a tela esvaziar)
	MUSIC,       ## troca a trilha com crossfade: `text` = nome da faixa ("boss", "main")
	BOSS,        ## ALERTA + chefe: `text` = id do chefe ("rock_mother"); o setor acaba quando ele cai
	CORRIDOR,    ## `duration` s de paredes seguidas com a brecha andando pouco (aviso na 1ª)
	STORM,       ## `duration` s de tempestade: raios em colunas, cada um avisado antes
	DRONES,      ## formação em V de `count` drones entrando pelo topo
	BIOME,       ## (Modo Infinito) troca de cenário: `count` = índice do setor (nebulosa + trilha)
	COMETS,      ## chuva de `count` cometas em sequência (cada um avisado em linha)
}

@export var at := 0.0                ## segundos desde o início do setor
@export var kind := Kind.MESSAGE
@export var duration := 0.0
@export_multiline var text := ""
@export var density := 1.0
@export var metals := true
@export_range(0.0, 1.0) var moving := 0.0   ## DENSITY: chance de metálico com propulsor por linha
@export_range(0.0, 1.0) var armored := 0.0  ## DENSITY: chance de poeira blindada
@export_range(0.0, 1.0) var clouds := 0.0   ## DENSITY: chance de nuvem iônica por linha
@export_range(0.0, 1.0) var mines := 0.0    ## DENSITY: chance de mina iônica por linha
@export_range(0.0, 1.0) var turrets := 0.0  ## DENSITY: chance de torreta (em destroço) por linha
@export_range(0.0, 1.0) var ice := 0.0      ## DENSITY: chance de cada poeira ser de gelo (racha em lascas)
@export_range(0.0, 1.0) var comets := 0.0   ## DENSITY: chance de um cometa avulso por linha
@export var count := 0                      ## DRONES/COMETS: quantos


static func make(at_seconds: float, event_kind: Kind, props := {}) -> WaveEvent:
	var e := WaveEvent.new()
	e.at = at_seconds
	e.kind = event_kind
	for key: String in props:
		e.set(key, props[key])
	return e
