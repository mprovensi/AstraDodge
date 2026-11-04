extends Node
## Autoload "Sfx": efeitos sonoros (pool de players) e música, em buses separados.

const SOUNDS := {
	"laser": preload("res://audio/laser.wav"),
	"hit": preload("res://audio/hit.wav"),
	"ricochet": preload("res://audio/ricochet.wav"),
	"explosion": preload("res://audio/explosion.wav"),
	"death": preload("res://audio/death.wav"),
	"shield_hit": preload("res://audio/shield_hit.wav"),
	"pickup_shield": preload("res://audio/pickup_shield.wav"),
	"pickup_crystal": preload("res://audio/pickup_crystal.wav"),
	"level_up": preload("res://audio/level_up.wav"),
	"level_down": preload("res://audio/level_down.wav"),
	"alarm": preload("res://audio/alarm.wav"),
	"click": preload("res://audio/click.wav"),
}
const MUSIC := preload("res://audio/music.wav")

const POOL_SIZE := 14
const MIN_REPEAT_INTERVAL := 0.035  # evita empilhar o mesmo som no mesmo frame
const MUSIC_VOLUME_DB := -10.0
const MUSIC_PAUSED_VOLUME_DB := -20.0

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _last_played := {}
var _music: AudioStreamPlayer
var _music_target_db := MUSIC_VOLUME_DB
var _music_target_pitch := 1.0


func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	# Limitador no Master: várias explosões juntas não distorcem.
	var limiter := AudioEffectHardLimiter.new()
	limiter.ceiling_db = -1.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Master"), limiter)
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.stream = MUSIC
	_music.volume_db = MUSIC_VOLUME_DB
	add_child(_music)
	apply_enabled()


func _process(delta: float) -> void:
	# Transições suaves de volume/pitch da música (pausa, câmera lenta).
	_music.volume_db = move_toward(_music.volume_db, _music_target_db, delta * 40.0)
	_music.pitch_scale = move_toward(_music.pitch_scale, _music_target_pitch, delta * 2.0)


func play(sound: String, volume_db := 0.0, pitch := 1.0, pitch_variation := 0.06) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(sound, -1.0)) < MIN_REPEAT_INTERVAL:
		return
	_last_played[sound] = now
	var p := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = SOUNDS[sound]
	p.volume_db = volume_db
	p.pitch_scale = maxf(0.1, pitch * randf_range(1.0 - pitch_variation, 1.0 + pitch_variation))
	p.play()


func start_music() -> void:
	_music_target_db = MUSIC_VOLUME_DB
	_music_target_pitch = 1.0
	if not _music.playing:
		_music.play()


## 1 = normal, perto de 0 = câmera lenta/pausa (música "arrasta" e abaixa).
func set_music_intensity(time_scale: float, paused: bool) -> void:
	_music_target_pitch = lerpf(0.8, 1.0, clampf(time_scale, 0.0, 1.0)) if not paused else 1.0
	_music_target_db = MUSIC_PAUSED_VOLUME_DB if paused else MUSIC_VOLUME_DB


func apply_enabled() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not Game.music_enabled)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), not Game.sfx_enabled)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")
