extends Camera3D

@export var target: Node3D
@export var follow_speed: float = 12.0
@export var mouse_sensitivity: float = 0.005

# Parameter Orbit & Zoom Isometrik
@export var distance: float = 24.0
@export var min_distance: float = 10.0
@export var max_distance: float = 45.0
@export var default_distance: float = 24.0

# Sudut orbit isometrik stabil (yaw = 0 menghadap Utara, pitch = 45 derajat)
var yaw: float = 0.0
var pitch: float = deg_to_rad(45.0)
var default_pitch: float = deg_to_rad(45.0)
var default_yaw: float = 0.0

var is_dragging: bool = false
var smooth_target_pos: Vector3 = Vector3.ZERO
var base_fov: float = 50.0

func _ready() -> void:
	base_fov = fov
	if target:
		smooth_target_pos = target.global_position
	yaw = default_yaw
	pitch = default_pitch
	distance = default_distance
	_update_camera_transform(true)

func _unhandled_input(event: InputEvent) -> void:
	# Putar kamera bebas dengan klik kanan atau tengah
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			is_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clamp(distance - 1.5, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clamp(distance + 1.5, min_distance, max_distance)

	elif event is InputEventMouseMotion and is_dragging:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clamp(pitch + event.relative.y * mouse_sensitivity, deg_to_rad(20.0), deg_to_rad(80.0))

	# Tombol C untuk reset instan ke sudut isometrik default kota
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			reset_to_default_view()

func reset_to_default_view() -> void:
	yaw = default_yaw
	pitch = default_pitch
	distance = default_distance

func set_target(new_target: Node3D, new_distance: float = -1.0) -> void:
	target = new_target
	if new_distance > 0.0:
		distance = new_distance
	if target:
		smooth_target_pos = target.global_position

func _process(delta: float) -> void:
	if not target:
		return
	
	# Ambil posisi terinterpolasi visual (menghilangkan stuttering fisika)
	var target_pos: Vector3 = target.global_position
	if target.has_method("get_global_transform_interpolated"):
		target_pos = target.get_global_transform_interpolated().origin
	
	# Smooth follow posisi frame-rate independent
	var t = 1.0 - exp(-follow_speed * delta)
	smooth_target_pos = smooth_target_pos.lerp(target_pos, t)
	
	# Efek Dynamic FOV halus saat melaju kencang
	if "current_speed" in target and "max_speed" in target and target.max_speed > 0.0:
		var spd_ratio = clamp(abs(target.current_speed) / target.max_speed, 0.0, 1.0)
		var target_fov = base_fov + (spd_ratio * 4.0)
		fov = lerp(fov, target_fov, 1.0 - exp(-6.0 * delta))
		
	_update_camera_transform(false)

func _update_camera_transform(_immediate: bool) -> void:
	# Hitung posisi orbit kamera isometrik
	var offset_x = distance * cos(pitch) * sin(yaw)
	var offset_y = distance * sin(pitch)
	var offset_z = distance * cos(pitch) * cos(yaw)
	var cam_offset = Vector3(offset_x, offset_y, offset_z)
	
	global_position = smooth_target_pos + cam_offset
	look_at(smooth_target_pos + Vector3(0, 0.6, 0), Vector3.UP)
