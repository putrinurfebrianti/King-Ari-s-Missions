extends Node3D

# ==============================================================================
# KING ARI'S MISSIONS: TENJO ISLAND WORLD REMODELING
# 3D Pixel Art Environment & Regional Level Design
# ==============================================================================

# Regional Bounds & Dimensions
const ISLAND_SPAN_X: float = 76.0
const ISLAND_SPAN_Z: float = 56.0

# Textures & Materials
var mat_grass: StandardMaterial3D
var mat_soil: StandardMaterial3D
var mat_sand: StandardMaterial3D
var mat_rock: StandardMaterial3D
var mat_ocean: StandardMaterial3D
var mat_lake: StandardMaterial3D
var mat_swamp: StandardMaterial3D
var mat_asphalt: StandardMaterial3D
var mat_marking: StandardMaterial3D
var mat_crosswalk: StandardMaterial3D
var mat_dirt_road: StandardMaterial3D
var mat_brick_red: StandardMaterial3D
var mat_brick_cream: StandardMaterial3D
var mat_roof_terracotta: StandardMaterial3D
var mat_roof_blue: StandardMaterial3D
var mat_roof_dark: StandardMaterial3D
var mat_castle_stone: StandardMaterial3D
var mat_wood_planks: StandardMaterial3D
var mat_container_blue: StandardMaterial3D
var mat_container_red: StandardMaterial3D
var mat_container_orange: StandardMaterial3D
var mat_container_green: StandardMaterial3D
var mat_rice_paddy: StandardMaterial3D
var mat_foliage_tropical: StandardMaterial3D
var mat_foliage_pine: StandardMaterial3D
var mat_tree_bark: StandardMaterial3D
var mat_train: StandardMaterial3D
var mat_station_facade: StandardMaterial3D
var mat_curb_stone: StandardMaterial3D
var mat_gold_trim: StandardMaterial3D

func _ready() -> void:
	_init_pixel_materials()
	_build_ocean_and_beaches()
	_build_island_terrain()
	_build_road_network()
	_build_region_1_royal_palace()
	_build_region_2_industrial_logistics()
	_build_region_3_tenjo_station_and_market()
	_build_region_4_eastern_housing_and_schools()
	_build_region_5_southern_swamp_and_sawah()
	_build_vegetation_and_props()

# ------------------------------------------------------------------------------
# 1. MATERIAL SETUP (3D PIXEL ART WITH NEAREST FILTERING)
# ------------------------------------------------------------------------------
func _init_pixel_materials() -> void:
	mat_grass = _create_pixel_mat("pixel_grass.png", 0.95, Vector2(16.0, 16.0))
	mat_soil = _create_pixel_mat("pixel_soil.png", 0.95, Vector2(8.0, 8.0))
	mat_sand = _create_pixel_mat("pixel_sand.png", 0.92, Vector2(8.0, 8.0))
	mat_rock = _create_pixel_mat("pixel_rock.png", 0.9, Vector2(4.0, 4.0))
	mat_ocean = _create_pixel_mat("pixel_ocean.png", 0.25, Vector2(32.0, 32.0))
	mat_ocean.metallic = 0.15
	mat_lake = _create_pixel_mat("pixel_lake.png", 0.2, Vector2(6.0, 6.0))
	mat_lake.metallic = 0.2
	mat_swamp = _create_pixel_mat("pixel_swamp.png", 0.35, Vector2(6.0, 6.0))
	mat_swamp.metallic = 0.1
	mat_asphalt = _create_pixel_mat("pixel_road_asphalt.png", 0.82, Vector2(6.0, 6.0))
	mat_marking = _create_pixel_mat("pixel_road_marking.png", 0.7, Vector2(1.0, 1.0))
	mat_crosswalk = _create_pixel_mat("pixel_crosswalk.png", 0.75, Vector2(2.0, 2.0))
	mat_dirt_road = _create_pixel_mat("pixel_dirt_road.png", 0.92, Vector2(4.0, 4.0))
	mat_brick_red = _create_pixel_mat("pixel_brick_red.png", 0.85, Vector2(3.0, 3.0))
	mat_brick_cream = _create_pixel_mat("pixel_brick_cream.png", 0.85, Vector2(3.0, 3.0))
	mat_roof_terracotta = _create_pixel_mat("pixel_roof_terracotta.png", 0.75, Vector2(3.0, 3.0))
	mat_roof_blue = _create_pixel_mat("pixel_roof_blue.png", 0.75, Vector2(3.0, 3.0))
	mat_roof_dark = _create_pixel_mat("pixel_roof_dark.png", 0.8, Vector2(3.0, 3.0))
	mat_castle_stone = _create_pixel_mat("pixel_castle_stone.png", 0.88, Vector2(4.0, 4.0))
	mat_wood_planks = _create_pixel_mat("pixel_wood_planks.png", 0.85, Vector2(3.0, 3.0))
	mat_container_blue = _create_pixel_mat("pixel_container_blue.png", 0.7, Vector2(2.0, 1.0))
	mat_container_red = _create_pixel_mat("pixel_container_red.png", 0.7, Vector2(2.0, 1.0))
	mat_container_orange = _create_pixel_mat("pixel_container_orange.png", 0.7, Vector2(2.0, 1.0))
	mat_container_green = _create_pixel_mat("pixel_container_green.png", 0.7, Vector2(2.0, 1.0))
	mat_rice_paddy = _create_pixel_mat("pixel_rice_paddy.png", 0.65, Vector2(4.0, 4.0))
	mat_foliage_tropical = _create_pixel_mat("pixel_foliage_tropical.png", 0.9, Vector2(2.0, 2.0))
	mat_foliage_pine = _create_pixel_mat("pixel_foliage_pine.png", 0.9, Vector2(2.0, 2.0))
	mat_tree_bark = _create_pixel_mat("pixel_tree_bark.png", 0.92, Vector2(1.0, 3.0))
	mat_train = _create_pixel_mat("pixel_train_side.png", 0.45, Vector2(1.0, 1.0))
	mat_station_facade = _create_pixel_mat("pixel_station_facade.png", 0.8, Vector2(2.0, 2.0))

	mat_curb_stone = StandardMaterial3D.new()
	mat_curb_stone.albedo_color = Color(0.68, 0.7, 0.68)
	mat_curb_stone.roughness = 0.8
	mat_curb_stone.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

	mat_gold_trim = StandardMaterial3D.new()
	mat_gold_trim.albedo_color = Color(0.96, 0.82, 0.22)
	mat_gold_trim.metallic = 0.35
	mat_gold_trim.roughness = 0.4
	mat_gold_trim.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

