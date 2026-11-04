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

@export_group("Chefes")
## Rocha-Mãe inteira (fase 1). Os núcleos são desenhados pelo código na borda.
@export var rock_mother_body: Texture2D
## Metade ESQUERDA da Rocha-Mãe rachada (fase 2); a direita é a mesma imagem espelhada.
@export var rock_mother_half: Texture2D
## Fração do raio da imagem ocupada pela rocha do chefe.
@export_range(0.5, 1.0, 0.01) var boss_fill := 0.95
## Minerador (Setor 2), frente para baixo. O olho (ponto fraco) é desenhado pelo código.
@export var miner_body: Texture2D


## Converte um ponto do PNG da nave para coordenadas locais da nave na tela.
func ship_point(px: Vector2) -> Vector2:
	var tex_size := ship_texture.get_size()
	return (px - tex_size * 0.5) * (ship_size / tex_size.x)
