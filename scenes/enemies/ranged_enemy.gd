extends "res://scenes/enemies/enemy_base.gd"

const PROJECTILE_SCENE := preload("res://scenes/enemies/projectile.tscn")

@export var fire_interval: float = 2.0
@export var projectile_speed: float = 420.0
@export var projectile_damage: float = 1.0

@onready var attack_timer: Timer = $AttackTimer
@onready var muzzle: Marker2D = $Muzzle


func _ready() -> void:
	super._ready()
	attack_timer.wait_time = fire_interval
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()


func _update_ai(_delta: float) -> void:
	# Stationary gunner: never chases, only faces the player and shoots.
	velocity.x = 0.0
	if _player_in_range():
		var player_is_right := player_ref.global_position.x > global_position.x
		sprite.flip_h = player_is_right
		muzzle.position.x = absf(muzzle.position.x) * (1.0 if player_is_right else -1.0)


func _on_attack_timer_timeout() -> void:
	if _dead or not _player_in_range():
		return
	var dir := (player_ref.global_position + PLAYER_CENTER) - muzzle.global_position
	if dir.length() < 1.0:
		return
	var proj := PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = muzzle.global_position
	proj.launch(dir, projectile_speed, projectile_damage)
	AudioManager.play_sfx("enemy_shoot")
