extends StaticBody3D

@onready var sign_label: Label3D = $SignBoard/SignLabel
@onready var flag_mesh: MeshInstance3D = $RoofFlag
var is_player_nearby: bool = false

func _ready() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.house_purchased.connect(_on_house_purchased)
		_update_display(gm.owns_house)

func _physics_process(_delta: float) -> void:
	var car = get_tree().get_first_node_in_group("player") as Node3D
	var ped = get_tree().get_first_node_in_group("pedestrian") as Node3D
	var p_pos = Vector3.ZERO
	if ped and is_instance_valid(ped) and ped.visible:
		p_pos = ped.global_position
	elif car and is_instance_valid(car):
		p_pos = car.global_position
	else:
		return

	var dist = global_position.distance_to(p_pos)
	is_player_nearby = (dist <= 8.0)

	var gm = get_node_or_null("/root/GameManager")
	if gm and is_player_nearby and not gm.owns_house:
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_B):
			attempt_buy()

func attempt_buy() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
	var success = gm.buy_house()
	var hud = get_node_or_null("/root/Main/HUD")
	if success:
		_update_display(true)
		if hud and hud.has_method("show_toast"):
			hud.show_toast("🏠 SELAMAT! Anda resmi membeli Rumah Pribadi di Tenjo Island (2.500 Koin)!", 4.0)
	else:
		if hud and hud.has_method("show_toast"):
			hud.show_toast("💰 Koin kurang! Butuh 2.500 koin untuk membeli rumah ini.", 3.0)

func _on_house_purchased() -> void:
	_update_display(true)

func _update_display(owned: bool) -> void:
	if not sign_label:
		return
	if owned:
		sign_label.text = "🏠 RUMAH PRIBADI PENGAWAL MBG\n[HAK MILIK ANDA]"
		sign_label.modulate = Color(0.2, 1.0, 0.4)
		if flag_mesh:
			flag_mesh.visible = true
	else:
		sign_label.text = "🏡 RUMAH DIJUAL: 2.500 KOIN\n[Dekati & Tekan B untuk Beli]"
		sign_label.modulate = Color(1.0, 0.85, 0.2)
		if flag_mesh:
			flag_mesh.visible = false
