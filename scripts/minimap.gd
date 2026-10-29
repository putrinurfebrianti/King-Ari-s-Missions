extends Control

@export var player: Node3D
@export var sppg_pos: Vector3 = Vector3(-50.0, 0.15, 0.0)
@export var spbu_pos: Vector3 = Vector3(18.0, 0.15, 40.0)
@export var blockade_pos: Vector3 = Vector3(-18.0, 0.15, 40.0)

var world_min_x: float = -75.0
var world_max_x: float = 75.0
var world_min_z: float = -55.0
var world_max_z: float = 55.0

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
		offset_left = -340
		offset_top = -240
		offset_right = 340
		offset_bottom = 240
	else:
		set_anchors_preset(Control.PRESET_TOP_RIGHT)
		offset_left = -240
		offset_top = 16
		offset_right = -20
		offset_bottom = 176
	queue_redraw()

func _process(delta: float) -> void:
	pulse_time += delta * 4.0
	queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y

	# Latar belakang panel minimap (Dark Semi-Transparent Glassmorphism)
	draw_rect(Rect2(0, 0, w, h), Color(0.06, 0.1, 0.16, 0.92), true)
	draw_rect(Rect2(0, 0, w, h), Color(0.2, 0.65, 0.95, 0.85), false, 2.0)

	# Label header minimap
	draw_string(ThemeDB.fallback_font, Vector2(10, 16), "🗺️ PETA TENJO ISLAND", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.9, 0.95, 1.0))

	# 0. Laut Pesisir Timur (Canal / Coast)
	var coast_top = world_to_map(Vector3(66, 0, -50))
	var coast_bot = world_to_map(Vector3(66, 0, 50))
	var water_rect = Rect2(coast_top.x, 0, w - coast_top.x, h)
	draw_rect(water_rect, Color(0.12, 0.42, 0.68, 0.75), true)
	draw_string(ThemeDB.fallback_font, Vector2(w - 32, h / 2.0), "🌊", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(0.8, 0.95, 1.0))

	# 1. Gambar Jalan Grid (Outer Loop & Center Cross)
	var road_color = Color(0.25, 0.28, 0.32, 1.0)
	var dash_color = Color(0.85, 0.85, 0.85, 0.35)

	# Jalan Utara (North EW)
	var n_start = world_to_map(Vector3(-55, 0, -40))
	var n_end = world_to_map(Vector3(55, 0, -40))
	draw_line(n_start, n_end, road_color, 7.0)
	draw_line(n_start, n_end, dash_color, 1.0)

	# Jalan Selatan (South EW)
	var s_start = world_to_map(Vector3(-55, 0, 40))
	var s_end = world_to_map(Vector3(55, 0, 40))
	draw_line(s_start, s_end, road_color, 7.0)
	draw_line(s_start, s_end, dash_color, 1.0)

	# Jalan Barat (West NS)
	var w_start = world_to_map(Vector3(-52, 0, -40))
	var w_end = world_to_map(Vector3(-52, 0, 40))
	draw_line(w_start, w_end, road_color, 7.0)
	draw_line(w_start, w_end, dash_color, 1.0)

	# Jalan Timur (East NS)
	var e_start = world_to_map(Vector3(52, 0, -40))
	var e_end = world_to_map(Vector3(52, 0, 40))
	draw_line(e_start, e_end, road_color, 7.0)
	draw_line(e_start, e_end, dash_color, 1.0)

	# Jalan Pusat Barat - Timur (Center EW)
	var ew_start = world_to_map(Vector3(-55, 0, 0))
	var ew_end = world_to_map(Vector3(55, 0, 0))
	draw_line(ew_start, ew_end, road_color, 9.0)
	draw_line(ew_start, ew_end, dash_color, 1.0)

	# Jalan Pusat Utara - Selatan (Center NS)
	var ns_start = world_to_map(Vector3(0, 0, -40))
	var ns_end = world_to_map(Vector3(0, 0, 40))
	draw_line(ns_start, ns_end, road_color, 9.0)
	draw_line(ns_start, ns_end, dash_color, 1.0)

	# 2. Bundaran Tengah (Roundabout & Air Mancur)
	var center_map = world_to_map(Vector3(0, 0, 0))
	var r_outer = (world_to_map(Vector3(12, 0, 0)).x - center_map.x)
	draw_arc(center_map, r_outer, 0, TAU, 28, road_color, 9.0)
	draw_circle(center_map, r_outer - 3.0, Color(0.18, 0.55, 0.25, 1.0))
	draw_circle(center_map, 3.2, Color(0.2, 0.7, 0.95, 1.0))

	# 3. Landmark Ikon Kota (Sesuai Denah)
	var hosp_pos = world_to_map(Vector3(-30, 0, -24))
	draw_string(ThemeDB.fallback_font, hosp_pos + Vector2(-6, 3), "🏥", HORIZONTAL_ALIGNMENT_CENTER, -1, 10)

	var ff_pos = world_to_map(Vector3(46, 0, -14))
	draw_string(ThemeDB.fallback_font, ff_pos + Vector2(-6, 3), "🍔", HORIZONTAL_ALIGNMENT_CENTER, -1, 10)

	var pol_pos = world_to_map(Vector3(-30, 0, 24))
	draw_string(ThemeDB.fallback_font, pol_pos + Vector2(-6, 3), "🚓", HORIZONTAL_ALIGNMENT_CENTER, -1, 10)

	var fire_pos = world_to_map(Vector3(24, 0, 24))
	draw_string(ThemeDB.fallback_font, fire_pos + Vector2(-6, 3), "🚒", HORIZONTAL_ALIGNMENT_CENTER, -1, 10)

	var smkt_pos = world_to_map(Vector3(44, 0, 22))
	draw_string(ThemeDB.fallback_font, smkt_pos + Vector2(-6, 3), "🛒", HORIZONTAL_ALIGNMENT_CENTER, -1, 10)

	var grave_pos = world_to_map(Vector3(-16, 0, -26))
	draw_string(ThemeDB.fallback_font, grave_pos + Vector2(-6, 3), "🪦", HORIZONTAL_ALIGNMENT_CENTER, -1, 10)

	var house_pos = world_to_map(Vector3(-44, 0, -14))
	draw_string(ThemeDB.fallback_font, house_pos + Vector2(-6, 3), "🏠", HORIZONTAL_ALIGNMENT_CENTER, -1, 10)

	# 4. Marker Blokade Demonstrasi Warga
	var block_map = world_to_map(blockade_pos)
	draw_rect(Rect2(block_map.x - 7, block_map.y - 3, 14, 6), Color(0.9, 0.15, 0.15, 0.95), true)
	draw_string(ThemeDB.fallback_font, block_map + Vector2(-12, -5), "⛔ Blokade", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1.0, 0.3, 0.3))

	# 5. Marker SPBU (Gas Station)
	var spbu_map = world_to_map(spbu_pos)
	draw_circle(spbu_map, 5.0, Color(0.1, 0.7, 1.0, 1.0))
	draw_string(ThemeDB.fallback_font, spbu_map + Vector2(-12, -7), "⛽ SPBU", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.3, 0.85, 1.0))

	# 6. Marker SPPG (Dapur Sentral MBG)
	var sppg_map = world_to_map(sppg_pos)
	draw_circle(sppg_map, 6.0, Color(0.15, 0.9, 0.4, 1.0))
	draw_string(ThemeDB.fallback_font, sppg_map + Vector2(-14, -7), "SPPG", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.2, 0.95, 0.4))

	# 7. Marker 5 Sekolah Tujuan (GDD Bab 4.2 & 12.2)
	var gm = get_node_or_null("/root/GameManager")
	if gm and "schools_data" in gm:
		for i in range(gm.schools_data.size()):
			var s_data = gm.schools_data[i]
			var s_pos = world_to_map(s_data["pos"])
			var is_current = (i == gm.current_school_idx and gm.current_state == gm.State.DELIVERING)
			var is_done = s_data.get("delivered", false)
			
			if is_done:
				# Sekolah sudah selesai dikirimkan
				draw_circle(s_pos, 4.5, Color(0.2, 0.85, 0.3, 0.85))
				draw_string(ThemeDB.fallback_font, s_pos + Vector2(6, 3), "✓ " + s_data["short_name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.4, 1.0, 0.5))
			elif is_current:
				# Sekolah target aktif yang berdenyut (Pulse)
				var pulse = 5.5 + sin(pulse_time) * 1.5
				draw_circle(s_pos, pulse + 2.0, Color(1.0, 0.75, 0.1, 0.45))
				draw_circle(s_pos, pulse, Color(1.0, 0.65, 0.05, 1.0))
				draw_string(ThemeDB.fallback_font, s_pos + Vector2(8, 3), "➔ " + s_data["short_name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.85, 0.2))
			else:
				# Sekolah berikutnya
				draw_circle(s_pos, 4.0, Color(0.65, 0.65, 0.7, 0.75))
				draw_string(ThemeDB.fallback_font, s_pos + Vector2(6, 3), s_data["short_name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.75, 0.8, 0.85))

	# 8. Posisi & Rotasi Mobil Pemain
	if player:
		var p_pos = player.global_position
		if player.has_method("get_global_transform_interpolated"):
			p_pos = player.get_global_transform_interpolated().origin
		var car_pos = world_to_map(p_pos)
		var forward_angle = -player.global_rotation.y - PI / 2.0
		
		draw_circle(car_pos, 4.5, Color(1.0, 1.0, 1.0, 1.0))
		var dir_vec = Vector2(cos(forward_angle), sin(forward_angle)) * 8.0
		draw_line(car_pos, car_pos + dir_vec, Color(0.2, 0.7, 1.0, 1.0), 2.5)

		# Teks jarak ke target aktif
		if gm:
			var target_pos = gm.get_active_target_pos()
			var dist = player.global_position.distance_to(target_pos)
			var target_name = gm.get_active_target_name()
			var dist_text = "%s: %dm" % [target_name, int(dist)]
			draw_string(ThemeDB.fallback_font, Vector2(10, h - 8), dist_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.9, 0.4))

		# Posisi Rama pejalan kaki
		var ped = get_tree().get_first_node_in_group("pedestrian") as Node3D
		if ped and ped.visible:
			var ped_pos = world_to_map(ped.global_position)
			draw_circle(ped_pos, 3.8, Color(0.2, 0.95, 1.0, 1.0))
			draw_string(ThemeDB.fallback_font, ped_pos + Vector2(5, 3), "Rama", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.3, 0.95, 1.0))

func world_to_map(world_pos: Vector3) -> Vector2:
	var pad = 14.0
	var nx = inverse_lerp(world_min_x, world_max_x, world_pos.x)
	var nz = inverse_lerp(world_min_z, world_max_z, world_pos.z)
	var mx = lerp(pad, size.x - pad, nx)
	var my = lerp(pad, size.y - pad, nz)
	return Vector2(mx, my)
