extends Area2D

const TEETH := 12

@export var radius: float = 38.0:
	set(value):
		radius = value
		if is_node_ready():
			_rebuild()
@export var travel: Vector2 = Vector2(0.0, 300.0)
@export var speed: float = 180.0
@export var phase: float = 0.0
@export var damage: float = 14.0
@export var hit_interval: float = 0.5
@export var ease_ends: bool = true

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _origin := Vector2.ZERO
var _u := 0.0
var _spin := 0.0
var _hit_cd := 0.0
var _awake := true
var _sparks: CPUParticles2D


func _ready() -> void:
	_origin = position
	_rebuild()
	area_entered.connect(_on_area_entered)
	_sparks = CPUParticles2D.new()
	_sparks.amount = 10
	_sparks.lifetime = 0.35
	_sparks.direction = Vector2(0.0, -1.0)
	_sparks.spread = 180.0
	_sparks.gravity = Vector2(0.0, 600.0)
	_sparks.initial_velocity_min = 90.0
	_sparks.initial_velocity_max = 200.0
	_sparks.scale_amount_min = 1.6
	_sparks.scale_amount_max = 2.8
	_sparks.color = Color(1.0, 0.7, 0.4)
	_sparks.emitting = false
	_sparks.local_coords = false
	add_child(_sparks)
	_update_position()


func _rebuild() -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius * 0.92
	collision_shape.shape = shape
	queue_redraw()


func _track_u() -> float:
	var length := travel.length()
	if length < 1.0:
		return 0.0
	var t := fposmod(Time.get_ticks_msec() * 0.001 * speed / length + phase, 2.0)
	var u := t if t <= 1.0 else 2.0 - t
	if ease_ends:
		u = smoothstep(0.0, 1.0, u)
	return u


func _update_position() -> void:
	_u = _track_u()
	position = _origin + travel * _u


func _process(delta: float) -> void:
	var visible_now := _near_view()
	if visible_now != _awake:
		_awake = visible_now
		monitoring = visible_now
		_sparks.emitting = false
	if not _awake:
		return
	_update_position()
	_spin += delta * (7.0 + speed * 0.03)
	_hit_cd = maxf(_hit_cd - delta, 0.0)
	_sparks.emitting = _hit_cd > 0.0
	if _hit_cd <= 0.0 and not Cutscene.active:
		for area in get_overlapping_areas():
			if area.has_method("take_damage"):
				_hit(area)
				break
	queue_redraw()


func _near_view() -> bool:
	var parent := get_parent() as Node2D
	var mid := _origin + travel * 0.5
	if parent != null:
		mid = parent.to_global(mid)
	var screen: Vector2 = get_viewport().get_canvas_transform() * mid
	var size := get_viewport().get_visible_rect().size
	var margin := 500.0 + travel.length() * 0.5
	return screen.x > -margin and screen.x < size.x + margin and screen.y > -margin and screen.y < size.y + margin


func _on_area_entered(area: Area2D) -> void:
	if _hit_cd <= 0.0 and area.has_method("take_damage"):
		_hit(area)


func _hit(area: Area2D) -> void:
	_hit_cd = hit_interval
	AudioManager.play_sfx_at("saw_hit", area.global_position, -1.0, 0.1)
	area.take_damage(damage * GameState.get_trap_multiplier())
	get_tree().call_group("main_camera", "shake", 4.0)


func _draw() -> void:
	_draw_rail()
	var teeth_color := Color(0.62, 0.64, 0.7)
	var rust := Color(0.45, 0.22, 0.16)
	var glow := 0.5 + 0.5 * sin(_spin * 2.0)
	draw_circle(Vector2.ZERO, radius * 1.55, Color(1.0, 0.15, 0.1, 0.07 + 0.04 * glow))
	var pts := PackedVector2Array()
	var step := TAU / TEETH
	for i in TEETH:
		var a := _spin + i * step
		pts.append(Vector2.from_angle(a) * radius * 0.74)
		pts.append(Vector2.from_angle(a + step * 0.12) * radius)
		pts.append(Vector2.from_angle(a + step * 0.62) * radius * 0.78)
	draw_colored_polygon(pts, teeth_color.darkened(0.25))
	draw_polyline(_closed(pts), teeth_color.lightened(0.15), 2.0)
	draw_circle(Vector2.ZERO, radius * 0.7, Color(0.2, 0.2, 0.26))
	draw_arc(Vector2.ZERO, radius * 0.7, 0.0, TAU, 28, rust, 3.0)
	for i in 3:
		var a := -_spin * 1.4 + i * TAU / 3.0
		draw_line(Vector2.from_angle(a) * radius * 0.2, Vector2.from_angle(a) * radius * 0.62, Color(0.4, 0.4, 0.5), 5.0)
	draw_circle(Vector2.ZERO, radius * 0.22, Color(0.55, 0.12, 0.1))
	draw_circle(Vector2.ZERO, radius * 0.1, Color(1.0, 0.7, 0.5, 0.6 + 0.4 * glow))
	for i in 4:
		var a := _spin * 0.5 + i * TAU / 4.0
		draw_circle(Vector2.from_angle(a) * radius * 0.52, 2.0, Color(0.7, 0.7, 0.8))


func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = pts.duplicate()
	out.append(pts[0])
	return out


func _draw_rail() -> void:
	var a := -travel * _u
	var b := travel * (1.0 - _u)
	if (b - a).length() < 2.0:
		return
	draw_line(a, b, Color(0.03, 0.03, 0.05, 0.9), 12.0)
	draw_line(a, b, Color(0.22, 0.2, 0.28, 0.9), 6.0)
	draw_line(a, b, Color(0.5, 0.2, 0.18, 0.5), 2.0)
	var dir := (b - a).normalized()
	var length := (b - a).length()
	var d := 0.0
	while d <= length:
		draw_circle(a + dir * d, 3.0, Color(0.45, 0.45, 0.55))
		d += 60.0
	draw_circle(a, 9.0, Color(0.14, 0.13, 0.18))
	draw_circle(b, 9.0, Color(0.14, 0.13, 0.18))
