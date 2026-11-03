extends SceneTree

func _init() -> void:
	print("[TextureGen] Generating 3D Pixel Art Textures...")
	var dir := DirAccess.open("res://assets/textures")
	if dir and not dir.dir_exists("environment"):
		dir.make_dir("environment")

	_create_grass_texture()
	_create_soil_texture()
	_create_sand_texture()
	_create_rock_texture()
	_create_ocean_texture()
	_create_lake_texture()
	_create_swamp_texture()
	_create_asphalt_texture()
	_create_road_marking_texture()
	_create_crosswalk_texture()
	_create_dirt_road_texture()
	_create_brick_red_texture()
	_create_brick_cream_texture()
	_create_roof_terracotta_texture()
	_create_roof_blue_texture()
	_create_roof_dark_texture()
	_create_castle_stone_texture()
	_create_wood_planks_texture()
	_create_container_textures()
	_create_rice_paddy_texture()
	_create_foliage_textures()
	_create_bark_texture()
	_create_train_texture()
	_create_station_facade_texture()
	_create_pothole_texture()
	_create_school_crest_texture()

	print("[TextureGen] All textures generated successfully!")
	quit(0)

func _create_grass_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var base := Color("3c8022")
	var dark := Color("2c5f18")
	var light := Color("54a631")
	var accent := Color("6dc242")
	for y in range(32):
		for x in range(32):
			var hash_val := int((x * 17 + y * 31 + (x ^ y) * 13)) % 100
			var col := base
			if hash_val < 25:
				col = dark
			elif hash_val < 50:
				col = light
			elif hash_val < 60:
				col = accent
			img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_grass.png")

func _create_soil_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var base := Color("5c3b1e")
	var dark := Color("432813")
	var light := Color("734c28")
	var stone := Color("885f34")
	for y in range(32):
		for x in range(32):
			var h := int((x * 19 + y * 29 + (x * 7) ^ (y * 11))) % 100
			var col := base
			if h < 26:
				col = dark
			elif h < 52:
				col = light
			elif h < 62:
				col = stone
			img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_soil.png")

func _create_sand_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var base := Color("ddc382")
	var dark := Color("cbb06d")
	var light := Color("ede09e")
	for y in range(32):
		for x in range(32):
			var h := int((x * 23 + y * 37)) % 100
			var col := base
			if h < 28:
				col = dark
			elif h < 55:
				col = light
			img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_sand.png")

func _create_rock_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var base := Color("535b62")
	var dark := Color("3d4349")
	var light := Color("6a737c")
	var edge := Color("828d97")
	for y in range(32):
		for x in range(32):
			var block_x := x / 8
			var block_y := y / 8
			var is_edge := (x % 8 == 0 or y % 8 == 0)
			var h := int((block_x * 13 + block_y * 23)) % 3
			var col := base if h == 0 else (dark if h == 1 else light)
			if is_edge:
				col = dark.lerp(Color.BLACK, 0.3) if (x % 8 == 0) else edge
			img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_rock.png")

func _create_ocean_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var deep := Color("143b78")
	var mid := Color("1c529e")
	var wave := Color("2970c4")
	var foam := Color("72d4ec")
	for y in range(32):
		for x in range(32):
			var wave_line := int(sin((x + y * 0.5) * 0.6) * 4.0)
			var h := (y + wave_line) % 8
			var col := deep
			if h == 0:
				col = foam
			elif h == 1 or h == 2:
				col = wave
			elif h == 3 or h == 4:
				col = mid
			img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_ocean.png")

func _create_lake_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var base := Color("1d7a9b")
	var deep := Color("155c76")
	var wave := Color("2ba4ca")
	var glint := Color("6ce0f4")
	for y in range(32):
		for x in range(32):
			var pat := int(sin(x * 0.4 + y * 0.3) * 3.0) + y
			var col := base
			if pat % 7 == 0:
				col = glint
			elif pat % 7 <= 2:
				col = wave
			elif pat % 7 == 6:
				col = deep
			img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_lake.png")

