extends Node

# Pure scene-flow orchestration. Persistent data lives in GameState only.

signal minigame_finished(won: bool)

const MINIGAME_SCENES := {
	"block_blast": "res://scenes/minigames/block_blast.tscn",
	"snake": "res://scenes/minigames/snake.tscn",
	"brick_breaker": "res://scenes/minigames/brick_breaker.tscn",
}

var _active_minigame: Control
var _dying := false


func goto_stage(path: String, use_checkpoint: bool = true) -> void:
	_dying = false
	get_tree().paused = false
	GameState.spawn_at_checkpoint = use_checkpoint and GameState.current_checkpoint_id != ""
	get_tree().change_scene_to_file(path)


func goto_main_menu() -> void:
	_dying = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func on_player_died() -> void:
	if _dying:
		return
	_dying = true
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
	instance.set("difficulty", GameState.get_minigame_difficulty())
	instance.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	layer.add_child(instance)
	get_tree().current_scene.add_child(layer)
	instance.finished.connect(_on_minigame_finished.bind(layer))
	_active_minigame = instance
	get_tree().paused = true


func _on_minigame_finished(won: bool, layer: CanvasLayer) -> void:
	get_tree().paused = false
	_active_minigame = null
	layer.queue_free()
	minigame_finished.emit(won)
