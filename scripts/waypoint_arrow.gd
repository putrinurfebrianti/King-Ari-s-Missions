extends Node3D

@export var follow_target: Node3D
@export var sppg_pos: Vector3 = Vector3(-50.0, 0.15, -2.0)
@export var school_pos: Vector3 = Vector3(52.0, 0.15, -2.0)
@export var base_y_offset: float = 3.2
@export var bob_amplitude: float = 0.15
@export var bob_speed: float = 3.5

@onready var arrow_anchor: Node3D = $ArrowAnchor
@onready var label_distance: Label3D = $LabelDistance
@onready var arrow_head: MeshInstance3D = get_node_or_null("ArrowAnchor/ArrowVisual/Head")
@onready var arrow_shaft: MeshInstance3D = get_node_or_null("ArrowAnchor/ArrowVisual/Shaft")
@onready var glow_ring: MeshInstance3D = get_node_or_null("ArrowAnchor/GlowRing")

var current_target_pos: Vector3 = Vector3.ZERO
var target_name: String = ""
var time_passed: float = 0.0

var mat_arrow: StandardMaterial3D

func _ready() -> void:
	if not follow_target:
		follow_target = get_tree().get_first_node_in_group("player") as Node3D
	
	# Buat material khusus unshaded toon glowing
	mat_arrow = StandardMaterial3D.new()
	mat_arrow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_arrow.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat_arrow.albedo_color = Color(0.1, 0.95, 0.4)
	
	if arrow_head:
		arrow_head.set_surface_override_material(0, mat_arrow)
	if arrow_shaft:
		arrow_shaft.set_surface_override_material(0, mat_arrow)

func _process(delta: float) -> void:
	var ped = get_tree().get_first_node_in_group("pedestrian") as Node3D
	if ped and ped.visible:
		var p_pos = ped.global_position
		if ped.has_method("get_global_transform_interpolated"):
			p_pos = ped.get_global_transform_interpolated().origin
		global_position = p_pos
	elif follow_target:
		var t_pos = follow_target.global_position
		if follow_target.has_method("get_global_transform_interpolated"):
			t_pos = follow_target.get_global_transform_interpolated().origin
		global_position = t_pos

	time_passed += delta
	
	if not GameManager:
		return

	# Tentukan target berdasarkan fase misi
	var is_active = false
	var target_color = Color(0.1, 0.95, 0.4)
	
	if GameManager.current_state == GameManager.State.AT_SPPG:
		is_active = true
		current_target_pos = GameManager.get_active_target_pos()
		target_name = "SPPG (Muat Ransum)"
		target_color = Color(0.1, 0.95, 0.4)
	elif GameManager.current_state == GameManager.State.DELIVERING:
		is_active = true
		current_target_pos = GameManager.get_active_target_pos()
		target_name = GameManager.get_active_target_name()
		target_color = Color(1.0, 0.72, 0.1)
	else:
		is_active = false
	
	visible = is_active
	if not is_active:
		return
		
	# Update warna arrow dan label
	if mat_arrow and mat_arrow.albedo_color != target_color:
		mat_arrow.albedo_color = target_color
		
	var dist = global_position.distance_to(current_target_pos)
	if label_distance:
		label_distance.text = "%s\n[ %dm ]" % [target_name, int(dist)]
		label_distance.modulate = target_color

	# Floating bobbing vertikal
	var float_y = base_y_offset + sin(time_passed * bob_speed) * bob_amplitude
	if arrow_anchor:
		arrow_anchor.position.y = float_y
		
		# Arah horizontal ke target
		var to_target = current_target_pos - global_position
		to_target.y = 0.0
		
		if to_target.length_squared() > 0.01:
			var target_yaw = atan2(-to_target.x, -to_target.z)
			arrow_anchor.global_rotation.y = lerp_angle(arrow_anchor.global_rotation.y, target_yaw, 12.0 * delta)
			
		# Jika mendekati zona (< 10m), condongkan panah ke bawah mengarah ke titik drop-off
		if dist < 12.0:
			var pitch_angle = deg_to_rad(lerp(0.0, -32.0, (12.0 - dist) / 12.0))
			arrow_anchor.rotation.x = pitch_angle
		else:
			arrow_anchor.rotation.x = lerp(arrow_anchor.rotation.x, 0.0, 8.0 * delta)
			
		# Sedikit pulsasi skala saat dekat
		var pulse_scale = 1.0 + (0.15 * sin(time_passed * 6.0) if dist < 15.0 else 0.0)
		arrow_anchor.scale = Vector3.ONE * pulse_scale
