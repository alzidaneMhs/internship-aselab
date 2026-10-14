extends Node2D

## Warning marker on the floor: a flattened ring that shrinks onto the target, a
## pulsing fill and bouncing arrows. Frees itself when `duration` is over.
## Origin is the target point on the ground.

var radius: float = 120.0
var duration: float = 1.0
var color: Color = Color(1.0, 0.25, 0.2)

var _t := 0.0


func _ready() -> void:
	z_index = 2
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _process(delta: float) -> void:
	_t += delta
	if _t >= duration:
		queue_free()
		return
	queue_redraw()


func _ellipse(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 33:
		var a := i * TAU / 32.0
		pts.append(Vector2(cos(a) * r, sin(a) * r * 0.2))
	return pts


func _draw() -> void:
	var k := clampf(_t / duration, 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(_t * 22.0)
	draw_colored_polygon(_ellipse(radius), Color(color, 0.1 + 0.22 * k * (0.6 + 0.4 * pulse)))
	draw_polyline(_ellipse(radius), Color(color, 0.9), 3.0)
	# Ring closing in on the target.
	draw_polyline(_ellipse(radius * (1.7 - 0.7 * k)), Color(1.0, 0.85, 0.7, 0.8 * (1.0 - k * 0.4)), 4.0)
	# Arrows pointing down at the spot.
	for i in 3:
		var y := -30.0 - i * 26.0 - 8.0 * sin(_t * 9.0 - i)
		draw_colored_polygon(PackedVector2Array([Vector2(-18, y - 14), Vector2(18, y - 14), Vector2(0, y + 4)]),
			Color(color, (0.85 - 0.25 * i) * (0.5 + 0.5 * pulse)))