func _create_swamp_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var murky := Color("184334")
	var moss := Color("225b49")
	var deep := Color("112e23")
	var scum := Color("377f64")
	for y in range(32):
		for x in range(32):
			var h := int((x * 11 + y * 23 + int(sin(x * 0.3) * 6.0))) % 100
			var col := murky
			if h < 20:
				col = deep
			elif h < 45:
				col = moss
			elif h < 55:
				col = scum
			img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_swamp.png")

func _create_asphalt_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var base := Color("2b2f35")
	var dark := Color("202328")
	var light := Color("3a4047")
	for y in range(32):
		for x in range(32):
			var h := int((x * 31 + y * 17 + (x ^ y) * 5)) % 100
			var col := base
			if h < 25:
				col = dark
			elif h < 50:
				col = light
			img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_road_asphalt.png")

func _create_road_marking_texture() -> void:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var yellow := Color("f5b922")
	var yellow_dark := Color("d29a14")
	var yellow_hi := Color("ffd44e")
	for y in range(16):
		for x in range(16):
			var is_border := (x == 0 or x == 15 or y == 0 or y == 15)
			var col := yellow
			if is_border:
				col = yellow_dark
			elif (x + y) % 5 == 0:
				col = yellow_hi
			img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_road_marking.png")

func _create_crosswalk_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var asphalt := Color("2b2f35")
	var white := Color("f0f2f5")
	var white_dark := Color("c8cbd2")
	for y in range(32):
		for x in range(32):
			var stripe := (x % 8 < 4)
			var col := asphalt
			if stripe:
				col = white if (y % 6 != 0) else white_dark
			img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_crosswalk.png")

func _create_dirt_road_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var base := Color("6c4c2c")
	var rut := Color("4e351d")
	var high := Color("85603b")
	var pebble := Color("9c774f")
	for y in range(32):
		for x in range(32):
			var is_wheel_rut := (x >= 6 and x <= 10) or (x >= 21 and x <= 25)
			var h := int((x * 29 + y * 13)) % 100
			var col := base
			if is_wheel_rut:
				col = rut if h < 70 else base
			elif h < 25:
				col = high
			elif h < 32:
				col = pebble
			img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_dirt_road.png")

func _create_brick_red_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var brick := Color("a53e2d")
	var brick_hi := Color("be4f3c")
	var brick_dark := Color("882f20")
	var mortar := Color("d8c4b2")
	for y in range(32):
		var row := y / 4
		var is_mortar_y := (y % 4 == 3)
		var shift := 8 if (row % 2 == 1) else 0
		for x in range(32):
			var is_mortar_x := ((x + shift) % 16 == 15)
			if is_mortar_y or is_mortar_x:
				img.set_pixel(x, y, mortar)
			else:
				var h := int((x * 7 + y * 13 + row * 19)) % 100
				var col := brick
				if h < 25:
					col = brick_dark
				elif h < 55:
					col = brick_hi
				img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_brick_red.png")

func _create_brick_cream_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var brick := Color("dccbb0")
	var brick_hi := Color("ebdcc4")
	var brick_dark := Color("beac90")
	var mortar := Color("8e7d66")
	for y in range(32):
		var row := y / 4
		var is_mortar_y := (y % 4 == 3)
		var shift := 8 if (row % 2 == 1) else 0
		for x in range(32):
			var is_mortar_x := ((x + shift) % 16 == 15)
			if is_mortar_y or is_mortar_x:
				img.set_pixel(x, y, mortar)
			else:
				var h := int((x * 7 + y * 13 + row * 19)) % 100
				var col := brick
				if h < 25:
					col = brick_dark
				elif h < 55:
					col = brick_hi
				img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_brick_cream.png")

func _create_roof_terracotta_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var tile := Color("b84326")
	var tile_hi := Color("d25737")
	var tile_shadow := Color("7a2713")
	for y in range(32):
		var tier := y % 6
		for x in range(32):
			var col := tile
			if tier == 0:
				col = tile_shadow
			elif tier == 1:
				col = tile_hi
			elif (x % 8 == 0):
				col = tile_shadow
			img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_roof_terracotta.png")

