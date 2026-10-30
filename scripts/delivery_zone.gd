extends Area3D

enum ZoneType { SPPG, SCHOOL, SPBU }
const PLAYER_CAR_COLLISION_LAYER: int = 2
const PLAYER_PEDESTRIAN_COLLISION_LAYER: int = 4

@export var zone_type: ZoneType = ZoneType.SPPG
@export var school_index: int = 0

func _ready() -> void:
	add_to_group("delivery_zone")
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

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") and not body.is_in_group("pedestrian"):
		return
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return

	if zone_type == ZoneType.SPBU:
		gm.set_refueling(true)
		var hud = get_node_or_null("/root/Main/HUD")
		if hud and hud.has_method("show_toast"):
			hud.show_toast("⛽ SPBU Tenjo: Mengisi bahan bakar hingga penuh...", 3.0)

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

func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player") and not body.is_in_group("pedestrian"):
		return
	var gm = get_node_or_null("/root/GameManager")
	if gm and zone_type == ZoneType.SPBU:
		gm.set_refueling(false)
