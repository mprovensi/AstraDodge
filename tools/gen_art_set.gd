extends SceneTree
## Cria data/art/default.tres (o ArtSet padrão). Depois de criado, a fonte da verdade é
## o .tres — edite pelo Inspetor do Godot. Rode de novo só para recriar do zero.
## Uso: godot --headless --path . --script res://tools/gen_art_set.gd

const OUT := "res://data/art/default.tres"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var art := ArtSet.new()
	art.ship_texture = load("res://sprites/ship.png")
	art.ship_size = 128.0
	art.ship_glow = Color(1.1, 1.1, 1.1)  # arte realista: só um toque acima de 1 (não vira neon)
	art.ship_engines_px.assign([Vector2(104, 214), Vector2(152, 214)])
	art.ship_muzzle_px = Vector2(128, 12)
	art.ship_wingtips_px.assign([Vector2(32, 176), Vector2(224, 176)])
	# Poses de rolagem (tools/gen_ship.gd): esquerda forte, esquerda, reta, direita, direita forte.
	art.ship_roll_textures.assign([load("res://sprites/ship_roll_l2.png"), load("res://sprites/ship_roll_l1.png"),
			load("res://sprites/ship.png"), load("res://sprites/ship_roll_r1.png"), load("res://sprites/ship_roll_r2.png")])
	art.dust_textures.assign([
		load("res://sprites/dust_1.png"), load("res://sprites/dust_2.png"), load("res://sprites/dust_3.png")])
	art.metal_textures.assign([
		load("res://sprites/metal_1.png"), load("res://sprites/metal_2.png"), load("res://sprites/metal_3.png")])
	art.dust_fill = 0.92
	art.metal_fill = 0.94
	art.rock_mother_body = load("res://sprites/boss_rock_mother.png")
	art.rock_mother_half = load("res://sprites/boss_rock_mother_half.png")
	art.boss_fill = 0.95
	art.dust_shell_texture = load("res://sprites/dust_shell.png")
	art.miner_body = load("res://sprites/boss_miner.png")
	art.medusa_body = load("res://sprites/boss_medusa.png")
	art.cruiser_body = load("res://sprites/boss_cruiser.png")
	art.ice_textures.assign([load("res://sprites/ice_1.png"), load("res://sprites/ice_2.png")])
	# Visual por setor: Setor 1 = padrão (lista vazia); 2..8 = dust_sN_k / metal_sN_k.
	var first := AsteroidLook.new()
	# Protótipo do giro 3D estilizado (ESPEC_ASTEROIDES.md, seção 8): Setor 1.
	first.dust_sheets.assign([load("res://sprites/rock_s1_1.png"), load("res://sprites/rock_s1_2.png"),
			load("res://sprites/rock_s1_3.png")])
	# Lixo espacial girando em 3D (PLANO_INDESTRUTIVEIS.md, J0): Setor 1.
	var looks: Array[AsteroidLook] = [first]
	for sector in range(2, 9):
		var look := AsteroidLook.new()
		for k in [1, 2]:
			look.dust_textures.append(load("res://sprites/dust_s%d_%d.png" % [sector, k]))
			look.metal_textures.append(load("res://sprites/metal_s%d_%d.png" % [sector, k]))
		# Giro 3D estilizado (tools/bake_rocks.gd): 3 rochas por setor.
		for k in [1, 2, 3]:
			look.dust_sheets.append(load("res://sprites/rock_s%d_%d.png" % [sector, k]))
		looks.append(look)
	# Lixo espacial girando em 3D (PLANO_INDESTRUTIVEIS.md, J1): 4 peças por setor, carregadas
	# só no setor em jogo (caminhos); a luz âmbar vem de data/art/junk_lamps.tres.
	var lamps: JunkLamps = load("res://data/art/junk_lamps.tres")
	for sector in range(1, 9):
		var look := looks[sector - 1]
		for k in range(1, 5):
			look.junk_paths.append("res://sprites/junk_s%d_%d.png" % [sector, k])
			look.junk_lamps.append(lamps.frames["s%d_%d" % [sector, k]])
	art.sector_looks.assign(looks)
	art.ice_colossus_body = load("res://sprites/boss_ice_colossus.png")
	art.hive_queen_body = load("res://sprites/boss_hive_queen.png")
	art.sentinel_body = load("res://sprites/boss_sentinel.png")
	art.rift_core_body = load("res://sprites/boss_rift_core.png")
	var err := ResourceSaver.save(art, OUT)
	print("%s -> %s" % [OUT, "OK" if err == OK else "ERRO %d" % err])
	quit()
