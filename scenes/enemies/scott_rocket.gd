extends Node2D

## One rocket of Scott's barrage. Origin is the impact point on the ground.
## 1. A red warning column and a ring mark where it will land, while the rocket
##    shoots up out of Scott's turret and leaves the screen.
## 2. After `warn_time` it plunges straight down onto the mark.
## 3. Boom: damage inside the blast radius, then a short fire column.
##
## Set the fields, add to the scene, then set global_position to the target.

const FX := preload("res://scripts/effects/laser_fx.gd")
const SKY := 1100.0
const LAUNCH_TIME := 0.5

enum Phase { WARN, FALL, BLAST }

var launch_from := Vector2.ZERO   # global position of the turret
var warn_time: float = 1.2
var fall_speed: float = 1700.0
var damage: float = 36.0
var blast_radius: float = 105.0
var source: Node

var _phase := Phase.WARN
var _t := 0.0
var _fall_y := -SKY
var _launch_local := Vector2.ZERO
var _smoke: Array = []
var _inited := false


func _ready() -> void:
	z_index = 4
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _physics_process(delta: float) -> void:
	if not _inited:
		# The owner positions us right after add_child(), so resolve this on the first frame.
		_inited = true
		_launch_local = to_local(launch_from)
	_t += delta
	match _phase:
		Phase.WARN:
			if _t < LAUNCH_TIME:
				_smoke.append({"p": _launch_local + Vector2(randf_range(-6.0, 6.0), -_t * 1500.0), "age": 0.0})
			if _t >= warn_time:
				_phase = Phase.FALL
				_t = 0.0
		Phase.FALL:
			_fall_y += fall_speed * delta
			_smoke.append({"p": Vector2(randf_range(-5.0, 5.0), _fall_y - 40.0), "age": 0.0})
			if _fall_y >= 0.0:
				_explode()
		Phase.BLAST:
			if _t >= 0.5:
				queue_free()
				return
	for s in _smoke:
		s["age"] = float(s["age"]) + delta
	while not _smoke.is_empty() and float(_smoke[0]["age"]) > 0.5:
		_smoke.pop_front()
	queue_redraw()


func _explode() -> void:
	_phase = Phase.BLAST
	_t = 0.0
	_smoke.clear()
	var shape := CircleShape2D.new()
	shape.radius = blast_radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position + Vector2(0.0, -24.0))
	query.collision_mask = 8
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for result in get_world_2d().direct_space_state.intersect_shape(query, 8):
		var hurtbox: Object = result["collider"]
		if hurtbox.has_method("take_damage"):
			hurtbox.take_damage(damage, source)
			break
	FX.spawn_death_burst(get_parent(), global_position + Vector2(0.0, -30.0), Color(1.0, 0.55, 0.2), 1.8)
	FX.spawn_dust(get_parent(), global_position, 12, Color(0.55, 0.5, 0.5, 0.7), blast_radius * 0.6)
	get_tree().call_group("main_camera", "shake", 9.0)
	AudioManager.play_sfx("rocket_boom")


func _ellipse(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 33:
		var a := i * TAU / 32.0
		pts.append(Vector2(cos(a) * r, sin(a) * r * 0.2))
	return pts


func _draw() -> void:
	match _phase:
		Phase.WARN:
			_draw_warning()
			_draw_launching()
		Phase.FALL:
			_draw_warning()
			_draw_rocket(Vector2(0.0, _fall_y), true)
		Phase.BLAST:
			_draw_blast()
	_draw_smoke()


func _draw_warning() -> void:
	var k := clampf(_t / warn_time, 0.0, 1.0) if _phase == Phase.WARN else 1.0
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.03)
	var red := Color(1.0, 0.2, 0.15)
	# Dashed column from the sky down to the spot, getting stronger as it nears.
	var y := -SKY
	var dash := 0
	while y < -10.0:
		if dash % 2 == 0:
			draw_line(Vector2(0.0, y), Vector2(0.0, minf(y + 46.0, -6.0)), Color(red, 0.18 + 0.5 * k), 5.0 + 5.0 * k)
		y += 46.0
		dash += 1
	draw_colored_polygon(_ellipse(blast_radius), Color(red, 0.1 + 0.25 * k * (0.6 + 0.4 * pulse)))
	draw_polyline(_ellipse(blast_radius), Color(red, 0.9), 3.0)
	draw_polyline(_ellipse(blast_radius * (1.8 - 0.8 * k)), Color(1.0, 0.85, 0.7, 0.8), 4.0)
	# Bouncing arrows over the target.
	for i in 3:
		var ay := -34.0 - i * 28.0 - 8.0 * sin(Time.get_ticks_msec() * 0.012 - i)
		draw_colored_polygon(PackedVector2Array([Vector2(-16, ay - 14), Vector2(16, ay - 14), Vector2(0, ay + 4)]),
			Color(red, (0.9 - 0.25 * i) * (0.5 + 0.5 * pulse)))


