extends "res://scenes/enemies/enemy_base.gd"

enum State { PATROL, AIM, DIVE, BOOM }

@export var hover_range: Vector2 = Vector2(120.0, 14.0)
@export var dive_speed: float = 720.0
@export var aim_time: float = 0.8
@export var explosion_damage: float = 24.0
@export var dive_lifetime: float = 1.15
@export var retry_delay: float = 1.0

@onready var contact_area: Area2D = $ContactArea
@onready var explosion_area: Area2D = $ExplosionArea

var _state := State.PATROL
var _state_time := 0.0
var _home := Vector2.ZERO
var _phase := 0.0
var _time := 0.0
var _cooldown := 1.0
var _aim_target := Vector2.ZERO
var _dive_dir := Vector2.DOWN
var _ghost_timer := 0.0


func _ready() -> void:
	super._ready()
	_home = global_position
	_phase = randf() * TAU
	_time = randf() * 10.0
	_cooldown = randf_range(0.6, 1.6)
	contact_area.area_entered.connect(_on_contact)
	explosion_area.area_entered.connect(_on_explosion_hit)


func _center() -> Vector2:
	return global_position + Vector2(0.0, -50.0)


func _has_line_of_sight() -> bool:
	var query := PhysicsRayQueryParameters2D.create(_center(), player_ref.global_position + PLAYER_CENTER, 1)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _state == State.DIVE and not _dead and not Cutscene.active and get_slide_collision_count() > 0:
		_explode()


func _update_ai(delta: float) -> void:
	_time += delta
	_state_time += delta
	_cooldown -= delta
	match _state:
		State.PATROL:
			var target := _home + Vector2(sin(_time * 0.9 + _phase) * hover_range.x, sin(_time * 1.7 + _phase) * hover_range.y)
			velocity = ((target - global_position) * 3.0).limit_length(170.0)
			if _cooldown <= 0.0 and _player_in_range() and _has_line_of_sight():
				_enter(State.AIM)
		State.AIM:
			velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
			if _state_time < aim_time - 0.22:
				_aim_target = player_ref.global_position + PLAYER_CENTER
			if _state_time >= aim_time:
				_dive_dir = (_aim_target - _center()).normalized()
				if _dive_dir == Vector2.ZERO:
					_dive_dir = Vector2.DOWN
				_enter(State.DIVE)
		State.DIVE:
			var speed := minf(dive_speed, 220.0 + _state_time * 2600.0)
			velocity = _dive_dir * speed
			_ghost_timer -= delta
			if _ghost_timer <= 0.0:
				_ghost_timer = 0.04
				_spawn_ghost()
			if _state_time > dive_lifetime:
				_explode()
		State.BOOM:
			velocity = Vector2.ZERO


func _enter(new_state: State) -> void:
	_state = new_state
	_state_time = 0.0
	contact_area.set_deferred("monitoring", new_state == State.DIVE)
	queue_redraw()
	if new_state == State.DIVE:
		AudioManager.play_sfx_at("drone_dive", global_position, 0.0, 0.08)
		get_tree().call_group("main_camera", "shake", 3.0)


func _process(delta: float) -> void:
	if _dead:
		return
	var alert := _state == State.AIM or _state == State.DIVE
	var base_frame := 2 if alert else 0
	sprite.frame = base_frame + int(_time * (16.0 if alert else 8.0)) % 2
	match _state:
		State.PATROL:
			sprite.position = sprite.position.lerp(Vector2(0.0, -50.0), minf(1.0, 12.0 * delta))
			sprite.rotation = lerp_angle(sprite.rotation, clampf(velocity.x / 500.0, -0.3, 0.3), minf(1.0, 8.0 * delta))
		State.AIM:
			sprite.position = Vector2(randf_range(-2.5, 2.5), -50.0 + randf_range(-2.5, 2.5))
			sprite.rotation = lerp_angle(sprite.rotation, 0.0, minf(1.0, 10.0 * delta))
		State.DIVE:
			sprite.position = Vector2(0.0, -50.0)
			sprite.rotation = clampf(atan2(-_dive_dir.x, _dive_dir.y), -1.7, 1.7)
	if _state == State.AIM:
		queue_redraw()
	elif _state == State.DIVE:
		queue_redraw()


func _draw() -> void:
	if _dead or Cutscene.active:
		return
	if _state == State.AIM:
		var k := clampf(_state_time / aim_time, 0.0, 1.0)
		var local_center := Vector2(0.0, -50.0)
		var dir := (_aim_target - _center()).normalized()
		if dir != Vector2.ZERO:
			var end := local_center + dir * 680.0
			draw_line(local_center, end, Color(1.0, 0.2, 0.15, 0.1 + 0.3 * k), 3.0 + 7.0 * k)
			draw_line(local_center, end, Color(1.0, 0.7, 0.6, 0.35 + 0.4 * k), 1.5)
		var pulse := 0.5 + 0.5 * sin(_state_time * 30.0)
		draw_arc(local_center, 50.0 + 24.0 * (1.0 - k), 0.0, TAU, 28, Color(1.0, 0.25, 0.2, 0.3 + 0.5 * k * pulse), 3.0)


func _spawn_ghost() -> void:
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.hframes = sprite.hframes
	ghost.frame = sprite.frame
	ghost.scale = sprite.scale
	ghost.rotation = sprite.rotation
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.modulate = Color(1.0, 0.4, 0.3, 0.45)
	ghost.z_index = -1
	ghost.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	get_parent().add_child(ghost)
	ghost.global_position = sprite.global_position
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tw.tween_callback(ghost.queue_free)


func _explode() -> void:
	if _state == State.BOOM or _dead:
		return
	_state = State.BOOM
	queue_redraw()
	_suicide = true
	velocity = Vector2.ZERO
	explosion_area.set_deferred("monitoring", true)
	contact_area.set_deferred("monitoring", false)
	await get_tree().create_timer(0.08).timeout
	if is_inside_tree() and not _dead:
		health.apply_damage(health.max_health)


func _on_contact(area: Area2D) -> void:
	if _state == State.DIVE and area.has_method("take_damage"):
		_explode()


func _on_explosion_hit(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(explosion_damage, self)
