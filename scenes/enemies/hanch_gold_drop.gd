extends Node2D

var warn_time := 0.9
var damage := 26.0
var radius := 72.0
var fall_height := 700.0
var source: Node
var style := "gold"

var _time := 0.0
var _phase := 0
var _fall := 0.0
var _fade := 1.0


func _ready() -> void:
	z_index = 4


func _process(delta: float) -> void:
	_time += delta
	match _phase:
		0:
			if _time >= warn_time:
				_phase = 1
				_time = 0.0
		1:
			_fall = minf(_time / 0.22, 1.0)
			if _fall >= 1.0:
				_impact()
				_phase = 2
				_time = 0.0
		2:
			_fade = maxf(1.0 - _time / 0.6, 0.0)
			if _fade <= 0.0:
				queue_free()
	queue_redraw()


func _impact() -> void:
	get_tree().call_group("main_camera", "shake", 5.0)
	AudioManager.play_sfx_at("gold_drop" if style == "gold" else "debris_crash", global_position, -2.0, 0.12)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		var dx := absf(player.global_position.x - global_position.x)
		var dy := global_position.y - player.global_position.y
		if dx <= radius + 26.0 and dy >= -10.0 and dy <= 150.0:
			var hurt := player.get_node_or_null("HurtBox")
			if hurt != null and hurt.has_method("take_damage"):
				hurt.take_damage(damage * GameState.get_trap_multiplier(), source)
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 16
	p.lifetime = 0.6
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.gravity = Vector2(0, 1100)
	p.initial_velocity_min = 150.0
	p.initial_velocity_max = 380.0
	p.scale_amount_min = 2.5
	p.scale_amount_max = 4.5
	p.color = Color(1.0, 0.85, 0.35) if style == "gold" else Color(0.55, 0.52, 0.6)
	get_parent().add_child(p)
	p.global_position = global_position + Vector2(0, -10)
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)


func _warn_color(a: float) -> Color:
	return Color(1.0, 0.8, 0.3, a) if style == "gold" else Color(1.0, 0.35, 0.3, a)


func _ellipse(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 33:
		var a := i * TAU / 32.0
		pts.append(Vector2(cos(a) * r, sin(a) * r * 0.22))
	return pts


func _draw() -> void:
	if _phase == 0:
		var k := clampf(_time / warn_time, 0.0, 1.0)
		var blink := 0.5 + 0.5 * sin(_time * 22.0)
		draw_colored_polygon(_ellipse(radius * (0.4 + 0.6 * k)), _warn_color(0.18 + 0.2 * k))
		draw_polyline(_ellipse(radius), _warn_color(0.5 + 0.4 * blink), 3.0)
		draw_line(Vector2(0, -fall_height), Vector2(0, 0), Color(1.0, 0.8, 0.3, 0.08 + 0.12 * k), 6.0)
	elif _phase == 1:
		var y := -fall_height * (1.0 - _fall)
		_draw_bar(Vector2(0, y - 18.0), 1.0)
		draw_polyline(_ellipse(radius), Color(1.0, 0.85, 0.35, 0.9), 3.0)
	else:
		_draw_bar(Vector2(0, -18.0), _fade)
		draw_colored_polygon(_ellipse(radius * (1.0 + (1.0 - _fade) * 0.6)), Color(1.0, 0.85, 0.4, 0.3 * _fade))


func _draw_bar(pos: Vector2, a: float) -> void:
	if style == "rock":
		var rock := PackedVector2Array([pos + Vector2(-34, 4), pos + Vector2(-26, -24), pos + Vector2(4, -32), pos + Vector2(32, -16), pos + Vector2(38, 10), pos + Vector2(10, 22), pos + Vector2(-22, 18)])
		draw_colored_polygon(rock, Color(0.3, 0.3, 0.38, a))
		draw_colored_polygon(PackedVector2Array([pos + Vector2(-26, -24), pos + Vector2(4, -32), pos + Vector2(0, -12), pos + Vector2(-18, -6)]), Color(0.46, 0.46, 0.56, a))
		draw_polyline(rock, Color(0.12, 0.12, 0.16, a), 2.0)
		return
	var top := PackedVector2Array([pos + Vector2(-34, -16), pos + Vector2(34, -16), pos + Vector2(44, 16), pos + Vector2(-44, 16)])
	draw_colored_polygon(top, Color(0.95, 0.68, 0.18, a))
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-34, -16), pos + Vector2(34, -16), pos + Vector2(30, -8), pos + Vector2(-30, -8)]), Color(1.0, 0.92, 0.6, a))
	draw_polyline(PackedVector2Array([top[0], top[1], top[2], top[3], top[0]]), Color(0.55, 0.33, 0.06, a), 2.0)
