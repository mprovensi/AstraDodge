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

# --- Tranco ao quebrar asteroide (diferente do tremor caótico de ser atingido) ---
const KICK_BASE := 260.0          # velocidade inicial do tranco (px/s)
const KICK_PER_RADIUS := 5.0      # asteroides maiores dão tranco maior
const KICK_STIFFNESS := 900.0     # mola que traz a tela de volta (≈ 5 Hz)
const KICK_DAMPING := 28.0        # amortecimento: 1–2 balanços e para
const KICK_VIBRATE_MS := 15       # vibração bem curta (ser atingido usa 60 ms)
const KICK_MAX := 30.0            # deslocamento máximo da tela pelo tranco (px)
const KICK_MAX_STEP := 1.0 / 120.0  # passo máximo da conta da mola (estabilidade)

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
const CORRIDOR_INTERVAL := 0.9           # s entre as paredes de um corredor
const CORRIDOR_SHIFT := 110.0            # quanto a brecha anda de uma parede para a próxima
const MOVING_METAL_SPEED_MIN := 140.0    # metálico com propulsor (Setor 2)
const MOVING_METAL_SPEED_MAX := 210.0
const ARMOR_SHELL_HITS := 2              # tiros para arrancar a casca da poeira blindada

# --- Setor 3: Nebulosa Iônica ---
const ION_DRAIN_MULT := 3.0        # dentro de uma nuvem iônica o escudo drena 3x mais rápido
const CLOUD_RADIUS_MIN := 150.0
const CLOUD_RADIUS_MAX := 230.0
const CLOUD_FALL_FACTOR := 0.85    # nuvens descem um pouco mais devagar que as rochas
const STORM_WIDTH := 170.0         # largura da coluna do raio
const STORM_TELEGRAPH := 1.0       # aviso antes do raio cair
const STORM_INTERVAL := 1.15       # s entre raios durante a tempestade
const SHIELD_DMG_STORM := 25.0
const MINE_RADIUS := 34.0
const MINE_HP := 2
const MINE_TRIGGER := 190.0        # chegou mais perto que isso: a mina arma
const MINE_FUSE := 0.7             # s entre armar e explodir
const MINE_BLAST := 110.0          # raio da explosão (dano em área)
const MINE_SHOTS := 10             # tiros em anel na explosão
const MINE_SHOT_SPEED := 380.0

# --- Chefes ---
const BOSS_ALERT_TIME := 2.6       # tela "ALERTA" + sirene antes do chefe entrar
const BOSS_ALARM_BEEPS := 3
const BOSS_SCORE := 1000
const BOSS_REWARD_ORBS := 6        # chuva de orbes e cristais ao derrotar
const BOSS_REWARD_CRYSTALS := 6
const STAR_DUST_RATIO := 0.7       # 3ª estrela: destruir ≥ 70% da poeira do setor
const BOSS_SHIELD_DROP_BONUS := 0.12  # chance extra de orbe de escudo durante a luta (20% -> 32%)
const BOSS_SHIELD_DRAIN_SCALE := 0.75  # o escudo drena um pouco menos durante a luta

# --- Inimigos (base para os setores 2–5) ---
const SHIELD_DMG_ENEMY_SHOT := 12.0
const SHIELD_DMG_ENEMY_BODY := 30.0
const SCORE_PER_ENEMY := 50
const ENEMY_CRYSTAL_CHANCE := 0.6

# --- Drops ---
const DROP_SHIELD_CHANCE := 0.20
const DROP_SHIELD_CHANCE_LOW_BONUS := 0.10  # extra quando o escudo está baixo
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
