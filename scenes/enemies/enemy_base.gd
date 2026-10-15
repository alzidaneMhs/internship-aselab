extends CharacterBody2D

const PLAYER_CENTER := Vector2(0, -48)
const FX := preload("res://scripts/effects/laser_fx.gd")

@export var max_health: float = 30.0
@export var points_value: int = 1
@export var detection_range: float = 520.0
@export var gravity: float = 1500.0
@export var burst_color: Color = Color(0.85, 0.6, 1.0, 1.0)
@export var wake_delay: float = 2.2

@onready var health: Node = $Health
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = $HurtBox

var player_ref: Node2D
var _dead := false
var _suicide := false
var _awake_at_msec := 0
var _stage_key := ""
var _kill_id := ""


func _ready() -> void:
	health.set_max_health(max_health, true)
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)
	player_ref = get_tree().get_first_node_in_group("player")
	_awake_at_msec = Time.get_ticks_msec() + int(wake_delay * 1000.0)
	if owner != null and not is_in_group("boss"):
		_stage_key = owner.scene_file_path
		_kill_id = str(owner.get_path_to(self))
		if GameState.is_enemy_killed(_stage_key, _kill_id):
			queue_free()


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if Cutscene.active:
		velocity = Vector2.ZERO
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	_update_ai(delta)
	move_and_slide()


func _player_in_range() -> bool:
	if Time.get_ticks_msec() < _awake_at_msec:
		return false
	return player_ref != null and global_position.distance_to(player_ref.global_position) <= detection_range


func _update_ai(_delta: float) -> void:
	pass


func _on_died() -> void:
	if _dead:
		return
	_dead = true
	if _kill_id != "":
		GameState.mark_enemy_killed(_stage_key, _kill_id)
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
