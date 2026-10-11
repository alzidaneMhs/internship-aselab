extends "res://scenes/enemies/boss_base.gd"

## LUSHTE (Stage 3 boss): winged robot. HP 380.
## Light attack: shoots a projectile (15 dmg).
## Heavy attack: flies high, then dives at the player with a blade (25 dmg).

const PROJECTILE_SCENE := preload("res://scenes/enemies/projectile.tscn")

enum State { HOVER, ASCEND, TELEGRAPH, DIVE, RECOVER }

@export var fly_speed: float = 280.0
@export var hover_offset: Vector2 = Vector2(240.0, -150.0)
@export var light_damage: float = 15.0
@export var dive_damage: float = 25.0
@export var dive_speed: float = 950.0
@export var shoot_interval: float = 1.8
@export var heavy_interval: float = 6.5

@onready var shoot_timer: Timer = $ShootTimer
@onready var heavy_timer: Timer = $HeavyTimer
@onready var muzzle: Marker2D = $Muzzle
@onready var blade_area: Area2D = $BladeArea

var _state := State.HOVER
var _state_time := 0.0
var _side := 1.0
var _dive_target := Vector2.ZERO
var _blade_hit := false


func _ready() -> void:
	super._ready()
	shoot_timer.wait_time = shoot_interval
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	shoot_timer.start()
	heavy_timer.wait_time = heavy_interval
	heavy_timer.timeout.connect(_on_heavy_timer_timeout)
	heavy_timer.start()
	blade_area.area_entered.connect(_on_blade_area_entered)


func _update_ai(delta: float) -> void:
	if not _player_in_range() and _state == State.HOVER:
		velocity = Vector2.ZERO
		return
	_state_time += delta
	var player_pos := player_ref.global_position
	match _state:
		State.HOVER:
			var side_now := signf(global_position.x - player_pos.x)
			if side_now != 0.0:
				_side = side_now
			var target := player_pos + Vector2(_side * absf(hover_offset.x), hover_offset.y)
			velocity = (target - global_position).limit_length(fly_speed * 1.2) * 3.0
			velocity = velocity.limit_length(fly_speed)
			_face(player_pos.x)
		State.ASCEND:
			var target := Vector2(player_pos.x, player_pos.y - 420.0)
			velocity = (target - global_position).limit_length(fly_speed * 2.0) * 4.0
			velocity = velocity.limit_length(fly_speed * 2.0)
			if _state_time > 0.9 or global_position.distance_to(target) < 40.0:
				_enter_state(State.TELEGRAPH)
		State.TELEGRAPH:
			velocity = Vector2.ZERO
			_face(player_pos.x)
			_dive_target = player_pos + Vector2(0, -40)
			if _state_time > 0.55:
				_enter_state(State.DIVE)
		State.DIVE:
			var to_target := _dive_target - global_position
			velocity = to_target.normalized() * dive_speed
			if to_target.length() < 40.0 or is_on_floor() or _state_time > 1.0:
				_enter_state(State.RECOVER)
		State.RECOVER:
			velocity.x = 0.0
			if _state_time > 1.2:
				_enter_state(State.HOVER)


func _enter_state(new_state: State) -> void:
	_state = new_state
	_state_time = 0.0
	match new_state:
		State.TELEGRAPH:
			var tw := create_tween()
			tw.tween_property(sprite, "self_modulate", Color(3.0, 0.6, 0.6), 0.25)
			tw.tween_property(sprite, "self_modulate", Color.WHITE, 0.25)
		State.DIVE:
			_blade_hit = false
			blade_area.monitoring = true
		State.RECOVER:
			blade_area.set_deferred("monitoring", false)
			velocity = Vector2.ZERO
		State.HOVER:
			blade_area.set_deferred("monitoring", false)


func _face(player_x: float) -> void:
	var player_is_right := player_x > global_position.x
	sprite.flip_h = player_is_right
	muzzle.position.x = absf(muzzle.position.x) * (1.0 if player_is_right else -1.0)


func _on_shoot_timer_timeout() -> void:
	if _defeated or stun_remaining > 0.0 or _state != State.HOVER or not _player_in_range():
		return
	var dir := (player_ref.global_position + PLAYER_CENTER) - muzzle.global_position
	if dir.length() < 1.0:
		return
	var proj := PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = muzzle.global_position
	proj.launch(dir, 460.0, light_damage)
	AudioManager.play_sfx("lushte_shoot")


func _on_heavy_timer_timeout() -> void:
	if _defeated or stun_remaining > 0.0 or _state != State.HOVER or not _player_in_range():
		return
	_enter_state(State.ASCEND)


func _on_stun_start() -> void:
	# Drops out of the air and cancels any dive in progress.
	_state = State.HOVER
	_state_time = 0.0
	blade_area.set_deferred("monitoring", false)
	velocity = Vector2.ZERO


func _on_stun_end() -> void:
	_state = State.HOVER
	_state_time = 0.0


func _on_blade_area_entered(area: Area2D) -> void:
	if _blade_hit or not area.has_method("take_damage"):
		return
	_blade_hit = true
	area.take_damage(dive_damage, self)


func _on_defeated_state() -> void:
	var st := get_node_or_null("ShootTimer") as Timer
	var ht := get_node_or_null("HeavyTimer") as Timer
	if st != null:
		st.stop()
	if ht != null:
		ht.stop()
	var blade := get_node_or_null("BladeArea") as Area2D
	if blade != null:
		blade.set_deferred("monitoring", false)
