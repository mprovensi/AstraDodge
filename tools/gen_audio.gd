extends SceneTree
## Gera os efeitos sonoros e a música lofi em res://audio/*.wav.
## Tudo sintetizado aqui: sem arquivos de terceiros nem licenças.
## Os efeitos são montados em CAMADAS (transiente + corpo + grave + cauda) para soar
## mais encorpados, e os mais frequentes têm 3 variações (nome_1..3) contra repetição.
## Uso: godot --headless --path . --script res://tools/gen_audio.gd

const RATE := 44100
const OUT_DIR := "res://audio"
const VARIANTS := 3

# Música
const BARS := 8


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	seed(1337)
	_save("music_lofi_calma", _lofi(78.0, CALM_CHORDS, CALM_MELODY, false))
	seed(4242)
	_save("music", _lofi(90.0, GAME_CHORDS, GAME_MELODY, true))
	seed(666)
	_save("music_boss", _boss_music())
	seed(2026)
	_save("music_sector2", _lofi(96.0, SECTOR2_CHORDS, SECTOR2_MELODY, true))
	seed(3033)
	_save("music_sector3", _lofi(84.0, SECTOR3_CHORDS, SECTOR3_MELODY, false))
	seed(4044)
	_save("music_sector4", _lofi(100.0, SECTOR4_CHORDS, SECTOR4_MELODY, true))
	seed(5055)
	_save("music_sector5", _lofi(88.0, SECTOR5_CHORDS, SECTOR5_MELODY, false, true))

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

## "Calma" (guardada, music_lofi_calma.wav): 78 BPM, Fmaj7 · Em7 · Dm9 · Cmaj7.
const CALM_CHORDS := [
	[53, 57, 60, 64],      # Fmaj7
	[52, 55, 59, 62],      # Em7
	[50, 53, 57, 60, 64],  # Dm9
	[48, 52, 55, 59],      # Cmaj7
]
# Melodias em colcheias (16 = 2 compassos): -1 = pausa.
const CALM_MELODY := [
	[-1, 72, -1, -1, 69, -1, 67, -1, -1, -1, 69, -1, -1, -1, -1, -1],
	[-1, -1, 76, -1, 74, -1, -1, 72, -1, -1, -1, -1, 69, -1, -1, -1],
	[-1, 69, -1, 72, -1, -1, 74, -1, -1, 72, -1, -1, -1, -1, -1, -1],
	[-1, -1, 67, -1, 69, -1, -1, -1, 72, -1, 69, -1, -1, -1, -1, -1],
]

## Trilha do jogo (music.wav): 90 BPM, ii–V–I–vi em Dó: Dm9 · G9 · Cmaj9 · Am7.
const GAME_CHORDS := [
	[50, 53, 57, 60, 64],  # Dm9
	[55, 59, 62, 65, 69],  # G9
	[48, 52, 55, 59, 62],  # Cmaj9
	[57, 60, 64, 67],      # Am7
]
const GAME_MELODY := [
	[76, -1, -1, 74, -1, 72, -1, -1, 74, -1, 76, -1, -1, -1, 79, -1],
	[-1, -1, 77, -1, 76, -1, 74, -1, -1, -1, 72, -1, 74, -1, -1, -1],
	[72, -1, -1, 76, -1, 79, -1, -1, 81, -1, 79, -1, -1, 76, -1, -1],
	[-1, 76, -1, 74, -1, -1, 72, -1, -1, 69, -1, -1, 72, -1, -1, -1],
]


## Setor 2 (music_sector2.wav): 96 BPM, Mi menor mais "metálico": Em9 · Cmaj7 · Am9 · B7.
const SECTOR2_CHORDS := [
	[52, 55, 59, 62, 66],  # Em9
	[48, 52, 55, 59],      # Cmaj7
	[45, 48, 52, 55, 59],  # Am9
	[47, 51, 54, 57],      # B7 (dominante: puxa de volta para Mi)
]
const SECTOR2_MELODY := [
	[71, -1, 74, -1, -1, 71, -1, 69, -1, -1, 67, -1, 64, -1, -1, -1],
	[-1, 67, -1, 71, -1, -1, 72, -1, 71, -1, -1, 67, -1, -1, -1, -1],
	[69, -1, -1, 72, -1, 76, -1, -1, 74, -1, 72, -1, -1, 69, -1, -1],
	[-1, 71, -1, 75, -1, -1, 74, -1, -1, 71, -1, -1, 69, -1, -1, -1],
]