func _create_roof_blue_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var tile := Color("294e79")
	var tile_hi := Color("3d6fa3")
	var tile_shadow := Color("18304f")
	for y in range(32):
		var tier := y % 6
		for x in range(32):
			var col := tile
			if tier == 0:
				col = tile_shadow
			elif tier == 1:
				col = tile_hi
			elif (x % 8 == 0):
				col = tile_shadow
			img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_roof_blue.png")

func _create_roof_dark_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var tile := Color("343a40")
	var tile_hi := Color("495057")
	var tile_shadow := Color("212529")
	for y in range(32):
		var tier := y % 4
		for x in range(32):
			var col := tile
			if tier == 0:
				col = tile_shadow
			elif tier == 1:
				col = tile_hi
			img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_roof_dark.png")

func _create_castle_stone_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var stone := Color("8b9198")
	var stone_hi := Color("a5abb2")
	var stone_dark := Color("6c7178")
	var mortar := Color("474a4f")
	for y in range(32):
		var row := y / 8
		var is_mortar_y := (y % 8 == 7)
		var shift := 8 if (row % 2 == 1) else 0
		for x in range(32):
			var is_mortar_x := ((x + shift) % 16 == 15)
			if is_mortar_y or is_mortar_x:
				img.set_pixel(x, y, mortar)
			else:
				var is_bevel := (y % 8 == 0 or (x + shift) % 16 == 0)
				var col := stone
				if is_bevel:
					col = stone_hi
				elif (y % 8 == 6 or (x + shift) % 16 == 14):
					col = stone_dark
				img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_castle_stone.png")

func _create_wood_planks_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var wood := Color("6c482b")
	var wood_hi := Color("865b38")
	var wood_dark := Color("51341c")
	var gap := Color("2d1c0e")
	for y in range(32):
		var plank := y / 6
		var is_gap := (y % 6 == 5)
		for x in range(32):
			if is_gap:
				img.set_pixel(x, y, gap)
			else:
				var grain := int((x * 13 + y * 7)) % 100
				var col := wood
				if grain < 25:
					col = wood_dark
				elif grain < 50:
					col = wood_hi
				if (x == 4 or x == 27) and y % 6 == 2:
					col = Color("1f130a") # nail head
				img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_wood_planks.png")

func _create_container_textures() -> void:
	var colors := {
		"blue": [Color("1e5790"), Color("2a72b8"), Color("133c66")],
		"red": [Color("a33226"), Color("c44335"), Color("752118")],
		"orange": [Color("d0681c"), Color("e87e2f"), Color("9c4b10")],
		"green": [Color("287a4c"), Color("389c64"), Color("195232")]
	}
	for name in colors.keys():
		var pal: Array = colors[name]
		var base: Color = pal[0]
		var hi: Color = pal[1]
		var dark: Color = pal[2]
		var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		for y in range(32):
			for x in range(32):
				var rib := x % 4
				var col := base
				if rib == 0:
					col = hi
				elif rib == 3:
					col = dark
				if y == 0 or y == 31 or x == 0 or x == 31:
					col = dark.lerp(Color.BLACK, 0.4)
				img.set_pixel(x, y, col)
		img.save_png("res://assets/textures/environment/pixel_container_%s.png" % name)

func _create_rice_paddy_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var water := Color("265842")
	var shoot := Color("5cb836")
	var shoot_hi := Color("7ce651")
	var shoot_dark := Color("3d8221")
	var mud := Color("3a2f1b")
	for y in range(32):
		for x in range(32):
			var is_dike := (x == 0 or x == 31 or y == 0 or y == 31)
			if is_dike:
				img.set_pixel(x, y, mud)
				continue
			var row := y % 4
			var col := water
			if row == 1 or row == 2:
				var cluster := (x % 4 < 2)
				if cluster:
					col = shoot_hi if (x % 4 == 0) else shoot
				else:
					col = shoot_dark if (row == 2) else water
			img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_rice_paddy.png")

