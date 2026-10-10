extends Area2D

## Vertical blinking beam. Origin is the top-left corner of the beam.

@export var size: Vector2 = Vector2(16, 170):
	set(value):
		size = value
		if is_node_ready():
			_rebuild()
@export var damage: float = 15.0
@export var tick_interval: float = 0.3
@export var on_duration: float = 1.5
@export var off_duration: float = 1.5

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var tick_timer: Timer = $TickTimer
@onready var toggle_timer: Timer = $ToggleTimer

var _is_on := true


func _ready() -> void:
	_rebuild()
	tick_timer.wait_time = tick_interval
	tick_timer.timeout.connect(_on_tick)
	tick_timer.start()

	toggle_timer.one_shot = true
	toggle_timer.timeout.connect(_toggle)
	toggle_timer.start(on_duration)


func _rebuild() -> void:
	var rect := RectangleShape2D.new()
	rect.size = size
	collision_shape.shape = rect
	collision_shape.position = size / 2.0
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.15, 0.15, 0.9))
	draw_rect(Rect2(Vector2(size.x * 0.3, 0.0), Vector2(size.x * 0.4, size.y)), Color(1.0, 0.8, 0.8, 0.9))


func _toggle() -> void:
	_is_on = not _is_on
	visible = _is_on
	monitoring = _is_on
	toggle_timer.start(on_duration if _is_on else off_duration)


func _on_tick() -> void:
	if not _is_on:
		return
	for area in get_overlapping_areas():
		if area.has_method("take_damage"):
			area.take_damage(damage * GameState.get_trap_multiplier())
