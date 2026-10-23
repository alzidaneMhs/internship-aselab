extends Node2D

const PROJECTILE_SCENE := preload("res://scenes/enemies/projectile.tscn")
const FX := preload("res://scripts/effects/laser_fx.gd")
const PLAYER_CENTER := Vector2(0.0, -48.0)

@export_enum("Left wall", "Right wall") var side: int = 0
@export var detect_range: float = 640.0
@export var fire_interval: float = 2.6
@export var charge_time: float = 0.7
@export var projectile_speed: float = 340.0
@export var projectile_damage: float = 11.0
@export var burst: int = 1
@export var burst_gap: float = 0.22
@export var wake_delay: float = 2.2
@export var max_angle: float = 1.15

var _dir := 1.0
var _aim := 0.0
var _cd := 0.0
var _charge := 0.0
var _recoil := 0.0
var _time := 0.0
var _awake_at_msec := 0
var _player: Node2D
var _firing := false


func _ready() -> void:
	_dir = 1.0 if side == 0 else -1.0
	_cd = randf_range(0.5, 1.6)
	_time = randf() * 10.0
	_awake_at_msec = Time.get_ticks_msec() + int(wake_delay * 1000.0)
	_player = get_tree().get_first_node_in_group("player") as Node2D
	z_index = 3


func _muzzle() -> Vector2:
	return global_position + Vector2(_dir * 36.0, 0.0) + Vector2.from_angle(_aim) * Vector2(_dir, 1.0) * 46.0


func _aim_angle_to(target: Vector2) -> float:
	var d := target - (global_position + Vector2(_dir * 36.0, 0.0))
	var a := atan2(d.y, d.x * _dir)
	return clampf(a, -max_angle, max_angle)


func _physics_process(delta: float) -> void:
	_time += delta
	_recoil = maxf(_recoil - delta * 5.0, 0.0)
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		return
	if not FX.on_screen(self, 900.0):
		_charge = 0.0
		return
	var target := _player.global_position + PLAYER_CENTER
	var in_range := Time.get_ticks_msec() >= _awake_at_msec and global_position.distance_to(target) <= detect_range and not Cutscene.active
	if in_range and not _firing:
		var want := _aim_angle_to(target)
		if _charge < 0.8:
			_aim = lerp_angle(_aim, want, minf(1.0, 6.0 * delta))
		_cd -= delta
		_charge = clampf(1.0 - _cd / charge_time, 0.0, 1.0) if _cd < charge_time else 0.0
		if _cd <= 0.0:
			_fire()
	elif not in_range:
		_charge = 0.0
		_cd = maxf(_cd, 0.6)
		_aim = lerp_angle(_aim, 0.0, minf(1.0, 3.0 * delta))
	queue_redraw()


func _fire() -> void:
	_firing = true
	_charge = 0.0
	for i in burst:
		if not is_inside_tree() or Cutscene.active:
			break
		if _has_line_of_fire():
			_spawn_bullet()
		if i < burst - 1:
			await get_tree().create_timer(burst_gap).timeout
	_cd = fire_interval
	_firing = false


func _has_line_of_fire() -> bool:
	var target := _player.global_position + PLAYER_CENTER
	var query := PhysicsRayQueryParameters2D.create(_muzzle(), target, 1)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _spawn_bullet() -> void:
	var bullet := PROJECTILE_SCENE.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = _muzzle()
	var dir := Vector2(_dir * cos(_aim), sin(_aim))
	bullet.launch(dir, projectile_speed, projectile_damage * GameState.get_trap_multiplier())
	_recoil = 1.0
	FX.spawn_muzzle_flash(get_parent(), _muzzle(), _dir)
	AudioManager.play_sfx_at("turret_fire", _muzzle(), -3.0, 0.1)


func _draw() -> void:
	var s := _dir
	var metal := Color(0.18, 0.19, 0.25)
	var metal_light := Color(0.4, 0.42, 0.52)
	var dark := Color(0.06, 0.06, 0.1)
	draw_polygon(PackedVector2Array([
		Vector2(0.0, -46.0), Vector2(s * 30.0, -34.0), Vector2(s * 40.0, 0.0), Vector2(s * 30.0, 34.0), Vector2(0.0, 46.0)]),
		PackedColorArray([metal, metal_light, metal, metal_light, metal]))
	draw_polyline(PackedVector2Array([
		Vector2(0.0, -46.0), Vector2(s * 30.0, -34.0), Vector2(s * 40.0, 0.0), Vector2(s * 30.0, 34.0), Vector2(0.0, 46.0)]), dark, 2.0)
	for k in 3:
		var yy := -26.0 + k * 26.0
		draw_rect(Rect2(Vector2(minf(s * 4.0, s * 12.0), yy - 4.0), Vector2(8.0, 8.0)), Color(0.55, 0.12, 0.1, 0.9))
	draw_circle(Vector2(s * 36.0, 0.0), 16.0, metal)
	draw_arc(Vector2(s * 36.0, 0.0), 16.0, 0.0, TAU, 20, dark, 2.5)
	var barrel_dir := Vector2(s * cos(_aim), sin(_aim))
	var back := Vector2(s * 36.0, 0.0) - barrel_dir * _recoil * 8.0
	var tip := back + barrel_dir * 48.0
	draw_line(back, tip, dark, 15.0)
	draw_line(back, tip, metal_light, 10.0)
	draw_line(back, tip, metal, 5.0)
	draw_circle(tip, 7.0, dark)
	var led := Color(0.35, 0.08, 0.08).lerp(Color(1.0, 0.25, 0.15), _charge)
	if _charge > 0.0:
		led = led.lerp(Color(1.0, 0.9, 0.7), 0.5 + 0.5 * sin(_time * 40.0))
		var end := tip + barrel_dir * 900.0
		draw_line(tip, end, Color(1.0, 0.2, 0.15, 0.1 + 0.3 * _charge), 2.0)
		draw_circle(tip, 8.0 + 12.0 * _charge, Color(1.0, 0.25, 0.15, 0.25 * _charge))
	draw_circle(Vector2(s * 36.0, 0.0), 6.0, led)
	draw_circle(Vector2(s * 36.0, 0.0), 2.5, Color(1, 1, 1, 0.6))
	var glow := 0.5 + 0.5 * sin(_time * 2.4)
	draw_circle(Vector2(s * 36.0, 0.0), 24.0 + 6.0 * glow, Color(led, 0.12))
