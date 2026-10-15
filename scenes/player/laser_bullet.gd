extends Area2D

const FX := preload("res://scripts/effects/laser_fx.gd")

@export var speed: float = 1700.0
@export var lifetime: float = 1.1

var direction: Vector2 = Vector2.RIGHT
var damage: float = 10.0
var source: Node

var _done := false


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	collision_layer = 32
	collision_mask = 17
	rotation = direction.angle()

	var glow := ColorRect.new()
	glow.color = Color(1.0, 0.1, 0.25, 1.0)
	glow.size = Vector2(76, 7)
	glow.position = -glow.size / 2.0
	add_child(glow)

	var core := ColorRect.new()
	core.color = Color(1.0, 1.0, 1.0, 1.0)
	core.size = Vector2(70, 2.5)
	core.position = -core.size / 2.0
	add_child(core)

	add_child(FX.make_light(Color(1.0, 0.15, 0.25), 0.8, 3.0))

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = glow.size
	shape.shape = rect
	add_child(shape)

	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _done:
		return
	if area.has_method("take_damage"):
		area.take_damage(damage, source)
		GameManager.hit_stop(0.035)
		_impact()


func _on_body_entered(_body: Node2D) -> void:
	if not _done:
		_impact()


func _impact() -> void:
	_done = true
	FX.spawn_impact(get_parent(), global_position)
	queue_free()
