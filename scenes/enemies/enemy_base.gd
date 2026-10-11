extends CharacterBody2D

# Distances in pixels; node origin is at the enemy's feet.

const PLAYER_CENTER := Vector2(0, -48)
const FX := preload("res://scripts/effects/laser_fx.gd")

@export var max_health: float = 30.0
@export var points_value: int = 1
@export var detection_range: float = 520.0
@export var gravity: float = 1500.0
@export var burst_color: Color = Color(0.85, 0.6, 1.0, 1.0)

@onready var health: Node = $Health
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = $HurtBox

var player_ref: Node2D
var _dead := false
var _suicide := false


func _ready() -> void:
	health.set_max_health(max_health, true)
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)
	player_ref = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	_update_ai(delta)
	move_and_slide()


func _player_in_range() -> bool:
	return player_ref != null and global_position.distance_to(player_ref.global_position) <= detection_range


## Overridden by subclasses.
func _update_ai(_delta: float) -> void:
	pass


## Regular robots drop Vonic and cost reputation when killed (not when they blow themselves up).
func _on_died() -> void:
	if _dead:
		return
	_dead = true
	var center := global_position + Vector2(0.0, -50.0)
	FX.spawn_death_burst(get_parent(), center, burst_color, 1.7 if _suicide else 1.0)
	if _suicide:
		get_tree().call_group("main_camera", "shake", 7.0)
	if not _suicide:
		GameState.add_points(points_value)
		GameState.on_regular_enemy_killed()
		FX.spawn_damage_number(get_parent(), center + Vector2(0.0, -30.0), "+%d Vonic" % points_value, Color(1.0, 0.85, 0.3), 22)
	AudioManager.play_sfx("enemy_death")
	set_physics_process(false)
	collision_shape.set_deferred("disabled", true)
	hurtbox.set_deferred("monitorable", false)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)


func _on_damaged(_amount: float) -> void:
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(3.0, 0.5, 0.5), 0.05)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.1)