func _create_pixel_mat(texture_file: String, roughness: float, uv_scale: Vector2 = Vector2.ONE) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	var path := "res://assets/textures/environment/" + texture_file
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = roughness
	mat.uv1_scale = Vector3(uv_scale.x, uv_scale.y, 1.0)
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	return mat

# ------------------------------------------------------------------------------
# 2. OCEAN & BEACHES
# ------------------------------------------------------------------------------
func _build_ocean_and_beaches() -> void:
	# Surrounding Ocean Plane
	var ocean := MeshInstance3D.new()
	ocean.name = "SurroundingOcean"
	var ocean_mesh := PlaneMesh.new()
	ocean_mesh.size = Vector2(320.0, 260.0)
	ocean.mesh = ocean_mesh
	ocean.material_override = mat_ocean
	ocean.position = Vector3(0.0, -1.35, 0.0)
	add_child(ocean)

	# Sandy Beach Fringes (Golden shore rim around the island)
	var beach_rings: Array[Vector3] = [
		Vector3(0.0, -0.4, -58.0), Vector3(25.0, -0.4, -52.0), Vector3(-25.0, -0.4, -52.0),
		Vector3(-45.0, -0.4, -40.0), Vector3(45.0, -0.4, -40.0),
		Vector3(-76.0, -0.4, -10.0), Vector3(-76.0, -0.4, 18.0), Vector3(-65.0, -0.4, 28.0),
		Vector3(76.0, -0.4, -20.0), Vector3(76.0, -0.4, 15.0), Vector3(65.0, -0.4, 38.0),
		Vector3(-38.0, -0.4, 54.0), Vector3(-10.0, -0.4, 56.0), Vector3(15.0, -0.4, 54.0),
		Vector3(40.0, -0.4, 50.0)
	]
	for b_pos in beach_rings:
		_add_box("BeachFringe", Vector3(22.0, 0.45, 14.0), b_pos, mat_sand)

# ------------------------------------------------------------------------------
# 3. ISLAND TERRAIN & ELEVATION
# ------------------------------------------------------------------------------
func _build_island_terrain() -> void:
	# 1. Main Base Terrain (Covering the full island shape)
	_add_solid_box("MainIslandBase", Vector3(150.0, 2.0, 110.0), Vector3(0.0, -1.0, 0.0), mat_grass)

	# 2. Regional Plateau Blocks (Building the 5 distinct geographical regions)
	# Region 1 (North - Royal Palace Highland):
	_add_solid_box("NorthPalaceHighland", Vector3(66.0, 0.04, 38.0), Vector3(0.0, 0.02, -44.0), mat_grass)
	_add_solid_box("NorthPalaceUpperTier", Vector3(44.0, 0.04, 22.0), Vector3(0.0, 0.04, -50.0), mat_castle_stone)

	# Region 2 (West - Industrial Logistics Plateau):
	_add_solid_box("WestLogisticsPlateau", Vector3(42.0, 0.04, 48.0), Vector3(-55.0, 0.02, 6.0), mat_soil)
	_add_solid_box("WestSPPGConcreteApron", Vector3(36.0, 0.04, 42.0), Vector3(-55.0, 0.06, 6.0), mat_asphalt)

	# Region 3 (Central - Station & Trade Valley):
	_add_solid_box("CentralUrbanDistrict", Vector3(56.0, 0.04, 36.0), Vector3(-8.0, 0.02, -4.0), mat_asphalt)

	# Region 4 (East - Modern Residential & School Plain):
	_add_solid_box("EastHousingDistrict", Vector3(58.0, 0.04, 68.0), Vector3(45.0, 0.02, 0.0), mat_grass)

	# Region 5 (South - Outskirts, Wetlands & Sawah):
	_add_solid_box("SouthWetlandBasin", Vector3(72.0, 0.04, 36.0), Vector3(-12.0, 0.02, 38.0), mat_soil)

