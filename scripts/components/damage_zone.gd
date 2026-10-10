extends Area2D

## Shared by spike.tscn and acid_pool.tscn. Origin is the top-left corner of the
## zone. Deals `damage` to anything overlapping every `tick_interval` seconds.

@export var size: Vector2 = Vector2(96, 28):
	set(value):
		size = value
		if is_node_ready():
			_rebuild()
@export var damage: float = 1.0
@export var tick_interval: float = 0.5
@export var color: Color = Color(0.75, 0.2, 0.2, 1.0)
@export var spiky: bool = false

@onready var tick_timer: Timer = $TickTimer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_rebuild()
	tick_timer.wait_time = tick_interval
	tick_timer.timeout.connect(_on_tick)
	tick_timer.start()


func _rebuild() -> void:
	var rect := RectangleShape2D.new()
	rect.size = size
	collision_shape.shape = rect
	collision_shape.position = size / 2.0
	queue_redraw()


func _draw() -> void:
	if spiky:
		var count: int = maxi(1, int(size.x / 24.0))
		var w: float = size.x / count
		for i in count:
			draw_colored_polygon(PackedVector2Array([
				Vector2(i * w, size.y),
				Vector2((i + 0.5) * w, 0.0),
				Vector2((i + 1) * w, size.y),
			]), color)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), color)


func _on_tick() -> void:
	for area in get_overlapping_areas():
		if area.has_method("take_damage"):
			area.take_damage(damage * GameState.get_trap_multiplier())