func _draw_launching() -> void:
	if _t < LAUNCH_TIME:
		_draw_rocket(_launch_local + Vector2(0.0, -_t * 1500.0), false)


func _draw_rocket(pos: Vector2, nose_down: bool) -> void:
	var d := 1.0 if nose_down else -1.0   # +1: pointing down the screen
	var body := Color(0.78, 0.8, 0.85)
	var dark := Color(0.35, 0.37, 0.45)
	# Flame behind the rocket.
	var flick := 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.05)
	var tail := pos - Vector2(0.0, d * 36.0)
	draw_colored_polygon(PackedVector2Array([tail + Vector2(-9, 0), tail + Vector2(9, 0), tail + Vector2(0, -d * 70.0 * flick)]), Color(1.0, 0.5, 0.1, 0.9))
	draw_colored_polygon(PackedVector2Array([tail + Vector2(-5, 0), tail + Vector2(5, 0), tail + Vector2(0, -d * 42.0 * flick)]), Color(1.0, 0.95, 0.6, 0.95))
	# Fins, body, red nose.
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-9, -d * 30.0), pos + Vector2(-24, -d * 46.0), pos + Vector2(-9, -d * 14.0)]), dark)
	draw_colored_polygon(PackedVector2Array([pos + Vector2(9, -d * 30.0), pos + Vector2(24, -d * 46.0), pos + Vector2(9, -d * 14.0)]), dark)
	draw_rect(Rect2(pos + Vector2(-10, -36.0), Vector2(20, 72.0)), body)
	draw_rect(Rect2(pos + Vector2(-10, -36.0), Vector2(6, 72.0)), Color(1, 1, 1, 0.25))
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-10, d * 36.0), pos + Vector2(10, d * 36.0), pos + Vector2(0, d * 62.0)]), Color(0.9, 0.2, 0.15))
	draw_rect(Rect2(pos + Vector2(-10, -4.0), Vector2(20, 8.0)), Color(0.9, 0.7, 0.15))


func _draw_smoke() -> void:
	for s in _smoke:
		var a := float(s["age"]) / 0.5
		draw_circle(s["p"], 8.0 + 22.0 * a, Color(0.8, 0.8, 0.85, 0.35 * (1.0 - a)))


func _draw_blast() -> void:
	var k := clampf(_t / 0.5, 0.0, 1.0)
	draw_circle(Vector2(0.0, -30.0), blast_radius * (0.5 + 0.7 * k), Color(1.0, 0.6, 0.2, 0.5 * (1.0 - k)))
	draw_arc(Vector2(0.0, -4.0), blast_radius * (0.4 + 1.2 * k), PI, TAU, 28, Color(1.0, 0.9, 0.6, 0.9 * (1.0 - k)), 10.0 * (1.0 - k) + 2.0)
	# Fire column rising and fading.
	var h := 260.0 * sin(clampf(k * 1.4, 0.0, 1.0) * PI * 0.5)
	draw_colored_polygon(PackedVector2Array([Vector2(-34, 0), Vector2(34, 0), Vector2(18, -h), Vector2(-18, -h)]), Color(1.0, 0.45, 0.1, 0.6 * (1.0 - k)))
	draw_colored_polygon(PackedVector2Array([Vector2(-18, 0), Vector2(18, 0), Vector2(8, -h * 0.7), Vector2(-8, -h * 0.7)]), Color(1.0, 0.9, 0.5, 0.8 * (1.0 - k)))
