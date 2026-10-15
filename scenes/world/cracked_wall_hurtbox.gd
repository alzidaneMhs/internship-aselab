extends Area2D

func take_damage(amount: float, attacker: Node = null) -> void:
	var wall := get_parent()
	if wall != null and wall.has_method("damage"):
		wall.damage(amount, attacker)
