extends Node
## Autoload "Sfx": efeitos sonoros e música.
## - Variações: "laser" sorteia entre laser_1..3 (se existirem) contra repetição.
## - Estéreo: `pos` (coordenadas da tela) posiciona o som da esquerda para a direita.
## - Limite de vozes por som, eco leve nos efeitos, compressor + limitador no master.
## - Ducking: a música abaixa um pouco em impactos grandes.
## - Motor: loop contínuo do propulsor, mais alto quando a nave se mexe.
## - Trilhas: play_music("boss") troca de faixa com crossfade (ver MUSIC_TRACKS).

const SOUND_NAMES := [
	"laser", "hit", "ricochet", "explosion", "death", "shield_hit", "pickup_shield",
	"pickup_crystal", "level_up", "level_down", "alarm", "click",
]
const MAX_VARIANTS := 3
const VOICE_LIMIT := {"explosion": 4, "hit": 3, "ricochet": 3, "laser": 3}
const DEFAULT_VOICE_LIMIT := 2

const POOL_SIZE := 18
const MIN_REPEAT_INTERVAL := 0.03  # evita empilhar o mesmo som no mesmo frame
const MUSIC_VOLUME_DB := -1.0
const MUSIC_PAUSED_VOLUME_DB := -11.0
## Trilhas: nome -> [arquivo, ganho em dB para igualar o volume percebido].
const MUSIC_TRACKS := {
	"main": ["res://audio/music.wav", 0.0],
	"boss": ["res://audio/music_boss.wav", -4.0],
	"sector2": ["res://audio/music_sector2.wav", 0.0],
	"sector3": ["res://audio/music_sector3.wav", 0.0],
	"sector4": ["res://audio/music_sector4.wav", 0.0],
	"sector5": ["res://audio/music_sector5.wav", 0.0],
	"sector6": ["res://audio/music_sector6.wav", 0.0],
	"sector7": ["res://audio/music_sector7.wav", 0.0],
	"sector8": ["res://audio/music_sector8.wav", 0.0],
	"victory": ["res://audio/music_victory.wav", 0.0],
}
const MUSIC_FADE_DB_PER_SEC := 40.0  # velocidade do crossfade (≈ 1,5 s até silenciar)
const ENGINE_IDLE_DB := -30.0
const ENGINE_MAX_DB := -17.0
const PAN_WIDTH := 0.8             # 0 = mono, 1 = esquerda/direita total

var _sounds := {}  # nome -> Array[AudioStream]
var _players: Array[AudioStreamPlayer2D] = []
var _next := 0
var _last_played := {}
var _music: AudioStreamPlayer      # trilha ativa
var _music_old: AudioStreamPlayer  # trilha saindo (crossfade)
var _track := "main"
var _engine: AudioStreamPlayer
var _music_target_db := MUSIC_VOLUME_DB
var _music_target_pitch := 1.0
var _duck_db := 0.0
var _engine_target_db := -80.0


func _ready() -> void:
	_load_sounds()
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_setup_effects()
	for i in POOL_SIZE:
		var p := AudioStreamPlayer2D.new()
		p.bus = "SFX"
		p.max_distance = 100000.0  # sem queda por distância: só o pan importa
		p.attenuation = 0.0
		p.panning_strength = PAN_WIDTH
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_music_old = AudioStreamPlayer.new()
	_music_old.bus = "Music"
	add_child(_music_old)
	_set_track_stream(_music, _track)
	_music.volume_db = _track_db()
	_engine = AudioStreamPlayer.new()
	_engine.bus = "SFX"
	_engine.stream = load("res://audio/engine.wav")
	_engine.volume_db = -80.0
	add_child(_engine)
	apply_enabled()


func _process(delta: float) -> void:
	# Transições suaves de volume/pitch da música (pausa, câmera lenta, ducking).
	_duck_db = move_toward(_duck_db, 0.0, delta * 12.0)
	_music.volume_db = move_toward(_music.volume_db, _music_target_db + _track_db() + _duck_db,
			delta * MUSIC_FADE_DB_PER_SEC)
	_music.pitch_scale = move_toward(_music.pitch_scale, _music_target_pitch, delta * 2.0)
	if _music_old.playing:
		_music_old.volume_db = move_toward(_music_old.volume_db, -60.0, delta * MUSIC_FADE_DB_PER_SEC)
		if _music_old.volume_db <= -59.0:
			_music_old.stop()
	_engine.volume_db = move_toward(_engine.volume_db, _engine_target_db, delta * 60.0)
	if _engine.volume_db <= -79.0 and _engine.playing:
		_engine.stop()


