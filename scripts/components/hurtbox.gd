extends Area2D

## Emitted before damage is applied, so the owner can react (knockback, stagger).
signal hit(amount: float, attacker: Node)

@export var health_path: NodePath

@onready var health: Node = get_node(health_path)


func take_damage(amount: float, attacker: Node = null) -> void:
	if health == null:
		return
	# The owner may veto/reduce damage (e.g. Krums' shield).
	var owner_node := get_parent()
	if owner_node != null and owner_node.has_method("modify_incoming_damage"):
		amount = owner_node.modify_incoming_damage(amount)
	if amount <= 0.0:
		return
	hit.emit(amount, attacker)
	health.apply_damage(amount)
