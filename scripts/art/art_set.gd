class_name ArtSet
extends Resource
## Conjunto de arte do jogo: TODAS as texturas e seus ajustes ficam aqui.
## O código nunca aponta direto para um PNG — sempre pergunta ao ArtSet ativo (Game.art).
##
## Para trocar sprites (ver README → "Trocar sprites"):
##  1. Edite o SVG em art/sprites/ e rode tools/gen_sprites.gd; ou
##  2. Substitua o PNG em sprites/ por outro com o MESMO nome; ou
##  3. Duplique data/art/default.tres, troque as texturas pelo Inspetor e
##     aponte Game.ART_SET_PATH para o novo arquivo (ex.: uma skin).
##
## Coordenadas "_px" são em pixels DA IMAGEM (origem no canto superior esquerdo do PNG):
## assim, se a arte mudar de resolução ou de desenho, basta conferir as posições no PNG.

@export_group("Nave")
@export var ship_texture: Texture2D
## Tamanho desenhado na tela (px, lado do quadrado). Não muda a colisão.
@export var ship_size := 128.0
## Multiplicador de cor: > 1 faz as partes claras do sprite passarem do limiar do glow (neon).
@export var ship_glow := Color(1.6, 1.6, 1.6)
## Centro de cada motor no PNG (uma chama por item).
@export var ship_engines_px: Array[Vector2] = []
## Ponta da nave no PNG (de onde saem os tiros).
@export var ship_muzzle_px := Vector2(128, 14)
## Pontas das asas no PNG (de onde saem os rastros de vapor nas curvas rápidas).
@export var ship_wingtips_px: Array[Vector2] = [Vector2(32, 176), Vector2(224, 176)]
## Poses de rolagem (5): [esquerda forte, esquerda, reta, direita, direita forte]. Vazio = só
## ship_texture (o jogo então inclina a imagem). Os pontos _px acima são da pose reta.
@export var ship_roll_textures: Array[Texture2D] = []

@export_group("Asteroides")
## Variações da poeira (destrutível). O jogo sorteia uma por asteroide.
@export var dust_textures: Array[Texture2D] = []
## Variações do metálico (indestrutível).
@export var metal_textures: Array[Texture2D] = []
## Fração do raio da imagem ocupada pela rocha (0,92 = a rocha vai até 92% da borda).
## Serve para casar o desenho com o raio de colisão.
@export_range(0.5, 1.0, 0.01) var dust_fill := 0.92
@export_range(0.5, 1.0, 0.01) var metal_fill := 0.94
## Casca da poeira blindada (Setor 2), desenhada por cima da rocha; centro transparente.
@export var dust_shell_texture: Texture2D
## Visual das rochas por setor (índice 0 = Setor 1). Setor sem AsteroidLook (ou com lista
## vazia) usa dust_textures/metal_textures acima. Ver PLANO_OBSTACULOS.md (O1).
@export var sector_looks: Array[AsteroidLook] = []
## Gelo (Setor 5): poeira que racha em lascas. Mesmo encaixe da poeira (dust_fill).
@export var ice_textures: Array[Texture2D] = []

@export_group("Chefes")
## Rocha-Mãe inteira (fase 1). Os núcleos são desenhados pelo código na borda.
@export var rock_mother_body: Texture2D
## Metade ESQUERDA da Rocha-Mãe rachada (fase 2); a direita é a mesma imagem espelhada.
@export var rock_mother_half: Texture2D
## Fração do raio da imagem ocupada pela rocha do chefe.
@export_range(0.5, 1.0, 0.01) var boss_fill := 0.95
## Minerador (Setor 2), frente para baixo. O olho (ponto fraco) é desenhado pelo código.
@export var miner_body: Texture2D
## Medusa (Setor 3): cúpula de plasma. Núcleo e tentáculos são desenhados pelo código.
@export var medusa_body: Texture2D
## Cruzador Fantasma (Setor 4): casco visto de cima, nariz para baixo, quadrado com a ponte no centro.
@export var cruiser_body: Texture2D
## Colosso de Gelo (Setor 5): bloco de gelo redondo. Núcleo e placas são desenhados pelo código.
@export var ice_colossus_body: Texture2D
## Rainha da Colmeia (Setor 6): inseto visto de cima, cabeça para BAIXO. Coração e guardas pelo código.
@export var hive_queen_body: Texture2D
## Sentinela (Setor 7): núcleo de IA blindado, preso ao teto. Olho, braços e drones pelo código.
@export var sentinel_body: Texture2D
## Núcleo da Fenda (Setor 8, chefe final): esfera escura com borda magenta. Núcleo e halo pelo código.
@export var rift_core_body: Texture2D
## Peças que se mexem / estados dos chefes (arte de IA, tools/gen_boss_sprites.gd), por nome
## ("rock_crystal", "miner_lid", "cruiser_turret"...). Sem a peça, o chefe desenha a forma simples.
@export var boss_parts := {}


