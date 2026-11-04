class_name Palette
extends RefCounted
## Cores do protótipo (estética neon).

const NEON := Color(0.25, 0.94, 1.0)
const NEON_DARK := Color(0.03, 0.1, 0.2)
const MAGENTA := Color(1.0, 0.3, 0.85)
const DANGER := Color(1.0, 0.22, 0.28)
const FLAME := Color(1.0, 0.55, 0.15)
const DUST_FILL := Color(0.42, 0.42, 0.46)
const DUST_LINE := Color(0.75, 0.75, 0.8)
const METAL_FILL := Color(0.1, 0.11, 0.15)
const METAL_LINE := Color(0.45, 0.55, 0.7)
const TEXT_DIM := Color(1, 1, 1, 0.55)

# Versões HDR (> 1.0): só estas cores "acendem" o glow do WorldEnvironment.
const NEON_HDR := Color(0.5, 1.9, 2.1)
const MAGENTA_HDR := Color(2.0, 0.6, 1.7)
const FLAME_HDR := Color(2.2, 1.1, 0.3)
const DANGER_HDR := Color(2.2, 0.4, 0.5)
const WHITE_HDR := Color(2.0, 2.0, 2.0)
const BLAST_HDR := Color(2.4, 2.0, 1.4)

# Inimigos e perigos: vermelho/laranja, sempre com forma própria (não só cor).
const ENEMY := Color(1.0, 0.35, 0.2)
const ENEMY_HDR := Color(2.4, 0.7, 0.3)
const ENEMY_FILL := Color(0.18, 0.04, 0.04)

# Setor 3 (iônico): violeta elétrico.
const ION := Color(0.72, 0.45, 1.0)
const ION_HDR := Color(1.4, 0.8, 2.4)
