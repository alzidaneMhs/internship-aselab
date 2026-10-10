extends CharacterBody2D

# All distances are in pixels. The node origin is at Isme's feet.
# Dash and double jump are NOT available from the start: they are boss item drops.

@export var move_speed: float = 300.0
@export var acceleration: float = 2600.0
@export var friction: float = 3200.0
@export var gravity: float = 1500.0
@export var jump_velocity: float = 640.0
@export var coyote_time: float = 0.1

@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 0.6

@export var charge_time: float = 0.6
@export var attack_duration: float = 0.15
@export var attack_cooldown: float = 0.3
@export var charge_attack_duration: float = 0.25
@export var charge_attack_cooldown: float = 0.5

@export var stun_time: float = 0.25
@export var invulnerable_time: float = 0.7
@export var knockback: float = 280.0
@export var vampire_heal: float = 8.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var health: Node = $Health
@onready var hurtbox: Node = $HurtBox
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var attack_visual: ColorRect = $AttackHitbox/AttackVisual
@onready var attack_timer: Timer = $AttackTimer

var _air_jumps_used := 0
var _coyote := 0.0

var _is_dashing := false
var _dash_timer := 0.0
var _dash_cd := 0.0

var _facing := 1.0
var _was_on_floor := true
var _base_scale: Vector2

var _charging := false
var _charge_held := 0.0
var _attacking := false
var _attack_cd := 0.0
var _pending_damage := 0.0
var _stun_timer := 0.0


func _ready() -> void:
	_base_scale = sprite.scale
	if GameState.spawn_at_checkpoint:
		global_position = GameState.spawn_position
		GameState.spawn_at_checkpoint = false
	health.set_max_health(GameState.get_max_hp(), true)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	hurtbox.hit.connect(_on_hit)
	GameState.regular_enemy_killed.connect(_on_regular_enemy_killed)
	attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)
	attack_timer.timeout.connect(_on_attack_timer_timeout)


func _physics_process(delta: float) -> void:
	if _stun_timer > 0.0:
		_stun_timer -= delta
	if _attack_cd > 0.0:
		_attack_cd -= delta

	if not is_on_floor():
		velocity.y += gravity * delta
		_coyote -= delta
	else:
		_air_jumps_used = 0
		_coyote = coyote_time

	if _stun_timer <= 0.0:
		_handle_attack_input(delta)
		_handle_dash(delta)
		if not _is_dashing:
			_handle_horizontal(delta)
		_handle_jump()
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * 0.5 * delta)
	_update_facing()

	move_and_slide()

	if is_on_floor() and not _was_on_floor:
		_play_land_squash()
	_was_on_floor = is_on_floor()


# --- Movement ---------------------------------------------------------------

func _handle_horizontal(delta: float) -> void:
	var speed := move_speed * (0.5 if _charging else 1.0)
	var input_dir := Input.get_axis("move_left", "move_right")
	if input_dir != 0.0:
		velocity.x = move_toward(velocity.x, input_dir * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or _coyote > 0.0:
			velocity.y = -jump_velocity
			_coyote = 0.0
		elif GameState.has_item("double_jump") and _air_jumps_used < 1:
			_air_jumps_used += 1
			velocity.y = -jump_velocity
	if Input.is_action_just_released("jump") and velocity.y < -250.0:
		velocity.y *= 0.55


func _handle_dash(delta: float) -> void:
	if _dash_cd > 0.0:
		_dash_cd -= delta
	if _is_dashing:
		_dash_timer -= delta
		velocity.x = _facing * dash_speed
		velocity.y = 0.0
		if _dash_timer <= 0.0:
			_is_dashing = false
	elif GameState.has_item("dash") and Input.is_action_just_pressed("dash") and _dash_cd <= 0.0:
		_is_dashing = true
		_dash_timer = dash_duration
		_dash_cd = dash_cooldown


func _update_facing() -> void:
	if velocity.x > 10.0:
		_facing = 1.0
	elif velocity.x < -10.0:
		_facing = -1.0
	sprite.flip_h = _facing < 0.0


# --- Combat -----------------------------------------------------------------

func _handle_attack_input(delta: float) -> void:
	if Input.is_action_just_pressed("attack") and _attack_cd <= 0.0 and not _attacking:
		_charging = true
		_charge_held = 0.0
	if not _charging:
		return
	if Input.is_action_pressed("attack"):
		_charge_held += delta
		if _charge_held >= charge_time:
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.03)
			sprite.self_modulate = Color(1.0 + 0.7 * pulse, 1.0 + 0.5 * pulse, 1.0)
		elif _charge_held > 0.15:
			sprite.self_modulate = Color(1.15, 1.15, 1.0)
	else:
		_charging = false
		sprite.self_modulate = Color.WHITE
		_do_attack(_charge_held >= charge_time)


