extends Area2D

@export_file("*.tscn") var next_stage_path: String = ""

var _used := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _draw() -> void:
	var c := Color(1.0, 0.9, 0.4, 1.0)
	draw_rect(Rect2(-40, -150, 80, 150), Color(c, 0.18))
	draw_rect(Rect2(-40, -150, 80, 150), c, false, 4.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-14, -100), Vector2(18, -75), Vector2(-14, -50)]), c)


func _on_body_entered(body: Node) -> void:
	if _used or not body.is_in_group("player"):
		return
	_used = true
	if next_stage_path.is_empty():
		GameState.set_checkpoint(GameState.DEFAULT_STAGE_PATH, "", Vector2.ZERO)
		GameState.save_game()
		GameManager.goto_ending()
	else:
		GameState.set_checkpoint(next_stage_path, "", Vector2.ZERO)
		GameState.save_game()
		GameManager.goto_stage(next_stage_path, false)
