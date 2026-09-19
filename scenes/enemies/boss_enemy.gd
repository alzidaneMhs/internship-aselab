extends "res://scenes/enemies/enemy_base.gd"

const PROJECTILE_SCENE := preload("res://scenes/enemies/projectile.tscn")

@export var move_speed: float = 3.0
@export var melee_range: float = 2.0
@export var melee_damage: float = 2.0
@export var melee_cooldown: float = 1.0
@export var fire_interval: float = 1.5
@export var projectile_speed: float = 12.0
@export var projectile_damage: float = 1.0

@onready var attack_timer: Timer = $AttackTimer
@onready var muzzle: Marker3D = $Muzzle
@onready var melee_area: Area3D = $MeleeArea

var _melee_cooldown_timer := 0.0


func _ready() -> void:
	super._ready()
	attack_timer.wait_time = fire_interval
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()
	melee_area.area_entered.connect(_on_melee_area_entered)


func _update_ai(delta: float) -> void:
	if _melee_cooldown_timer > 0.0:
		_melee_cooldown_timer -= delta

	if not _player_in_range():
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		return

	var dx := player_ref.global_position.x - global_position.x
	sprite.flip_h = dx < 0.0
	if absf(dx) > melee_range:
		velocity.x = sign(dx) * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		_try_melee()


func _try_melee() -> void:
	if _melee_cooldown_timer > 0.0:
		return
	_melee_cooldown_timer = melee_cooldown
	melee_area.monitoring = true
	await get_tree().create_timer(0.15).timeout
	melee_area.monitoring = false


func _on_melee_area_entered(area: Area3D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(melee_damage, self)


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
	AudioManager.play_sfx("boss_shoot")
