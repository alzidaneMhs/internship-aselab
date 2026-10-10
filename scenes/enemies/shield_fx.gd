extends Node2D

## Visual ring for Krums' shield. `ratio` is shield remaining (0..1).

@export var radius: float = 170.0

var ratio: float = 1.0:
	set(value):
		ratio = clampf(value, 0.0, 1.0)
		visible = ratio > 0.0
		queue_redraw()


func _draw() -> void:
	var c := Color(0.35, 0.85, 1.0, 0.25 + 0.5 * ratio)
	draw_circle(Vector2.ZERO, radius, Color(c, 0.08))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, c, 5.0)
