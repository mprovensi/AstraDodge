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
var turrets := 0.0
var rain_left := 0.0
var calm_left := 0.0
var finished := false
var music_track := "main"  # última trilha pedida pela linha do tempo (para o "Continuar")
var boss_id := ""          # chefe já anunciado neste setor (o "Continuar" recomeça a luta)

## Modo Infinito: a linha do tempo não vem do .tres, é gerada sob demanda por aqui.
var generator: EndlessGenerator

var _events: Array[WaveEvent] = []
var _next := 0


func _init(data: SectorData, endless_generator: EndlessGenerator = null) -> void:
	sector = data
	music_track = data.music
	generator = endless_generator
	_events = data.events.duplicate()
	if generator != null:
		_events.append_array(generator.generate_until(0.0))
	_events.sort_custom(_by_time)


static func _by_time(a: WaveEvent, b: WaveEvent) -> bool:
	return a.at < b.at


func progress() -> float:
	return clampf(time / sector.duration, 0.0, 1.0)


func difficulty() -> float:
	if generator != null:
		return EndlessGenerator.difficulty(time)
	return sector.difficulty_at(time)


## Acrescenta à linha do tempo os trechos gerados que faltam (só no Modo Infinito).
func _extend() -> void:
	if generator == null or generator.generated_until > time + EndlessGenerator.CHUNK:
		return
	var rest := _events.slice(_next)
	rest.append_array(generator.generate_until(time))
	rest.sort_custom(_by_time)
	_events = rest
	_next = 0


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
				turrets = e.turrets
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
	_extend()
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
				turrets = e.turrets
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
