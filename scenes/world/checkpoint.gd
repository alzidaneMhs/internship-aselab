extends Area2D

@export var checkpoint_id: String = ""
@export var stage_scene_path: String = ""

@onready var spawn_point: Marker2D = $SpawnPoint

var _active := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _draw() -> void:
	var c := Color(0.4, 1.0, 0.5) if _active else Color(0.3, 0.9, 1.0)
	draw_line(Vector2.ZERO, Vector2(0, -130), c, 6.0)
	draw_colored_polygon(PackedVector2Array([Vector2(3, -130), Vector2(62, -108), Vector2(3, -86)]), c)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	GameState.set_checkpoint(stage_scene_path, checkpoint_id, spawn_point.global_position)
	GameState.save_game()
	AudioManager.play_sfx("checkpoint")
	_active = true
	queue_redraw()
