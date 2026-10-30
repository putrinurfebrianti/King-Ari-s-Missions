extends Camera3D

signal camera_mode_changed(mode_name: String)

enum CameraMode {
	ISOMETRIC,      # POV Awal (Tinjauan Kota Isometrik dari atas)
	IN_CAR_HOOD,    # POV Dalam Mobil / Kap Depan (Jalanan Full Kelihatan)
	CHASE_CAM       # POV Chase Belakang Mobil (Third-person follow)
}

@export var camera_mode: CameraMode = CameraMode.ISOMETRIC
@export var target: Node3D
@export var mouse_sensitivity: float = 0.005

# Parameter Mode Isometrik (Awal)
@export var distance: float = 24.0
@export var min_distance: float = 10.0
@export var max_distance: float = 45.0
@export var default_distance: float = 24.0

var yaw: float = 0.0
var pitch: float = deg_to_rad(45.0)
var default_pitch: float = deg_to_rad(45.0)
var default_yaw: float = 0.0

var is_dragging: bool = false
var follow_target_pos: Vector3 = Vector3.ZERO
var smooth_target_pos: Vector3 = Vector3.ZERO
var base_fov: float = 70.0

# Parameter Mode Dalam Mobil (In-Car / Hood / Road-Full View)
# Letak kamera di depan kaca/dashboard dengan sudut luas sehingga jalanan di depan 100% full kelihatan
var in_car_local_offset: Vector3 = Vector3(0.0, 1.25, -1.25)
var in_car_fov: float = 78.0 # Sudut lebar lapang (FOV luas)

# Parameter Mode Chase Belakang
var chase_distance: float = 6.8
var chase_height: float = 2.8
var chase_smooth_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	process_physics_priority = 200
	if target:
		follow_target_pos = target.global_position
		smooth_target_pos = target.global_position
		chase_smooth_pos = target.global_position + target.global_transform.basis.z * chase_distance + Vector3(0, chase_height, 0)
	yaw = default_yaw
	pitch = default_pitch
	distance = default_distance
	_apply_camera_mode_settings()
	_update_camera_transform(true)

