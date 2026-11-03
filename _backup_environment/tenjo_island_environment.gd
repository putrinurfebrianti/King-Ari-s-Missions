extends Node3D

const ISLAND_RADIAL_SEGMENTS := 96
const ISLAND_RADIAL_RINGS := 16
const ISLAND_RADIUS_X := 71.0
const ISLAND_RADIUS_Z := 52.0

var terrain_material: StandardMaterial3D
var trunk_material: StandardMaterial3D
var foliage_material: StandardMaterial3D
var rock_material: StandardMaterial3D
var stone_material: StandardMaterial3D
var palace_roof_material: StandardMaterial3D
var palace_wall_material: StandardMaterial3D
var water_material: StandardMaterial3D
var rail_material: StandardMaterial3D
var road_marking_material: StandardMaterial3D

func _ready() -> void:
	_create_materials()
	_create_ocean()
	_create_island_terrain()
	_create_road_details()
	_create_royal_palace()
	_create_industrial_area()
	_create_station_and_market()
	_create_southern_wetlands()
	_create_vegetation()
	_create_residential_props()

func _create_materials() -> void:
	terrain_material = _material(Color.WHITE, 0.95)
	terrain_material.vertex_color_use_as_albedo = true
	trunk_material = _material(Color(0.28, 0.17, 0.08), 0.9)
	foliage_material = _material(Color.WHITE, 0.95)
	foliage_material.vertex_color_use_as_albedo = true
	rock_material = _material(Color(0.35, 0.39, 0.34), 0.95)
	stone_material = _material(Color(0.68, 0.65, 0.55), 0.85)
	palace_roof_material = _material(Color(0.58, 0.22, 0.13), 0.75)
	palace_wall_material = _material(Color(0.84, 0.78, 0.62), 0.85)
	water_material = _material(Color(0.035, 0.28, 0.52), 0.24)
	water_material.metallic = 0.12
	rail_material = _material(Color(0.24, 0.28, 0.3), 0.55)
	road_marking_material = _material(Color(0.9, 0.77, 0.28), 0.7)

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	return result

func _create_ocean() -> void:
	var ocean := MeshInstance3D.new()
	ocean.name = "SurroundingOcean"
	var ocean_mesh := PlaneMesh.new()
	ocean_mesh.size = Vector2(260.0, 210.0)
	ocean.mesh = ocean_mesh
	ocean.material_override = water_material
	ocean.position.y = -1.25
	add_child(ocean)

func _create_island_terrain() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in range(ISLAND_RADIAL_RINGS):
		var inner_radius := float(ring) / ISLAND_RADIAL_RINGS
		var outer_radius := float(ring + 1) / ISLAND_RADIAL_RINGS
		for segment in range(ISLAND_RADIAL_SEGMENTS):
			var angle_a := TAU * float(segment) / ISLAND_RADIAL_SEGMENTS
			var angle_b := TAU * float(segment + 1) / ISLAND_RADIAL_SEGMENTS
			var inner_a := _island_point(inner_radius, angle_a)
			var inner_b := _island_point(inner_radius, angle_b)
			var outer_a := _island_point(outer_radius, angle_a)
			var outer_b := _island_point(outer_radius, angle_b)
			_add_colored_triangle(surface, inner_a, inner_b, outer_a)
			_add_colored_triangle(surface, outer_a, inner_b, outer_b)
	surface.generate_normals()
	var island_mesh := surface.commit()
	var island := MeshInstance3D.new()
	island.name = "ShapedTropicalIsland"
	island.mesh = island_mesh
	island.material_override = terrain_material
	add_child(island)
	var island_collision := ConcavePolygonShape3D.new()
	island_collision.set_faces(island_mesh.get_faces())
	var island_body := StaticBody3D.new()
	island_body.name = "IslandTerrainCollision"
	var collision := CollisionShape3D.new()
	collision.shape = island_collision
	island_body.add_child(collision)
	add_child(island_body)

