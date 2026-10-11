extends Camera2D

@export var target_path: NodePath
@export var follow_offset: Vector2 = Vector2(0.0, -120.0)

@onready var target: Node2D = get_node_or_null(target_path)

var _shake_strength := 0.0
var _shake_decay := 40.0


func _ready() -> void:
	add_to_group("main_camera")
	if target != null:
		global_position = target.global_position + follow_offset
		reset_smoothing()


# With physics interpolation on, Godot runs Camera2D in the physics step and
# interpolates it, so following the player's physics position here stays in sync.
func _physics_process(_delta: float) -> void:
	if target != null:
		global_position = target.global_position + follow_offset


func _process(delta: float) -> void:
	if _shake_strength > 0.0:
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength
		_shake_strength = maxf(_shake_strength - _shake_decay * delta, 0.0)
		if _shake_strength == 0.0:
			offset = Vector2.ZERO


func shake(strength: float) -> void:
	_shake_strength = maxf(_shake_strength, strength)
