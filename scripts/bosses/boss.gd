class_name Boss
extends Node2D
## Base dos chefes: vida, fases, estados e a interface que o Main usa
## (tiro acertou núcleo ou armadura? encostou na nave? onde mirar?).
## Cada chefe herda daqui e implementa seus padrões. Coordenadas sempre de MUNDO
## (o nó fica na origem; cada chefe guarda o próprio centro).
##
## Regras de design (PLANO_V2.md, 2.1): todo ataque é avisado antes (TelegraphLayer),
## sempre existe rota segura, e só os núcleos (pontos fracos) levam dano.

signal defeated                 ## fim da animação de morte: pode encerrar o setor
signal phase_changed(phase: int)

enum State { ENTERING, FIGHT, TRANSITION, DYING, DONE }
enum Hit { NONE, ARMOR, CORE }

var display_name := "CHEFE"
var max_hp := 100
var hp := 100.0  # aceita frações: o dano do tiro depende do tipo de arma
var phase := 1
var state := State.ENTERING
var view_size := Vector2.ZERO

var shots: EnemyBulletLayer
var telegraph: TelegraphLayer
var asteroids: AsteroidField
var fx: FxLayer
## Chamado com a intensidade do tremor (o Main liga ao seu screen shake).
var impact: Callable = func(_amount: float) -> void: pass

var _t := 0.0
var _flash := 0.0
var _state_t := 0.0


func setup(size: Vector2, shot_layer: EnemyBulletLayer, telegraph_layer: TelegraphLayer,
		asteroid_field: AsteroidField, fx_layer: FxLayer) -> void:
	view_size = size
	shots = shot_layer
	telegraph = telegraph_layer
	asteroids = asteroid_field
	fx = fx_layer
	hp = max_hp
	_enter()


func hp_ratio() -> float:
	return clampf(float(hp) / float(max_hp), 0.0, 1.0)


func is_vulnerable() -> bool:
	return state == State.FIGHT


func update(dt: float, ship_pos: Vector2) -> void:
	_t += dt
	_state_t += dt
	_flash = maxf(0.0, _flash - dt)
	_update_boss(dt, ship_pos)
	queue_redraw()


## Dano num núcleo. O Main só chama quando hit_bullet() devolveu Hit.CORE.
func damage(amount: float) -> void:
	if not is_vulnerable():
		return
	hp = maxf(0.0, hp - amount)
	_flash = 0.06
	if hp <= 0.0:
		_set_state(State.DYING)
	else:
		_on_damaged()


func _set_state(new_state: State) -> void:
	state = new_state
	_state_t = 0.0


# ---- implementados por cada chefe ----

## Começo da entrada em cena.
func _enter() -> void:
	pass


func _update_boss(_dt: float, _ship_pos: Vector2) -> void:
	pass


## Depois de levar dano (ex.: checar se muda de fase).
func _on_damaged() -> void:
	pass


## O tiro em `p` acertou o quê?
func hit_bullet(_p: Vector2) -> Hit:
	return Hit.NONE


## O corpo do chefe encosta num círculo (nave)?
func touches(_p: Vector2, _radius: float) -> bool:
	return false


## Algum feixe do chefe (laser, parede de energia) atinge o círculo agora? Dano de feixe,
## menor que encostar no corpo.
func beam_hits(_p: Vector2, _radius: float) -> bool:
	return false


## X do ponto fraco exposto agora (usado pelo teste automático para "jogar").
func aim_x() -> float:
	return view_size.x * 0.5


## Explosões de área que aconteceram neste passo: (x, y, raio). O Main checa a nave.
func take_blasts() -> Array[Vector3]:
	return []


## Ponto fraco ABERTO desenhado por cima da arte (olho, coração, joia): halo + brilho translúcido +
## anel pulsando. A arte continua aparecendo por baixo e a região passa do limiar do glow.
func _weak_glow(pos: Vector2, radius: float, color := Palette.BLAST_HDR) -> void:
	var pulse := 0.85 + 0.15 * sin(_t * 8.0)
	# Brilho fraco (passa pouco do limiar do glow): a arte do ponto fraco continua visível.
	var soft := Color(color.r * 0.55, color.g * 0.55, color.b * 0.55)
	draw_circle(pos, radius * 1.4, Color(Palette.ENEMY, 0.12))
	draw_circle(pos, radius * 0.9 * pulse, Color(soft, 0.16 if _flash <= 0.0 else 0.5))
	draw_arc(pos, radius * pulse, 0.0, TAU, 40, Color(soft, 0.9), 3.0, true)


## Peça de arte centrada em `pos`, com `size` = lado maior na tela (mantém a proporção).
func _draw_part(tex: Texture2D, pos: Vector2, size: float, angle := 0.0, tint := Color.WHITE,
		flip := false) -> void:
	var w := float(tex.get_width())
	var h := float(tex.get_height())
	var k := size / maxf(w, h)
	draw_set_transform(pos, angle, Vector2(-k if flip else k, k))
	draw_texture(tex, Vector2(-w, -h) * 0.5, tint)
	draw_set_transform(Vector2.ZERO, 0.0)