func boss_part(name: String) -> Texture2D:
	return boss_parts.get(name) as Texture2D


## Converte um ponto do PNG da nave para coordenadas locais da nave na tela.
func ship_point(px: Vector2) -> Vector2:
	var tex_size := ship_texture.get_size()
	return (px - tex_size * 0.5) * (ship_size / tex_size.x)


## Texturas da rocha (`metal` ou poeira) para o setor `look` (índice), com o padrão como reserva.
func rock_textures(metal: bool, look: int) -> Array[Texture2D]:
	if look >= 0 and look < sector_looks.size() and sector_looks[look] != null:
		var list := sector_looks[look].metal_textures if metal else sector_looks[look].dust_textures
		if not list.is_empty():
			return list
	return metal_textures if metal else dust_textures


## Rolagem da nave: onde um x do PNG da pose reta vai parar na pose com rolagem `r` (-1..1).
## Encurta o lado para onde a nave rola (a asa "afunda") e alonga um pouco o outro.
## Usada por tools/gen_ship.gd (para desenhar as poses) e pela Ship (motores, asas).
static func roll_x(x: float, r: float) -> float:
	var dx := x - 128.0
	var sink := dx * r > 0.0
	var k := 1.0 - 0.42 * absf(r) if sink else 1.0 + 0.06 * absf(r)
	return 128.0 + dx * k - r * 6.0


const ROLL_POSES := [-1.0, -0.5, 0.0, 0.5, 1.0]


## Índice da pose de rolagem para uma inclinação contínua (-1..1).
static func roll_pose(bank: float) -> int:
	return clampi(roundi((bank + 1.0) * 2.0), 0, ROLL_POSES.size() - 1)


## Folhas de quadros das rochas que giram em 3D (AsteroidLook.dust_sheets).
const SHEET_FRAMES := 12
const SHEET_COLS := 4
const SHEET_ROWS := 3
## Folhas do lixo espacial (tools/bake_junk.gd): mais quadros, porque peça de metal tem
## quinas e detalhes que "pulam" com poucos quadros.
const JUNK_FRAMES := 24
const JUNK_COLS := 6
const JUNK_ROWS := 4


## Folhas de giro da poeira do setor `look` (vazio = usa as imagens fixas).
func dust_sheets(look: int) -> Array[Texture2D]:
	if look >= 0 and look < sector_looks.size() and sector_looks[look] != null:
		return sector_looks[look].dust_sheets
	return []


## Folhas do lixo espacial carregadas: { look: Array[Texture2D] }. Guarda só os 2 setores
## mais recentes (o atual e o anterior, cujas peças ainda podem estar na tela).
var _junk_cache := {}


## Folhas do lixo espacial do setor `look` (vazio = blocos fixos). Carrega na 1ª vez.
func junk_sheets(look: int) -> Array[Texture2D]:
	if _junk_cache.has(look):
		return _junk_cache[look]
	var list: Array[Texture2D] = []
	if look >= 0 and look < sector_looks.size() and sector_looks[look] != null:
		for path in sector_looks[look].junk_paths:
			list.append(load(path))
	while _junk_cache.size() >= 2:
		_junk_cache.erase(_junk_cache.keys()[0])
	_junk_cache[look] = list
	return list


## Luz âmbar de cada peça do setor `look` (mesma ordem de junk_sheets).
func junk_lamps(look: int) -> Array[PackedVector3Array]:
	if look >= 0 and look < sector_looks.size() and sector_looks[look] != null:
		return sector_looks[look].junk_lamps
	return []
