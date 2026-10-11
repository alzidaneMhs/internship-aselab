extends Node2D

## Glowing orb at the muzzle that grows while the attack key is held.

var ratio: float = 0.0:
	set(value):
		ratio = clampf(value, 0.0, 1.0)
		visible = ratio > 0.0
		queue_redraw()


func _process(_delta: float) -> void:
	if ratio >= 1.0:
		queue_redraw()


func _draw() -> void:
	if ratio <= 0.0:
		return
	var pulse := 1.0
	if ratio >= 1.0:
		pulse = 1.0 + 0.25 * sin(Time.get_ticks_msec() * 0.03)
	var r := (5.0 + 17.0 * ratio) * pulse
	draw_circle(Vector2.ZERO, r * 1.7, Color(1.0, 0.1, 0.25, 0.22))
	draw_circle(Vector2.ZERO, r, Color(1.0, 0.3, 0.4, 0.85))
	draw_circle(Vector2.ZERO, r * 0.5, Color(1.0, 1.0, 1.0, 1.0))
