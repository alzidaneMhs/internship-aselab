extends Area3D

@export var points: int = 5

var _collected := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	GameState.add_points(points)
	AudioManager.play_sfx("pickup")
	queue_free()
