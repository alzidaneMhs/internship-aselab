extends CharacterBody2D

# All distances are in pixels. The node origin is at Isme's feet.
# Dash and double jump are NOT available from the start: they are boss item drops.
#
# Combat: tap the attack key = laser bolt. Hold it until the orb glows, release
# = laser beam (charge attack). Movement tuning follows the old Reverse Poppy
# controller: fast acceleration, heavier fall, coyote time, jump buffer, jump cut.

const LASER_BULLET := preload("res://scenes/player/laser_bullet.gd")
const LASER_BEAM := preload("res://scenes/player/laser_beam.gd")
const FX := preload("res://scripts/effects/laser_fx.gd")

@export_group("Movement")
@export var move_speed: float = 420.0
@export var acceleration: float = 3800.0
@export var friction: float = 4600.0
@export var air_control: float = 0.9
@export var gravity: float = 1700.0
@export var fall_multiplier: float = 1.6
@export var max_fall_speed: float = 1500.0
@export var jump_velocity: float = 760.0
@export var jump_cut: float = 0.45
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

@export_group("Dash")
@export var dash_speed: float = 1000.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.5

@export_group("Combat")
@export var attack_cooldown: float = 0.28
@export var charge_start_time: float = 0.2
@export var charge_time: float = 0.7
@export var beam_cooldown: float = 0.7
@export var stun_time: float = 0.2
@export var invulnerable_time: float = 0.7
@export var knockback: float = 320.0
@export var vampire_heal: float = 8.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: Node = $Health
@onready var hurtbox: Node = $HurtBox
@onready var attack_timer: Timer = $AttackTimer
@onready var charge_fx = $ChargeFX  # untyped: script defines `ratio`

var _air_jumps_used := 0
var _coyote := 0.0
var _jump_buffer := 0.0

var _is_dashing := false
var _dash_timer := 0.0
var _dash_cd := 0.0

var _facing := 1.0
var _base_scale: Vector2
var _base_sprite_y: float
var _anim_time := 0.0

var _charging := false
var _charge_held := 0.0
var _attacking := false
var _attack_cd := 0.0
var _stun_timer := 0.0
var _ghost_timer := 0.0
var _land_timer := 0.0

# Cutscenes: input is ignored, Isme can be told to walk, and nothing can hurt her.
var controls_locked := false
var auto_walk := 0.0


func _ready() -> void:
	_base_scale = sprite.scale
	_base_sprite_y = sprite.position.y
	if GameState.spawn_at_checkpoint:
		global_position = GameState.spawn_position
		GameState.spawn_at_checkpoint = false
	health.set_max_health(GameState.get_max_hp(), true)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	hurtbox.hit.connect(_on_hit)
	GameState.regular_enemy_killed.connect(_on_regular_enemy_killed)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	charge_fx.ratio = 0.0


func _physics_process(delta: float) -> void:
	if _stun_timer > 0.0:
		_stun_timer -= delta
	if _attack_cd > 0.0:
		_attack_cd -= delta

	var was_on_floor := is_on_floor()
	_apply_gravity(delta)

	if controls_locked:
		_locked_motion(delta)
	elif _stun_timer <= 0.0:
		_handle_attack_input(delta)
		_handle_dash(delta)
		if not _is_dashing:
			_handle_horizontal(delta)
		_handle_jump(delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * 0.5 * delta)

	var fall_speed := velocity.y
	move_and_slide()

	if _land_timer > 0.0:
		_land_timer -= delta
	if is_on_floor() and not was_on_floor:
		sprite.scale = _base_scale * Vector2(1.12, 0.9)
		if fall_speed > 350.0:
			_land_timer = 0.12


func set_cutscene(locked: bool) -> void:
	controls_locked = locked
	auto_walk = 0.0
	if locked:
		_charging = false
		_charge_held = 0.0
		_is_dashing = false
		charge_fx.ratio = 0.0
		sprite.self_modulate = Color.WHITE
	health.invulnerable = locked
	hurtbox.set_deferred("monitorable", not locked)


func cutscene_face(direction: float) -> void:
	if direction != 0.0:
		_facing = signf(direction)


