extends Area2D

## Lets the player's laser bolt and beam damage a cracked wall. They look for
## `take_damage` on anything they overlap on the enemy-hurtbox layer.


func take_damage(amount: float, attacker: Node = null) -> void:
	var wall := get_parent()
	if wall != null and wall.has_method("damage"):
		wall.damage(amount, attacker)
