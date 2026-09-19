extends Area3D

## Shared by spike.tscn and acid_pool.tscn — a hazard that deals `damage`
## to anything overlapping it every `tick_interval` seconds while occupied.

@export var damage: float = 1.0
@export var tick_interval: float = 0.5

@onready var tick_timer: Timer = $TickTimer


func _ready() -> void:
	tick_timer.wait_time = tick_interval
	tick_timer.timeout.connect(_on_tick)
	tick_timer.start()


func _on_tick() -> void:
	for area in get_overlapping_areas():
		if area.has_method("take_damage"):
			area.take_damage(damage)