func _island_point(radius: float, angle: float) -> Vector3:
	var contour := 1.0 \
		+ 0.055 * sin(angle * 3.0 + 0.4) \
		+ 0.032 * sin(angle * 7.0 - 0.8) \
		+ 0.018 * cos(angle * 11.0)
	var local_radius := radius * contour
	var north_ridge := smoothstep(0.48, 0.94, -sin(angle)) * smoothstep(0.62, 0.92, radius)
	var south_ridge := smoothstep(0.68, 0.96, sin(angle)) * smoothstep(0.76, 0.98, radius)
	var low_terrain_variation := 0.08 * sin(angle * 9.0 + radius * 28.0)
	var height := 0.035 + north_ridge * 0.24 + south_ridge * 0.08 + low_terrain_variation
	if radius > 0.86:
		height = lerp(height, -0.08, smoothstep(0.86, 1.0, radius))
	return Vector3(
		cos(angle) * ISLAND_RADIUS_X * local_radius,
		height,
		sin(angle) * ISLAND_RADIUS_Z * local_radius
	)

func _add_colored_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.set_color(_terrain_color(a))
	surface.add_vertex(a)
	surface.set_color(_terrain_color(b))
	surface.add_vertex(b)
	surface.set_color(_terrain_color(c))
	surface.add_vertex(c)

func _terrain_color(point: Vector3) -> Color:
	var radius := Vector2(point.x / ISLAND_RADIUS_X, point.z / ISLAND_RADIUS_Z).length()
	if radius > 0.91:
		return Color(0.72, 0.63, 0.42)
	var color := Color(0.22, 0.39, 0.19)
	if point.z < -34.0:
		color = color.lerp(Color(0.35, 0.39, 0.32), 0.48)
	elif point.z > 32.0:
		color = color.lerp(Color(0.29, 0.39, 0.21), 0.35)
	if absf(point.x) < 20.0 and absf(point.z) < 28.0:
		color = color.lerp(Color(0.35, 0.4, 0.25), 0.2)
	return color

func _create_road_details() -> void:
	_add_box("NorthSidewalk", Vector3(124.0, 0.12, 1.35), Vector3(0.0, 0.04, -50.0), stone_material)
	_add_box("SouthSidewalk", Vector3(124.0, 0.12, 1.35), Vector3(0.0, 0.04, 50.0), stone_material)
	_add_box("WestSidewalk", Vector3(1.35, 0.12, 90.0), Vector3(-61.0, 0.04, 0.0), stone_material)
	_add_box("EastSidewalk", Vector3(1.35, 0.12, 90.0), Vector3(61.0, 0.04, 0.0), stone_material)

	var dash_mesh := BoxMesh.new()
	dash_mesh.size = Vector3(3.0, 0.035, 0.16)
	var road_dashes := MultiMesh.new()
	road_dashes.transform_format = MultiMesh.TRANSFORM_3D
	road_dashes.mesh = dash_mesh
	road_dashes.instance_count = 37
	for index in range(road_dashes.instance_count):
		var x := -57.0 + float(index) * 3.15
		road_dashes.set_instance_transform(index, Transform3D(Basis.IDENTITY, Vector3(x, 0.27, 0.0)))
	var dash_instance := MultiMeshInstance3D.new()
	dash_instance.name = "MainRoadCenterMarkings"
	dash_instance.multimesh = road_dashes
	dash_instance.material_override = road_marking_material
	add_child(dash_instance)

	_add_box("NorthCoastalRoadStripe", Vector3(118.0, 0.035, 0.16), Vector3(0.0, 0.27, -40.0), road_marking_material)
	_add_box("SouthCoastalRoadStripe", Vector3(118.0, 0.035, 0.16), Vector3(0.0, 0.27, 40.0), road_marking_material)
	_add_box("WestCoastalRoadStripe", Vector3(0.16, 0.035, 88.0), Vector3(-52.0, 0.27, 0.0), road_marking_material)
	_add_box("EastCoastalRoadStripe", Vector3(0.16, 0.035, 88.0), Vector3(52.0, 0.27, 0.0), road_marking_material)

