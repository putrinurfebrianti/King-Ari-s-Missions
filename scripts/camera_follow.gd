extends Camera3D

@export var target: Node3D
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
var follow_target_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	process_physics_priority = 200
	if target:
		follow_target_pos = target.global_position
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
		follow_target_pos = target.global_position

# Gunakan _physics_process agar kamera sinkron dengan CharacterBody3D
# dan mencegah warning "Interpolated Camera3D triggered from outside physics process"
func _physics_process(_delta: float) -> void:
	if not target:
		return

	# Follow target directly; Godot physics interpolation smooths both transforms together.
	follow_target_pos = target.global_position

	_update_camera_transform(false)

func _update_camera_transform(_immediate: bool) -> void:
	# Hitung posisi orbit kamera isometrik
	var offset_x = distance * cos(pitch) * sin(yaw)
	var offset_y = distance * sin(pitch)
	var offset_z = distance * cos(pitch) * cos(yaw)
	var cam_offset = Vector3(offset_x, offset_y, offset_z)

	global_position = follow_target_pos + cam_offset
	look_at(follow_target_pos + Vector3(0, 0.6, 0), Vector3.UP)
