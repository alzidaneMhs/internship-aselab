extends Area2D

const FX := preload("res://scripts/effects/laser_fx.gd")

var damage: float = 45.0
var source: Node

var _dir := Vector2.LEFT
var _speed := 540.0
var _time := 0.0
var _done := false


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	collision_layer = 64
	collision_mask = 9
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 34.0
	shape.shape = circle
	add_child(shape)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func launch(direction: Vector2, speed: float) -> void:
	_dir = direction.normalized()
	_speed = speed


func _physics_process(delta: float) -> void:
	_time += delta
	global_position += _dir * _speed * delta
	queue_redraw()
	if _time > 4.0:
		queue_free()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 30.0)
	for i in 6:
		var back := -_dir * (14.0 + i * 20.0)
		draw_circle(back, 30.0 - i * 4.0, Color(0.4, 0.8, 1.0, 0.18 - i * 0.025))
	draw_circle(Vector2.ZERO, 54.0 + 6.0 * pulse, Color(0.35, 0.7, 1.0, 0.16))
	draw_circle(Vector2.ZERO, 36.0, Color(0.5, 0.85, 1.0, 0.5))
	draw_circle(Vector2.ZERO, 22.0, Color(0.85, 0.97, 1.0, 0.9))
	draw_circle(Vector2.ZERO, 10.0, Color.WHITE)
	for k in 5:
		var a := _time * 9.0 + k * TAU / 5.0
		draw_line(Vector2.from_angle(a) * 24.0, Vector2.from_angle(a) * (44.0 + 8.0 * pulse), Color(0.7, 0.95, 1.0, 0.8), 3.0)


func _on_area_entered(area: Area2D) -> void:
	if _done or not area.has_method("take_damage"):
		return
	area.take_damage(damage, source)
	_burst()


func _on_body_entered(_body: Node2D) -> void:
	if not _done:
		_burst()


func _burst() -> void:
	_done = true
	FX.spawn_death_burst(get_parent(), global_position, Color(0.5, 0.85, 1.0), 1.2)
	get_tree().call_group("main_camera", "shake", 6.0)
	queue_free()
