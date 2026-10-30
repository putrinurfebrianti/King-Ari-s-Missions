extends Area3D

enum ZoneType { SPPG, SCHOOL, SPBU }
const PLAYER_CAR_COLLISION_LAYER: int = 2
const PLAYER_PEDESTRIAN_COLLISION_LAYER: int = 4

@export var zone_type: ZoneType = ZoneType.SPPG
@export var school_index: int = 0

var player_car: Node3D
var player_ped: Node3D
var prompt_label: Label3D
var mesh_indicator: MeshInstance3D
var is_player_nearby: bool = false
var pulse_time: float = 0.0

func _ready() -> void:
	add_to_group("delivery_zone")
	collision_layer = 1
	collision_mask = PLAYER_CAR_COLLISION_LAYER | PLAYER_PEDESTRIAN_COLLISION_LAYER
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_school_label()

func _update_school_label() -> void:
	if zone_type != ZoneType.SCHOOL:
		return
	var gm = get_node_or_null("/root/GameManager")
	if not gm or school_index < 0 or school_index >= gm.schools_data.size():
		return

	var label := get_node_or_null("Label3D") as Label3D
	if label:
		var school: Dictionary = gm.schools_data[school_index]
		label.text = "SEKOLAH\n%s" % _format_sign_name(school["name"])
		label.font_size = 30
		label.pixel_size = 0.015
		label.position = Vector3(0.0, 2.45, 4.12)
		label.modulate = Color(0.94, 0.9, 0.75, 1.0)
		label.outline_modulate = Color(0.08, 0.12, 0.09, 1.0)
		label.outline_size = 6
		_create_school_sign()

func _format_sign_name(school_name: String) -> String:
	var lines: Array[String] = []
	var current_line := ""
	for word in school_name.split(" "):
		if not current_line.is_empty() and current_line.length() + word.length() + 1 > 16:
			lines.append(current_line)
			current_line = word
		elif current_line.is_empty():
			current_line = word
		else:
			current_line += " " + word
	if not current_line.is_empty():
		lines.append(current_line)
	return "\n".join(lines)

func _create_school_sign() -> void:
	var board_material := StandardMaterial3D.new()
	board_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	board_material.albedo_color = Color(0.18, 0.29, 0.22, 1.0)

	var board := MeshInstance3D.new()
	board.name = "SchoolSignBoard"
	var board_mesh := BoxMesh.new()
	board_mesh.size = Vector3(11.0, 2.5, 0.22)
	board_mesh.material = board_material
	board.mesh = board_mesh
	board.position = Vector3(0.0, 2.45, 4.0)
	add_child(board)

	var post_material := StandardMaterial3D.new()
	post_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	post_material.albedo_color = Color(0.31, 0.24, 0.16, 1.0)
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.name = "SchoolSignPost%s" % ("Left" if side < 0.0 else "Right")
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.28, 2.5, 0.3)
		post_mesh.material = post_material
		post.mesh = post_mesh
		post.position = Vector3(side * 5.1, 1.25, 4.0)
		add_child(post)

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
	var active_pos: Vector3 = player_car.global_position
	if player_ped and is_instance_valid(player_ped) and player_ped.visible:
		active_pos = player_ped.global_position

	var dist: float = global_position.distance_to(active_pos)
	var trigger_dist: float = 8.5

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
			if zone_type == ZoneType.SPBU:
				var gm = get_node_or_null("/root/GameManager")
				if gm:
					gm.set_refueling(true)
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
			prompt_label.text = "📦 DAPUR SPPG\n[ENTER: AMBIL RANSUM MBG]"
			prompt_label.modulate = Color(0.2, 1.0, 0.4)
		else:
			prompt_label.visible = false

	elif zone_type == ZoneType.SCHOOL:
		var is_active: bool = (
			gm.current_state == gm.State.DELIVERING
			and gm.current_school_idx == school_index
		)
		var is_delivered: bool = false
		if school_index < gm.schools_data.size():
			is_delivered = gm.schools_data[school_index].get("delivered", false)

		if is_delivered:
			prompt_label.visible = true
			prompt_label.text = "✓ %s\n[TERKIRIM]" % gm.schools_data[school_index]["name"]
			prompt_label.modulate = Color(0.3, 1.0, 0.4)
		elif is_active:
			prompt_label.visible = true
			prompt_label.text = "🏫 %s\n[ENTER: ANTAR MBG]" % gm.schools_data[school_index]["name"]
			prompt_label.modulate = Color(1.0, 0.85, 0.1)
		else:
			prompt_label.visible = true
			prompt_label.text = "🏫 %s" % gm.schools_data[school_index]["name"]
			prompt_label.modulate = Color(0.7, 0.7, 0.75)

	elif zone_type == ZoneType.SPBU:
		prompt_label.visible = true
		prompt_label.text = "⛽ SPBU TENJO\n[PENGISIAN BENSIN]"
		prompt_label.modulate = Color(0.3, 0.85, 1.0)

func can_interact(actor: Node3D) -> bool:
	var gm = get_node_or_null("/root/GameManager")
	if not gm or not actor:
		return false

	if zone_type == ZoneType.SPPG:
		return (
			gm.current_state == gm.State.AT_SPPG
			and actor.is_in_group("pedestrian")
			and actor.get("is_active") == true
		)
	if zone_type == ZoneType.SCHOOL:
		return (
			gm.current_state == gm.State.DELIVERING
			and school_index == gm.current_school_idx
		)
	return false

func interact(actor: Node3D) -> bool:
	if not can_interact(actor):
		return false

	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return false

	if zone_type == ZoneType.SPPG:
		gm.start_delivery()
	else:
		gm.deliver_to_school(school_index)
	return true

func _exit_zone_action() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and zone_type == ZoneType.SPBU:
		gm.set_refueling(false)

func _on_body_entered(body: Node3D) -> void:
	if zone_type == ZoneType.SPBU and (
		body.is_in_group("player") or body.is_in_group("pedestrian")
	):
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			gm.set_refueling(true)

func _on_body_exited(body: Node3D) -> void:
	if zone_type == ZoneType.SPBU and (
		body.is_in_group("player") or body.is_in_group("pedestrian")
	):
		_exit_zone_action()