## Setor 3 (music_sector3.wav): 84 BPM, etéreo/sonhador em Ré: Dmaj7 · Bm9 · Gmaj7 · A6.
const SECTOR3_CHORDS := [
	[50, 54, 57, 61],      # Dmaj7
	[47, 50, 54, 57, 61],  # Bm9
	[43, 47, 50, 54],      # Gmaj7
	[45, 49, 52, 54],      # A6
]
const SECTOR3_MELODY := [
	[-1, 78, -1, -1, 76, -1, -1, 73, -1, -1, -1, -1, 71, -1, -1, -1],
	[-1, -1, 74, -1, -1, 76, -1, -1, 78, -1, -1, -1, -1, -1, -1, -1],
	[81, -1, -1, -1, 78, -1, -1, 76, -1, -1, 74, -1, -1, -1, -1, -1],
	[-1, -1, 73, -1, -1, 71, -1, -1, 69, -1, -1, -1, 73, -1, -1, -1],
]


## Setor 4 (music_sector4.wav): 100 BPM, Dó menor mais "marcial": Cm9 · A♭maj7 · Fm9 · G7.
const SECTOR4_CHORDS := [
	[48, 51, 55, 58, 62],  # Cm9
	[44, 48, 51, 55],      # Abmaj7
	[41, 44, 48, 51, 55],  # Fm9
	[43, 47, 50, 53],      # G7
]
const SECTOR4_MELODY := [
	[72, -1, -1, 70, -1, 67, -1, -1, 70, -1, -1, 72, -1, -1, -1, -1],
	[-1, 75, -1, -1, 74, -1, 72, -1, -1, 70, -1, -1, 67, -1, -1, -1],
	[68, -1, -1, 72, -1, 75, -1, -1, 77, -1, 75, -1, -1, 72, -1, -1],
	[-1, 71, -1, 74, -1, -1, 77, -1, -1, 74, -1, -1, 71, -1, -1, -1],
]


## Setor 5 (music_sector5.wav): 88 BPM, cristalino em Mi: Emaj9 · C#m11 · Amaj7 · B6 + sinos.
const SECTOR5_CHORDS := [
	[52, 56, 59, 63, 66],  # Emaj9
	[49, 52, 56, 59, 66],  # C#m11 (sem a 9ª)
	[45, 49, 52, 56],      # Amaj7
	[47, 51, 54, 56],      # B6
]
const SECTOR5_MELODY := [
	[-1, 80, -1, -1, 83, -1, -1, 80, -1, 78, -1, -1, -1, -1, 75, -1],
	[76, -1, -1, 78, -1, -1, 80, -1, -1, -1, 76, -1, -1, -1, -1, -1],
	[-1, -1, 81, -1, 80, -1, -1, 76, -1, -1, 73, -1, -1, 76, -1, -1],
	[78, -1, -1, -1, 75, -1, -1, 78, -1, 80, -1, -1, -1, -1, -1, -1],
]


