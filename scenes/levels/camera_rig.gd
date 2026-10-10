extends Camera2D

@export var target_path: NodePath
@export var follow_offset: Vector2 = Vector2(0.0, -120.0)

@onready var target: Node2D = get_node_or_null(target_path)


func _ready() -> void:
	if target != null:
		global_position = target.global_position + follow_offset
		reset_smoothing()


func _physics_process(_delta: float) -> void:
	if target != null:
		global_position = target.global_position + follow_offset
