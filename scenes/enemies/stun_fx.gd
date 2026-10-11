extends Node2D

## Stun marker above a boss: orbiting stars, jittering sparks and a countdown ring.
## `progress` is the stun time left (1 -> 0).

var active: bool = false:
	set(value):
		active = value
		visible = value
		queue_redraw()

var progress: float = 1.0

var _time := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	visible = false
	z_index = 3


func _process(delta: float) -> void:
	if active:
		_time += delta
		queue_redraw()


func _draw() -> void:
	if not active:
		return
	# Orbiting stars.
	for i in 4:
		var a := _time * 4.5 + i * TAU / 4.0
		var p := Vector2(cos(a) * 54.0, sin(a) * 14.0)
		var depth := 0.6 + 0.4 * sin(a)
		_star(p, 9.0 * depth + 3.0, Color(1.0, 0.9, 0.3, 0.6 + 0.4 * depth))
	# Short electric arcs that re-roll ~14 times a second.
	_rng.seed = int(_time * 14.0)
	for k in 2:
		var pts := PackedVector2Array()
		var start := Vector2(_rng.randf_range(-40, 40), _rng.randf_range(-6, 10))
		pts.append(start)
		for j in 3:
			start += Vector2(_rng.randf_range(-14, 14), _rng.randf_range(-12, 4))
			pts.append(start)
		draw_polyline(pts, Color(0.7, 0.95, 1.0, 0.9), 2.0)
	# Countdown ring.
	var c := Vector2(0, 36)
	draw_arc(c, 17.0, 0.0, TAU, 28, Color(0, 0, 0, 0.45), 6.0)
	draw_arc(c, 17.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(progress, 0.0, 1.0), 28, Color(1.0, 0.85, 0.3), 4.0)


func _star(center: Vector2, size: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var r := size if i % 2 == 0 else size * 0.38
		pts.append(center + Vector2.from_angle(i * TAU / 8.0 - PI / 2.0) * r)
	draw_colored_polygon(pts, color)
