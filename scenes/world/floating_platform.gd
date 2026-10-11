@tool
extends AnimatableBody2D

## Hovering platform that drifts in a small loop. One-way: you can jump up
## through it from below. The player is carried along while standing on it.
## Origin is the top-left corner of the slab.

@export var size: Vector2 = Vector2(170, 22):
	set(value):
		size = value
		if is_inside_tree():
			_rebuild()
@export var accent: Color = Color(1.0, 0.55, 0.2, 1.0):
	set(value):
		accent = value
		queue_redraw()
@export var amplitude: Vector2 = Vector2(60, 18)
@export var speed: float = 0.8
@export var phase: float = 0.0

var _origin: Vector2
var _t := 0.0
var _body_style := StyleBoxFlat.new()


func _ready() -> void:
	_origin = position
	_t = phase
	_body_style.set_corner_radius_all(7)
	_body_style.bg_color = Color(0.2, 0.18, 0.27)
	_body_style.border_color = Color(0.07, 0.05, 0.1)
	_body_style.set_border_width_all(2)
	_rebuild()


func _rebuild() -> void:
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null:
		var rect := RectangleShape2D.new()
		rect.size = size
		cs.shape = rect
		cs.position = size / 2.0
		cs.one_way_collision = true
		cs.one_way_collision_margin = 8.0
	queue_redraw()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta * speed
	position = _origin + Vector2(sin(_t) * amplitude.x, cos(_t * 1.3) * amplitude.y)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var time := Time.get_ticks_msec() * 0.001
	# Thruster glow under both ends.
	for fx in [0.2, 0.8]:
		var base := Vector2(size.x * fx, size.y)
		var flame := 14.0 + 6.0 * sin(time * 22.0 + fx * 9.0)
		draw_colored_polygon(PackedVector2Array([base + Vector2(-9, 0), base + Vector2(9, 0), base + Vector2(0, flame)]), Color(accent, 0.55))
		draw_colored_polygon(PackedVector2Array([base + Vector2(-4, 0), base + Vector2(4, 0), base + Vector2(0, flame * 0.6)]), Color(1.0, 0.95, 0.8, 0.9))
		draw_circle(base + Vector2(0, 2), 12.0, Color(accent, 0.12))
	# Slab.
	draw_style_box(_body_style, Rect2(Vector2.ZERO, size))
	draw_rect(Rect2(6.0, 3.0, size.x - 12.0, 3.0), Color(1, 1, 1, 0.2))
	draw_rect(Rect2(6.0, size.y - 5.0, size.x - 12.0, 3.0), accent)
	draw_rect(Rect2(4.0, size.y - 7.0, size.x - 8.0, 8.0), Color(accent, 0.2))
	for i in 3:
		draw_circle(Vector2(size.x * (0.25 + 0.25 * i), size.y * 0.5), 2.0, Color(accent.lightened(0.4), 0.9))