func _do_attack(charged: bool) -> void:
	_attacking = true
	var duration := charge_attack_duration if charged else attack_duration
	_attack_cd = charge_attack_cooldown if charged else attack_cooldown
	var box := Vector2(170, 130) if charged else Vector2(90, 90)
	var reach := 100.0 if charged else 70.0
	if charged:
		_pending_damage = GameState.get_charge_attack()
		if GameState.has_item("volatile_core") and randi() % 3 == 0:
			_pending_damage += 10.0
			GameState.toast("Volatile Core! +10 damage")
	else:
		_pending_damage = GameState.get_attack()
	(attack_shape.shape as RectangleShape2D).size = box
	attack_visual.size = box
	attack_visual.position = -box / 2.0
	attack_visual.color = Color(1.0, 0.9, 0.4, 0.45) if charged else Color(1, 1, 1, 0.35)
	attack_hitbox.position = Vector2(reach * _facing, -48.0)
	attack_hitbox.monitoring = true
	attack_visual.visible = true
	attack_timer.start(duration)
	AudioManager.play_sfx("player_charge_attack" if charged else "player_attack")


func _cancel_attack() -> void:
	attack_timer.stop()
	attack_hitbox.set_deferred("monitoring", false)
	attack_visual.visible = false
	_attacking = false
	_charging = false
	_charge_held = 0.0
	_attack_cd = 0.25
	sprite.self_modulate = Color.WHITE


func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if not attack_hitbox.monitoring:
		return
	if area.has_method("take_damage"):
		area.take_damage(_pending_damage, self)


func _on_attack_timer_timeout() -> void:
	attack_hitbox.monitoring = false
	attack_visual.visible = false
	_attacking = false


func _on_hit(_amount: float, attacker: Node) -> void:
	if health.invulnerable:
		return
	var armored := GameState.has_item("anti_interrupt")
	if not armored:
		if _attacking or _charging:
			_cancel_attack()
		_stun_timer = stun_time
	if attacker is Node2D and not (armored and _attacking):
		var dir := signf(global_position.x - (attacker as Node2D).global_position.x)
		if dir == 0.0:
			dir = -_facing
		velocity.x = dir * knockback
		velocity.y = -180.0


func _on_damaged(_amount: float) -> void:
	health.invulnerable = true
	get_tree().create_timer(invulnerable_time).timeout.connect(_end_invulnerability)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(3.0, 0.5, 0.5), 0.05)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	for i in 4:
		tw.tween_property(sprite, "modulate:a", 0.35, 0.08)
		tw.tween_property(sprite, "modulate:a", 1.0, 0.08)


func _end_invulnerability() -> void:
	health.invulnerable = false


func _on_regular_enemy_killed() -> void:
	if GameState.has_item("vampire"):
		health.heal(vampire_heal)


func _on_died() -> void:
	GameManager.on_player_died()


func _play_land_squash() -> void:
	var tw := create_tween()
	tw.tween_property(sprite, "scale", _base_scale * Vector2(1.15, 0.85), 0.05)
	tw.tween_property(sprite, "scale", _base_scale, 0.1)
