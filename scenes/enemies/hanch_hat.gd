extends Area2D

var direction := 1.0
var distance := 1000.0
var speed := 760.0
var damage := 22.0
var source: Node2D
var min_x := -1.0e9
var max_x := 1.0e9
var height := 70.0

var _time := 0.0
var _origin := Vector2.ZERO
var _returning := false
var _travelled := 0.0
var _hit_cd := 0.0
var _spin := 0.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	collision_layer = 64
	collision_mask = 8
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(86, 50)
	shape.shape = rect
	add_child(shape)
	area_entered.connect(_on_area_entered)
	z_index = 5
	_origin = global_position


func is_done() -> bool:
	return is_queued_for_deletion()


func _physics_process(delta: float) -> void:
	_time += delta
	_spin += delta * 16.0
	_hit_cd = maxf(_hit_cd - delta, 0.0)
	if not _returning:
		var step := speed * delta
		global_position.x += direction * step
		_travelled += step
		if _travelled >= distance or global_position.x <= min_x or global_position.x >= max_x:
			_returning = true
	else:
		var home := _origin
		if source != null and is_instance_valid(source):
			home = Vector2(source.global_position.x, _origin.y)
		var to_home := home - global_position
		var step2 := speed * 1.1 * delta
		if to_home.length() <= step2 + 4.0:
			queue_free()
			return
		global_position += to_home.normalized() * step2
	if _hit_cd <= 0.0:
		for area in get_overlapping_areas():
			if area.has_method("take_damage"):
				_hit(area)
				break
	queue_redraw()
	if _time > 6.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _hit_cd <= 0.0 and area.has_method("take_damage"):
		_hit(area)


func _hit(area: Area2D) -> void:
	_hit_cd = 0.6
	area.take_damage(damage, source)
	get_tree().call_group("main_camera", "shake", 5.0)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 54.0, Color(1.0, 0.7, 0.25, 0.08))
	var trail := 4
	for i in trail:
		var off := Vector2(-direction * (14.0 + i * 12.0) * (-1.0 if _returning else 1.0), 0.0)
		draw_circle(off, 18.0 - i * 3.0, Color(1.0, 0.8, 0.4, 0.12 - i * 0.025))
	draw_set_transform(Vector2.ZERO, _spin, Vector2.ONE)
	draw_rect(Rect2(-44, 6, 88, 12), Color(0.45, 0.27, 0.12))
	draw_rect(Rect2(-44, 6, 88, 4), Color(0.6, 0.38, 0.18))
	draw_colored_polygon(PackedVector2Array([Vector2(-26, 8), Vector2(26, 8), Vector2(22, -34), Vector2(-24, -30)]), Color(0.58, 0.36, 0.17))
	draw_rect(Rect2(-26, -4, 52, 9), Color(0.85, 0.12, 0.1))
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -22), Vector2(-2, -14), Vector2(-12, -10)]), Color(0.32, 0.18, 0.08))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
