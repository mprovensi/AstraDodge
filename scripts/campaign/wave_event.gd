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
}

@export var at := 0.0                ## segundos desde o início do setor
@export var kind := Kind.MESSAGE
@export var duration := 0.0
@export_multiline var text := ""
@export var density := 1.0
@export var metals := true


static func make(at_seconds: float, event_kind: Kind, props := {}) -> WaveEvent:
	var e := WaveEvent.new()
	e.at = at_seconds
	e.kind = event_kind
	for key: String in props:
		e.set(key, props[key])
	return e
