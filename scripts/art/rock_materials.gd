class_name RockMaterials
extends RefCounted
## Materiais dos asteroides 2.5D (PLANO_ARTE_25D.md, A1) e quais aparecem em cada setor.
## Os valores vão para shaders/asteroid.gdshader (um índice por rocha, lido do vértice).
## Regra de leitura: poeira destrutível é sempre CLARA o bastante para não parecer o metal escuro.

enum { ROCHOSO, FERROSO, CARBONACEO, GELO, CRISTALINO, POMES, VULCANICO }

## [nome, cor clara, cor escura, cor da borda, cor da emissão, crateras, relevo, poros,
##  especular, translucidez, emissão, cor da explosão]
const TABLE := [
	["ROCHOSO", Color(0.78, 0.78, 0.82), Color(0.30, 0.30, 0.34), Color(0.85, 0.88, 1.0), Color(1, 0.5, 0.1), 0.7, 0.5, 0.0, 0.0, 0.0, 0.0, Color(0.62, 0.62, 0.66)],
	["FERROSO", Color(0.86, 0.6, 0.46), Color(0.36, 0.2, 0.14), Color(1.0, 0.85, 0.7), Color(1, 0.5, 0.1), 0.4, 0.4, 0.0, 0.6, 0.0, 0.0, Color(0.7, 0.45, 0.32)],
	["CARBONÁCEO", Color(0.58, 0.55, 0.56), Color(0.18, 0.17, 0.18), Color(1.0, 0.95, 0.85), Color(1, 0.5, 0.1), 0.5, 0.7, 0.4, 0.0, 0.0, 0.0, Color(0.45, 0.43, 0.43)],
	["GELO", Color(0.88, 0.96, 1.0), Color(0.4, 0.6, 0.82), Color(0.9, 1.0, 1.0), Color(0.6, 0.9, 1.0), 0.2, 0.25, 0.0, 1.0, 0.8, 0.0, Color(0.75, 0.9, 1.0)],
	["CRISTALINO", Color(0.72, 0.64, 0.88), Color(0.28, 0.2, 0.4), Color(0.9, 0.85, 1.0), Color(0.7, 0.4, 1.0), 0.3, 0.45, 0.0, 0.3, 0.0, 1.0, Color(0.65, 0.5, 0.9)],
	["PEDRA-POMES", Color(0.94, 0.9, 0.82), Color(0.6, 0.55, 0.5), Color(1.0, 0.98, 0.92), Color(1, 0.5, 0.1), 0.2, 0.3, 0.9, 0.0, 0.0, 0.0, Color(0.85, 0.8, 0.72)],
	["VULCÂNICO", Color(0.5, 0.42, 0.4), Color(0.14, 0.09, 0.08), Color(1.0, 0.8, 0.6), Color(1.0, 0.4, 0.08), 0.4, 0.6, 0.0, 0.0, 0.0, 1.0, Color(0.55, 0.3, 0.2)],
]

## Materiais da poeira em cada setor (índice do setor 0..7), sorteados por rocha.
const BY_SECTOR := [
	[ROCHOSO, ROCHOSO, POMES],             # 1 Cinturão
	[FERROSO, FERROSO, ROCHOSO],           # 2 Campo Metálico
	[CARBONACEO, CRISTALINO, CRISTALINO],  # 3 Nebulosa
	[ROCHOSO, FERROSO],                    # 4 Destroços
	[GELO, ROCHOSO, POMES],                # 5 Anel Glacial
	[POMES, FERROSO],                      # 6 Colmeia
	[ROCHOSO, FERROSO, CARBONACEO],        # 7 Estação
	[CARBONACEO, VULCANICO, VULCANICO],    # 8 Fenda
]


static func pick(sector: int) -> int:
	var list: Array = BY_SECTOR[clampi(sector, 0, BY_SECTOR.size() - 1)]
	return list[randi() % list.size()]


## Parâmetros em vetores para o shader (arrays por material).
static func shader_arrays() -> Dictionary:
	var light := PackedVector3Array()
	var dark := PackedVector3Array()
	var rim := PackedVector3Array()
	var emis := PackedVector3Array()
	var p1 := PackedVector4Array()
	var p2 := PackedVector4Array()
	for m in TABLE:
		light.append(_v(m[1]))
		dark.append(_v(m[2]))
		rim.append(_v(m[3]))
		emis.append(_v(m[4]))
		p1.append(Vector4(m[5], m[6], m[7], m[8]))  # crateras, relevo, poros, especular
		p2.append(Vector4(m[9], m[10], 0.0, 0.0))    # translucidez, emissão
	return {"m_light": light, "m_dark": dark, "m_rim": rim, "m_emission_color": emis, "m_p1": p1, "m_p2": p2}


static func debris_color(mat: int) -> Color:
	return TABLE[clampi(mat, 0, TABLE.size() - 1)][11]


static func _v(c: Color) -> Vector3:
	return Vector3(c.r, c.g, c.b)