func _create_foliage_textures() -> void:
	var img_trop := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var leaf := Color("2d7028")
	var leaf_hi := Color("489f3e")
	var leaf_dark := Color("1b4a18")
	var leaf_sun := Color("6bc75a")
	for y in range(32):
		for x in range(32):
			var h := int((x * 23 + y * 41 + (x ^ y) * 9)) % 100
			var col := leaf
			if h < 25:
				col = leaf_dark
			elif h < 60:
				col = leaf_hi
			elif h < 75:
				col = leaf_sun
			img_trop.set_pixel(x, y, col)
	img_trop.save_png("res://assets/textures/environment/pixel_foliage_tropical.png")

	var img_pine := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var pine := Color("1c4e30")
	var pine_hi := Color("296e45")
	var pine_dark := Color("123320")
	for y in range(32):
		for x in range(32):
			var h := int((x * 19 + y * 37)) % 100
			var col := pine
			if h < 35:
				col = pine_dark
			elif h < 65:
				col = pine_hi
			img_pine.set_pixel(x, y, col)
	img_pine.save_png("res://assets/textures/environment/pixel_foliage_pine.png")

func _create_bark_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var bark := Color("4a3420")
	var bark_hi := Color("5e432a")
	var bark_dark := Color("322113")
	for y in range(32):
		for x in range(32):
			var is_ridge := (x % 4 == 0)
			var h := int((x * 11 + y * 29)) % 100
			var col := bark
			if is_ridge:
				col = bark_dark
			elif h < 35:
				col = bark_hi
			img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_tree_bark.png")

func _create_train_texture() -> void:
	var img := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	var body := Color("dbe0e6")
	var stripe := Color("1f62b0")
	var window := Color("25384d")
	var win_glint := Color("5b89ba")
	var roof := Color("8e959e")
	var base := Color("383c42")
	for y in range(32):
		for x in range(64):
			var col := body
			if y < 4:
				col = roof
			elif y >= 28:
				col = base
			elif y >= 18 and y <= 21:
				col = stripe
			elif y >= 7 and y <= 15:
				var win_x := x % 16
				if win_x >= 3 and win_x <= 13:
					col = win_glint if (win_x <= 5 or y == 7) else window
			img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_train_side.png")

func _create_station_facade_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var wall := Color("cfbfa3")
	var trim := Color("7a5330")
	var window := Color("294158")
	var glass := Color("4a7499")
	for y in range(32):
		for x in range(32):
			var col := wall
			if y < 4 or y > 27 or x < 2 or x > 29:
				col = trim
			elif y >= 10 and y <= 22 and x >= 6 and x <= 25:
				if x == 15 or x == 16 or y == 16:
					col = trim
				else:
					col = glass if (x == 7 or y == 11) else window
			img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_station_facade.png")

func _create_pothole_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var asphalt := Color("2b2f35")
	var pit := Color("141618")
	var crack := Color("3d434a")
	var water := Color("1d2c38")
	for y in range(32):
		for x in range(32):
			var dx := float(x - 16)
			var dy := float(y - 16)
			var dist := sqrt(dx * dx + dy * dy * 1.5)
			var col := asphalt
			if dist < 6.0:
				col = water
			elif dist < 10.0:
				col = pit
			elif dist < 12.5:
				col = crack
			img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_pothole.png")

func _create_school_crest_texture() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var gold := Color("f5b922")
	var blue := Color("1a4a82")
	var white := Color("f0f2f5")
	var red := Color("b83020")
	for y in range(32):
		for x in range(32):
			var col := Color.TRANSPARENT
			var dx := float(x - 16)
			var dy := float(y - 16)
			if absf(dx) + absf(dy) < 14.0:
				col = blue
				if absf(dx) + absf(dy) < 12.0:
					col = white if dy < 0.0 else red
				if absf(dx) < 2.0 or absf(dy) < 2.0:
					col = gold
			img.set_pixel(x, y, col)
	img.save_png("res://assets/textures/environment/pixel_school_crest.png")

