extends "res://scenes/enemies/enemy_base.gd"

const PROJECTILE_SCENE := preload("res://scenes/enemies/projectile.tscn")

@export var fire_interval: float = 2.0
@export var projectile_speed: float = 10.0
@export var projectile_damage: float = 1.0

@onready var attack_timer: Timer = $AttackTimer
@onready var muzzle: Marker3D = $Muzzle


func _ready() -> void:
	super._ready()
	attack_timer.wait_time = fire_interval
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()


func _update_ai(_delta: float) -> void:
	# Stationary defensive gunner — doesn't chase, just faces and shoots.
	velocity.x = move_toward(velocity.x, 0.0, 20.0)
	if _player_in_range():
		sprite.flip_h = player_ref.global_position.x < global_position.x


func _on_attack_timer_timeout() -> void:
	if not _player_in_range():
		return
	var dir := player_ref.global_position - muzzle.global_position
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	dir = dir.normalized()
	var proj := PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = muzzle.global_position
	proj.launch(dir, projectile_speed, projectile_damage)
	AudioManager.play_sfx("enemy_shoot")
