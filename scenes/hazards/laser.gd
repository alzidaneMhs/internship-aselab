extends Area3D

@export var damage: float = 1.0
@export var tick_interval: float = 0.3
@export var on_duration: float = 1.5
@export var off_duration: float = 1.5

@onready var beam_mesh: MeshInstance3D = $BeamMesh
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var tick_timer: Timer = $TickTimer
@onready var toggle_timer: Timer = $ToggleTimer

var _is_on := true


func _ready() -> void:
	tick_timer.wait_time = tick_interval
	tick_timer.timeout.connect(_on_tick)
	tick_timer.start()

	toggle_timer.one_shot = true
	toggle_timer.timeout.connect(_toggle)
	_set_on(true)
	toggle_timer.wait_time = on_duration
	toggle_timer.start()


func _toggle() -> void:
	_is_on = not _is_on
	_set_on(_is_on)
	toggle_timer.wait_time = on_duration if _is_on else off_duration
	toggle_timer.start()


func _set_on(on: bool) -> void:
	beam_mesh.visible = on
	collision_shape.disabled = not on
	monitoring = on


func _on_tick() -> void:
	if not _is_on:
		return
	for area in get_overlapping_areas():
		if area.has_method("take_damage"):
			area.take_damage(damage)
