extends StaticBody3D

@export var stand_time: float = 1.0
@export var respawn_time: float = 2.5

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var touch_detector: Area3D = $TouchDetector
@onready var stand_timer: Timer = $StandTimer
@onready var respawn_timer: Timer = $RespawnTimer

var _triggered := false


func _ready() -> void:
	touch_detector.body_entered.connect(_on_touch)
	stand_timer.wait_time = stand_time
	stand_timer.one_shot = true
	stand_timer.timeout.connect(_disappear)
	respawn_timer.wait_time = respawn_time
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(_reappear)


func _on_touch(body: Node) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	stand_timer.start()


func _disappear() -> void:
	mesh.visible = false
	collision_shape.disabled = true
	respawn_timer.start()


func _reappear() -> void:
	mesh.visible = true
	collision_shape.disabled = false
	_triggered = false