# ------------------------------------------------------------------------------
# 4. ROAD NETWORK & BRIDGES (CONNECTED ARTERIALS)
# ------------------------------------------------------------------------------
func _build_road_network() -> void:
	# A. MAIN EAST-WEST ARTERIAL (The primary highway connecting West -> Central -> East)
	_add_solid_box("MainRoad_EW", Vector3(138.0, 0.08, 9.0), Vector3(0.0, 0.06, 0.0), mat_asphalt)
	_add_box("MainRoad_Markings", Vector3(136.0, 0.02, 0.22), Vector3(0.0, 0.11, 0.0), mat_marking)

	# B. NORTH-SOUTH CENTRAL ARTERIAL (Connecting Central to North & South)
	_add_solid_box("CentralRoad_NS", Vector3(9.0, 0.08, 70.0), Vector3(0.0, 0.06, 0.0), mat_asphalt)
	_add_box("CentralRoad_Markings", Vector3(0.22, 0.02, 68.0), Vector3(0.0, 0.11, 0.0), mat_marking)

	# C. WESTERN INDUSTRIAL PERIMETER ROAD (Ring road surrounding SPPG compound)
	_add_solid_box("WestRingRoad_North", Vector3(42.0, 0.08, 7.5), Vector3(-54.0, 0.06, -18.0), mat_asphalt)
	_add_solid_box("WestRingRoad_South", Vector3(42.0, 0.08, 7.5), Vector3(-54.0, 0.06, 28.0), mat_asphalt)
	_add_solid_box("WestRingRoad_West", Vector3(7.5, 0.08, 48.0), Vector3(-72.0, 0.06, 5.0), mat_asphalt)
	_add_solid_box("WestRingRoad_East", Vector3(7.5, 0.08, 48.0), Vector3(-35.0, 0.06, 5.0), mat_asphalt)

	# D. NORTHERN ROYAL PALACE LOOP (Winding route looping around Palace Lake up to the castle)
	_add_solid_box("NorthLakeRoad_South", Vector3(48.0, 0.08, 7.0), Vector3(0.0, 0.06, -24.0), mat_asphalt)
	_add_solid_box("NorthLakeRoad_West", Vector3(7.0, 0.08, 26.0), Vector3(-22.0, 0.06, -36.0), mat_asphalt)
	_add_solid_box("NorthLakeRoad_East", Vector3(7.0, 0.08, 26.0), Vector3(22.0, 0.06, -36.0), mat_asphalt)
	_add_solid_box("PalaceCourtAvenue", Vector3(36.0, 0.08, 8.5), Vector3(0.0, 0.06, -44.0), mat_castle_stone)

	# E. EASTERN RESIDENTIAL & SCHOOL GRID ROADS
	_add_solid_box("EastGrid_NorthAvenue", Vector3(56.0, 0.08, 7.5), Vector3(46.0, 0.06, -22.0), mat_asphalt)
	_add_solid_box("EastGrid_SouthAvenue", Vector3(56.0, 0.08, 7.5), Vector3(46.0, 0.06, 21.0), mat_asphalt)
	_add_solid_box("EastGrid_OuterEast", Vector3(7.5, 0.08, 52.0), Vector3(70.0, 0.06, 0.0), mat_asphalt)
	_add_solid_box("EastGrid_MidAvenue_NS", Vector3(7.5, 0.08, 52.0), Vector3(44.0, 0.06, 0.0), mat_asphalt)
	_add_solid_box("EastGrid_WestAvenue_NS", Vector3(7.5, 0.08, 52.0), Vector3(20.0, 0.06, 0.0), mat_asphalt)

	# F. SOUTHERN SCENIC DIRT ROAD (Winding trail through the wetlands & sawah)
	_add_solid_box("SouthDirtRoad_Sec1", Vector3(24.0, 0.06, 6.0), Vector3(-42.0, 0.04, 30.0), mat_dirt_road)
	_add_solid_box("SouthDirtRoad_Sec2", Vector3(6.0, 0.06, 18.0), Vector3(-32.0, 0.04, 38.0), mat_dirt_road)
	_add_solid_box("SouthDirtRoad_Sec3", Vector3(30.0, 0.06, 6.0), Vector3(-18.0, 0.04, 48.0), mat_dirt_road)
	_add_solid_box("SouthDirtRoad_Sec4", Vector3(6.0, 0.06, 16.0), Vector3(-2.0, 0.04, 42.0), mat_dirt_road)
	_add_solid_box("SouthDirtRoad_Sec5", Vector3(26.0, 0.06, 6.0), Vector3(10.0, 0.04, 34.0), mat_dirt_road)
	_add_solid_box("SouthDirtRoad_Sec6", Vector3(6.0, 0.06, 16.0), Vector3(22.0, 0.04, 28.0), mat_dirt_road)

	# G. BRIDGES (Wooden & Concrete Timber Bridges crossing water)
	# 1. West-to-South Timber Bridge
	_build_wooden_bridge("Bridge_WestToSouth", Vector3(-48.0, 0.08, 27.0), Vector3(8.0, 0.12, 12.0), 0.0)
	# 2. Central Wetland Wooden Bridge
	_build_wooden_bridge("Bridge_CentralWetland", Vector3(-12.0, 0.08, 48.0), Vector3(14.0, 0.12, 6.5), 0.0)
	# 3. South-to-East Wetland Bridge
	_build_wooden_bridge("Bridge_SouthToEast", Vector3(22.0, 0.08, 24.0), Vector3(6.5, 0.12, 12.0), 0.0)

	# H. PEDESTRIAN CROSSINGS (Zebra Crossings)
	var zebra_locs: Array[Vector3] = [
		Vector3(-28.0, 0.11, 0.0), Vector3(14.0, 0.11, 0.0), Vector3(30.0, 0.11, 0.0),
		Vector3(0.0, 0.11, -16.0), Vector3(0.0, 0.11, 14.0),
		Vector3(30.0, 0.11, -16.0), Vector3(56.0, 0.11, -16.0),
		Vector3(30.0, 0.11, 16.0), Vector3(56.0, 0.11, 16.0)
	]
	for z_pos in zebra_locs:
		_add_box("ZebraCrossing", Vector3(6.5, 0.02, 3.5), z_pos, mat_crosswalk)

