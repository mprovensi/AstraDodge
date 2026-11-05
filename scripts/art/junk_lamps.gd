class_name JunkLamps
extends Resource
## Luz âmbar de alerta de cada peça de lixo espacial (gerado por tools/bake_junk.gd).
## `frames["s{setor}_{k}"]` = um Vector3 por quadro: (x, y) da lâmpada em -1..1 do quadro
## (y para baixo) e z = quanto dela aparece (0 = escondida atrás da peça).

@export var frames := {}
