class_name AsteroidLook
extends Resource
## Visual das rochas de UM setor (poeira destrutível + metálico indestrutível).
## O ArtSet guarda um destes por setor (`sector_looks`); lista vazia = usa o padrão do ArtSet.
## Regra: poeira CLARA, metal ESCURO — é assim que o jogador sabe o que dá para quebrar.

const ROCK := "rochoso"
const CRYSTAL := "cristalino"
const VOLCANIC := "vulcanico"

@export var dust_textures: Array[Texture2D] = []
## Material de cada imagem (ou folha 3D), na mesma ordem. Vazio = rocha comum.
## Cristalino garante escudo; vulcânico solta brasas avisadas ao ser destruído a tiro.
@export var dust_materials: PackedStringArray = []
@export var metal_textures: Array[Texture2D] = []
## Folhas de quadros do giro 3D (tools/bake_rocks.gd). Se houver, a POEIRA usa estas no lugar
## de dust_textures. Grade: ArtSet.SHEET_COLS x ArtSet.SHEET_ROWS quadros.
@export var dust_sheets: Array[Texture2D] = []
## Lixo espacial girando em 3D (tools/bake_junk.gd). Se houver, o METAL usa estas folhas no
## lugar de metal_textures. São CAMINHOS: o ArtSet só carrega as do setor em jogo (memória do
## celular antigo). `junk_lamps[i]` = luz âmbar da peça i, um Vector3 por quadro (ver JunkLamps).
## Grade: ArtSet.JUNK_COLS x ArtSet.JUNK_ROWS quadros.
@export var junk_paths: PackedStringArray = []
## Luz âmbar de cada metal_textures[i] (sprites desenhados, PLANO_SPRITES_IA.md): ponto em
## -1..1 da imagem. Vazio = sem luz.
@export var metal_lamps: PackedVector2Array = []
@export var junk_lamps: Array[PackedVector3Array] = []
