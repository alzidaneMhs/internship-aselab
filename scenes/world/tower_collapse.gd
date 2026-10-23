extends Node2D

const DROP := preload("res://scenes/enemies/hanch_gold_drop.gd")

@export var trigger_y: float = -6300.0
@export var start_y: float = -5700.0
@export var finish_y: float = -7240.0
@export var rise_speed: float = 40.0
@export var rise_accel: float = 0.6
@export var max_lag: float = 900.0
@export var shaft_left: float = 0.0
@export var shaft_right: float = 1100.0
@export var delay: float = 2.6
@export var debris_interval: float = 1.3
@export var debris_damage: float = 18.0

var _state := 0
var _surface := 0.0
var _speed := 0.0
var _t := 0.0
var _debris_t := 0.0
var _shake_t := 0.0
var _time := 0.0
var _killed := false
var _player: Node2D
var _dust: CPUParticles2D


func _ready() -> void:
	z_index = 6
	_surface = start_y
	_speed = rise_speed
	_dust = CPUParticles2D.new()
	_dust.amount = 50
	_dust.lifetime = 2.2
	_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust.emission_rect_extents = Vector2(700.0, 10.0)
	_dust.direction = Vector2(0, 1)
	_dust.spread = 15.0
	_dust.gravity = Vector2(0, 500)
	_dust.initial_velocity_min = 60.0
	_dust.initial_velocity_max = 160.0
	_dust.scale_amount_min = 2.0
	_dust.scale_amount_max = 4.5
	_dust.color = Color(0.45, 0.42, 0.5, 0.7)
	_dust.emitting = false
	_dust.local_coords = false
	add_child(_dust)


func _physics_process(delta: float) -> void:
	_time += delta
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		return
	if Cutscene.active:
		return
	match _state:
		0:
			if _player.global_position.y < trigger_y:
				_begin()
		1:
			_t += delta
			_rumble(delta, 3.0)
			if _t >= delay:
				_state = 2
		2:
			_speed += rise_accel * delta
			_surface -= _speed * delta
			_surface = minf(_surface, _player.global_position.y + max_lag)
			_rumble(delta, 2.0)
			_debris_t -= delta
			if _debris_t <= 0.0:
				_debris_t = debris_interval
				_spawn_debris()
			if not _killed and _player.global_position.y > _surface - 6.0:
				_killed = true
				get_tree().call_group("main_camera", "shake", 18.0)
				GameManager.on_player_died()
			if _player.global_position.y < finish_y:
				_finish()
		3:
			_surface += 60.0 * delta
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		_dust.global_position = cam.get_screen_center_position() + Vector2(0.0, -380.0)
	queue_redraw()


func _begin() -> void:
	_state = 1
	_t = 0.0
	_dust.emitting = true
	GameState.toast(tr("MENARA RUNTUH! Panjat secepatnya, virus naik dari bawah!"))
	get_tree().call_group("main_camera", "shake", 16.0)
	AudioManager.play_sfx("tower_collapse")


func _finish() -> void:
	_state = 3
	_dust.emitting = false
	GameState.toast(tr("Kamu berhasil lolos dari reruntuhan menara!"))
	AudioManager.play_sfx("tower_escape")
	get_tree().call_group("main_camera", "shake", 6.0)


func _rumble(delta: float, strength: float) -> void:
	_shake_t -= delta
	if _shake_t <= 0.0:
		_shake_t = 0.45
		AudioManager.play_sfx("rumble", -10.0, 0.1)
		get_tree().call_group("main_camera", "shake", strength)


func _spawn_debris() -> void:
	var tx := clampf(_player.global_position.x + randf_range(-320.0, 320.0), shaft_left + 60.0, shaft_right - 60.0)
	if randf() < 0.4:
		tx = clampf(_player.global_position.x + _player.velocity.x * 0.4, shaft_left + 60.0, shaft_right - 60.0)
	var from := Vector2(tx, _player.global_position.y - 120.0)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0.0, 700.0), 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var drop = Node2D.new()
	drop.set_script(DROP)
	drop.damage = debris_damage
	drop.warn_time = 0.85
	drop.style = "rock"
	get_parent().add_child(drop)
	drop.global_position = hit["position"]


func _draw() -> void:
	if _state == 0:
		return
	var top := _surface
	var left := shaft_left - 120.0
	var right := shaft_right + 120.0
	var pts := PackedVector2Array()
	var x := left
	while x <= right:
		var wave := sin(x * 0.02 + _time * 3.0) * 10.0 + sin(x * 0.051 - _time * 4.3) * 6.0
		pts.append(Vector2(x, top + wave))
		x += 24.0
	var body := pts.duplicate()
	body.append(Vector2(right, top + 1600.0))
	body.append(Vector2(left, top + 1600.0))
	draw_colored_polygon(body, Color(0.28, 0.05, 0.36, 0.92))
	draw_rect(Rect2(left, top + 40.0, right - left, 1560.0), Color(0.18, 0.02, 0.24, 0.6))
	draw_polyline(pts, Color(0.85, 0.35, 1.0, 0.95), 6.0)
	var glow_pts := PackedVector2Array()
	for p in pts:
		glow_pts.append(p + Vector2(0.0, -10.0))
	draw_polyline(glow_pts, Color(0.75, 0.3, 1.0, 0.25), 18.0)
	for i in 14:
		var bx := left + fposmod(i * 97.0 + _time * 23.0 * (1.0 + i % 3), right - left)
		var rise := fposmod(_time * 0.7 + i * 0.37, 1.0)
		var by := top + 160.0 - rise * 150.0
		draw_circle(Vector2(bx, by), 6.0 + 6.0 * (1.0 - rise), Color(0.9, 0.5, 1.0, 0.5 * (1.0 - rise)))
	for i in 6:
		var sx := left + (i + 0.5) * (right - left) / 6.0 + sin(_time + i) * 20.0
		draw_circle(Vector2(sx, top + 70.0), 18.0, Color(0.1, 0.0, 0.12, 0.8))
		draw_circle(Vector2(sx - 6.0, top + 66.0), 4.0, Color(1.0, 0.3, 0.3, 0.9))
		draw_circle(Vector2(sx + 6.0, top + 66.0), 4.0, Color(1.0, 0.3, 0.3, 0.9))
