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
	# Chefes: arte de IA no estilo cartoon (PLANO_CHEFES_ARTE.md, tools/gen_boss_sprites.gd). Os
	# corpos já vêm montados no quadrado que cada chefe desenha; os antigos boss_*.png ficam de reserva.
	art.rock_mother_body = load("res://sprites/ia/boss/rock_body.png")
	art.rock_mother_half = load("res://sprites/ia/boss/rock_half_l.png")
	art.boss_fill = 0.75
	art.dust_shell_texture = load("res://sprites/dust_shell.png")
	art.miner_body = load("res://sprites/ia/boss/miner_body.png")
	art.medusa_body = load("res://sprites/ia/boss/medusa_dome.png")
	art.cruiser_body = load("res://sprites/ia/boss/cruiser_hull.png")
	art.ice_textures.assign([load("res://sprites/ice_1.png"), load("res://sprites/ice_2.png")])
	# Visual por setor (PLANO_SPRITES_IA.md): rochas e lixo desenhados (recortes das folhas de IA,
	# tools/gen_ia_sprites.gd), girando no plano. O lixo tem a luz âmbar num ponto fixo da peça.
	# (O giro 3D pré-renderizado — rock_s*/junk_s* — continua nos arquivos como reserva.)
	var lamps: JunkLamps = load("res://data/art/junk_lamps.tres")
	var looks: Array[AsteroidLook] = []
	for sector in range(1, 9):
		var look := AsteroidLook.new()
		if sector == 3:
			look.dust_materials.assign([AsteroidLook.ROCK, AsteroidLook.ROCK, AsteroidLook.ROCK, AsteroidLook.CRYSTAL])
		elif sector == 8:
			look.dust_materials.assign([AsteroidLook.ROCK, AsteroidLook.ROCK, AsteroidLook.VOLCANIC, AsteroidLook.VOLCANIC])
		for k in range(1, 5):
			look.dust_textures.append(load("res://sprites/ia/rock_s%d_%d.png" % [sector, k]))
			look.metal_textures.append(load("res://sprites/ia/junk_s%d_%d.png" % [sector, k]))
			var p: Vector3 = lamps.frames["ia_s%d_%d" % [sector, k]][0]
			look.metal_lamps.append(Vector2(p.x, p.y))
		looks.append(look)
	art.sector_looks.assign(looks)
	art.ice_colossus_body = load("res://sprites/ia/boss/ice_body.png")
	art.hive_queen_body = load("res://sprites/ia/boss/queen_body.png")
	art.sentinel_body = load("res://sprites/ia/boss/sentinel_body.png")
	art.rift_core_body = load("res://sprites/ia/boss/rift_body.png")
	for part in ["rock_crystal", "rock_lid", "miner_eye", "miner_lid", "medusa_tentacle", "medusa_tip",
			"medusa_node", "cruiser_turret", "cruiser_launcher", "cruiser_launcher_open", "cruiser_wreck",
			"ice_blade", "sentinel_arm", "sentinel_arm_broken", "sentinel_drone"]:
		art.boss_parts[part] = load("%s%s.png" % ["res://sprites/ia/boss/", part])
	var err := ResourceSaver.save(art, OUT)
	print("%s -> %s" % [OUT, "OK" if err == OK else "ERRO %d" % err])
	quit()
