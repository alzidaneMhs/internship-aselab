extends Node3D

@export var target_path: NodePath
@export var follow_offset: Vector3 = Vector3(0.0, 1.5, 12.0)
@export var follow_smoothing: float = 8.0

@onready var target: Node3D = get_node_or_null(target_path)


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var desired := Vector3(target.global_position.x, target.global_position.y + follow_offset.y, follow_offset.z)
	global_position = global_position.lerp(desired, 1.0 - exp(-follow_smoothing * delta))