## Toca um efeito. `pos`: posição na tela (Vector2.INF = centro, sem pan).
func play(sound: String, volume_db := 0.0, pitch := 1.0, pitch_variation := 0.06, pos := Vector2.INF) -> void:
	var variants: Array = _sounds.get(sound, [])
	if variants.is_empty():
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(sound, -1.0)) < MIN_REPEAT_INTERVAL:
		return
	_last_played[sound] = now

	var p := _pick_player(sound)
	p.stream = variants[randi() % variants.size()]
	p.set_meta("sound", sound)
	p.volume_db = volume_db + randf_range(-1.0, 1.0)
	p.pitch_scale = maxf(0.1, pitch * randf_range(1.0 - pitch_variation, 1.0 + pitch_variation))
	var center := get_viewport().get_visible_rect().size * 0.5
	p.global_position = center if pos == Vector2.INF else Vector2(pos.x, center.y)
	p.play()


## Abaixa a música por um instante (impactos grandes, entrada de chefe).
func duck(amount_db := -6.0) -> void:
	_duck_db = minf(_duck_db, amount_db)


func start_music() -> void:
	_music_target_db = MUSIC_VOLUME_DB
	_music_target_pitch = 1.0
	if not _music.playing:
		_music.play()


## Troca a trilha (ex.: "boss" na entrada do chefe, "main" ao recomeçar). Se a música
## estiver tocando, faz crossfade; se não, só deixa a faixa pronta para start_music().
func play_music(track: String) -> void:
	if track == _track or not MUSIC_TRACKS.has(track):
		return
	_track = track
	if not _music.playing:
		_set_track_stream(_music, track)
		return
	# A faixa atual vira a "que sai"; a nova entra do silêncio.
	var outgoing := _music
	_music = _music_old
	_music_old = outgoing
	_set_track_stream(_music, track)
	_music.volume_db = -40.0
	_music.pitch_scale = _music_old.pitch_scale
	_music.play()


func current_track() -> String:
	return _track


func _set_track_stream(player: AudioStreamPlayer, track: String) -> void:
	player.stream = load(MUSIC_TRACKS[track][0])


func _track_db() -> float:
	return float(MUSIC_TRACKS[_track][1])


## 1 = normal, perto de 0 = câmera lenta/pausa (música "arrasta" e abaixa).
func set_music_intensity(time_scale: float, paused: bool) -> void:
	_music_target_pitch = lerpf(0.8, 1.0, clampf(time_scale, 0.0, 1.0)) if not paused else 1.0
	_music_target_db = MUSIC_PAUSED_VOLUME_DB if paused else MUSIC_VOLUME_DB


## Motor da nave: `level` 0 (parada) a 1 (movendo rápido); `on` false desliga suavemente.
func set_engine(on: bool, level: float) -> void:
	if on:
		if not _engine.playing:
			_engine.play()
		_engine_target_db = lerpf(ENGINE_IDLE_DB, ENGINE_MAX_DB, clampf(level, 0.0, 1.0))
		_engine.pitch_scale = lerpf(0.9, 1.25, clampf(level, 0.0, 1.0))
	else:
		_engine_target_db = -80.0


func apply_enabled() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not Game.music_enabled)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), not Game.sfx_enabled)


func _load_sounds() -> void:
	for sound: String in SOUND_NAMES:
		var list: Array[AudioStream] = []
		for v in range(1, MAX_VARIANTS + 1):
			var path := "res://audio/%s_%d.wav" % [sound, v]
			if ResourceLoader.exists(path):
				list.append(load(path))
		if list.is_empty() and ResourceLoader.exists("res://audio/%s.wav" % sound):
			list.append(load("res://audio/%s.wav" % sound))
		_sounds[sound] = list


## Respeita o limite de vozes do som (rouba a mais antiga); senão usa o próximo da fila.
func _pick_player(sound: String) -> AudioStreamPlayer2D:
	var limit: int = VOICE_LIMIT.get(sound, DEFAULT_VOICE_LIMIT)
	var same: Array[AudioStreamPlayer2D] = []
	for p in _players:
		if p.playing and p.get_meta("sound", "") == sound:
			same.append(p)
	if same.size() >= limit:
		var oldest := same[0]
		for p in same:
			if p.get_playback_position() > oldest.get_playback_position():
				oldest = p
		return oldest
	for i in POOL_SIZE:
		var p := _players[(_next + i) % POOL_SIZE]
		if not p.playing:
			_next = (_next + i + 1) % POOL_SIZE
			return p
	var fallback := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	return fallback


func _setup_effects() -> void:
	# Eco leve nos efeitos: dá "espaço" sem embolar.
	var reverb := AudioEffectReverb.new()
	reverb.room_size = 0.35
	reverb.damping = 0.5
	reverb.spread = 0.6
	reverb.predelay_msec = 20.0
	reverb.wet = 0.12
	reverb.dry = 1.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index("SFX"), reverb)
	# Master: compressor (cola o mix) e limitador (nada distorce).
	var master := AudioServer.get_bus_index("Master")
	var comp := AudioEffectCompressor.new()
	comp.threshold = -12.0
	comp.ratio = 3.0
	comp.attack_us = 5000.0
	comp.release_ms = 120.0
	AudioServer.add_bus_effect(master, comp)
	var limiter := AudioEffectHardLimiter.new()
	limiter.ceiling_db = -1.0
	AudioServer.add_bus_effect(master, limiter)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")
