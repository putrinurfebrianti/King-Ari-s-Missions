extends CharacterBody3D

@export var car_type: int = 0 # 0=Sedan, 1=Taksi, 2=Hatchback, 3=Angkot, 4=Pickup, 5=SUV
@export var base_speed: float = 10.5
@export var waypoints: Array[Vector3] = []
@export var current_waypoint_idx: int = 0
@export var stop_distance: float = 6.0
@export var waypoint_reach_dist: float = 3.5

var current_speed: float = 0.0
var target_speed: float = 10.5
var is_stopped_by_obstacle: bool = false
var stop_timer: float = 0.0
var honk_cooldown: float = 0.0

@onready var visual_root: Node3D = $Visual
@onready var front_ray: RayCast3D = $FrontRay
@onready var headlights: Node3D = $Headlights
@onready var taillights_mesh: MeshInstance3D = get_node_or_null("Visual/Taillights")

var wheel_nodes: Array[Node3D] = []

func _ready() -> void:
	add_to_group("npc_traffic")
	collision_layer = 2 # Sama dengan layer mobil agar interaksi benturan realistis
	collision_mask = 1 | 2

	# Variasikan kecepatan sedikit agar tidak monoton
	target_speed = base_speed * randf_range(0.9, 1.15)
	current_speed = target_speed

	_find_wheels()
	_apply_vehicle_style()

	# Hubungkan cuaca/season untuk lampu malam
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_signal("season_changed"):
		gm.season_changed.connect(_on_season_changed)
		_update_night_lights(gm.current_season == gm.Season.MALAM)
	else:
		_update_night_lights(false)

func _find_wheels() -> void:
	wheel_nodes.clear()
	for w_name in ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]:
		var w = get_node_or_null("Visual/" + w_name) as Node3D
		if w:
			wheel_nodes.append(w)

func _apply_vehicle_style() -> void:
	var body_mesh = get_node_or_null("Visual/Body") as MeshInstance3D
	if not body_mesh:
		return

	# Material unik untuk ragam jenis kendaraan
	var mat = StandardMaterial3D.new()
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.roughness = 0.35

	match car_type:
		0: # Sedan Klasik (Merah Cerah)
			mat.albedo_color = Color(0.85, 0.18, 0.18)
		1: # Taksi Kota Tenjo (Kuning Taksi)
			mat.albedo_color = Color(0.95, 0.82, 0.12)
		2: # Hatchback Compact (Biru Elektrik)
			mat.albedo_color = Color(0.18, 0.45, 0.88)
		3: # Angkot / Minibus Penumpang (Hijau Daun)
			mat.albedo_color = Color(0.2, 0.75, 0.35)
		4: # Pickup Muatan Warga (Abu-abu Perak)
			mat.albedo_color = Color(0.65, 0.68, 0.72)
		_: # SUV Kota (Oranye Sporty)
			mat.albedo_color = Color(0.92, 0.45, 0.12)

	body_mesh.material_override = mat

func _physics_process(delta: float) -> void:
	if waypoints.is_empty():
		return

	honk_cooldown -= delta

	# Deteksi rintangan di depan (Mobil Pemain, Pejalan Kaki, atau Mobil NPC Lain)
	var obstacle_in_front = false
	if front_ray and front_ray.is_colliding():
		var col = front_ray.get_collider()
		if col != self:
			obstacle_in_front = true

	# Jarak langsung ke pemain (PlayerCar atau PlayerPedestrian)
	var player_car = get_tree().get_first_node_in_group("player") as Node3D
	if player_car and is_instance_valid(player_car):
		var to_player = player_car.global_position - global_position
		# Cek apakah pemain tepat di depan mobil dalam sudut 45 derajat
		var fwd = -global_transform.basis.z
		var dist_to_player = to_player.length()
		if dist_to_player < stop_distance and fwd.dot(to_player.normalized()) > 0.5:
			obstacle_in_front = true

	# Manajemen kecepatan & pengereman
	if obstacle_in_front:
		is_stopped_by_obstacle = true
		stop_timer += delta
		current_speed = lerp(current_speed, 0.0, 1.0 - exp(-15.0 * delta))
	else:
		is_stopped_by_obstacle = false
		stop_timer = 0.0
		current_speed = lerp(current_speed, target_speed, 1.0 - exp(-6.0 * delta))

	# Navigasi ke Waypoint aktif
	var target_wp = waypoints[current_waypoint_idx]
	var to_wp = target_wp - global_position
	to_wp.y = 0.0

	var dist_wp = to_wp.length()
	if dist_wp < waypoint_reach_dist:
		current_waypoint_idx = (current_waypoint_idx + 1) % waypoints.size()
		target_wp = waypoints[current_waypoint_idx]
		to_wp = target_wp - global_position
		to_wp.y = 0.0

	# Kemudi Halus menuju Waypoint
	if to_wp.length() > 0.1:
		var target_rot_y = atan2(-to_wp.x, -to_wp.z)
		rotation.y = lerp_angle(rotation.y, target_rot_y, 1.0 - exp(-6.0 * delta))

	# Gerak Maju
	var move_vec = -global_transform.basis.z * current_speed
	velocity.x = move_vec.x
	velocity.z = move_vec.z
	velocity.y = 0.0

	move_and_slide()

	# Putar Roda
	var wheel_spin = (current_speed / 0.38) * delta
	for w in wheel_nodes:
		if is_instance_valid(w):
			w.rotate_x(wheel_spin)

func _on_season_changed(season_int: int) -> void:
	var gm = get_node_or_null("/root/GameManager")
	var is_night = (gm and season_int == gm.Season.MALAM)
	_update_night_lights(is_night)

func _update_night_lights(is_night: bool) -> void:
	if headlights:
		headlights.visible = is_night
	if taillights_mesh:
		var mat = taillights_mesh.get_active_material(0)
		if mat is StandardMaterial3D:
			mat.emission_energy_multiplier = 2.0 if is_night else 0.5

