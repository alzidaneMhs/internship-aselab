extends Node

# Pure scene-flow orchestration. This node never stores game data itself —
# all persistent state lives in GameState. Keeping the two separate means
# "what is true" (GameState) never gets tangled with "what is on screen"
# (GameManager).

const MINIGAME_SCENES := {
	"block_blast": "res://scenes/minigames/block_blast.tscn",
	"brick_breaker": "res://scenes/minigames/brick_breaker.tscn",
}

var _active_minigame: Control


func goto_stage(path: String, use_checkpoint: bool = true) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	if use_checkpoint:
		await get_tree().process_frame
		_place_player_at_checkpoint()


func _place_player_at_checkpoint() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.global_position = GameState.spawn_position


func goto_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func on_player_died() -> void:
	goto_stage(GameState.current_stage_path, true)


func launch_minigame(kind: String) -> void:
	if _active_minigame != null:
		return
	var scene_path: String = MINIGAME_SCENES.get(kind, "")
	if scene_path.is_empty():
		push_warning("GameManager: unknown minigame kind '%s'" % kind)
		return
	var scene: PackedScene = load(scene_path)
	var instance: Control = scene.instantiate()
	instance.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	layer.add_child(instance)
	get_tree().current_scene.add_child(layer)
	instance.finished.connect(_on_minigame_finished.bind(layer))
	_active_minigame = instance
	get_tree().paused = true


func _on_minigame_finished(_won: bool, layer: CanvasLayer) -> void:
	get_tree().paused = false
	_active_minigame = null
	layer.queue_free()
