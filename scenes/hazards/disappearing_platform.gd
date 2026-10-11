@tool
extends "res://scenes/world/platform.gd"

@export var stand_time: float = 1.0
@export var respawn_time: float = 2.5

@onready var touch_detector: Area2D = $TouchDetector
@onready var stand_timer: Timer = $StandTimer
@onready var respawn_timer: Timer = $RespawnTimer

var _triggered := false


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	touch_detector.body_entered.connect(_on_touch)
	stand_timer.wait_time = stand_time
	stand_timer.one_shot = true
	stand_timer.timeout.connect(_disappear)
	respawn_timer.wait_time = respawn_time
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(_reappear)


func _rebuild() -> void:
	super._rebuild()
	var detector_shape := get_node_or_null("TouchDetector/CollisionShape2D") as CollisionShape2D
	if detector_shape != null:
		var rect := RectangleShape2D.new()
		rect.size = Vector2(size.x, 16.0)
		detector_shape.shape = rect
		detector_shape.position = Vector2(size.x / 2.0, -8.0)


func _on_touch(body: Node) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	stand_timer.start()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.45, stand_time)


func _disappear() -> void:
	visible = false
	$CollisionShape2D.set_deferred("disabled", true)
	respawn_timer.start()


func _reappear() -> void:
	modulate.a = 1.0
	visible = true
	$CollisionShape2D.set_deferred("disabled", false)
	_triggered = false
