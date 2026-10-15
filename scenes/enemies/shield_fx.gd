extends Node2D

@export var radius: float = 170.0

var ratio: float = 1.0:
	set(value):
		ratio = clampf(value, 0.0, 1.0)
		visible = ratio > 0.0 or _burst > 0.0
		queue_redraw()

var _flash := 0.0
var _burst := 0.0
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	_flash = move_toward(_flash, 0.0, delta * 3.5)
	if visible:
		queue_redraw()


func hit_flash() -> void:
	_flash = 1.0


func break_burst() -> void:
	_burst = 0.01
	visible = true
	var tw := create_tween()
	tw.tween_property(self, "_burst", 1.0, 0.55)
	tw.tween_callback(_finish_burst)


func _finish_burst() -> void:
	_burst = 0.0
	visible = ratio > 0.0
	queue_redraw()


func _draw() -> void:
	if ratio > 0.0:
		var low := 1.0 - ratio
		var wobble := 1.0 + 0.012 * sin(_time * (3.0 + 10.0 * low))
		var r := radius * wobble
		var rim := Color(0.4, 0.9, 1.0).lerp(Color(1.0, 0.6, 0.35), low * 0.6)
		draw_circle(Vector2.ZERO, r, Color(rim, 0.07 + 0.2 * _flash))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 72, Color(rim, 0.55 + 0.4 * _flash), 4.0 + 5.0 * _flash)
		draw_arc(Vector2.ZERO, r - 9.0, 0.0, TAU, 72, Color(rim, 0.18), 2.0)
		for i in 3:
			var a0 := _time * 1.3 + i * TAU / 3.0
			draw_arc(Vector2.ZERO, r - 4.0, a0, a0 + 0.75, 14, Color(1, 1, 1, 0.55 * ratio + 0.2), 3.0)
		for i in 6:
			var a := _time * 0.25 + i * TAU / 6.0
			draw_line(Vector2.from_angle(a) * (r - 40.0), Vector2.from_angle(a + TAU / 6.0) * (r - 40.0), Color(rim, 0.12), 2.0)
	if _burst > 0.0:
		var k := _burst
		draw_arc(Vector2.ZERO, radius * (1.0 + k * 0.6), 0.0, TAU, 72, Color(0.7, 0.97, 1.0, 1.0 - k), 8.0 * (1.0 - k) + 1.0)
		draw_circle(Vector2.ZERO, radius * (0.4 + k), Color(0.8, 1.0, 1.0, 0.35 * (1.0 - k)))
		for i in 16:
			var dir := Vector2.from_angle(i * TAU / 16.0 + 0.2)
			draw_line(dir * radius * (0.85 + k * 0.6), dir * radius * (1.05 + k * 1.1), Color(1, 1, 1, 1.0 - k), 3.0)