# ------------------------------------------------------------------------------
# 5. REGION 1 – NORTHERN REGION (ROYAL PALACE OF KING ARI)
# ------------------------------------------------------------------------------
func _build_region_1_royal_palace() -> void:
	# A. Palace Lake (Danau Istana - South of the castle keep)
	_add_box("PalaceLakeWater", Vector3(36.0, 0.08, 16.0), Vector3(0.0, 0.22, -34.0), mat_lake)
	_add_box("PalaceLakeBorder", Vector3(38.0, 0.16, 18.0), Vector3(0.0, 0.15, -34.0), mat_sand)

	# B. Royal Palace Main Keep (Istana Megah Raja Ari)
	_add_solid_box("PalaceMainKeep", Vector3(24.0, 10.0, 14.0), Vector3(0.0, 6.0, -52.0), mat_castle_stone)
	_add_solid_box("PalaceRoofCentral", Vector3(26.0, 3.0, 16.0), Vector3(0.0, 12.0, -52.0), mat_roof_terracotta)
	_add_solid_box("PalaceCrownTower", Vector3(10.0, 6.0, 8.0), Vector3(0.0, 15.0, -52.0), mat_castle_stone)
	_add_cone("PalaceCrownRoof", 7.0, 6.0, Vector3(0.0, 20.0, -52.0), mat_roof_blue, 8)

	# C. Flanking Royal Towers & Battlements
	for side in [-14.0, 14.0]:
		_add_solid_box("PalaceWing", Vector3(10.0, 7.5, 12.0), Vector3(side, 4.5, -51.0), mat_castle_stone)
		_add_cylinder("PalaceCornerTower", 3.2, 14.0, Vector3(side * 1.35, 7.5, -51.0), mat_castle_stone, 8)
		_add_cone("PalaceTowerRoof", 3.8, 5.0, Vector3(side * 1.35, 16.5, -51.0), mat_roof_terracotta, 8)

	# D. Grand Palace Gateway & Courtyard
	_add_solid_box("PalaceGateArchLeft", Vector3(2.5, 6.0, 3.0), Vector3(-6.0, 3.5, -44.0), mat_castle_stone)
	_add_solid_box("PalaceGateArchRight", Vector3(2.5, 6.0, 3.0), Vector3(6.0, 3.5, -44.0), mat_castle_stone)
	_add_solid_box("PalaceGateArchTop", Vector3(14.5, 1.8, 3.2), Vector3(0.0, 6.8, -44.0), mat_gold_trim)
	_add_label("PalaceSignLabel", "👑 ISTANA KERAJAAN RAJA ARI 👑", Vector3(0.0, 9.0, -43.8), Color(1.0, 0.88, 0.25))

	# E. Mountain Ranges (Northern Boundary Peaks)
	var mountain_peaks: Array[Vector3] = [
		Vector3(-36.0, 5.0, -56.0), Vector3(-20.0, 7.0, -60.0),
		Vector3(0.0, 8.5, -62.0), Vector3(20.0, 7.0, -60.0), Vector3(36.0, 5.0, -56.0)
	]
	for peak in mountain_peaks:
		_add_cone("NorthernMountain", 14.0, 12.0, peak, mat_rock, 7)

	# F. Royal Village Cottages around the Lake
	var cottage_positions: Array[Vector3] = [
		Vector3(-28.0, 0.0, -32.0), Vector3(-26.0, 0.0, -20.0),
		Vector3(26.0, 0.0, -20.0), Vector3(28.0, 0.0, -32.0)
	]
	for c_pos in cottage_positions:
		_build_cottage("RoyalCottage", c_pos)