## Loop lofi de 8 compassos com swing (2 compassos por acorde).
## Piano elétrico suave, baixo redondo, melodia esparsa, bateria abafada, chiado de vinil
## e um filtro passa-baixa no fim para soar "quente". As caudas dão a volta no buffer,
## então o loop emenda sem clique. `drive`: bumbo extra no "e" do 4 (mais embalo).
## `bells`: sinos cristalinos dobram a melodia uma oitava acima (Setor 5, gelo).
func _lofi(bpm: float, chords: Array, melody: Array, drive: bool, bells := false) -> PackedFloat32Array:
	var beat := 60.0 / bpm
	var bar := beat * 4.0
	var n := int(round(bar * BARS * RATE))
	var out := _buf(n)

	for b in BARS:
		var chord: Array = chords[(b / 2) % chords.size()]
		var bar_start := b * bar

		# Acordes: "dedilhado" lento no tempo 1 e um toque mais leve no "e" do 3.
		for hit: Array in [[0.0, 0.42], [2.5, 0.22]]:
			for ni in chord.size():
				var at: float = bar_start + float(hit[0]) * beat + ni * 0.018
				_mix(out, _at(at), _ep_note(_midi(chord[ni]), beat * 2.2), float(hit[1]) * 0.55)

		# Baixo: tônica no 1 e no "e" do 2, uma oitava abaixo.
		var root: int = chord[0] - 12
		_mix(out, _at(bar_start), _sub_bass(_midi(root), beat * 1.4), 0.55)
		_mix(out, _at(bar_start + 1.5 * beat), _sub_bass(_midi(root), beat * 0.9), 0.4)

		# Melodia (só nos compassos pares de cada acorde, para respirar).
		if b % 2 == 0:
			var line: Array = melody[(b / 2) % melody.size()]
			for e in line.size():
				if line[e] >= 0:
					_mix(out, _at(bar_start + _swing(e) * beat), _ep_note(_midi(line[e]), beat * 1.2), 0.28)
					if bells:
						_mix(out, _at(bar_start + _swing(e) * beat), _bell(_midi(line[e] + 12), beat * 2.5), 0.14)
		# Sinos: um brilho agudo do acorde no "e" do 4 de todo compasso.
		if bells:
			_mix(out, _at(bar_start + 3.5 * beat), _bell(_midi(chord[chord.size() - 1] + 24), beat * 2.0), 0.08)

		# Bateria preguiçosa: bumbo no 1 e no "e" do 2, caixa no 2 e no 4, chimbal em colcheias com swing.
		_mix(out, _at(bar_start), _lofi_kick(), 0.75)
		_mix(out, _at(bar_start + 1.5 * beat), _lofi_kick(), 0.5)
		if drive:
			_mix(out, _at(bar_start + (3.0 + 0.62) * beat), _lofi_kick(), 0.4)
		_mix(out, _at(bar_start + 1.0 * beat), _lofi_snare(), 0.45)
		_mix(out, _at(bar_start + 3.0 * beat), _lofi_snare(), 0.45)
		for e in 8:
			_mix(out, _at(bar_start + _swing(e) * beat), _lofi_hat(), 0.16 if e % 2 == 0 else 0.1)

	# Vinil: chiado constante + estalos raros.
	var hiss_low := 0.0
	for i in n:
		hiss_low += 0.2 * (randf_range(-1.0, 1.0) - hiss_low)
		out[i] += hiss_low * 0.025
		if randf() < 0.00012:
			out[i] += randf_range(-0.35, 0.35)

	# Passa-baixa "quente" (~3,5 kHz). Duas voltas no buffer para o filtro emendar no loop.
	var a := 1.0 - exp(-TAU * 3500.0 / RATE)
	var y := 0.0
	for lap in 2:
		for i in n:
			y += a * (out[i] - y)
			if lap == 1:
				out[i] = y

	var peak := 0.0
	for i in n:
		peak = maxf(peak, absf(out[i]))
	var gain := 0.85 / maxf(peak, 0.001)
	for i in n:
		out[i] = _soft(out[i] * gain)
	return out


## Posição (em tempos) da colcheia `e` com swing: as do contratempo atrasam um pouco.
func _swing(e: int) -> float:
	return floor(e / 2.0) + (0.62 if e % 2 == 1 else 0.0)


func _at(seconds: float) -> int:
	return int(round(seconds * RATE))


## Piano elétrico: senoide com harmônicos curtos (ataque de sino) + tremolo lento.
func _ep_note(freq: float, duration: float) -> PackedFloat32Array:
	var n := _len(duration)
	var out := _buf(n)
	for i in n:
		var t := float(i) / RATE
		var ph := TAU * freq * t
		var tone := sin(ph) + 0.3 * sin(ph * 2.0) * exp(-t * 4.0) + 0.12 * sin(ph * 3.0) * exp(-t * 8.0)
		var tremolo := 1.0 + 0.12 * sin(TAU * 4.5 * t)
		var env := minf(1.0, t * 200.0) * exp(-t * 1.6) * (1.0 - smoothstep(0.85, 1.0, float(i) / n))
		out[i] = tone * tremolo * env
	return out


## Sino de vidro/gelo: parciais inarmônicas (como um sino de verdade) com ataque seco.
func _bell(freq: float, duration: float) -> PackedFloat32Array:
	var n := _len(duration)
	var out := _buf(n)
	for i in n:
		var t := float(i) / RATE
		var ph := TAU * freq * t
		var tone := sin(ph) + 0.5 * sin(ph * 2.76) * exp(-t * 3.0) + 0.25 * sin(ph * 5.4) * exp(-t * 6.0)
		out[i] = tone * minf(1.0, t * 400.0) * exp(-t * 2.2) * (1.0 - smoothstep(0.85, 1.0, float(i) / n))
	return out


