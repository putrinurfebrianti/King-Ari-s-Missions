extends Area3D

enum ZoneType { SPPG, SCHOOL, SPBU }
@export var zone_type: ZoneType = ZoneType.SPPG
@export var school_index: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") and not body.is_in_group("pedestrian"):
		return
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return

	if zone_type == ZoneType.SPPG:
		gm.start_delivery()
	elif zone_type == ZoneType.SCHOOL:
		gm.deliver_to_school(school_index)
	elif zone_type == ZoneType.SPBU:
		gm.set_refueling(true)
		var hud = get_node_or_null("/root/Main/HUD")
		if hud and hud.has_method("show_toast"):
			hud.show_toast("⛽ SPBU Tenjo: Mengisi bahan bakar hingga penuh...", 3.0)

func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player") and not body.is_in_group("pedestrian"):
		return
	var gm = get_node_or_null("/root/GameManager")
	if gm and zone_type == ZoneType.SPBU:
		gm.set_refueling(false)