func _create_royal_palace() -> void:
	_add_solid_box("PalaceFoundation", Vector3(28.0, 0.8, 15.0), Vector3(0.0, 0.5, -49.0), stone_material)
	_add_solid_box("PalaceMainHall", Vector3(14.0, 8.0, 10.0), Vector3(0.0, 4.8, -49.0), palace_wall_material)
	_add_solid_box("PalaceLeftWing", Vector3(7.0, 5.5, 8.0), Vector3(-10.0, 3.55, -49.0), palace_wall_material)
	_add_solid_box("PalaceRightWing", Vector3(7.0, 5.5, 8.0), Vector3(10.0, 3.55, -49.0), palace_wall_material)
	_add_solid_box("PalaceFrontSteps", Vector3(10.0, 0.45, 4.0), Vector3(0.0, 0.32, -40.0), stone_material)

	for tower_x in [-11.0, 0.0, 11.0]:
		var tower_height := 11.0 if is_zero_approx(tower_x) else 7.0
		_add_cylinder("PalaceTower", 2.0, tower_height, Vector3(tower_x, tower_height * 0.5 + 0.8, -49.0), palace_wall_material, 8)
		_add_cone("PalaceTowerRoof", 2.5, 4.0, Vector3(tower_x, tower_height + 2.8, -49.0), palace_roof_material, 8)
	_add_cone("PalaceMainRoof", 8.5, 4.5, Vector3(0.0, 11.1, -49.0), palace_roof_material, 8)
	_add_label("PalaceSign", "ISTANA RAJA ARI", Vector3(0.0, 10.5, -42.8), Color(1.0, 0.84, 0.3))

	for mountain in [
		Vector3(-31.0, 3.2, -48.0),
		Vector3(-22.0, 4.1, -56.0),
		Vector3(22.0, 4.4, -56.0),
		Vector3(31.0, 3.0, -47.0)
	]:
		_add_cone("NorthernMountain", 10.0, 8.0, mountain, rock_material, 7)
	_add_flat_water("PalaceLake", Vector3(15.0, -0.01, -33.0), Vector2(12.0, 7.0), 0.25)

func _create_industrial_area() -> void:
	_add_box("SPPGLoadingApron", Vector3(17.0, 0.08, 7.0), Vector3(-50.0, 0.05, 24.0), stone_material)
	_add_solid_box("SPPGWarehouseWest", Vector3(12.0, 5.5, 9.0), Vector3(-64.0, 2.75, 23.0), palace_wall_material)
	_add_box("WarehouseRoofWest", Vector3(13.0, 1.2, 10.0), Vector3(-64.0, 6.1, 23.0), palace_roof_material)
	_add_solid_box("SPPGWarehouseEast", Vector3(10.0, 4.8, 8.0), Vector3(-39.0, 2.4, 25.0), stone_material)
	_add_box("WarehouseRoofEast", Vector3(11.0, 1.0, 9.0), Vector3(-39.0, 5.3, 25.0), palace_roof_material)
	_add_box("ShippingContainerBlue", Vector3(7.0, 2.8, 2.6), Vector3(-57.0, 1.4, 31.0), _material(Color(0.1, 0.32, 0.55), 0.75))
	_add_box("ShippingContainerRed", Vector3(7.0, 2.8, 2.6), Vector3(-48.0, 1.4, 31.0), _material(Color(0.58, 0.2, 0.13), 0.75))
	_add_label("SPPGDistrictSign", "KAWASAN INDUSTRI & LOGISTIK", Vector3(-50.0, 3.6, 34.0), Color(0.75, 0.95, 1.0))

