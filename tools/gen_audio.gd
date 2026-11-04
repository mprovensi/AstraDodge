extends SceneTree
## Gera os efeitos sonoros e a música synthwave em res://audio/*.wav.
## Tudo sintetizado aqui: sem arquivos de terceiros nem licenças.
## Os efeitos são montados em CAMADAS (transiente + corpo + grave + cauda) para soar
## mais encorpados, e os mais frequentes têm 3 variações (nome_1..3) contra repetição.
## Uso: godot --headless --path . --script res://tools/gen_audio.gd

const RATE := 44100
const OUT_DIR := "res://audio"
const VARIANTS := 3

# Música
const BPM := 128.0
const BARS := 8
const STEPS_PER_BAR := 16


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	seed(1337)
	_save("music", _music())

	for v in VARIANTS:
		seed(100 + v)
		_save("laser_%d" % (v + 1), _laser(v))
		_save("hit_%d" % (v + 1), _hit(v))
		_save("ricochet_%d" % (v + 1), _ricochet(v))
		_save("explosion_%d" % (v + 1), _explosion(0.7 + 0.1 * v, 0.85))

	seed(7)
	_save("death", _explosion(1.8, 1.0))
	_save("shield_hit", _shield_hit())
	_save("pickup_shield", _pickup_shield())
	_save("pickup_crystal", _pickup_crystal())
	_save("level_up", _arpeggio([72, 76, 79, 84], 0.08, 0.5))
	_save("level_down", _arpeggio([72, 67, 63, 60], 0.09, 0.5))
	_save("alarm", _alarm())
	_save("click", _click())
	_save("engine", _engine())
	print("Áudio gerado em ", OUT_DIR)
	quit()


# ---------------------------------------------------------------- efeitos

## Tiro: "pew" de pulso de energia — triângulo descendo rápido + grave uma oitava abaixo
## + clique suave no ataque. Curto e macio: toca várias vezes por segundo sem cansar.
func _laser(v: int) -> PackedFloat32Array:
	var dur := 0.1
	var f0: float = [950.0, 880.0, 1020.0][v]
	var n := _len(dur)
	var dry := _buf(n)
	var p := 0.0
	var low := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := t / dur
		var freq := f0 * pow(0.38, sqrt(k))
		p += freq / RATE
		var body := _tri(p) * 0.7 + sin(p * TAU * 0.5) * 0.45  # corpo + grave
		var click := randf_range(-1.0, 1.0) * exp(-t * 600.0) * 0.25
		var x := (body + click) * minf(1.0, t * 800.0) * exp(-k * 5.0)
		low += 0.4 * (x - low)  # tira o brilho áspero
		dry[i] = low * 0.9
	return _with_echo(dry, 0.045, 0.18)


## Lasca de rocha: batida grave curta + estalo de ruído.
func _hit(v: int) -> PackedFloat32Array:
	var dur := 0.1
	var n := _len(dur)
	var out := _buf(n)
	var knock_f: float = [170.0, 200.0, 230.0][v]
	var phase := 0.0
	var low := 0.0
	for i in n:
		var t := float(i) / RATE
		phase += knock_f * (1.0 - t * 2.0) / RATE
		var noise := randf_range(-1.0, 1.0)
		low += 0.35 * (noise - low)
		var crack := (noise - low) * exp(-t * 70.0)
		var knock := sin(phase * TAU) * exp(-t * 40.0)
		out[i] = (crack * 0.5 + knock * 0.6) * 0.6
	return out


## Tiro no metálico: batida em ferro maciço — "tunc" grave e pesado + ressonância metálica
## curta e abafada (bloco sólido vibra pouco) + estalo de impacto. Sem o "ping" de sino.
func _ricochet(v: int) -> PackedFloat32Array:
	var dur := 0.3
	var base: float = [420.0, 380.0, 470.0][v]
	var ratios := [1.0, 2.76, 5.40]
	var amps := [1.0, 0.45, 0.2]
	var decays := [16.0, 26.0, 40.0]
	var n := _len(dur)
	var out := _buf(n)
	var thunk_phase := 0.0
	var low := 0.0
	for i in n:
		var t := float(i) / RATE
		var ring := 0.0
		for p in ratios.size():
			ring += sin(TAU * base * ratios[p] * t) * amps[p] * exp(-t * decays[p])
		thunk_phase += lerpf(160.0, 90.0, minf(1.0, t * 25.0)) / RATE
		var thunk := sin(thunk_phase * TAU) * exp(-t * 32.0)
		var noise := randf_range(-1.0, 1.0)
		low += 0.25 * (noise - low)
		var strike := low * exp(-t * 180.0)
		out[i] = _soft(thunk * 1.0 + ring * 0.45 + strike * 0.9) * 0.7
	return out


