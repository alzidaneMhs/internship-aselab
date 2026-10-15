extends Node2D

const FX := preload("res://scripts/effects/laser_fx.gd")

@export var left_x: float = 0.0
@export var right_x: float = 1000.0
@export var floor_y: float = 600.0
@export var wall_height: float = 760.0
@export var accent: Color = Color(1.0, 0.55, 0.2, 1.0)
@export var boss_id: String = ""
@export var lock_zoom: float = 1.0
@export var show_back_decor: bool = true

var _left_progress := 0.0
var _right_progress := 1.0
var _locked := false
var _finished := false
var _trigger: Area2D
var _time := 0.0

var _back: Node2D
var _front: Node2D
var _barrier: Node2D
var _left_wall: StaticBody2D
var _right_wall: StaticBody2D
var _light: PointLight2D


func _ready() -> void:
	_back = _make_layer(-5, _draw_back)
	_front = _make_layer(0, _draw_front)
	_barrier = _make_layer(6, _draw_barrier)
	_left_wall = _make_wall(left_x)
	_right_wall = _make_wall(right_x)
	_set_wall(_left_wall, false)
	_build_embers()

	var mid := (left_x + right_x) / 2.0
	_light = FX.make_light(accent, 0.35, 12.0)
	_light.position = Vector2(mid, floor_y - 300.0)
	add_child(_light)

	var boss := get_tree().get_first_node_in_group("boss")
	var already_done := GameState.is_boss_defeated(boss_id) or GameState.is_boss_freed(boss_id)
	if already_done or boss == null:
		_right_progress = 0.0
		_set_wall(_right_wall, false)
		return
	boss.call_deferred("hide_for_intro")
	boss.set("arena_left", left_x + 70.0)
	boss.set("arena_right", right_x - 70.0)
	boss.connect("defeated", _unlock)
	_build_trigger()


func _make_layer(z: int, drawer: Callable) -> Node2D:
	var n := Node2D.new()
	n.z_index = z
	add_child(n)
	n.draw.connect(drawer)
	return n


func _make_wall(x: float) -> StaticBody2D:
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	wall.collision_mask = 0
	wall.position = Vector2(x, floor_y - 350.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40.0, 1300.0)
	shape.shape = rect
	wall.add_child(shape)
	add_child(wall)
	return wall


func _set_wall(wall: StaticBody2D, enabled: bool) -> void:
	(wall.get_child(0) as CollisionShape2D).set_deferred("disabled", not enabled)


func _build_trigger() -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var x0 := left_x + 170.0
	var x1 := right_x - 70.0
	area.position = Vector2((x0 + x1) / 2.0, floor_y - 350.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(x1 - x0, 1300.0)
	shape.shape = rect
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_trigger_body_entered)
	_trigger = area


func _build_embers() -> void:
	var p := CPUParticles2D.new()
	var mid := (left_x + right_x) / 2.0
	p.position = Vector2(mid, floor_y - 260.0)
	p.amount = 36
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2((right_x - left_x) / 2.0, 260.0)
	p.direction = Vector2(0, -1)
	p.spread = 40.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 26.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	grad.colors = PackedColorArray([Color(accent, 0.0), Color(accent.lightened(0.3), 0.8), Color(accent, 0.0)])
	p.color_ramp = grad
	p.z_index = 2
	add_child(p)


func _on_trigger_body_entered(body: Node) -> void:
	if _locked or _finished or not body.is_in_group("player"):
		return
	_locked = true
	_set_wall(_left_wall, true)
	create_tween().tween_property(self, "_left_progress", 1.0, 0.6)
	_set_camera_limits(true)
	GameState.toast("ARENA TERKUNCI! Kalahkan bos untuk keluar.")
	get_tree().call_group("main_camera", "shake", 9.0)
	AudioManager.play_sfx("arena_lock")
	var boss := get_tree().get_first_node_in_group("boss")
	if boss != null:
		await Cutscene.boss_intro(boss, lock_zoom)
		await boss.ensure_revealed()
		boss.set("dormant", false)


func _unlock() -> void:
	_locked = false
	_finished = true
	if _trigger != null:
		_trigger.set_deferred("monitoring", false)
	_set_wall(_left_wall, false)
	_set_wall(_right_wall, false)
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "_left_progress", 0.0, 0.7)
	tw.tween_property(self, "_right_progress", 0.0, 0.7)
	_set_camera_limits(false)
	GameState.toast("Arena terbuka.")
	AudioManager.play_sfx("arena_unlock")


func _set_camera_limits(active: bool) -> void:
	for cam in get_tree().get_nodes_in_group("main_camera"):
		cam.set("limit_left", int(left_x - 120.0) if active else -10000000)
		cam.set("limit_right", int(right_x + 120.0) if active else 10000000)
		var target_zoom := Vector2.ONE * (lock_zoom if active else 1.0)
		create_tween().tween_property(cam, "zoom", target_zoom, 0.8).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	_time += delta
	_back.queue_redraw()
	_front.queue_redraw()
	_barrier.queue_redraw()


