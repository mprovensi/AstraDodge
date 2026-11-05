class_name Weapons
extends RefCounted
## Tipos de arma (PLANO_ARMA.md, versão 2). Cada tipo define, por degrau do padrão (1–4),
## os tiros de um disparo e o intervalo entre disparos. A potência (por setor) multiplica o dano.

const PULSE := "pulse"
const LASER := "laser"
const SPREAD := "spread"
const MISSILE := "missile"
const ALL := [PULSE, LASER, SPREAD, MISSILE]

## Cada tiro: [deslocamento x, ângulo em graus, perfura].
const DATA := {
	PULSE: {
		"name": "PULSO", "tag": "EQUILIBRADA", "color": Color(0.25, 0.94, 1.0),
		"desc": "Tiros retos que viram leque",
		"damage": 1.0, "speed": 1.0,
		"interval": [0.0, 0.28, 0.28, 0.28, 0.26],
		"shots": [[], [[0, 0, false]],
			[[-16, 0, false], [16, 0, false]],
			[[-16, 0, false], [16, 0, false], [0, -10, false], [0, 10, false]],
			[[-20, 0, false], [0, 0, false], [20, 0, false], [0, -10, false], [0, 10, false]]],
	},
	LASER: {
		"name": "LASER", "tag": "FOCO", "color": Color(1.0, 0.3, 0.85),
		"desc": "Feixes rápidos que atravessam tudo",
		"damage": 0.8, "speed": 1.4,
		"interval": [0.0, 0.26, 0.28, 0.28, 0.26],
		"shots": [[], [[0, 0, true]],
			[[-10, 0, true], [10, 0, true]],
			[[-14, 0, true], [0, 0, true], [14, 0, true]],
			[[-21, 0, true], [-7, 0, true], [7, 0, true], [21, 0, true]]],
	},
	SPREAD: {
		"name": "DISPERSÃO", "tag": "MULTIDÃO", "color": Color(0.45, 1.0, 0.5),
		"desc": "Leque largo que limpa a tela (fraco no chefe)",
		"damage": 0.6, "speed": 0.9,
		"interval": [0.0, 0.34, 0.32, 0.30, 0.30],
		"shots": [[], [[0, -12, false], [0, 0, false], [0, 12, false]],
			[[0, -15, false], [0, -5, false], [0, 5, false], [0, 15, false]],
			[[0, -20, false], [0, -10, false], [0, 0, false], [0, 10, false], [0, 20, false]],
			[[0, -30, false], [0, -20, false], [0, -10, false], [0, 0, false], [0, 10, false],
				[0, 20, false], [0, 30, false]]],
	},
	MISSILE: {
		"name": "MÍSSIL", "tag": "PESADA", "color": Color(1.0, 0.6, 0.2),
		"desc": "Lento e forte, persegue o alvo",
		"damage": 2.0, "speed": 0.55,
		"interval": [0.0, 0.55, 0.55, 0.42, 0.40],
		"shots": [[], [[0, 0, false]],
			[[-14, -8, false], [14, 8, false]],
			[[-14, -8, false], [14, 8, false]],
			[[-18, -8, false], [0, 0, false], [18, 8, false]]],
	},
}


static func valid(type: String) -> String:
	return type if DATA.has(type) else PULSE


static func info(type: String) -> Dictionary:
	return DATA[valid(type)]


static func interval(type: String, level: int) -> float:
	return info(type).interval[clampi(level, 1, Tuning.PATTERN_MAX)]


static func shots(type: String, level: int) -> Array:
	return info(type).shots[clampi(level, 1, Tuning.PATTERN_MAX)]


## Dano base por segundo num alvo à frente (tiros com ângulo pequeno acertam de perto).
static func dps(type: String, level: int) -> float:
	var hits := 0.0
	for s: Array in shots(type, level):
		hits += 1.0 if absf(float(s[1])) <= 10.0 else 0.4
	return hits * float(info(type).damage) / interval(type, level)


## Potência (multiplicador de dano) do setor vencido / tempo de partida.
static func power(step: int) -> float:
	return Tuning.WEAPON_POWER[clampi(step, 0, Tuning.WEAPON_POWER.size() - 1)]