## Explosão em 4 camadas: transiente + corpo (ruído fechando) + grave + destroços (crepitar).
func _explosion(duration: float, volume: float) -> PackedFloat32Array:
	var n := _len(duration)
	var out := _buf(n)
	var body := 0.0
	var hp_low := 0.0
	var phase := 0.0
	var grain := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := float(i) / n
		var noise := randf_range(-1.0, 1.0)
		var transient := noise * exp(-t * 250.0)
		body += lerpf(0.4, 0.015, sqrt(k)) * (noise - body)
		phase += lerpf(75.0, 32.0, minf(1.0, t * 3.0)) / RATE
		var sub := sin(phase * TAU) * exp(-t * 5.5)
		# Destroços: grãos curtos e aleatórios, cada vez mais raros.
		grain *= 0.985
		if randf() < 0.004 * pow(1.0 - k, 2.0):
			grain = randf_range(0.3, 0.8)
		var g := randf_range(-1.0, 1.0)
		hp_low += 0.3 * (g - hp_low)
		var debris := (g - hp_low) * grain
		var x := transient * 0.8 + body * 2.4 * exp(-k * 3.2) + sub * 1.0 + debris * 0.5
		out[i] = _soft(x) * volume * 0.75
	return out


## Impacto no escudo: baque grave + zumbido elétrico pulsante + chiado.
func _shield_hit() -> PackedFloat32Array:
	var dur := 0.38
	var n := _len(dur)
	var out := _buf(n)
	var p_thump := 0.0
	var p_buzz := 0.0
	var low := 0.0
	for i in n:
		var t := float(i) / RATE
		p_thump += lerpf(120.0, 50.0, minf(1.0, t * 5.0)) / RATE
		p_buzz += 110.0 / RATE
		var thump := sin(p_thump * TAU) * exp(-t * 14.0)
		var buzz := _square(p_buzz, 0.5) * (0.5 + 0.5 * sin(TAU * 32.0 * t)) * exp(-t * 9.0)
		low += 0.12 * (buzz - low)
		var hiss := randf_range(-1.0, 1.0) * exp(-t * 60.0)
		out[i] = _soft(thump * 1.1 + low * 0.9 + hiss * 0.3) * 0.65
	return out


## Orbe de escudo: sino que "sobe" (energia carregando).
func _pickup_shield() -> PackedFloat32Array:
	var dur := 0.45
	var n := _len(dur)
	var out := _buf(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := 700.0 * (1.0 + minf(1.0, t / 0.07))
		phase += f / RATE
		var s := sin(phase * TAU) + 0.45 * sin(phase * TAU * 2.0) * exp(-t * 6.0) + 0.25 * sin(phase * TAU * 3.01) * exp(-t * 10.0)
		out[i] = s * minf(1.0, t * 300.0) * exp(-t * 7.0) * 0.35
	return out


## Cristal: duas notas de vidro com parciais inarmônicas.
func _pickup_crystal() -> PackedFloat32Array:
	var dur := 0.5
	var n := _len(dur)
	var out := _buf(n)
	var notes := [[1318.5, 0.0], [1975.5, 0.06]]
	var ratios := [1.0, 2.32, 4.25]
	var decays := [8.0, 14.0, 22.0]
	for i in n:
		var t := float(i) / RATE
		var s := 0.0
		for note: Array in notes:
			var tt: float = t - note[1]
			if tt < 0.0:
				continue
			for p in ratios.size():
				s += sin(TAU * note[0] * ratios[p] * tt) * exp(-tt * decays[p]) / (p + 1.0)
		out[i] = s * 0.2
	return out


## Propulsor em loop (2 s): ruído "marrom" filtrado + zumbido grave. Emenda sem clique.
func _engine() -> PackedFloat32Array:
	var dur := 2.0
	var xf := _len(0.25)
	var n := _len(dur)
	var raw := _buf(n + xf)
	var brown := 0.0
	var low := 0.0
	var phase := 0.0
	for i in n + xf:
		brown = clampf(brown + randf_range(-1.0, 1.0) * 0.04, -1.0, 1.0) * 0.998
		low += 0.08 * (brown - low)
		phase += 55.0 / RATE
		raw[i] = low * 0.55 + _saw(phase) * 0.03
	var out := _buf(n)
	for i in n:
		out[i] = raw[i]
		if i < xf:  # crossfade: o fim do loop emenda no começo
			var w := float(i) / xf
			out[i] = raw[i] * w + raw[n + i] * (1.0 - w)
	return out


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


## Soma um eco (atraso `delay` s, ganho `gain`) — dá "espaço" ao som seco.
func _with_echo(dry: PackedFloat32Array, delay: float, gain: float) -> PackedFloat32Array:
	var d := _len(delay)
	var out := _buf(dry.size() + d)
	for i in dry.size():
		out[i] += dry[i]
		out[i + d] += dry[i] * gain
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