# ------------------------------------------------------------------------------
# 6. REGION 2 – WESTERN REGION (INDUSTRY & LOGISTICS / SPPG HUB)
# ------------------------------------------------------------------------------
func _build_region_2_industrial_logistics() -> void:
	# A. SPPG Central Kitchen Complex (Dapur Sentral MBG)
	_add_solid_box("SPPG_CentralKitchenMain", Vector3(22.0, 6.0, 14.0), Vector3(-55.0, 3.2, -6.0), mat_brick_cream)
	_add_solid_box("SPPG_SawtoothRoof", Vector3(23.0, 2.2, 15.0), Vector3(-55.0, 7.1, -6.0), mat_roof_dark)

	# Chimneys / Industrial Exhaust Vents
	for cx in [-60.0, -55.0, -50.0]:
		_add_cylinder("SPPG_Chimney", 0.9, 5.0, Vector3(cx, 9.5, -6.0), mat_rock, 6)

	# B. Logistics Warehouse Hub
	_add_solid_box("LogisticsWarehouseWest", Vector3(16.0, 5.5, 12.0), Vector3(-58.0, 2.9, 14.0), mat_castle_stone)
	_add_solid_box("LogisticsWarehouseEast", Vector3(14.0, 5.0, 10.0), Vector3(-40.0, 2.7, 14.0), mat_brick_cream)

	# C. Multi-Colored Cargo Containers (Blue, Red, Orange, Green)
	var container_layout: Array[Dictionary] = [
		{"pos": Vector3(-62.0, 1.4, 23.0), "mat": mat_container_blue},
		{"pos": Vector3(-56.0, 1.4, 23.0), "mat": mat_container_red},
		{"pos": Vector3(-50.0, 1.4, 23.0), "mat": mat_container_orange},
		{"pos": Vector3(-44.0, 1.4, 23.0), "mat": mat_container_green},
		# Stacked top tier:
		{"pos": Vector3(-59.0, 4.0, 23.0), "mat": mat_container_red},
		{"pos": Vector3(-47.0, 4.0, 23.0), "mat": mat_container_blue}
	]
	for cont in container_layout:
		_add_solid_box("CargoContainer", Vector3(5.8, 2.6, 2.5), cont["pos"], cont["mat"])

	# D. Loading Dock & Sign
	_add_solid_box("SPPG_LoadingDockApron", Vector3(18.0, 0.45, 6.0), Vector3(-52.0, 0.35, 2.0), mat_curb_stone)
	_add_label("SPPGDistrictSign", "🏭 SPPG CENTRAL KITCHEN & LOGISTIK", Vector3(-52.0, 6.2, 2.0), Color(0.3, 0.95, 1.0))

# ------------------------------------------------------------------------------
# 7. REGION 3 – CENTRAL REGION (TENJO STATION & TRADE CENTER)
# ------------------------------------------------------------------------------
func _build_region_3_tenjo_station_and_market() -> void:
	# A. Double Railway Track Line (Horizontal EW)
	var rail_len := 110.0
	for r_z in [-7.5, -4.5]:
		_add_box("RailSteel1", Vector3(rail_len, 0.14, 0.16), Vector3(-10.0, 0.24, r_z - 0.4), mat_curb_stone)
		_add_box("RailSteel2", Vector3(rail_len, 0.14, 0.16), Vector3(-10.0, 0.24, r_z + 0.4), mat_curb_stone)

	# Timber Railway Sleepers (MultiMesh)
	var sleeper_mesh := BoxMesh.new()
	sleeper_mesh.size = Vector3(0.24, 0.1, 4.2)
	var sleeper_mm := MultiMesh.new()
	sleeper_mm.transform_format = MultiMesh.TRANSFORM_3D
	sleeper_mm.mesh = sleeper_mesh
	sleeper_mm.instance_count = 55
	for i in range(sleeper_mm.instance_count):
		var x := -60.0 + float(i) * 2.1
		sleeper_mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(x, 0.16, -6.0)))
	var sleeper_inst := MultiMeshInstance3D.new()
	sleeper_inst.name = "TenjoRailSleepers"
	sleeper_inst.multimesh = sleeper_mm
	sleeper_inst.material_override = mat_wood_planks
	add_child(sleeper_inst)

	# B. Sleek Commuter Passenger Train (Kereta Tenjo)
	for car_idx in range(4):
		var cx := -28.0 + float(car_idx) * 12.5
		_add_solid_box("TrainCarriage", Vector3(11.5, 3.2, 2.8), Vector3(cx, 2.0, -4.5), mat_train)
		_add_box("TrainRoof", Vector3(11.8, 0.4, 2.9), Vector3(cx, 3.7, -4.5), mat_roof_dark)

	# C. Tenjo Station Building & Canopy Platform
	_add_solid_box("StationPlatform", Vector3(72.0, 0.45, 5.5), Vector3(-10.0, 0.35, -10.5), mat_curb_stone)
	_add_solid_box("StationBuildingMain", Vector3(20.0, 5.5, 6.0), Vector3(-10.0, 3.0, -15.5), mat_station_facade)
	_add_solid_box("StationCanopy", Vector3(56.0, 0.35, 7.0), Vector3(-10.0, 4.6, -10.5), mat_roof_blue)
	_add_label("StationSign", "🚉 STASIUN TENJO", Vector3(-10.0, 6.2, -8.0), Color(1.0, 0.88, 0.2))

	# D. Pasar Tenjo Commercial Trade Center (Shophouses & Traditional Market)
	var shop_colors: Array[Color] = [
		Color(0.85, 0.42, 0.25), Color(0.28, 0.58, 0.78),
		Color(0.88, 0.72, 0.32), Color(0.35, 0.68, 0.45),
		Color(0.75, 0.35, 0.55), Color(0.45, 0.52, 0.62)
	]
	for s_idx in range(7):
		var sx := -34.0 + float(s_idx) * 9.5
		var col := shop_colors[s_idx % shop_colors.size()]
		var shop_mat := StandardMaterial3D.new()
		shop_mat.albedo_color = col
		shop_mat.roughness = 0.85
		shop_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

		# 2-Story Shophouse (Ruko)
		_add_solid_box("PasarRuko", Vector3(7.5, 5.5, 6.5), Vector3(sx, 2.9, 8.5), shop_mat)
		# Striped Market Awning
		_add_box("RukoAwning", Vector3(7.8, 0.4, 2.4), Vector3(sx, 3.5, 5.0), mat_roof_terracotta if s_idx % 2 == 0 else mat_roof_blue)

	_add_label("PasarTenjoSign", "🏮 PASAR TRADISIONAL TENJO", Vector3(-6.0, 6.5, 5.0), Color(1.0, 0.85, 0.2))

