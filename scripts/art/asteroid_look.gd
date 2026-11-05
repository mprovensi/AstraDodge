class_name AsteroidLook
extends Resource
## Visual das rochas de UM setor (poeira destrutível + metálico indestrutível).
## O ArtSet guarda um destes por setor (`sector_looks`); lista vazia = usa o padrão do ArtSet.
## Regra: poeira CLARA, metal ESCURO — é assim que o jogador sabe o que dá para quebrar.

@export var dust_textures: Array[Texture2D] = []
@export var metal_textures: Array[Texture2D] = []
## Folhas de quadros do giro 3D (tools/bake_rocks.gd). Se houver, a POEIRA usa estas no lugar
## de dust_textures. Grade: ArtSet.SHEET_COLS x ArtSet.SHEET_ROWS quadros.
@export var dust_sheets: Array[Texture2D] = []
## Lixo espacial girando em 3D (tools/bake_junk.gd). Se houver, o METAL usa estas no lugar de
## metal_textures. `junk_lights[i]` = luz âmbar da peça `junk_sheets[i]`.
## Grade: ArtSet.JUNK_COLS x ArtSet.JUNK_ROWS quadros.
@export var junk_sheets: Array[Texture2D] = []
@export var junk_lights: Array[Texture2D] = []
