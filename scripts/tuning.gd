class_name Tuning
extends RefCounted
## Valores de balanceamento centralizados. Ajuste aqui durante os testes.

# --- Controle ---
const DRAG_SENSITIVITY_DEFAULT := 1.2
const SHIP_FOLLOW_SHARPNESS := 25.0      # quanto maior, mais "colada" ao dedo
const SHIP_MIN_Y_RATIO := 0.33           # a nave não sobe acima de 33% da altura
const SHIP_MARGIN := 60.0
const SHIP_HITBOX_RADIUS := 26.0         # menor que o desenho, para ser justo
const RELEASE_SLOWMO_SCALE := 0.3
const RELEASE_SLOWMO_TIME := 0.4         # segundos reais antes de pausar

# --- Escudo ---
const SHIELD_MAX := 100.0
const SHIELD_DRAIN_PER_SEC := 1.5
const SHIELD_DMG_DUST := 15.0
const SHIELD_DMG_METAL := 50.0
const SHIELD_ORB_VALUE := 10.0
const SHIELD_LOW_RATIO := 0.25
const HIT_INVULN_TIME := 1.0
const REVIVE_INVULN_TIME := 2.0
const REVIVE_CLEAR_RADIUS := 650.0

# --- Arma (índice = nível; índice 0 não é usado) ---
const WEAPON_START_LEVEL := 1
const WEAPON_MAX_LEVEL := 5
const WEAPON_FIRE_INTERVAL := [0.0, 0.333, 0.333, 0.2, 0.2, 0.18]
const WEAPON_CRYSTALS_TO_NEXT := [0, 4, 6, 9, 12]
const BULLET_SPEED := 2200.0
const BULLET_DAMAGE := 1
const DOUBLE_SHOT_OFFSET := 16.0
const FAN_ANGLE_DEG := 10.0
const METAL_PUSH := 22.0                 # empurrão do tiro nível 5 nos metálicos

# --- Sensação de impacto (tiro que acerta sem destruir) ---
const HIT_KNOCKBACK_DUST := 140.0        # px/s de recuo por tiro na poeira
const HIT_KNOCKBACK_METAL := 45.0        # metálicos são pesados: recuam menos
const HIT_KNOCKBACK_MAX := 260.0         # limite para não "voltar para cima" com arma forte
const HIT_KNOCKBACK_DECAY := 6.0         # quão rápido o recuo some
const HIT_PUNCH_SCALE := 0.08            # encolhida momentânea (8%)

# --- Mundo / dificuldade ---
const SCROLL_SPEED_START := 380.0
const SCROLL_SPEED_MAX := 950.0
const DIFFICULTY_TIME_CONSTANT := 100.0  # segundos para ~63% da dificuldade máxima
const FIRST_ROW_DISTANCE := 300.0
const ROW_SPACING_START := 560.0
const ROW_SPACING_END := 360.0
const SAFE_GAP_WIDTH := 260.0            # corredor sempre livre de metálicos por linha
const SAFE_GAP_MAX_SHIFT := 150.0        # deslocamento máximo do corredor entre linhas
const DUST_RAIN_DENSITY := 1.8           # linhas mais próximas durante a chuva de poeira
const WALL_METAL_RADIUS := 70.0
const WALL_TELEGRAPH_TIME := 1.4         # aviso antes do paredão aparecer
const WALL_EXTRA_SPEED := 600.0          # px/s a mais que a rolagem: o paredão avisado cai rápido

# --- Inimigos (base para os setores 2–5) ---
const SHIELD_DMG_ENEMY_SHOT := 12.0
const SHIELD_DMG_ENEMY_BODY := 30.0
const SCORE_PER_ENEMY := 50
const ENEMY_CRYSTAL_CHANCE := 0.6

# --- Drops ---
const DROP_SHIELD_CHANCE := 0.35
const DROP_SHIELD_CHANCE_LOW_BONUS := 0.15  # extra quando o escudo está baixo
const DROP_CRYSTAL_CHANCE := 0.30
const PICKUP_MAGNET_RADIUS := 170.0
const PICKUP_COLLECT_RADIUS := 60.0
const PICKUP_FALL_FACTOR := 0.6

# --- Pontuação ---
const SCORE_PER_PIXEL := 0.02
const SCORE_PER_DUST_HP := 10
const SCORE_LAST_CHANCE_SAVE := 25


## 0 no início da partida, tende a 1 com o tempo.
static func difficulty(elapsed: float) -> float:
	return 1.0 - exp(-elapsed / DIFFICULTY_TIME_CONSTANT)
