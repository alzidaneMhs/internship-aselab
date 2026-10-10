extends Node

signal health_changed(current: float, max: float)
signal damaged(amount: float)
signal died()

@export var max_health: float = 100.0

var current_health: float
var invulnerable: bool = false


func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func apply_damage(amount: float) -> void:
	if current_health <= 0.0 or invulnerable:
		return
	current_health = clampf(current_health - amount, 0.0, max_health)
	damaged.emit(amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		died.emit()


func heal(amount: float) -> void:
	current_health = clampf(current_health + amount, 0.0, max_health)
	health_changed.emit(current_health, max_health)


func set_max_health(value: float, refill: bool = false) -> void:
	max_health = value
	if refill:
		current_health = max_health
	else:
		current_health = clampf(current_health, 0.0, max_health)
	health_changed.emit(current_health, max_health)
