extends CharacterBody3D

const LOCKED_Z: float = 0.0

@export var max_health: float = 3.0
@export var points_value: int = 1
@export var detection_range: float = 8.0

@onready var health: Node = $Health
@onready var sprite: Sprite3D = $Sprite3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var hurtbox: Area3D = $HurtBox

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var player_ref: Node3D
var _dead := false


func _ready() -> void:
	health.max_health = max_health
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)
	player_ref = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if not is_on_floor():
		velocity.y -= _gravity * delta
	_update_ai(delta)
	velocity.z = 0.0
	move_and_slide()
	global_position.z = LOCKED_Z


func _player_in_range() -> bool:
	return player_ref != null and global_position.distance_to(player_ref.global_position) <= detection_range


## Overridden by subclasses (chasing/ranged/boss AI).
func _update_ai(_delta: float) -> void:
	pass


func _on_died() -> void:
	if _dead:
		return
	_dead = true
	GameState.add_points(points_value)
	AudioManager.play_sfx("enemy_death")
	set_physics_process(false)
	collision_shape.disabled = true
	hurtbox.monitorable = false
	var tw := create_tween()
	tw.tween_property(sprite, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)


func _on_damaged(_amount: float) -> void:
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(3.0, 0.5, 0.5), 0.05)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.1)
