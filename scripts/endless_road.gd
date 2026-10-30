extends Node3D

@export var follow_target: Node3D
@export var ground: StaticBody3D

@onready var road_ew: MeshInstance3D = $RoadEW
@onready var road_ns: MeshInstance3D = $RoadNS
@onready var shoulder_ew: MeshInstance3D = $SandShoulderEW
@onready var curb_north: MeshInstance3D = $CurbNorth
@onready var curb_south: MeshInstance3D = $CurbSouth
@onready var curb_west: MeshInstance3D = $CurbWest
@onready var curb_east: MeshInstance3D = $CurbEast
@onready var guardrail_south: MeshInstance3D = $GuardrailSouth


func _ready() -> void:
	process_physics_priority = 100
	if not follow_target:
		follow_target = get_tree().get_first_node_in_group("player_car") as Node3D


func _physics_process(_delta: float) -> void:
	if not follow_target:
		return

	var target_position := follow_target.global_position
	road_ew.position.x = target_position.x
	shoulder_ew.position.x = target_position.x
	curb_north.position.x = target_position.x
	curb_south.position.x = target_position.x
	guardrail_south.position.x = target_position.x

	road_ns.position.z = target_position.z
	curb_west.position.z = target_position.z
	curb_east.position.z = target_position.z

	if ground:
		var ground_offset := Vector2(
			target_position.x - ground.global_position.x,
			target_position.z - ground.global_position.z
		)
		if ground_offset.length() > 40000.0:
			ground.global_position = Vector3(
				target_position.x, ground.global_position.y, target_position.z
			)
