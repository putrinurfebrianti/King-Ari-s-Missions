extends Control

const TENJO_MAP_TEXTURE: Texture2D = preload("res://assets/textures/tenjo_island_map.png")

@export var player: Node3D
@export var sppg_pos: Vector3 = Vector3(-50.0, 0.15, -2.0)
@export var spbu_pos: Vector3 = Vector3(16.0, 0.15, 10.0)
@export var blockade_pos: Vector3 = Vector3(-14.0, 0.15, 8.0)

var world_min_x: float = -80.0
var world_max_x: float = 80.0
var world_min_z: float = -60.0
var world_max_z: float = 60.0

var pulse_time: float = 0.0
var is_fullscreen_map: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			toggle_map_size()

func toggle_map_size() -> void:
	is_fullscreen_map = not is_fullscreen_map
	if is_fullscreen_map:
		set_anchors_preset(Control.PRESET_CENTER)
		offset_left = -520
		offset_top = -310
		offset_right = 520
		offset_bottom = 310
	else:
		set_anchors_preset(Control.PRESET_TOP_RIGHT)
		offset_left = -340
		offset_top = 16
		offset_right = -20
		offset_bottom = 256
	queue_redraw()

func _process(delta: float) -> void:
	pulse_time += delta * 4.0
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y

	# 1. OCEAN BACKGROUND
	draw_rect(Rect2(0, 0, w, h), Color(0.07, 0.22, 0.44, 0.96), true)

	# 2. TENJO ISLAND COASTLINE & BEACH (Matching reference map 5-region geography)
	var island_beach_pts := PackedVector2Array()
	var raw_beach_coords: Array[Vector3] = [
		Vector3(-28, 0, -42), Vector3(-18, 0, -56), Vector3(0, 0, -58), Vector3(18, 0, -56), Vector3(28, 0, -42),
		Vector3(34, 0, -36), Vector3(72, 0, -35), Vector3(76, 0, -18), Vector3(76, 0, 16), Vector3(70, 0, 36),
		Vector3(34, 0, 36), Vector3(22, 0, 42), Vector3(10, 0, 52), Vector3(-15, 0, 54), Vector3(-35, 0, 50),
		Vector3(-45, 0, 36), Vector3(-58, 0, 28), Vector3(-74, 0, 24), Vector3(-76, 0, 6), Vector3(-74, 0, -16),
		Vector3(-55, 0, -20), Vector3(-36, 0, -35)
	]
	for pt in raw_beach_coords:
		island_beach_pts.append(world_to_map(pt))
	draw_colored_polygon(island_beach_pts, Color(0.85, 0.74, 0.52, 1.0))

	# 3. INTERIOR ISLAND LANDMASS
	var island_land_pts := PackedVector2Array()
	var raw_land_coords: Array[Vector3] = [
		Vector3(-26, 0, -40), Vector3(-16, 0, -53), Vector3(0, 0, -55), Vector3(16, 0, -53), Vector3(26, 0, -40),
		Vector3(32, 0, -34), Vector3(69, 0, -33), Vector3(73, 0, -16), Vector3(73, 0, 14), Vector3(67, 0, 33),
		Vector3(32, 0, 33), Vector3(20, 0, 39), Vector3(8, 0, 49), Vector3(-14, 0, 51), Vector3(-33, 0, 47),
		Vector3(-43, 0, 34), Vector3(-55, 0, 26), Vector3(-71, 0, 22), Vector3(-73, 0, 6), Vector3(-71, 0, -14),
		Vector3(-53, 0, -18), Vector3(-34, 0, -33)
	]
	for pt in raw_land_coords:
		island_land_pts.append(world_to_map(pt))
	draw_colored_polygon(island_land_pts, Color(0.24, 0.46, 0.22, 1.0))
	island_beach_pts.append(island_beach_pts[0])
	draw_polyline(island_beach_pts, Color(0.92, 0.82, 0.58, 1.0), 1.5, true)
	draw_rect(Rect2(0, 0, w, h), Color(0.2, 0.65, 0.95, 0.85), false, 2.0)

	# 4. WATER BODIES (Palace Lake in North, Swamp Waterways in South)
	# Palace Lake (Danau Istana)
	var lake_pts := PackedVector2Array()
	for pt in [
		Vector3(-16, 0, -36), Vector3(0, 0, -38), Vector3(16, 0, -36),
		Vector3(14, 0, -30), Vector3(0, 0, -28), Vector3(-14, 0, -30)
	]:
		lake_pts.append(world_to_map(pt))
	draw_colored_polygon(lake_pts, Color(0.12, 0.48, 0.65, 0.95))

	# Southern Swamp Canals & Ponds
	var swamp_col := Color(0.1, 0.32, 0.25, 0.95)
	for sc in [
		Rect2(world_to_map(Vector3(-44, 0, 38)), world_to_map(Vector3(-26, 0, 46)) - world_to_map(Vector3(-44, 0, 38))),
		Rect2(world_to_map(Vector3(-22, 0, 44)), world_to_map(Vector3(-2, 0, 52)) - world_to_map(Vector3(-22, 0, 44))),
		Rect2(world_to_map(Vector3(6, 0, 38)), world_to_map(Vector3(22, 0, 46)) - world_to_map(Vector3(6, 0, 38)))
	]:
		draw_rect(sc.abs(), swamp_col, true)

	# Sawah Plots (Rice Paddies in South)
	var sawah_col := Color(0.38, 0.68, 0.25, 0.9)
	for sp in [Vector3(-24, 0, 34), Vector3(-12, 0, 34), Vector3(4, 0, 38)]:
		var m_sp = world_to_map(sp)
		draw_rect(Rect2(m_sp.x - 6, m_sp.y - 4, 12, 8), sawah_col, true)

	# 5. RAILWAY LINE & STASIUN TENJO (East-West across Central)
	var r_start = world_to_map(Vector3(-65, 0, -5))
	var r_end = world_to_map(Vector3(68, 0, -5))
	draw_line(r_start, r_end, Color(0.32, 0.35, 0.38, 1.0), 3.5)
	draw_line(r_start, r_end, Color(0.85, 0.85, 0.88, 0.8), 1.0)

	# 6. ROAD NETWORK
	var road_asphalt := Color(0.18, 0.2, 0.22, 1.0)
	var road_marking := Color(0.9, 0.8, 0.25, 0.6)
	var dirt_road_col := Color(0.48, 0.34, 0.2, 1.0)
	var bridge_col := Color(0.55, 0.38, 0.22, 1.0)

	# Main Road (EW Highway: West -> Central -> East)
	var main_start = world_to_map(Vector3(-65, 0, 0))
	var main_end = world_to_map(Vector3(68, 0, 0))
	draw_line(main_start, main_end, road_asphalt, 7.0)
	draw_line(main_start, main_end, road_marking, 1.2)

	# Central NS Road
	var c_ns_s = world_to_map(Vector3(0, 0, -24))
	var c_ns_e = world_to_map(Vector3(0, 0, 24))
	draw_line(c_ns_s, c_ns_e, road_asphalt, 6.0)

	# West Industrial Ring Road
	var w_ring_n = world_to_map(Vector3(-55, 0, -18))
	var w_ring_s = world_to_map(Vector3(-55, 0, 26))
	var w_ring_w = world_to_map(Vector3(-72, 0, 5))
	var w_ring_e = world_to_map(Vector3(-36, 0, 5))
	draw_line(world_to_map(Vector3(-72, 0, -18)), world_to_map(Vector3(-36, 0, -18)), road_asphalt, 5.0)
	draw_line(world_to_map(Vector3(-72, 0, 26)), world_to_map(Vector3(-36, 0, 26)), road_asphalt, 5.0)
	draw_line(world_to_map(Vector3(-72, 0, -18)), world_to_map(Vector3(-72, 0, 26)), road_asphalt, 5.0)
	draw_line(world_to_map(Vector3(-36, 0, -18)), world_to_map(Vector3(-36, 0, 26)), road_asphalt, 5.0)

	# Northern Palace Lake Road Loop
	draw_line(world_to_map(Vector3(-22, 0, -24)), world_to_map(Vector3(22, 0, -24)), road_asphalt, 5.0)
	draw_line(world_to_map(Vector3(-22, 0, -24)), world_to_map(Vector3(-22, 0, -44)), road_asphalt, 5.0)
	draw_line(world_to_map(Vector3(22, 0, -24)), world_to_map(Vector3(22, 0, -44)), road_asphalt, 5.0)
	draw_line(world_to_map(Vector3(-22, 0, -44)), world_to_map(Vector3(22, 0, -44)), road_asphalt, 5.0)

	# Eastern Residential & School Grid
	draw_line(world_to_map(Vector3(20, 0, -22)), world_to_map(Vector3(68, 0, -22)), road_asphalt, 5.0)
	draw_line(world_to_map(Vector3(20, 0, 20)), world_to_map(Vector3(68, 0, 20)), road_asphalt, 5.0)
	draw_line(world_to_map(Vector3(20, 0, -32)), world_to_map(Vector3(20, 0, 32)), road_asphalt, 5.0)
	draw_line(world_to_map(Vector3(44, 0, -32)), world_to_map(Vector3(44, 0, 32)), road_asphalt, 5.0)
	draw_line(world_to_map(Vector3(68, 0, -32)), world_to_map(Vector3(68, 0, 32)), road_asphalt, 5.0)

	# Southern Winding Dirt Road (Scenic Swamp Trail)
	var dirt_trail: Array[Vector3] = [
		Vector3(-46, 0, 26), Vector3(-38, 0, 30), Vector3(-32, 0, 38), Vector3(-18, 0, 48),
		Vector3(-2, 0, 44), Vector3(10, 0, 34), Vector3(22, 0, 26)
	]
	for di in range(dirt_trail.size() - 1):
		draw_line(world_to_map(dirt_trail[di]), world_to_map(dirt_trail[di + 1]), dirt_road_col, 4.0)

	# Wooden Bridges
	draw_line(world_to_map(Vector3(-48, 0, 24)), world_to_map(Vector3(-48, 0, 30)), bridge_col, 6.0)
	draw_line(world_to_map(Vector3(-14, 0, 48)), world_to_map(Vector3(-10, 0, 48)), bridge_col, 6.0)
	draw_line(world_to_map(Vector3(22, 0, 22)), world_to_map(Vector3(22, 0, 26)), bridge_col, 6.0)

	# Use the uploaded pixel-art map as the base while keeping live game markers.
	var map_origin := world_to_map(Vector3(world_min_x, 0.0, world_min_z))
	var map_extent := world_to_map(Vector3(world_max_x, 0.0, world_max_z)) - map_origin
	draw_texture_rect(TENJO_MAP_TEXTURE, Rect2(map_origin, map_extent), false)

	# 7. REGIONAL LANDMARKS & SIGNS
	# Header
	draw_string(ThemeDB.fallback_font, Vector2(10, 16), "🗺️ TENJO ISLAND", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.9, 0.95, 1.0))

	# Region 1: Royal Palace of King Ari
	var palace_m = world_to_map(Vector3(0, 0, -50))
	draw_string(ThemeDB.fallback_font, palace_m + Vector2(-8, 3), "👑", HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
	draw_string(ThemeDB.fallback_font, palace_m + Vector2(-22, -8), "Istana Raja Ari", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1.0, 0.88, 0.3))

	# Region 2: SPPG Central Kitchen & Logistics
	var sppg_m = world_to_map(sppg_pos)
	draw_circle(sppg_m, 6.0, Color(0.15, 0.92, 0.42, 1.0))
	draw_string(ThemeDB.fallback_font, sppg_m + Vector2(-16, -8), "🏭 SPPG", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.2, 0.95, 0.4))

	# Region 3: Tenjo Station & Trade Center
	var station_m = world_to_map(Vector3(-10, 0, -10))
	draw_string(ThemeDB.fallback_font, station_m + Vector2(-6, 3), "🚉", HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
	draw_string(ThemeDB.fallback_font, station_m + Vector2(-18, -8), "St. Tenjo", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.85, 0.9, 1.0))

	var market_m = world_to_map(Vector3(-8, 0, 8))
	draw_string(ThemeDB.fallback_font, market_m + Vector2(-6, 3), "🏮", HORIZONTAL_ALIGNMENT_CENTER, -1, 10)

	# SPBU (Gas Station)
	var spbu_m = world_to_map(spbu_pos)
	draw_circle(spbu_m, 5.0, Color(0.1, 0.72, 1.0, 1.0))
	draw_string(ThemeDB.fallback_font, spbu_m + Vector2(7, 3), "⛽ SPBU", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.3, 0.88, 1.0))

	# Road Blockade (Demonstran)
	var block_m = world_to_map(blockade_pos)
	draw_rect(Rect2(block_m.x - 7, block_m.y - 3, 14, 6), Color(0.92, 0.18, 0.18, 0.95), true)
	draw_string(ThemeDB.fallback_font, block_m + Vector2(-14, -6), "⛔ Blokade", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1.0, 0.3, 0.3))

	# 8. THE 5 SCHOOLS (Region 4: Eastern Modern Housing & Schools)
	var gm = get_node_or_null("/root/GameManager")
	if gm and "schools_data" in gm:
		for i in range(gm.schools_data.size()):
			var s_data: Dictionary = gm.schools_data[i]
			var s_pos = world_to_map(s_data["pos"])
			var is_current: bool = (i == gm.current_school_idx and gm.current_state == gm.State.DELIVERING)
			var is_done: bool = s_data.get("delivered", false)

			if is_done:
				draw_circle(s_pos, 4.5, Color(0.2, 0.88, 0.32, 0.9))
				draw_string(ThemeDB.fallback_font, s_pos + Vector2(6, 3), "✓ " + s_data["short_name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.4, 1.0, 0.5))
			elif is_current:
				var pulse = 5.5 + sin(pulse_time) * 1.5
				draw_circle(s_pos, pulse + 2.0, Color(1.0, 0.75, 0.1, 0.45))
				draw_circle(s_pos, pulse, Color(1.0, 0.65, 0.05, 1.0))
				draw_string(ThemeDB.fallback_font, s_pos + Vector2(8, 3), "➔ " + s_data["short_name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.88, 0.2))
			else:
				draw_circle(s_pos, 4.0, Color(0.68, 0.68, 0.72, 0.75))
				draw_string(ThemeDB.fallback_font, s_pos + Vector2(6, 3), s_data["short_name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.8, 0.84, 0.88))

	# 9. DYNAMIC TRAFFIC CARS
	var npc_cars = get_tree().get_nodes_in_group("npc_traffic")
	for npc in npc_cars:
		if is_instance_valid(npc) and npc is Node3D:
			var npc_pos = world_to_map(npc.global_position)
			draw_circle(npc_pos, 3.0, Color(1.0, 0.72, 0.18, 0.95))

	# 10. PLAYER CAR POSITION & FORWARD HEADING ARROW
	if player and is_instance_valid(player):
		var p_pos = player.global_position
		if player.has_method("get_global_transform_interpolated"):
			p_pos = player.get_global_transform_interpolated().origin
		var car_pos = world_to_map(p_pos)
		var forward_angle = -player.global_rotation.y - PI / 2.0

		draw_circle(car_pos, 5.0, Color.WHITE)
		var dir_vec = Vector2(cos(forward_angle), sin(forward_angle)) * 8.5
		draw_line(car_pos, car_pos + dir_vec, Color(0.2, 0.72, 1.0, 1.0), 2.5)

		# Distance counter to active mission goal
		if gm:
			var target_pos = gm.get_active_target_pos()
			var dist = player.global_position.distance_to(target_pos)
			var target_name = gm.get_active_target_name()
			var dist_text = "%s: %dm" % [target_name, int(dist)]
			draw_string(ThemeDB.fallback_font, Vector2(10, h - 8), dist_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.9, 0.4))

func world_to_map(world_pos: Vector3) -> Vector2:
	var pad = 12.0
	var nx = inverse_lerp(world_min_x, world_max_x, world_pos.x)
	var nz = inverse_lerp(world_min_z, world_max_z, world_pos.z)
	var mx = lerp(pad, size.x - pad, nx)
	var my = lerp(pad, size.y - pad, nz)
	return Vector2(mx, my)
