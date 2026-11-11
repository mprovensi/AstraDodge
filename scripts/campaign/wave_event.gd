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
	SWARM,       ## grupo do enxame com `count` insetos (`text` opcional: dica na tela)
	HATCH,       ## eclosão: `count` ovos de uma vez (destrua antes do anel fechar!)
	GATES,       ## `count` portões de laser em sequência (ligam e desligam no compasso)
	SLIDE,       ## `count` paredes móveis em sequência (a brecha desliza de lado)
	BLACKOUT,    ## blecaute por `duration` s: só a luz em volta da nave
	INVERT,      ## inversão: aviso e depois `duration` s de rochas vindo de baixo
	MOTHERSHIP,  ## nave-mãe cruza o alto da tela; derrubada solta um contêiner de módulo
	FORMATION,   ## `text` = id de Formations; entra pelo topo, com rota segura
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
@export_range(0.0, 1.0) var swarm := 0.0    ## DENSITY: chance de um grupo pequeno do enxame por linha
@export_range(0.0, 1.0) var eggs := 0.0     ## DENSITY: chance de um ovo por linha
@export_range(0.0, 1.0) var wells := 0.0    ## DENSITY: chance de um poço gravitacional por linha
@export_range(0.0, 1.0) var portals := 0.0  ## DENSITY: chance de um par de portais por linha
@export_range(0.0, 1.0) var formations := 0.0 ## DENSITY: chance de trocar uma fileira por uma formação
@export var count := 0                      ## DRONES/COMETS/SWARM/HATCH/GATES/SLIDE: quantos


static func make(at_seconds: float, event_kind: Kind, props := {}) -> WaveEvent:
	var e := WaveEvent.new()
	e.at = at_seconds
	e.kind = event_kind
	for key: String in props:
		e.set(key, props[key])
	return e