func _locked_motion(delta: float) -> void:
	var goal := auto_walk * move_speed * 0.55
	if auto_walk != 0.0:
		_facing = signf(auto_walk)
		velocity.x = move_toward(velocity.x, goal, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		_air_jumps_used = 0
		_coyote = coyote_time
		return
	_coyote -= delta
	var g := gravity * (fall_multiplier if velocity.y > 0.0 else 1.0)
	velocity.y = minf(velocity.y + g * delta, max_fall_speed)


# --- Movement ---------------------------------------------------------------

func _handle_horizontal(delta: float) -> void:
	var speed := move_speed * (0.75 if _charging else 1.0)
	var dir := Input.get_axis("move_left", "move_right")
	var on_floor := is_on_floor()
	if dir != 0.0:
		_facing = signf(dir)
		var accel := acceleration * (1.0 if on_floor else air_control)
		if velocity.x != 0.0 and signf(velocity.x) != signf(dir):
			accel *= 1.6  # snappy turn-around
		velocity.x = move_toward(velocity.x, dir * speed, accel * delta)
	else:
		var decel := friction if on_floor else friction * 0.35
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)


func _handle_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = jump_buffer_time
	elif _jump_buffer > 0.0:
		_jump_buffer -= delta

	if _jump_buffer > 0.0:
		if _coyote > 0.0:
			_start_jump()
		elif GameState.has_item("double_jump") and _air_jumps_used < 1 and not is_on_floor():
			_air_jumps_used += 1
			_start_jump()

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut


func _start_jump() -> void:
	velocity.y = -jump_velocity
	_jump_buffer = 0.0
	_coyote = 0.0
	sprite.scale = _base_scale * Vector2(0.8, 1.25)


func _handle_dash(delta: float) -> void:
	if _dash_cd > 0.0:
		_dash_cd -= delta
	if _is_dashing:
		_dash_timer -= delta
		velocity.x = _facing * dash_speed
		velocity.y = 0.0
		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			_ghost_timer = 0.03
			_spawn_ghost()
		if _dash_timer <= 0.0:
			_is_dashing = false
	elif GameState.has_item("dash") and Input.is_action_just_pressed("dash") and _dash_cd <= 0.0:
		_is_dashing = true
		_dash_timer = dash_duration
		_dash_cd = dash_cooldown


# --- Visual feedback (the sprite is a single static pose) --------------------

func _process(delta: float) -> void:
	_anim_time += delta
	sprite.flip_h = _facing < 0.0

	_update_animation()

	# Small lean into the movement direction; the walk cycle itself comes from the frames.
	var target_rot := clampf(velocity.x / move_speed, -1.0, 1.0) * 0.05
	var target_y := _base_sprite_y
	if is_on_floor() and absf(velocity.x) <= 40.0:
		target_y -= (sin(_anim_time * 3.0) * 0.5 + 0.5) * 1.5
	sprite.rotation = lerp_angle(sprite.rotation, target_rot, minf(1.0, 20.0 * delta))
	sprite.position.y = lerpf(sprite.position.y, target_y, minf(1.0, 20.0 * delta))

	var stretch := 0.0 if is_on_floor() else clampf(absf(velocity.y) / 1500.0, 0.0, 1.0) * 0.14
	var target_scale := _base_scale * Vector2(1.0 - stretch, 1.0 + stretch)
	sprite.scale = sprite.scale.lerp(target_scale, minf(1.0, 18.0 * delta))

	if _charging:
		charge_fx.position = Vector2(_facing * 58.0, -56.0)


func _update_animation() -> void:
	var anim := "idle"
	if not is_on_floor():
		if absf(velocity.y) < 200.0:
			anim = "apex"
		else:
			anim = "jump" if velocity.y < 0.0 else "fall"
	elif _land_timer > 0.0 and absf(velocity.x) <= 40.0:
		anim = "land"
	elif absf(velocity.x) > 40.0:
		anim = "walk"
	if sprite.animation != anim:
		sprite.play(anim)
	# Faster legs/treads when running faster.
	sprite.speed_scale = clampf(absf(velocity.x) / move_speed, 0.6, 1.3) if anim == "walk" else 1.0


# --- Combat -----------------------------------------------------------------