# ------------------------------------------------------------------------------
# 8. REGION 4 – EASTERN REGION (MODERN HOUSING & 5 SCHOOLS)
# ------------------------------------------------------------------------------
func _build_region_4_eastern_housing_and_schools() -> void:
	# A. 5 DEDICATED SCHOOL CAMPUSES (GDD School Delivery Destinations)
	var school_data: Array[Dictionary] = [
		{"name": "SDN 01 TENJO", "pos": Vector3(30.0, 0.0, -24.0)},
		{"name": "SDN 02 HARAPAN", "pos": Vector3(56.0, 0.0, -24.0)},
		{"name": "SMPN 01 NUSA", "pos": Vector3(30.0, 0.0, 20.0)},
		{"name": "SDN 03 GARUDA", "pos": Vector3(56.0, 0.0, 20.0)},
		{"name": "MADRASAH TENJO", "pos": Vector3(44.0, 0.0, -2.0)}
	]
	for s in school_data:
		_build_school_campus(s["name"], s["pos"])

	# B. Modern Residential Neighborhood Houses
	var house_positions: Array[Vector3] = [
		Vector3(20.0, 0.0, -32.0), Vector3(32.0, 0.0, -32.0), Vector3(44.0, 0.0, -32.0), Vector3(56.0, 0.0, -32.0),
		Vector3(20.0, 0.0, -10.0), Vector3(58.0, 0.0, -10.0),
		Vector3(20.0, 0.0, 10.0), Vector3(58.0, 0.0, 10.0),
		Vector3(20.0, 0.0, 32.0), Vector3(32.0, 0.0, 32.0), Vector3(44.0, 0.0, 32.0), Vector3(56.0, 0.0, 32.0)
	]
	for h_idx in range(house_positions.size()):
		var h_pos: Vector3 = house_positions[h_idx]
		var is_blue := (h_idx % 2 == 1)
		_build_modern_house("ModernHouse", h_pos, is_blue)

	# C. Community Neighborhood Park
	_add_box("CommunityParkGrass", Vector3(18.0, 0.08, 14.0), Vector3(44.0, 0.16, 10.0), mat_grass)
	_add_box("ParkFountainBase", Vector3(4.0, 0.4, 4.0), Vector3(44.0, 0.35, 10.0), mat_curb_stone)
	_add_box("ParkFountainWater", Vector3(3.2, 0.42, 3.2), Vector3(44.0, 0.4, 10.0), mat_lake)

# ------------------------------------------------------------------------------
# 9. REGION 5 – SOUTHERN REGION (OUTSKIRTS & SWAMP / SAWAH)
# ------------------------------------------------------------------------------
func _build_region_5_southern_swamp_and_sawah() -> void:
	# A. Meandering Swamp Waterways & Ponds
	_add_box("SwampCanalWest", Vector3(26.0, 0.06, 14.0), Vector3(-35.0, 0.12, 42.0), mat_swamp)
	_add_box("SwampCanalCenter", Vector3(28.0, 0.06, 12.0), Vector3(-10.0, 0.12, 48.0), mat_swamp)
	_add_box("SwampCanalEast", Vector3(22.0, 0.06, 14.0), Vector3(16.0, 0.12, 42.0), mat_swamp)

	# B. Stepped Rice Paddies (Sawah Tenjo)
	var sawah_plots: Array[Vector3] = [
		Vector3(-24.0, 0.0, 34.0), Vector3(-12.0, 0.0, 34.0),
		Vector3(-24.0, 0.0, 42.0), Vector3(-12.0, 0.0, 42.0),
		Vector3(4.0, 0.0, 40.0), Vector3(16.0, 0.0, 48.0)
	]
	for plot in sawah_plots:
		_add_box("SawahField", Vector3(10.0, 0.14, 7.0), plot + Vector3(0.0, 0.12, 0.0), mat_rice_paddy)
		_add_box("SawahDike", Vector3(10.8, 0.18, 7.8), plot + Vector3(0.0, 0.08, 0.0), mat_soil)

	# C. Rural Village Stilt Huts (Rumah Panggung Desa)
	_build_rural_hut("RuralHutWest", Vector3(-44.0, 0.0, 44.0))
	_build_rural_hut("RuralHutSouth", Vector3(-20.0, 0.0, 54.0))
	_build_rural_hut("RuralHutEast", Vector3(6.0, 0.0, 48.0))

	_add_label("SouthernSign", "🌾 PERSAWAHAN & RAWA TENJO", Vector3(-10.0, 3.5, 36.0), Color(0.75, 0.98, 0.45))

