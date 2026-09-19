extends Area3D

@export var checkpoint_id: String = ""
@export var stage_scene_path: String = ""

@onready var spawn_point: Marker3D = $SpawnPoint


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	GameState.set_checkpoint(stage_scene_path, checkpoint_id, spawn_point.global_position)
	GameState.save_game()
	AudioManager.play_sfx("checkpoint")
