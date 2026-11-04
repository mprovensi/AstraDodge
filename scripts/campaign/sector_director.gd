class_name SectorDirector
extends RefCounted
## Executa a linha do tempo de um SectorData e expõe o "clima" atual para o spawner.

var sector: SectorData
var time := 0.0
var density := 1.0
var metals := true
var moving := 0.0
var armored := 0.0
var clouds := 0.0
var mines := 0.0
var rain_left := 0.0
var calm_left := 0.0
var finished := false
var music_track := "main"  # última trilha pedida pela linha do tempo (para o "Continuar")
var boss_id := ""          # chefe já anunciado neste setor (o "Continuar" recomeça a luta)

var _events: Array[WaveEvent] = []
var _next := 0


func _init(data: SectorData) -> void:
	sector = data
	music_track = data.music
	_events = data.events.duplicate()
	_events.sort_custom(func(a: WaveEvent, b: WaveEvent) -> bool: return a.at < b.at)


func progress() -> float:
	return clampf(time / sector.duration, 0.0, 1.0)


func difficulty() -> float:
	return sector.difficulty_at(time)


## Pula direto para o tempo `t` (continuar de onde parou): aplica o "clima" dos
## eventos já passados sem disparar mensagens nem paredões.
func seek(t: float) -> void:
	time = t
	while _next < _events.size() and _events[_next].at <= t:
		var e := _events[_next]
		_next += 1
		match e.kind:
			WaveEvent.Kind.DENSITY:
				density = e.density
				metals = e.metals
				moving = e.moving
				armored = e.armored
				clouds = e.clouds
				mines = e.mines
			WaveEvent.Kind.DUST_RAIN:
				rain_left = maxf(0.0, e.at + e.duration - t)
			WaveEvent.Kind.CALM:
				calm_left = maxf(0.0, e.at + e.duration - t)
			WaveEvent.Kind.END:
				finished = true
			WaveEvent.Kind.BOSS:
				boss_id = e.text
			WaveEvent.Kind.MUSIC:
				music_track = e.text


## Avança o tempo e devolve os eventos que dispararam neste passo.
func update(dt: float) -> Array[WaveEvent]:
	time += dt
	rain_left = maxf(0.0, rain_left - dt)
	calm_left = maxf(0.0, calm_left - dt)
	var fired: Array[WaveEvent] = []
	while _next < _events.size() and _events[_next].at <= time:
		var e := _events[_next]
		_next += 1
		match e.kind:
			WaveEvent.Kind.DENSITY:
				density = e.density
				metals = e.metals
				moving = e.moving
				armored = e.armored
				clouds = e.clouds
				mines = e.mines
			WaveEvent.Kind.DUST_RAIN:
				rain_left = e.duration
			WaveEvent.Kind.CALM:
				calm_left = e.duration
			WaveEvent.Kind.END:
				finished = true
			WaveEvent.Kind.BOSS:
				boss_id = e.text
			WaveEvent.Kind.MUSIC:
				music_track = e.text
		fired.append(e)
	return fired
