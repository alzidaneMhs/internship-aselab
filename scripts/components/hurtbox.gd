extends Area3D

@export var health_path: NodePath

@onready var health: Node = get_node(health_path)


func take_damage(amount: float, _attacker: Node = null) -> void:
	if health != null:
		health.apply_damage(amount)
