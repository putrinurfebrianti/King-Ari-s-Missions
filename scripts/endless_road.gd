extends Node3D

@export var follow_target: Node3D
@export var ground: StaticBody3D

const ROAD_RECENTER_DISTANCE: float = 20000.0
const ROAD_RECENTER_STEP: float = 10000.0

@onready var road_ew: MeshInstance3D = get_node_or_null("RoadEW") as MeshInstance3D
@onready var road_ns: MeshInstance3D = get_node_or_null("RoadNS") as MeshInstance3D
@onready var shoulder_ew: MeshInstance3D = get_node_or_null("SandShoulderEW") as MeshInstance3D


func _ready() -> void:
	process_physics_priority = 100
	if not is_instance_valid(follow_target):
		follow_target = get_tree().get_first_node_in_group("player_car") as Node3D


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(follow_target):
		return

	var target_position := to_local(follow_target.global_position)
	if road_ew and absf(target_position.x - road_ew.position.x) > ROAD_RECENTER_DISTANCE:
		var road_x := floorf(target_position.x / ROAD_RECENTER_STEP) * ROAD_RECENTER_STEP
		road_ew.position.x = road_x
		if shoulder_ew:
			shoulder_ew.position.x = road_x
	if road_ns and absf(target_position.z - road_ns.position.z) > ROAD_RECENTER_DISTANCE:
		road_ns.position.z = floorf(target_position.z / ROAD_RECENTER_STEP) * ROAD_RECENTER_STEP

	if is_instance_valid(ground):
		var ground_local_position := to_local(ground.global_position)
		var ground_x := ground_local_position.x
		var ground_z := ground_local_position.z
		if absf(target_position.x - ground_x) > ROAD_RECENTER_DISTANCE:
			ground_x = floorf(target_position.x / ROAD_RECENTER_STEP) * ROAD_RECENTER_STEP
		if absf(target_position.z - ground_z) > ROAD_RECENTER_DISTANCE:
			ground_z = floorf(target_position.z / ROAD_RECENTER_STEP) * ROAD_RECENTER_STEP
		if ground_x != ground_local_position.x or ground_z != ground_local_position.z:
			ground.global_position = to_global(
				Vector3(ground_x, ground_local_position.y, ground_z)
			)
