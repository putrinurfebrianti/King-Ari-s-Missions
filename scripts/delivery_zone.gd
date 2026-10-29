extends Area3D

enum ZoneType { SPPG, SCHOOL, SPBU }
@export var zone_type: ZoneType = ZoneType.SPPG
@export var school_index: int = 0

var player_car: Node3D
var player_ped: Node3D
var prompt_label: Label3D
var mesh_indicator: MeshInstance3D
var is_player_nearby: bool = false
var pulse_time: float = 0.0

func _ready() -> void:
	# Pastikan mendeteksi Layer 1 (World), Layer 2 (Car), dan Layer 4 (Pedestrian) -> mask 7 (0b111)
	collision_layer = 1
	collision_mask = 7

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_setup_visual_indicator()
	call_deferred("_find_players")

func _setup_visual_indicator() -> void:
	# Buat label 3D mengambang jika belum ada
	prompt_label = get_node_or_null("Label3D") as Label3D
	if not prompt_label:
		prompt_label = Label3D.new()
		prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		prompt_label.font_size = 24
		prompt_label.outline_size = 6
		prompt_label.outline_modulate = Color.BLACK
		prompt_label.position = Vector3(0, 2.8, 0)
		add_child(prompt_label)

	mesh_indicator = get_node_or_null("MeshInstance3D") as MeshInstance3D

	_update_prompt_text()

func _find_players() -> void:
	player_car = get_tree().get_first_node_in_group("player") as Node3D
	player_ped = get_tree().get_first_node_in_group("pedestrian") as Node3D

func _physics_process(delta: float) -> void:
	pulse_time += delta * 4.0

	if not player_car or not is_instance_valid(player_car):
		_find_players()
		return

	# Cek posisi pemain terdekat (mobil atau pejalan kaki)
	var active_pos = player_car.global_position
	if player_ped and is_instance_valid(player_ped) and player_ped.visible:
		active_pos = player_ped.global_position

	var dist = global_position.distance_to(active_pos)
	var trigger_dist = 8.5

	# Animasi visual pulse
	if mesh_indicator:
		var s = 1.0 + sin(pulse_time) * 0.06
		mesh_indicator.scale = Vector3(s, 1.0, s)

	# Update visibilitas & teks label sesuai status misi
	_update_prompt_text()

	# Pengecekan pemicu berdasarkan jarak (Fallback Jaminan 100% Aktif)
	if dist <= trigger_dist:
		if not is_player_nearby:
			is_player_nearby = true
			_trigger_zone_action()
	else:
		if is_player_nearby:
			is_player_nearby = false
			_exit_zone_action()

func _update_prompt_text() -> void:
	if not prompt_label:
		return

	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return

	if zone_type == ZoneType.SPPG:
		if gm.current_state == gm.State.AT_SPPG:
			prompt_label.visible = true
			prompt_label.text = "📦 DAPUR SPPG\n[AMBIL RANSUM MBG DI SINI]"
			prompt_label.modulate = Color(0.2, 1.0, 0.4)
		else:
			prompt_label.visible = false

	elif zone_type == ZoneType.SCHOOL:
		var is_active = (gm.current_state == gm.State.DELIVERING and gm.current_school_idx == school_index)
		var is_delivered = false
		if school_index < gm.schools_data.size():
			is_delivered = gm.schools_data[school_index].get("delivered", false)

		if is_delivered:
			prompt_label.visible = true
			prompt_label.text = "✓ %s\n[TERKIRIM]" % gm.schools_data[school_index]["name"]
			prompt_label.modulate = Color(0.3, 1.0, 0.4)
		elif is_active:
			prompt_label.visible = true
			prompt_label.text = "🏫 %s\n➔ [ANTAR MBG KE SINI]" % gm.schools_data[school_index]["name"]
			prompt_label.modulate = Color(1.0, 0.85, 0.1)
		else:
			prompt_label.visible = true
			prompt_label.text = "🏫 %s" % gm.schools_data[school_index]["name"]
			prompt_label.modulate = Color(0.7, 0.7, 0.75)

	elif zone_type == ZoneType.SPBU:
		prompt_label.visible = true
		prompt_label.text = "⛽ SPBU TENJO\n[PENGISIAN BENSIN]"
		prompt_label.modulate = Color(0.3, 0.85, 1.0)

func _trigger_zone_action() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return

	if zone_type == ZoneType.SPPG:
		if gm.current_state == gm.State.AT_SPPG:
			gm.start_delivery()
			var hud = get_node_or_null("/root/Main/HUD")
			if hud and hud.has_method("show_toast"):
				hud.show_toast("🚚 Ransum MBG Dimuat! Kawal ke 5 Sekolah sebelum waktu habis (05:00)!", 4.0)

	elif zone_type == ZoneType.SCHOOL:
		if gm.current_state == gm.State.DELIVERING and gm.current_school_idx == school_index:
			gm.deliver_to_school(school_index)
			var hud = get_node_or_null("/root/Main/HUD")
			if hud and hud.has_method("show_toast"):
				var school_name = gm.schools_data[school_index]["name"]
				hud.show_toast("🎉 MBG Berhasil Diserahkan ke %s! Upah: +5 Koin Perak!" % school_name, 3.5)

	elif zone_type == ZoneType.SPBU:
		gm.set_refueling(true)
		var hud = get_node_or_null("/root/Main/HUD")
		if hud and hud.has_method("show_toast"):
			hud.show_toast("⛽ SPBU Tenjo: Mengisi bahan bakar (40L)...", 3.0)

func _exit_zone_action() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and zone_type == ZoneType.SPBU:
		gm.set_refueling(false)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("pedestrian"):
		_trigger_zone_action()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("pedestrian"):
		_exit_zone_action()