# ------------------------------------------------------------------------------
# 10. VEGETATION & PROPS (OPTIMIZED MULTIMESH RENDERING)
# ------------------------------------------------------------------------------
func _build_vegetation_and_props() -> void:
	# Tropical Palm & Pine Trees
	var tree_instances: Array[Vector3] = []
	var pine_instances: Array[Vector3] = []

	# Northern Pine Forest around Palace
	for x in range(-35, 36, 6):
		pine_instances.append(Vector3(float(x), 0.5, -42.0))
		pine_instances.append(Vector3(float(x), 1.0, -58.0))

	# Southern Tropical Palms around Sawah & Swamp
	for x in range(-45, 25, 7):
		tree_instances.append(Vector3(float(x), 0.1, 26.0))
		tree_instances.append(Vector3(float(x), 0.1, 52.0))

	# Eastern Residential Street Trees
	for z in range(-30, 32, 10):
		tree_instances.append(Vector3(26.0, 0.1, float(z)))
		tree_instances.append(Vector3(62.0, 0.1, float(z)))

	# Render Palms
	if not tree_instances.is_empty():
		_add_tree_multimesh("TropicalPalmsCanopy", _sphere_mesh(1.6, 6, 4), tree_instances, mat_foliage_tropical, 3.6)
		_add_tree_multimesh("TropicalPalmsTrunk", _cylinder_mesh(0.28, 0.42, 4.0, 6), tree_instances, mat_tree_bark, 2.0)

	# Render Pines
	if not pine_instances.is_empty():
		_add_tree_multimesh("NorthernPinesCanopy", _cone_mesh(1.8, 4.5, 6), pine_instances, mat_foliage_pine, 3.8)
		_add_tree_multimesh("NorthernPinesTrunk", _cylinder_mesh(0.25, 0.35, 2.5, 6), pine_instances, mat_tree_bark, 1.25)

	# Street Lamps along Main Road
	for lx in range(-55, 65, 18):
		_add_street_lamp(Vector3(float(lx), 0.2, -5.5))
		_add_street_lamp(Vector3(float(lx), 0.2, 5.5))

# ------------------------------------------------------------------------------
# HELPER BUILDERS: PREFABS, SHAPES & COLLIDERS
# ------------------------------------------------------------------------------
func _build_school_campus(school_name: String, base_pos: Vector3) -> void:
	var school_root := Node3D.new()
	school_root.name = "Campus_" + school_name.replace(" ", "_")
	school_root.position = base_pos

	# Main Academic School Building
	_add_solid_box_child(school_root, "SchoolMainHall", Vector3(14.0, 4.8, 6.5), Vector3(0.0, 2.4, -4.0), mat_brick_red)
	_add_solid_box_child(school_root, "SchoolRoof", Vector3(14.8, 2.0, 7.2), Vector3(0.0, 5.8, -4.0), mat_roof_terracotta)

	# School Courtyard / Yard
	_add_box_child(school_root, "SchoolYard", Vector3(15.0, 0.12, 10.0), Vector3(0.0, 0.08, 3.0), mat_curb_stone)

	# Gate Arch
	_add_box_child(school_root, "GatePillarL", Vector3(0.5, 3.2, 0.5), Vector3(-4.5, 1.6, 7.5), mat_curb_stone)
	_add_box_child(school_root, "GatePillarR", Vector3(0.5, 3.2, 0.5), Vector3(4.5, 1.6, 7.5), mat_curb_stone)
	_add_box_child(school_root, "GateTopArch", Vector3(9.5, 0.6, 0.6), Vector3(0.0, 3.2, 7.5), mat_gold_trim)

	# School Signboard
	var label := Label3D.new()
	label.name = "SchoolLabel"
	label.text = "🏫 " + school_name
	label.font_size = 26
	label.outline_size = 6
	label.modulate = Color(1.0, 0.9, 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0.0, 4.2, 7.5)
	school_root.add_child(label)

	add_child(school_root)

func _build_modern_house(h_name: String, pos: Vector3, is_blue_roof: bool) -> void:
	_add_solid_box(h_name, Vector3(7.0, 3.6, 6.0), pos + Vector3(0.0, 1.8, 0.0), mat_brick_cream)
	_add_solid_box(h_name + "Roof", Vector3(7.8, 1.8, 6.8), pos + Vector3(0.0, 4.5, 0.0), mat_roof_blue if is_blue_roof else mat_roof_terracotta)

func _build_cottage(c_name: String, pos: Vector3) -> void:
	_add_solid_box(c_name, Vector3(5.5, 3.2, 4.8), pos + Vector3(0.0, 1.6, 0.0), mat_wood_planks)
	_add_solid_box(c_name + "Roof", Vector3(6.2, 1.6, 5.4), pos + Vector3(0.0, 4.0, 0.0), mat_roof_terracotta)