func _draw_back() -> void:
	if not show_back_decor:
		return
	var w := right_x - left_x
	var mid := (left_x + right_x) / 2.0
	var shade := Color(0.05, 0.03, 0.09, 0.75)

	for s in [-0.28, 0.0, 0.28]:
		var cx: float = mid + w * s
		_back.draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 30.0, floor_y - 900.0), Vector2(cx + 30.0, floor_y - 900.0),
			Vector2(cx + 150.0, floor_y), Vector2(cx - 150.0, floor_y),
		]), Color(accent, 0.05))

	var c := Vector2(mid, floor_y - 360.0)
	for i in 3:
		var r := 150.0 + i * 55.0
		var dir := 1.0 if i % 2 == 0 else -1.0
		for k in 6:
			var a0 := _time * 0.35 * dir + k * TAU / 6.0
			_back.draw_arc(c, r, a0, a0 + 0.7, 14, Color(accent, 0.2 - i * 0.045), 4.0)

	var bays := maxi(2, int(w / 330.0))
	var bay_w := w / bays
	for i in bays + 1:
		var x := left_x + i * bay_w
		_back.draw_rect(Rect2(x - 11.0, floor_y - 430.0, 22.0, 430.0), shade)
		_back.draw_rect(Rect2(x - 11.0, floor_y - 430.0, 3.0, 430.0), Color(accent, 0.22))
	for i in bays:
		var cx := left_x + (i + 0.5) * bay_w
		var rx := bay_w / 2.0
		_back.draw_arc(Vector2(cx, floor_y - 430.0), rx, PI, TAU, 28, shade, 22.0)
		_back.draw_arc(Vector2(cx, floor_y - 430.0), rx - 12.0, PI, TAU, 28, Color(accent, 0.28), 3.0)


func _draw_front() -> void:
	var w := right_x - left_x
	var mid := (left_x + right_x) / 2.0
	var pulse := 0.5 + 0.5 * sin(_time * 2.2)

	_front.draw_rect(Rect2(left_x, floor_y - 12.0, w, 12.0), Color(accent, 0.1))
	_front.draw_rect(Rect2(left_x, floor_y - 3.0, w, 3.0), accent.lightened(0.35))

	for side in [0, 1]:
		var x0 := left_x if side == 0 else right_x - 110.0
		for i in 8:
			if i % 2 == 0:
				var bx := x0 + i * 14.0
				_front.draw_colored_polygon(PackedVector2Array([
					Vector2(bx, floor_y + 22.0), Vector2(bx + 14.0, floor_y + 22.0),
					Vector2(bx + 22.0, floor_y + 38.0), Vector2(bx + 8.0, floor_y + 38.0),
				]), Color(accent, 0.8))

	var ec := Vector2(mid, floor_y + 1.0)
	for ring in [[120.0, 0.9], [84.0, 0.6], [48.0, 0.9]]:
		var pts := PackedVector2Array()
		for k in 41:
			var a := k * TAU / 40.0
			pts.append(ec + Vector2(cos(a) * ring[0], sin(a) * ring[0] * 0.13))
		_front.draw_polyline(pts, Color(accent, (0.25 + 0.35 * pulse) * ring[1]), 2.0)
	for k in 8:
		var a := k * TAU / 8.0 + _time * 0.2
		_front.draw_line(ec + Vector2(cos(a) * 48.0, sin(a) * 48.0 * 0.13), ec + Vector2(cos(a) * 120.0, sin(a) * 120.0 * 0.13), Color(accent, 0.2 + 0.2 * pulse), 2.0)

	for px in [left_x + 44.0, right_x - 44.0]:
		var top_y := floor_y - 400.0
		_front.draw_rect(Rect2(px - 26.0, top_y, 52.0, 400.0), Color(0.11, 0.09, 0.15))
		_front.draw_rect(Rect2(px - 26.0, top_y, 6.0, 400.0), Color(0.3, 0.28, 0.38))
		_front.draw_rect(Rect2(px + 20.0, top_y, 6.0, 400.0), Color(0.05, 0.04, 0.08))
		_front.draw_rect(Rect2(px - 3.0, top_y + 30.0, 6.0, 340.0), Color(accent, 0.45 + 0.3 * pulse))
		_front.draw_rect(Rect2(px - 36.0, top_y - 14.0, 72.0, 18.0), Color(0.2, 0.18, 0.27))
		_front.draw_rect(Rect2(px - 36.0, top_y - 14.0, 72.0, 4.0), accent)
		_front.draw_circle(Vector2(px, top_y - 30.0), 22.0 + 4.0 * pulse, Color(accent, 0.2))
		_front.draw_circle(Vector2(px, top_y - 30.0), 11.0, accent.lightened(0.3))
		_front.draw_circle(Vector2(px, top_y - 30.0), 5.0, Color.WHITE)


func _draw_barrier() -> void:
	for side in [0, 1]:
		var x := left_x if side == 0 else right_x
		var p := _left_progress if side == 0 else _right_progress
		if p <= 0.01:
			continue
		var h := wall_height * p
		var top := floor_y - h
		var flicker := 0.85 + 0.15 * sin(_time * 30.0 + side * 2.0)
		_barrier.draw_polygon(
			PackedVector2Array([Vector2(x - 20.0, top), Vector2(x + 20.0, top), Vector2(x + 20.0, floor_y), Vector2(x - 20.0, floor_y)]),
			PackedColorArray([Color(accent, 0.02), Color(accent, 0.02), Color(accent, 0.5 * flicker), Color(accent, 0.5 * flicker)])
		)
		for i in 5:
			var bx := x - 14.0 + i * 7.0
			_barrier.draw_line(Vector2(bx, top), Vector2(bx, floor_y), Color(accent.lightened(0.3), 0.25 + 0.3 * sin(_time * 7.0 + i)), 2.0)
		for k in 7:
			var y := floor_y - fposmod(_time * 140.0 + k * h / 7.0, h)
			_barrier.draw_line(Vector2(x - 20.0, y), Vector2(x + 20.0, y), Color(1, 1, 1, 0.45 * p), 2.0)
		_barrier.draw_rect(Rect2(x - 22.0, floor_y - 10.0, 44.0, 14.0), Color(0.15, 0.12, 0.2))
		_barrier.draw_rect(Rect2(x - 22.0, floor_y - 10.0, 44.0, 3.0), accent)
		_barrier.draw_circle(Vector2(x, top), 10.0 * p, Color(accent.lightened(0.4), 0.9))