func _create_station_and_market() -> void:
	_add_box("TenjoStationPlatform", Vector3(64.0, 0.28, 5.0), Vector3(4.0, 0.17, -17.8), stone_material)
	_add_solid_box("StationBuilding", Vector3(12.0, 4.0, 5.0), Vector3(1.0, 2.2, -25.0), palace_wall_material)
	_add_box("StationCanopy", Vector3(17.0, 0.45, 7.0), Vector3(1.0, 4.5, -19.8), palace_roof_material)
	_add_label("StationSign", "STASIUN TENJO", Vector3(1.0, 5.2, -16.0), Color(1.0, 0.84, 0.3))

	var rail_left := _material(Color(0.2, 0.23, 0.24), 0.45)
	_add_box("RailWest", Vector3(94.0, 0.16, 0.18), Vector3(2.0, 0.22, -19.1), rail_left)
	_add_box("RailEast", Vector3(94.0, 0.16, 0.18), Vector3(2.0, 0.22, -16.7), rail_left)
	var sleeper_mesh := BoxMesh.new()
	sleeper_mesh.size = Vector3(0.22, 0.12, 3.6)
	var sleepers := MultiMesh.new()
	sleepers.transform_format = MultiMesh.TRANSFORM_3D
	sleepers.mesh = sleeper_mesh
	sleepers.instance_count = 40
	for index in range(sleepers.instance_count):
		var x := -44.0 + float(index) * 2.35
		sleepers.set_instance_transform(index, Transform3D(Basis.IDENTITY, Vector3(x, 0.16, -17.9)))
	var sleeper_instance := MultiMeshInstance3D.new()
	sleeper_instance.name = "StationRailSleepers"
	sleeper_instance.multimesh = sleepers
	sleeper_instance.material_override = _material(Color(0.32, 0.22, 0.13), 0.9)
	add_child(sleeper_instance)

	for carriage_index in range(3):
		var carriage_x := -1.0 + float(carriage_index) * 11.0
		_add_solid_box("TenjoTrainCarriage", Vector3(9.5, 3.2, 3.0), Vector3(carriage_x, 2.1, -17.9), _material(Color(0.12, 0.38, 0.52), 0.6))
		for window_index in range(3):
			_add_box("TrainWindow", Vector3(1.5, 0.9, 0.08), Vector3(carriage_x - 3.0 + float(window_index) * 3.0, 2.5, -16.35), _material(Color(0.35, 0.7, 0.78), 0.25))

	for shop_index in range(6):
		var shop_x := -31.0 + float(shop_index) * 10.0
		var shop_color := Color(0.78, 0.62, 0.4) if shop_index % 2 == 0 else Color(0.66, 0.38, 0.25)
		_add_solid_box("TenjoMarketShop", Vector3(7.5, 4.6, 6.0), Vector3(shop_x, 2.3, -9.0), _material(shop_color, 0.85))
		_add_box("TenjoMarketAwning", Vector3(7.8, 0.55, 2.2), Vector3(shop_x, 4.3, -5.0), _material(Color(0.82, 0.32, 0.15) if shop_index % 2 == 0 else Color(0.18, 0.42, 0.58), 0.75))

func _create_southern_wetlands() -> void:
	_add_flat_water("SouthernWetlandWest", Vector3(-34.0, 0.02, 48.0), Vector2(16.0, 7.5), -0.18)
	_add_flat_water("SouthernWetlandEast", Vector3(35.0, 0.02, 48.0), Vector2(15.0, 7.0), 0.2)
	_add_flat_water("SouthernWetlandCenter", Vector3(0.0, 0.015, 51.0), Vector2(19.0, 6.0), -0.08)
	_add_box("RiceFieldWest", Vector3(25.0, 0.08, 9.0), Vector3(-22.0, 0.05, 34.0), _material(Color(0.32, 0.47, 0.2), 0.95))
	_add_box("RiceFieldEast", Vector3(26.0, 0.08, 9.0), Vector3(22.0, 0.05, 34.0), _material(Color(0.39, 0.52, 0.24), 0.95))
	_add_box("WoodenWetlandBridge", Vector3(12.0, 0.22, 2.2), Vector3(0.0, 0.22, 47.0), _material(Color(0.36, 0.23, 0.12), 0.9))
	_add_label("SouthernRegionSign", "RAWA & PERSAWAHAN TENJO", Vector3(0.0, 2.1, 51.0), Color(0.76, 0.94, 0.55))

func _create_vegetation() -> void:
	var tree_positions: Array[Vector3] = []
	var tree_colors: Array[Color] = []
	for index in range(180):
		var angle := TAU * float(index) / 180.0
		var radius := 0.68 + 0.23 * float((index * 37) % 101) / 100.0
		var x := cos(angle) * ISLAND_RADIUS_X * radius
		var z := sin(angle) * ISLAND_RADIUS_Z * radius
		if _is_near_road(x, z) or _is_near_landmark(x, z):
			continue
		tree_positions.append(Vector3(x, 0.1, z))
		var green_tint := 0.82 + 0.28 * float((index * 13) % 17) / 16.0
		tree_colors.append(Color(0.16, 0.39, 0.18) * green_tint)
	_add_multimesh("TropicalForestCanopies", _sphere_mesh(1.0, 7, 4), tree_positions, tree_colors, Vector3(2.2, 2.8, 2.2), 4.0, foliage_material)
	_add_multimesh("TropicalForestTrunks", _cylinder_mesh(0.34, 0.5, 5.0, 7), tree_positions, [], Vector3.ONE, 2.5, trunk_material)

