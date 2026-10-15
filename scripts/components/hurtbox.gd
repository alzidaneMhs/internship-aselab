extends Area2D

signal hit(amount: float, attacker: Node)

@export var health_path: NodePath

const FX := preload("res://scripts/effects/laser_fx.gd")

@onready var health: Node = get_node(health_path)

var _number_y := -100.0


func _ready() -> void:
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null and cs.shape is RectangleShape2D:
		_number_y = cs.position.y - (cs.shape as RectangleShape2D).size.y / 2.0 - 6.0


func take_damage(amount: float, attacker: Node = null) -> void:
	if health == null:
		return
	var owner_node := get_parent()
	var original := amount
	if owner_node != null and owner_node.has_method("modify_incoming_damage"):
		amount = owner_node.modify_incoming_damage(amount)
	if amount <= 0.0:
		if original > 0.0:
			_show_number(original, Color(0.5, 0.9, 1.0), 20)
		return
	hit.emit(amount, attacker)
	if not health.invulnerable:
		_show_number(amount, _number_color(owner_node, amount, original), 30 if amount >= 20.0 else 24)
	health.apply_damage(amount)


func _number_color(owner_node: Node, amount: float, original: float) -> Color:
	if owner_node != null and owner_node.is_in_group("player"):
		return Color(1.0, 0.35, 0.35)
	if amount > original + 0.01:
		return Color(1.0, 0.65, 0.2)
	return Color(1.0, 0.95, 0.6)


func _show_number(value: float, color: Color, font_size: int) -> void:
	var scene := get_tree().current_scene
	FX.spawn_damage_number(scene, global_position + Vector2(0.0, _number_y), str(roundi(value)), color, font_size)
