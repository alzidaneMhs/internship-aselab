extends Area3D

const LOCKED_Z: float = 0.0

var _direction: Vector3 = Vector3.ZERO
var _speed: float = 10.0
var _damage: float = 1.0

@onready var lifetime_timer: Timer = $Timer


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(queue_free)
	lifetime_timer.start()


func launch(direction: Vector3, speed: float, damage: float) -> void:
	_direction = direction.normalized()
	_speed = speed
	_damage = damage


func _physics_process(delta: float) -> void:
	global_position += _direction * _speed * delta
	global_position.z = LOCKED_Z


func _on_area_entered(area: Area3D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(_damage)
	queue_free()


func _on_body_entered(_body: Node) -> void:
	queue_free()