func _build_rural_hut(h_name: String, pos: Vector3) -> void:
	# Stilt Pillars
	for px in [-2.0, 2.0]:
		for pz in [-1.8, 1.8]:
			_add_cylinder(h_name + "Pillar", 0.18, 1.4, pos + Vector3(px, 0.7, pz), mat_tree_bark, 6)
	_add_solid_box(h_name + "Body", Vector3(4.8, 2.8, 4.2), pos + Vector3(0.0, 2.8, 0.0), mat_wood_planks)
	_add_solid_box(h_name + "Roof", Vector3(5.6, 1.6, 5.0), pos + Vector3(0.0, 5.0, 0.0), mat_roof_dark)

func _build_wooden_bridge(b_name: String, pos: Vector3, size: Vector3, rot_y: float) -> void:
	var bridge_body := StaticBody3D.new()
	bridge_body.name = b_name
	bridge_body.position = pos
	bridge_body.rotation.y = rot_y
	var col := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	col.shape = box_shape
	bridge_body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.material_override = mat_wood_planks
	bridge_body.add_child(mesh_inst)

	# Timber Guardrails
	for side in [-size.z * 0.46, size.z * 0.46]:
		var rail := MeshInstance3D.new()
		var rail_box := BoxMesh.new()
		rail_box.size = Vector3(size.x, 0.45, 0.22)
		rail.mesh = rail_box
		rail.material_override = mat_wood_planks
		rail.position = Vector3(0.0, size.y * 0.5 + 0.25, side)
		bridge_body.add_child(rail)

	add_child(bridge_body)

func _add_street_lamp(pos: Vector3) -> void:
	var pole := MeshInstance3D.new()
	pole.name = "StreetLampPole"
	pole.mesh = _cylinder_mesh(0.08, 0.12, 3.8, 6)
	pole.material_override = mat_curb_stone
	pole.position = pos + Vector3(0.0, 1.9, 0.0)
	add_child(pole)

	var lamp := MeshInstance3D.new()
	lamp.name = "StreetLampHead"
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 0.22, 0.35)
	lamp.mesh = box
	lamp.material_override = mat_gold_trim
	lamp.position = pos + Vector3(0.0, 3.8, 0.0)
	add_child(lamp)

func _add_tree_multimesh(node_name: String, mesh: Mesh, positions: Array[Vector3], mat: Material, y_offset: float) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = positions.size()
	for i in range(positions.size()):
		var t := Transform3D(Basis.IDENTITY, positions[i] + Vector3(0.0, y_offset, 0.0))
		mm.set_instance_transform(i, t)
	var inst := MultiMeshInstance3D.new()
	inst.name = node_name
	inst.multimesh = mm
	inst.material_override = mat
	add_child(inst)

# ------------------------------------------------------------------------------
# PRIMITIVE SHAPE GENERATION WITH SOLID COLLISION
# ------------------------------------------------------------------------------
func _add_box(node_name: String, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	inst.name = node_name
	var box := BoxMesh.new()
	box.size = size
	inst.mesh = box
	inst.material_override = mat
	inst.position = pos
	add_child(inst)
	return inst

func _add_box_child(parent: Node, node_name: String, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	inst.name = node_name
	var box := BoxMesh.new()
	box.size = size
	inst.mesh = box
	inst.material_override = mat
	inst.position = pos
	parent.add_child(inst)
	return inst

func _add_solid_box(node_name: String, size: Vector3, pos: Vector3, mat: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	var col := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	col.shape = box_shape
	body.add_child(col)

	var visual := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	visual.mesh = box_mesh
	visual.material_override = mat
	body.add_child(visual)

	add_child(body)
	return body

func _add_solid_box_child(parent: Node, node_name: String, size: Vector3, pos: Vector3, mat: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	var col := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	col.shape = box_shape
	body.add_child(col)

	var visual := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	visual.mesh = box_mesh
	visual.material_override = mat
	body.add_child(visual)

	parent.add_child(body)
	return body

func _add_cylinder(node_name: String, radius: float, height: float, pos: Vector3, mat: Material, sides: int = 8) -> void:
	var inst := MeshInstance3D.new()
	inst.name = node_name
	inst.mesh = _cylinder_mesh(radius, radius, height, sides)
	inst.material_override = mat
	inst.position = pos
	add_child(inst)

func _add_cone(node_name: String, radius: float, height: float, pos: Vector3, mat: Material, sides: int = 8) -> void:
	var inst := MeshInstance3D.new()
	inst.name = node_name
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = radius
	cone.height = height
	cone.radial_segments = sides
	inst.mesh = cone
	inst.material_override = mat
	inst.position = pos
	add_child(inst)

func _add_label(node_name: String, text: String, pos: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.name = node_name
	label.text = text
	label.font_size = 28
	label.outline_size = 6
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = pos
	add_child(label)

func _sphere_mesh(radius: float, radial_segments: int, rings: int) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = radial_segments
	m.rings = rings
	return m

func _cylinder_mesh(top_radius: float, bottom_radius: float, height: float, sides: int) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top_radius
	m.bottom_radius = bottom_radius
	m.height = height
	m.radial_segments = sides
	return m

func _cone_mesh(radius: float, height: float, sides: int) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = 0.0
	m.bottom_radius = radius
	m.height = height
	m.radial_segments = sides
	return m
