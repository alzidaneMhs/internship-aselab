extends CharacterBody3D

@export var move_speed: float = 6.0
@export var acceleration: float = 40.0
@export var friction: float = 50.0

@export var jump_velocity: float = 9.0
@export var charge_jump_max_velocity: float = 16.0
@export var charge_jump_hold_time: float = 0.8
@export var charge_jump_min_hold_time: float = 0.15

@export var dash_speed: float = 16.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.5

@export var attack_damage: float = 1.0
@export var attack_duration: float = 0.15
@export var attack_cooldown: float = 0.35
@export var attack_offset_x: float = 0.6

const LOCKED_Z: float = 0.0

@onready var sprite: Sprite3D = $Sprite3D
@onready var health: Node = $Health
@onready var attack_hitbox: Area3D = $AttackHitbox
@onready var attack_timer: Timer = $AttackTimer

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var _is_holding_jump := false
var _jump_hold_time := 0.0
var _air_jumps_used := 0

var _is_dashing := false
var _dash_timer := 0.0
var _dash_charges_current: int = 1
var _dash_charges_max: int = 1
var _dash_regen_timer: float = 0.0

var _facing := 1.0

var _can_attack := true


func _ready() -> void:
	health.set_max_health(GameState.get_max_hp(), true)
	_dash_charges_max = 1 + GameState.get_dash_charges()
	_dash_charges_current = _dash_charges_max
	attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)
	attack_timer.timeout.connect(_on_attack_timer_timeout)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		_air_jumps_used = 0

	_handle_dash(delta)
	if not _is_dashing:
		_handle_horizontal(delta)
	_handle_jump(delta)
	_update_facing()

	velocity.z = 0.0
	move_and_slide()
	global_position.z = LOCKED_Z  # hard backstop against any Jolt collision Z-drift


func _handle_horizontal(delta: float) -> void:
	var input_dir := Input.get_axis("move_left", "move_right")
	if input_dir != 0.0:
		velocity.x = move_toward(velocity.x, input_dir * move_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


func _handle_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			_is_holding_jump = true
			_jump_hold_time = 0.0
		elif _air_jumps_used < GameState.get_extra_jumps():
			_air_jumps_used += 1
			_is_holding_jump = true
			_jump_hold_time = 0.0

	if _is_holding_jump:
		if Input.is_action_pressed("jump"):
			_jump_hold_time = min(_jump_hold_time + delta, charge_jump_hold_time)

		if Input.is_action_just_released("jump") or _jump_hold_time >= charge_jump_hold_time:
			_do_jump()
			_is_holding_jump = false


func _do_jump() -> void:
	if _jump_hold_time < charge_jump_min_hold_time:
		velocity.y = jump_velocity
	else:
		var t := _jump_hold_time / charge_jump_hold_time
		velocity.y = lerp(jump_velocity, charge_jump_max_velocity, t)


func _handle_dash(delta: float) -> void:
	if _dash_charges_current < _dash_charges_max:
		_dash_regen_timer -= delta
		if _dash_regen_timer <= 0.0:
			_dash_charges_current += 1
			_dash_regen_timer = dash_cooldown

	if _is_dashing:
		_dash_timer -= delta
		velocity.x = _facing * dash_speed
		if _dash_timer <= 0.0:
			_is_dashing = false
	elif Input.is_action_just_pressed("dash") and _dash_charges_current > 0:
		_is_dashing = true
		_dash_timer = dash_duration
		_dash_charges_current -= 1
		_dash_regen_timer = dash_cooldown


func _update_facing() -> void:
	if velocity.x > 0.1:
		_facing = 1.0
	elif velocity.x < -0.1:
		_facing = -1.0
	sprite.flip_h = _facing < 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		_on_attack()


func _on_attack() -> void:
	if not _can_attack:
		return
	_can_attack = false
	attack_hitbox.position.x = attack_offset_x * _facing
	attack_hitbox.monitoring = true
	attack_timer.start(attack_duration)
	AudioManager.play_sfx("player_attack")


func _on_attack_hitbox_area_entered(area: Area3D) -> void:
	if not attack_hitbox.monitoring:
		return
	if area.has_method("take_damage"):
		area.take_damage(attack_damage + GameState.get_attack_damage_bonus(), self)


func _on_attack_timer_timeout() -> void:
	attack_hitbox.monitoring = false
	await get_tree().create_timer(attack_cooldown - attack_duration).timeout
	_can_attack = true


func full_heal() -> void:
	health.set_max_health(health.max_health, true)
