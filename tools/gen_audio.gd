extends SceneTree
## Gera os efeitos sonoros (8-bit) e a música synthwave em res://audio/*.wav.
## Tudo sintetizado aqui: sem arquivos de terceiros nem licenças.
## Uso: godot --headless --path . --script res://tools/gen_audio.gd

const RATE := 32000
const OUT_DIR := "res://audio"

# Música
const BPM := 128.0
const BARS := 8
const STEPS_PER_BAR := 16


func _initialize() -> void:
	seed(1337)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_save("laser", _laser())
	_save("hit", _hit())
	_save("ricochet", _ricochet())
	_save("explosion", _explosion(0.55, 0.8))
	_save("death", _explosion(1.5, 1.0))
	_save("shield_hit", _shield_hit())
	_save("pickup_shield", _pickup_shield())
	_save("pickup_crystal", _pickup_crystal())
	_save("level_up", _arpeggio([72, 76, 79, 84], 0.08, 0.5))
	_save("level_down", _arpeggio([72, 67, 63, 60], 0.09, 0.5))
	_save("alarm", _alarm())
	_save("click", _click())
	_save("music", _music())
	print("Áudio gerado em ", OUT_DIR)
	quit()


# ---------------------------------------------------------------- efeitos

func _laser() -> PackedFloat32Array:
	var n := _len(0.13)
	var out := _buf(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := t / 0.13
		var freq := 1500.0 * pow(0.3, k)
		phase += freq / RATE
		out[i] = (_square(phase, 0.5) * 0.6 + _saw(phase * 0.5) * 0.4) * exp(-k * 4.0) * 0.5
	return out


func _hit() -> PackedFloat32Array:
	var n := _len(0.07)
	var out := _buf(n)
	var phase := 0.0
	for i in n:
		var k := float(i) / n
		phase += 320.0 * (1.0 - k * 0.5) / RATE
		out[i] = (randf_range(-1, 1) * 0.6 + _square(phase, 0.5) * 0.4) * exp(-k * 6.0) * 0.5
	return out


func _ricochet() -> PackedFloat32Array:
	var n := _len(0.22)
	var out := _buf(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := float(i) / n
		var freq := 2400.0 - 700.0 * k + sin(t * 2.0 * PI * 45.0) * 120.0
		phase += freq / RATE
		var click := randf_range(-1, 1) * exp(-t * 300.0)
		out[i] = (_tri(phase) * 0.7 * exp(-k * 5.0) + click * 0.5) * 0.45
	return out


func _explosion(duration: float, volume: float) -> PackedFloat32Array:
	var n := _len(duration)
	var out := _buf(n)
	var low := 0.0
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := float(i) / n
		# Ruído com filtro passa-baixa que vai fechando = "estrondo" que se afasta.
		var cutoff := lerpf(0.35, 0.02, sqrt(k))
		low += cutoff * (randf_range(-1, 1) - low)
		phase += lerpf(140.0, 38.0, minf(1.0, t * 4.0)) / RATE
		var thump := sin(phase * TAU) * exp(-t * 7.0)
		out[i] = _soft(low * 2.2 * exp(-k * 3.5) + thump * 0.9) * volume * 0.8
	return out


func _shield_hit() -> PackedFloat32Array:
	var n := _len(0.3)
	var out := _buf(n)
	var phase := 0.0
	var low := 0.0
	for i in n:
		var k := float(i) / n
		phase += lerpf(260.0, 70.0, k) / RATE
		low += 0.2 * (randf_range(-1, 1) - low)
		out[i] = _soft(_square(phase, 0.3) * 0.5 + low * 1.4) * exp(-k * 4.0) * 0.6
	return out


func _pickup_shield() -> PackedFloat32Array:
	var n := _len(0.2)
	var out := _buf(n)
	var phase := 0.0
	for i in n:
		var k := float(i) / n
		phase += lerpf(620.0, 1300.0, k) / RATE
		out[i] = (sin(phase * TAU) * 0.7 + sin(phase * TAU * 2.0) * 0.25) * _env(k, 0.05, 2.5) * 0.45
	return out


func _pickup_crystal() -> PackedFloat32Array:
	return _arpeggio([81, 88], 0.06, 0.4)


func _arpeggio(notes: Array, note_len: float, volume: float) -> PackedFloat32Array:
	var per := _len(note_len)
	var tail := _len(0.12)
	var out := _buf(per * notes.size() + tail)
	for ni in notes.size():
		var freq := _midi(notes[ni])
		var phase := 0.0
		var n := per + tail
		for i in n:
			var k := float(i) / n
			phase += freq / RATE
			out[ni * per + i] += _square(phase, 0.25) * exp(-k * 5.0) * volume * 0.6
	return out


func _alarm() -> PackedFloat32Array:
	var n := _len(0.5)
	var out := _buf(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var freq := 880.0 if fmod(t, 0.25) < 0.125 else 660.0
		phase += freq / RATE
		out[i] = _tri(phase) * _env(float(i) / n, 0.02, 1.0) * 0.45
	return out


func _click() -> PackedFloat32Array:
	var n := _len(0.05)
	var out := _buf(n)
	var phase := 0.0
	for i in n:
		var k := float(i) / n
		phase += 1100.0 / RATE
		out[i] = _square(phase, 0.5) * exp(-k * 8.0) * 0.35
	return out


# ---------------------------------------------------------------- música

## Loop synthwave de 8 compassos (Lá menor: Am F C G), 128 BPM.
## As caudas das notas "dão a volta" no buffer, então o loop emenda sem clique.
func _music() -> PackedFloat32Array:
	var step := 60.0 / BPM / 4.0
	var total_steps := BARS * STEPS_PER_BAR
	var n := int(round(step * total_steps * RATE))
	var out := _buf(n)
	var chords := [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]]  # Am F C G

	for s in total_steps:
		var bar := s / STEPS_PER_BAR
		var chord: Array = chords[(bar / 2) % chords.size()]
		var start := int(round(s * step * RATE))
		var beat_step := s % 4

		# Bateria
		if beat_step == 0:
			_mix(out, start, _kick(), 0.9)
		if s % 8 == 4:
			_mix(out, start, _snare(), 0.55)
		if s % 2 == 1:
			_mix(out, start, _hat(), 0.22)

		# Baixo em colcheias, alternando oitava
		if s % 2 == 0:
			var root: int = chord[0] - 24 + (12 if s % 4 == 2 else 0)
			_mix(out, start, _bass_note(_midi(root), step * 2.0), 0.42)

		# Arpejo em semicolcheias (sobe e desce pelas notas do acorde)
		var pattern := [0, 1, 2, 1]
		var note: int = chord[pattern[s % 4]] + 12 + (12 if (s / 4) % 2 == 1 else 0)
		_mix(out, start, _arp_note(_midi(note), step), 0.16)

		# Pad no início de cada acorde (2 compassos)
		if s % (STEPS_PER_BAR * 2) == 0:
			for cn: int in chord:
				_mix(out, start, _pad_note(_midi(cn), step * STEPS_PER_BAR * 2.0), 0.07)

	for i in n:
		out[i] = _soft(out[i] * 0.9)
	return out


func _kick() -> PackedFloat32Array:
	var n := _len(0.3)
	var out := _buf(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		phase += (45.0 + 110.0 * exp(-t * 30.0)) / RATE
		out[i] = sin(phase * TAU) * exp(-t * 9.0)
	return out


func _snare() -> PackedFloat32Array:
	var n := _len(0.2)
	var out := _buf(n)
	var phase := 0.0
	var low := 0.0
	for i in n:
		var t := float(i) / RATE
		phase += 190.0 / RATE
		var noise := randf_range(-1, 1)
		low += 0.3 * (noise - low)
		out[i] = ((noise - low) * 0.8 * exp(-t * 18.0) + sin(phase * TAU) * 0.5 * exp(-t * 30.0))
	return out


func _hat() -> PackedFloat32Array:
	var n := _len(0.04)
	var out := _buf(n)
	var low := 0.0
	for i in n:
		var noise := randf_range(-1, 1)
		low += 0.5 * (noise - low)
		out[i] = (noise - low) * exp(-float(i) / n * 6.0)
	return out


func _bass_note(freq: float, duration: float) -> PackedFloat32Array:
	var n := _len(duration)
	var out := _buf(n)
	var phase := 0.0
	var low := 0.0
	for i in n:
		var k := float(i) / n
		phase += freq / RATE
		var cutoff := lerpf(0.25, 0.06, k)
		low += cutoff * (_saw(phase) - low)
		out[i] = low * _env(k, 0.01, 1.5)
	return out


func _arp_note(freq: float, duration: float) -> PackedFloat32Array:
	var n := _len(duration * 1.6)  # leve "eco" passando da nota seguinte
	var out := _buf(n)
	var phase := 0.0
	for i in n:
		var k := float(i) / n
		phase += freq / RATE
		out[i] = _square(phase, 0.25) * exp(-k * 4.0)
	return out


func _pad_note(freq: float, duration: float) -> PackedFloat32Array:
	var n := _len(duration)
	var out := _buf(n)
	var p1 := 0.0
	var p2 := 0.0
	var low := 0.0
	for i in n:
		var k := float(i) / n
		p1 += freq * 1.004 / RATE
		p2 += freq * 0.996 / RATE
		low += 0.05 * ((_saw(p1) + _saw(p2)) * 0.5 - low)
		out[i] = low * _env(k, 0.15, 0.0) * (1.0 - smoothstep(0.85, 1.0, k))
	return out


# ---------------------------------------------------------------- utilitários

func _mix(dst: PackedFloat32Array, start: int, src: PackedFloat32Array, gain: float) -> void:
	var n := dst.size()
	for i in src.size():
		var j := (start + i) % n
		dst[j] += src[i] * gain


func _square(phase: float, duty: float) -> float:
	return 1.0 if fmod(phase, 1.0) < duty else -1.0


func _saw(phase: float) -> float:
	return 2.0 * fmod(phase, 1.0) - 1.0


func _tri(phase: float) -> float:
	return 4.0 * absf(fmod(phase, 1.0) - 0.5) - 1.0


## Envelope: sobe em `attack` (fração) e decai exponencialmente.
func _env(k: float, attack: float, decay: float) -> float:
	if k < attack:
		return k / attack
	return exp(-(k - attack) * decay)


func _soft(x: float) -> float:
	return tanh(x)


func _midi(note: int) -> float:
	return 440.0 * pow(2.0, (note - 69) / 12.0)


func _len(seconds: float) -> int:
	return int(seconds * RATE)


func _buf(n: int) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(n)
	return b


func _save(name: String, samples: PackedFloat32Array) -> void:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	wav.save_to_wav("%s/%s.wav" % [OUT_DIR, name])
