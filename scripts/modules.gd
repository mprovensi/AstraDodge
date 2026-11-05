class_name Modules
extends RefCounted
## MÓDULOS (PLANO_CARTAS.md): melhorias em formato de carta que mudam o estilo de jogo.
## Ganhos no CONTÊINER DE CARGA que os chefes derrubam (escolha 1 de 3). Mão de até MAX_HAND;
## pegar um módulo que já está na mão sobe o nível (até MAX_LEVEL).
## Esta classe é a MÃO da partida + o catálogo; o Main consulta os valores (ricochetes, ímã...).

const MAX_HAND := 3
const MAX_LEVEL := 3
const REPAIR := "reparo"  # opção extra (não fica na mão): escudo cheio

## id -> [nome, categoria, descrição por nível (I, II, III)]
const CATALOG := {
	"ricochete": ["RICOCHETE", "ARMA", ["Tiros quicam 1 vez no metal", "Tiros quicam 2 vezes", "Tiros quicam 3 vezes"]],
	"perfurante": ["PERFURANTE", "ARMA", ["Tiros atravessam 1 poeira", "Atravessam 2 poeiras", "Atravessam 3 poeiras"]],
	"ima": ["ÍMÃ", "COLETA", ["Puxa orbes e cristais de 50% mais longe", "Puxa de 2x mais longe", "Puxa de 2,5x mais longe"]],
	"medico": ["MÉDICO", "COLETA", ["Orbes recarregam +50% de escudo", "Orbes recarregam +100%", "Orbes recarregam +150%"]],
	"explosivo": ["ESCUDO EXPLOSIVO", "ESCUDO", ["Quando o escudo quebra, explode e limpa em volta", "Explosão maior", "Explosão enorme"]],
	"vidro": ["VIDRO", "RISCO", ["Dano em dobro · pontos x1,5", "Dano em dobro · pontos x1,8", "Dano em dobro · pontos x2"]],
}
const CATEGORY_COLORS := {"ARMA": Color(1.0, 0.55, 0.2), "COLETA": Color(0.3, 0.95, 1.0),
		"ESCUDO": Color(0.4, 1.0, 0.6), "RISCO": Color(1.0, 0.35, 0.45), "REPARO": Color(0.9, 0.9, 1.0)}

var hand := {}  # id -> nível (1..MAX_LEVEL)


func level(id: String) -> int:
	return int(hand.get(id, 0))


func clear() -> void:
	hand.clear()


## Cópia da mão (para o checkpoint/próximo setor).
func to_dict() -> Dictionary:
	return hand.duplicate()


func load_dict(d: Dictionary) -> void:
	hand.clear()
	for id: String in d:
		if CATALOG.has(id):
			hand[id] = clampi(int(d[id]), 1, MAX_LEVEL)


## Pega um módulo (ou sobe o nível). Retorna false se não couber.
func take(id: String) -> bool:
	if not CATALOG.has(id):
		return false
	if hand.has(id):
		if hand[id] >= MAX_LEVEL:
			return false
		hand[id] += 1
		return true
	if hand.size() >= MAX_HAND:
		return false
	hand[id] = 1
	return true


## 3 opções para o contêiner: módulos novos (se a mão tiver espaço) ou subir nível dos que já
## tem. Se faltar opção, completa com REPARO (escudo cheio) — nunca há escolha "vazia".
func offer(rng: RandomNumberGenerator) -> Array[String]:
	var pool: Array[String] = []
	for id: String in CATALOG:
		if hand.has(id):
			if hand[id] < MAX_LEVEL:
				pool.append(id)
		elif hand.size() < MAX_HAND:
			pool.append(id)
	var out: Array[String] = []
	while out.size() < 3 and not pool.is_empty():
		out.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	while out.size() < 3:
		out.append(REPAIR)
	return out


## Texto da carta: [título, categoria, descrição] do que a escolha VAI dar.
func card_text(id: String) -> Array:
	if id == REPAIR:
		return ["REPARO", "REPARO", "Escudo cheio agora"]
	var next := level(id) + 1
	var info: Array = CATALOG[id]
	var title: String = info[0] + ("" if next == 1 else " " + ["", "I", "II", "III"][next])
	return [title, info[1], info[2][next - 1]]


# ---- valores que o jogo consulta ----

func ricochets() -> int:
	return level("ricochete")


func pierces() -> int:
	return level("perfurante")


func magnet_scale() -> float:
	return [1.0, 1.5, 2.0, 2.5][level("ima")]


func heal_scale() -> float:
	return [1.0, 1.5, 2.0, 2.5][level("medico")]


func blast_radius() -> float:
	return [0.0, 320.0, 430.0, 560.0][level("explosivo")]


func damage_scale() -> float:
	return 2.0 if level("vidro") > 0 else 1.0


func score_scale() -> float:
	return [1.0, 1.5, 1.8, 2.0][level("vidro")]
