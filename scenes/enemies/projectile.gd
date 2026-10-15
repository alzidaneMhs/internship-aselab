extends Area2D

var _direction: Vector2 = Vector2.ZERO
var _speed: float = 420.0
var _damage: float = 1.0

@onready var lifetime_timer: Timer = $Timer


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(queue_free)
	lifetime_timer.start()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 11.0, Color(1.0, 0.3, 0.2))
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.85, 0.65))


func launch(direction: Vector2, speed: float, damage: float) -> void:
	_direction = direction.normalized()
	_speed = speed
	_damage = damage


func _physics_process(delta: float) -> void:
	global_position += _direction * _speed * delta


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(_damage)
	queue_free()


func _on_body_entered(_body: Node) -> void:
	queue_free()