func _sub_bass(freq: float, duration: float) -> PackedFloat32Array:
	var n := _len(duration)
	var out := _buf(n)
	for i in n:
		var t := float(i) / RATE
		var k := float(i) / n
		out[i] = (sin(TAU * freq * t) + 0.2 * sin(TAU * freq * 2.0 * t)) * minf(1.0, t * 150.0) * (1.0 - k) * exp(-t * 1.2)
	return out


func _lofi_kick() -> PackedFloat32Array:
	var n := _len(0.35)
	var out := _buf(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		phase += (48.0 + 70.0 * exp(-t * 25.0)) / RATE
		out[i] = sin(phase * TAU) * exp(-t * 8.0)
	return out


func _lofi_snare() -> PackedFloat32Array:
	var n := _len(0.22)
	var out := _buf(n)
	var low := 0.0
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		low += 0.18 * (randf_range(-1.0, 1.0) - low)  # ruído abafado
		phase += 180.0 / RATE
		out[i] = low * 1.8 * exp(-t * 16.0) + sin(phase * TAU) * 0.35 * exp(-t * 35.0)
	return out


func _lofi_hat() -> PackedFloat32Array:
	var n := _len(0.05)
	var out := _buf(n)
	var low := 0.0
	for i in n:
		var noise := randf_range(-1.0, 1.0)
		low += 0.45 * (noise - low)
		out[i] = (noise - low) * exp(-float(i) / n * 7.0) * 0.7
	return out


# ---------------------------------------------------------------- música de chefe

const BOSS_BPM := 112.0
const BOSS_ROOTS := [38, 38, 34, 33]  # Ré, Ré, Si♭, Lá (graves) — i · i · VI · V em Ré menor


## Tema de chefe (8 compassos em loop): drone grave, baixo pulsante em semicolcheias com
## meio-tom "frígio" de tensão, acordes dissonantes (menor + segunda menor), cordas em
## tremolo que crescem na 2ª metade, bateria pesada e virada de tons a cada 4 compassos.
func _boss_music() -> PackedFloat32Array:
	var beat := 60.0 / BOSS_BPM
	var bar := beat * 4.0
	var n := int(round(bar * BARS * RATE))
	var out := _buf(n)
	for b in BARS:
		var root: int = BOSS_ROOTS[(b / 2) % BOSS_ROOTS.size()]
		var bs := b * bar

		if b % 2 == 0:
			_mix(out, _at(bs), _drone(_midi(root - 12), bar * 2.0), 0.55)

		for s in 16:
			var note := root
			if s == 14:
				note = root + 1  # meio-tom acima: o "arrepio" frígio
			elif s % 8 == 6:
				note = root + 12
			_mix(out, _at(bs + s * beat / 4.0), _pulse_bass(_midi(note), beat / 4.0 * 0.9), 0.3 if s % 4 == 0 else 0.2)

		var stab := [root + 24, root + 27, root + 31, root + 25]  # tônica, 3ª menor, 5ª, 2ª menor
		for at_beat: float in [0.0, 1.5]:
			for nn: int in stab:
				_mix(out, _at(bs + at_beat * beat), _stab(_midi(nn), beat * 0.6), 0.08)

		if b >= 4:
			for nn: int in [root + 36, root + 39]:
				_mix(out, _at(bs), _tremolo_strings(_midi(nn), bar), 0.04 + 0.02 * (b - 4))

		for kb: float in [0.0, 1.5, 2.0, 3.5]:
			_mix(out, _at(bs + kb * beat), _heavy_kick(), 0.8)
		for sb: float in [1.0, 3.0]:
			_mix(out, _at(bs + sb * beat), _heavy_snare(), 0.5)
		for h in 16:
			_mix(out, _at(bs + h * beat / 4.0), _boss_hat(), 0.1 if h % 2 == 0 else 0.06)
		if b % 4 == 3:
			for t in 4:
				_mix(out, _at(bs + (3.0 + t * 0.25) * beat), _tom(_midi(45 - t * 3)), 0.45)

	# Filtro escuro (~5 kHz), duas voltas para emendar o loop; normaliza.
	var a := 1.0 - exp(-TAU * 5000.0 / RATE)
	var y := 0.0
	for lap in 2:
		for i in n:
			y += a * (out[i] - y)
			if lap == 1:
				out[i] = y
	var peak := 0.0
	for i in n:
		peak = maxf(peak, absf(out[i]))
	var gain := 0.9 / maxf(peak, 0.001)
	for i in n:
		out[i] = _soft(out[i] * gain)
	return out


## Drone: serrotes desafinados + grave, filtro abrindo e fechando devagar.
func _drone(freq: float, duration: float) -> PackedFloat32Array:
	var n := _len(duration)
	var out := _buf(n)
	var p1 := 0.0
	var p2 := 0.0
	var low := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := float(i) / n
		p1 += freq * 1.006 / RATE
		p2 += freq * 0.994 / RATE
		var cutoff := 0.012 + 0.025 * (0.5 + 0.5 * sin(TAU * 0.25 * t))
		low += cutoff * ((_saw(p1) + _saw(p2)) * 0.5 - low)
		var env := smoothstep(0.0, 0.1, k) * (1.0 - smoothstep(0.85, 1.0, k))
		out[i] = (low * 1.6 + sin(TAU * freq * 0.5 * t) * 0.4) * env
	return out


func _pulse_bass(freq: float, duration: float) -> PackedFloat32Array:
	var n := _len(duration)
	var out := _buf(n)
	var phase := 0.0
	var low := 0.0
	for i in n:
		var t := float(i) / RATE
		phase += freq / RATE
		low += 0.15 * (_saw(phase) - low)
		out[i] = low * minf(1.0, t * 400.0) * exp(-t * 14.0)
	return out


## Acorde "metálico" curto: serrotes com filtro que fecha (como metais).
func _stab(freq: float, duration: float) -> PackedFloat32Array:
	var n := _len(duration)
	var out := _buf(n)
	var phases := [0.0, 0.0, 0.0]
	var detune := [1.0, 1.007, 0.993]
	var low := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := float(i) / n
		var s := 0.0
		for j in 3:
			phases[j] += freq * detune[j] / RATE
			s += _saw(phases[j])
		low += lerpf(0.3, 0.04, k) * (s / 3.0 - low)
		out[i] = low * minf(1.0, t * 200.0) * exp(-t * 6.0)
	return out


func _tremolo_strings(freq: float, duration: float) -> PackedFloat32Array:
	var n := _len(duration)
	var out := _buf(n)
	var p1 := 0.0
	var p2 := 0.0
	var low := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := float(i) / n
		p1 += freq * 1.004 / RATE
		p2 += freq * 0.996 / RATE
		low += 0.12 * ((_saw(p1) + _saw(p2)) * 0.5 - low)
		var trem := 0.6 + 0.4 * sin(TAU * 9.0 * t)
		out[i] = low * trem * smoothstep(0.0, 0.3, k) * (1.0 - smoothstep(0.9, 1.0, k))
	return out


func _heavy_kick() -> PackedFloat32Array:
	var n := _len(0.4)
	var out := _buf(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		phase += (40.0 + 120.0 * exp(-t * 28.0)) / RATE
		var click := randf_range(-1.0, 1.0) * exp(-t * 300.0) * 0.3
		out[i] = _soft((sin(phase * TAU) * exp(-t * 7.0) + click) * 1.4)
	return out


func _heavy_snare() -> PackedFloat32Array:
	var n := _len(0.35)
	var out := _buf(n)
	var low := 0.0
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var noise := randf_range(-1.0, 1.0)
		low += 0.35 * (noise - low)
		phase += 200.0 / RATE
		out[i] = (noise - low * 0.5) * 0.9 * exp(-t * 11.0) + sin(phase * TAU) * 0.5 * exp(-t * 25.0)
	return out


func _boss_hat() -> PackedFloat32Array:
	var n := _len(0.035)
	var out := _buf(n)
	var low := 0.0
	for i in n:
		var noise := randf_range(-1.0, 1.0)
		low += 0.55 * (noise - low)
		out[i] = (noise - low) * exp(-float(i) / n * 6.0)
	return out


func _tom(freq: float) -> PackedFloat32Array:
	var n := _len(0.3)
	var out := _buf(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		phase += freq * (1.0 + 0.5 * exp(-t * 20.0)) / RATE
		out[i] = sin(phase * TAU) * exp(-t * 10.0)
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
