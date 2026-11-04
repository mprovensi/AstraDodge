class_name AsteroidLook
extends Resource
## Visual das rochas de UM setor (poeira destrutível + metálico indestrutível).
## O ArtSet guarda um destes por setor (`sector_looks`); lista vazia = usa o padrão do ArtSet.
## Regra: poeira CLARA, metal ESCURO — é assim que o jogador sabe o que dá para quebrar.

@export var dust_textures: Array[Texture2D] = []
@export var metal_textures: Array[Texture2D] = []