func _unhandled_input(event: InputEvent) -> void:
	# Putar kamera bebas dengan klik kanan atau tengah saat mode ISOMETRIC
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			is_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if camera_mode == CameraMode.ISOMETRIC:
				distance = clamp(distance - 1.5, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if camera_mode == CameraMode.ISOMETRIC:
				distance = clamp(distance + 1.5, min_distance, max_distance)

	elif event is InputEventMouseMotion and is_dragging:
		if camera_mode == CameraMode.ISOMETRIC:
			yaw -= event.relative.x * mouse_sensitivity
			pitch = clamp(pitch + event.relative.y * mouse_sensitivity, deg_to_rad(20.0), deg_to_rad(80.0))

	# Tombol C atau V untuk berganti mode kamera (POV Awal <-> POV Dalam Mobil <-> POV Chase)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C or event.keycode == KEY_V:
			toggle_camera_mode()

func toggle_camera_mode() -> void:
	var next_mode = (int(camera_mode) + 1) % 3
	set_camera_mode(next_mode as CameraMode)

func set_camera_mode(new_mode: CameraMode) -> void:
	camera_mode = new_mode
	_apply_camera_mode_settings()

func _apply_camera_mode_settings() -> void:
	var mode_name = ""
	match camera_mode:
		CameraMode.ISOMETRIC:
			mode_name = "Tinjauan Kota (POV Awal)"
			fov = base_fov
		CameraMode.IN_CAR_HOOD:
			mode_name = "Dalam Mobil (Jalanan Full)"
			fov = in_car_fov
		CameraMode.CHASE_CAM:
			mode_name = "Belakang Mobil (Chase Cam)"
			fov = 62.0

	camera_mode_changed.emit(mode_name)
	print("[Kamera] Mode berganti: ", mode_name)

	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast("🎥 Kamera: %s" % mode_name, 2.2)

func reset_to_default_view() -> void:
	yaw = default_yaw
	pitch = default_pitch
	distance = default_distance

func set_target(new_target: Node3D, new_distance: float = -1.0) -> void:
	target = new_target
	if new_distance > 0.0:
		distance = new_distance
	if target:
		follow_target_pos = target.global_position
		smooth_target_pos = target.global_position
		chase_smooth_pos = target.global_position + target.global_transform.basis.z * chase_distance + Vector3(0, chase_height, 0)

# Gunakan _physics_process agar kamera sinkron dengan CharacterBody3D
# dan mencegah warning "Interpolated Camera3D triggered from outside physics process"
func _physics_process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		return

	# Jika target adalah pejalan kaki (Rama turun mobil), otomatis gunakan mode tinjauan agar navigasi orang nyaman
	var is_pedestrian: bool = target.is_in_group("pedestrian")
	var active_mode: CameraMode = camera_mode
	if is_pedestrian and active_mode == CameraMode.IN_CAR_HOOD:
		active_mode = CameraMode.ISOMETRIC

	var target_pos: Vector3 = target.global_position
	if active_mode != CameraMode.ISOMETRIC and target.has_method("get_global_transform_interpolated"):
		target_pos = target.get_global_transform_interpolated().origin

	match active_mode:
		CameraMode.ISOMETRIC:
			_process_isometric(target_pos, delta)
		CameraMode.IN_CAR_HOOD:
			_process_in_car(delta)
		CameraMode.CHASE_CAM:
			_process_chase(target_pos, delta)

func _process_isometric(target_pos: Vector3, _delta: float) -> void:
	smooth_target_pos = target_pos
	follow_target_pos = smooth_target_pos
	fov = base_fov

	_update_camera_transform(false)

func _update_camera_transform(_immediate: bool) -> void:
	var offset_x = distance * cos(pitch) * sin(yaw)
	var offset_y = distance * sin(pitch)
	var offset_z = distance * cos(pitch) * cos(yaw)
	var cam_offset = Vector3(offset_x, offset_y, offset_z)

	global_position = smooth_target_pos + cam_offset
	look_at(smooth_target_pos + Vector3(0, 0.6, 0), Vector3.UP)

func _process_in_car(delta: float) -> void:
	# POV Dalam Mobil: Kamera diletakkan di kabin depan / kaca depan menghadap lurus ke jalanan
	var t_basis = target.global_transform.basis
	var t_origin = target.global_position
	if target.has_method("get_global_transform_interpolated"):
		var gt = target.get_global_transform_interpolated()
		t_basis = gt.basis
		t_origin = gt.origin

	# Posisi di kaca depan / dashboard
	var desired_cam_pos = t_origin + (t_basis * in_car_local_offset)

	# Transisi super responsif dan halus
	global_position = global_position.lerp(desired_cam_pos, 1.0 - exp(-32.0 * delta))

	# Arah pandang lurus jauh ke jalanan di depan mobil (-Z)
	var forward_dir = -t_basis.z
	var look_target = global_position + (forward_dir * 25.0) + Vector3(0, -0.3, 0)

	# Sedikit kemiringan (roll/pitch) realistis mengikuti kemudi mobil
	var up_vec = t_basis.y.lerp(Vector3.UP, 0.4).normalized()
	look_at(look_target, up_vec)

	# Dynamic FOV lapang saat mengebut
	if "current_speed" in target and "max_speed" in target and target.max_speed > 0.0:
		var spd_ratio = clamp(abs(target.current_speed) / target.max_speed, 0.0, 1.0)
		var target_fov = in_car_fov + (spd_ratio * 5.0)
		fov = lerp(fov, target_fov, 1.0 - exp(-8.0 * delta))
	else:
		fov = in_car_fov

func _process_chase(target_pos: Vector3, delta: float) -> void:
	# Mode Kamera Chase di Belakang Mobil
	var t_basis = target.global_transform.basis
	if target.has_method("get_global_transform_interpolated"):
		t_basis = target.get_global_transform_interpolated().basis

	var desired_pos = target_pos + (t_basis.z * chase_distance) + Vector3(0, chase_height, 0)
	chase_smooth_pos = chase_smooth_pos.lerp(desired_pos, 1.0 - exp(-12.0 * delta))
	global_position = chase_smooth_pos

	var look_target = target_pos + Vector3(0, 1.0, 0) - (t_basis.z * 4.0)
	look_at(look_target, Vector3.UP)