func _muzzle() -> Vector2:
	return global_position + Vector2(_facing * 56.0, -56.0)


func _handle_attack_input(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		if _attack_cd <= 0.0 and not _attacking:
			_fire_bullet()
		_charging = true
		_charge_held = 0.0
	if not _charging:
		return
	if Input.is_action_pressed("attack"):
		_charge_held += delta
		var ratio := (_charge_held - charge_start_time) / (charge_time - charge_start_time)
		charge_fx.ratio = ratio if _charge_held > charge_start_time else 0.0
		if _charge_held >= charge_time:
			sprite.self_modulate = Color(1.0 + 0.4 * (0.5 + 0.5 * sin(_anim_time * 25.0)), 1.0, 1.0)
	else:
		var full := _charge_held >= charge_time
		_charging = false
		charge_fx.ratio = 0.0
		sprite.self_modulate = Color.WHITE
		if full:
			_fire_beam()


func _fire_bullet() -> void:
	_attacking = true
	_attack_cd = attack_cooldown
	attack_timer.start(0.1)
	var bullet = Area2D.new()
	bullet.set_script(LASER_BULLET)
	bullet.direction = Vector2(_facing, 0.0)
	bullet.damage = GameState.get_attack()
	bullet.source = self
	get_parent().add_child(bullet)
	bullet.global_position = _muzzle()
	FX.spawn_muzzle_flash(get_parent(), _muzzle(), _facing)
	AudioManager.play_sfx("player_attack")


func _fire_beam() -> void:
	_attacking = true
	_attack_cd = beam_cooldown
	attack_timer.start(0.3)
	var damage := GameState.get_charge_attack()
	if GameState.has_item("volatile_core") and randi() % 3 == 0:
		damage += 10.0
		GameState.toast("Volatile Core! +10 damage")
	var beam = Node2D.new()
	beam.set_script(LASER_BEAM)
	get_parent().add_child(beam)
	beam.fire(_muzzle(), Vector2(_facing, 0.0), damage, self)
	velocity.x -= _facing * 140.0
	get_tree().call_group("main_camera", "shake", 8.0)
	AudioManager.play_sfx("player_charge_attack")


func _cancel_attack() -> void:
	attack_timer.stop()
	_attacking = false
	_charging = false
	_charge_held = 0.0
	_attack_cd = 0.25
	charge_fx.ratio = 0.0
	sprite.self_modulate = Color.WHITE


func _on_attack_timer_timeout() -> void:
	_attacking = false


func _on_hit(_amount: float, attacker: Node) -> void:
	if health.invulnerable:
		return
	var armored := GameState.has_item("anti_interrupt")
	if not armored:
		if _attacking or _charging:
			_cancel_attack()
		_stun_timer = stun_time
	if attacker is Node2D and not (armored and (_attacking or _charging)):
		var dir := signf(global_position.x - (attacker as Node2D).global_position.x)
		if dir == 0.0:
			dir = -_facing
		velocity.x = dir * knockback
		velocity.y = -220.0


func _on_damaged(_amount: float) -> void:
	GameManager.hit_stop(0.07)
	health.invulnerable = true
	get_tree().create_timer(invulnerable_time).timeout.connect(_end_invulnerability)
	get_tree().call_group("main_camera", "shake", 5.0)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(3.0, 0.5, 0.5), 0.05)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	for i in 4:
		tw.tween_property(sprite, "modulate:a", 0.35, 0.08)
		tw.tween_property(sprite, "modulate:a", 1.0, 0.08)


func _spawn_ghost() -> void:
	var tex := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if tex == null:
		return
	var ghost := Sprite2D.new()
	ghost.texture = tex
	ghost.scale = sprite.scale
	ghost.flip_h = sprite.flip_h
	ghost.modulate = Color(0.5, 0.9, 1.0, 0.55)
	ghost.z_index = -1
	ghost.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	get_parent().add_child(ghost)
	ghost.global_position = sprite.global_position
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tw.tween_callback(ghost.queue_free)


func _end_invulnerability() -> void:
	health.invulnerable = false


func _on_regular_enemy_killed() -> void:
	if GameState.has_item("vampire"):
		health.heal(vampire_heal)


func _on_died() -> void:
	GameManager.on_player_died()
