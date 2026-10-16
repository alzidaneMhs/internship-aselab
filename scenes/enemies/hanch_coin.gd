extends Area2D

var velocity := Vector2.ZERO
var gravity_force := 1150.0
var damage := 14.0
var source: Node

var _time := 0.0
var _spin := 0.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	collision_layer = 64
	collision_mask = 9
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 13.0
	shape.shape = circle
	add_child(shape)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	z_index = 4
	_spin = randf() * TAU


func _physics_process(delta: float) -> void:
	_time += delta
	_spin += delta * 14.0
	velocity.y += gravity_force * delta
	global_position += velocity * delta
	queue_redraw()
	if _time > 4.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage, source)
		_burst()


func _on_body_entered(_body: Node) -> void:
	if _time < 0.08:
		return
	_burst()


func _burst() -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 8
	p.lifetime = 0.45
	p.direction = Vector2(0, -1)
	p.spread = 80.0
	p.gravity = Vector2(0, 900)
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 200.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 3.5
	p.color = Color(1.0, 0.85, 0.35)
	get_parent().add_child(p)
	p.global_position = global_position
	p.emitting = true
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)
	queue_free()


func _draw() -> void:
	var w := absf(cos(_spin)) * 13.0 + 2.0
	draw_circle(Vector2.ZERO, 22.0, Color(1.0, 0.8, 0.3, 0.12))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(w / 13.0, 1.0))
	draw_circle(Vector2.ZERO, 13.0, Color(0.85, 0.55, 0.12))
	draw_circle(Vector2.ZERO, 10.5, Color(1.0, 0.82, 0.3))
	draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 14, Color(0.8, 0.5, 0.1), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2(-4, -5), 2.5, Color(1, 1, 0.9, 0.9))