func _is_near_road(x: float, z: float) -> bool:
	if absf(z) < 11.0 or absf(x) < 11.0:
		return true
	if absf(absf(z) - 40.0) < 7.5 or absf(absf(x) - 52.0) < 7.5:
		return true
	return false

func _is_near_landmark(x: float, z: float) -> bool:
	if Vector2(x + 50.0, z - 14.0).length() < 17.0:
		return true
	if Vector2(x, z + 49.0).length() < 21.0:
		return true
	if x > 20.0 and z > -36.0 and z < 32.0:
		return true
	return false

func _add_multimesh(
	node_name: String,
	mesh: Mesh,
	positions: Array[Vector3],
	colors: Array[Color],
	instance_scale: Vector3,
	height_offset: float,
	material: Material
) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = not colors.is_empty()
	multimesh.mesh = mesh
	multimesh.instance_count = positions.size()
	for index in range(positions.size()):
		var instance_basis := Basis.IDENTITY.scaled(instance_scale)
		var instance_origin := positions[index] + Vector3(0.0, height_offset, 0.0)
		multimesh.set_instance_transform(index, Transform3D(instance_basis, instance_origin))
		if not colors.is_empty():
			multimesh.set_instance_color(index, colors[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.material_override = material
	add_child(instance)

func _create_residential_props() -> void:
	var home_positions: Array[Vector3] = [
		Vector3(34.0, 0.0, -39.0),
		Vector3(44.0, 0.0, -38.0),
		Vector3(55.0, 0.0, -27.0),
		Vector3(34.0, 0.0, 35.0),
		Vector3(54.0, 0.0, 28.0),
		Vector3(-26.0, 0.0, 29.0),
		Vector3(-37.0, 0.0, -30.0)
	]
	for index in range(home_positions.size()):
		var home := home_positions[index]
		_add_solid_box("IslandHome", Vector3(6.0, 3.3, 5.0), home + Vector3(0.0, 1.65, 0.0), palace_wall_material)
		_add_cone("IslandHomeRoof", 4.2, 2.2, home + Vector3(0.0, 4.4, 0.0), palace_roof_material, 4)

func _add_flat_water(node_name: String, position: Vector3, size: Vector2, rotation: float) -> void:
	var water := MeshInstance3D.new()
	water.name = node_name
	var water_mesh := PlaneMesh.new()
	water_mesh.size = size
	water.mesh = water_mesh
	water.material_override = water_material
	water.position = position
	water.rotation.y = rotation
	add_child(water)

func _add_box(node_name: String, size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var box := BoxMesh.new()
	box.size = size
	instance.mesh = box
	instance.material_override = material
	instance.position = position
	add_child(instance)
	return instance

func _add_solid_box(node_name: String, size: Vector3, position: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	var collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	collision.shape = box_shape
	body.add_child(collision)
	var visual := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	visual.mesh = box_mesh
	visual.material_override = material
	body.add_child(visual)
	add_child(body)

func _add_cylinder(node_name: String, radius: float, height: float, position: Vector3, material: Material, sides: int) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = _cylinder_mesh(radius, radius, height, sides)
	instance.material_override = material
	instance.position = position
	add_child(instance)

func _add_cone(node_name: String, radius: float, height: float, position: Vector3, material: Material, sides: int) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = radius
	cone.height = height
	cone.radial_segments = sides
	instance.mesh = cone
	instance.material_override = material
	instance.position = position
	add_child(instance)

func _add_label(node_name: String, text: String, position: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.name = node_name
	label.text = text
	label.font_size = 30
	label.outline_size = 5
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = position
	add_child(label)

func _sphere_mesh(radius: float, radial_segments: int, rings: int) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = radial_segments
	mesh.rings = rings
	return mesh

func _cylinder_mesh(top_radius: float, bottom_radius: float, height: float, sides: int) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = sides
	return mesh
