extends Node

# Scene-flow orchestration. Persistent data lives in GameState only.
# Every scene change goes through SceneTransition (iris wipe) and, when entering
# a stage fresh, shows the stage title card and its opening dialogue.

signal minigame_finished(won: bool)

const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const INTRO_SCENE := "res://scenes/ui/intro_scene.tscn"
const ENDING_SCENE := "res://scenes/ui/ending.tscn"
const MINIGAME_SCENES := {
	"block_blast": "res://scenes/minigames/block_blast.tscn",
	"snake": "res://scenes/minigames/snake.tscn",
	"brick_breaker": "res://scenes/minigames/brick_breaker.tscn",
}

var _active_minigame: Control
var _dying := false
var _changing := false
var _hit_stop_active := false


## mode: "stage" (title card + dialogue), "quick" (respawn), "plain" (menus, Continue).
func goto_stage(path: String, use_checkpoint: bool = true, mode: String = "") -> void:
	GameState.spawn_at_checkpoint = use_checkpoint and GameState.current_checkpoint_id != ""
	if mode.is_empty():
		mode = "quick" if use_checkpoint else "stage"
	_change_scene.call_deferred(path, mode)


func goto_main_menu() -> void:
	_change_scene.call_deferred(MENU_SCENE, "plain")


func goto_ending() -> void:
	_change_scene.call_deferred(ENDING_SCENE, "plain")


func start_new_game() -> void:
	GameState.reset_new_game()
	_change_scene.call_deferred(INTRO_SCENE, "plain")


func on_player_died() -> void:
	if _dying:
		return
	_dying = true
	goto_stage(GameState.current_stage_path, true)


func _change_scene(path: String, mode: String) -> void:
	if _changing:
		return
	_changing = true
	Engine.time_scale = 1.0
	_hit_stop_active = false
	get_tree().paused = true
	await SceneTransition.close(0.35 if mode == "quick" else 0.65)
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	_dying = false
	_changing = false
	if mode == "stage":
		await _enter_stage(path)
	else:
		SceneTransition.open(0.45 if mode == "quick" else 0.7)
		get_tree().paused = false


func _enter_stage(path: String) -> void:
	var info := Story.get_stage_info(path)
	SceneTransition.open(0.8)
	if not info.is_empty():
		await SceneTransition.show_card(info["label"], info["title"])
		await Story.play_once(info["intro"])
	get_tree().paused = false


## Freeze-frame on impact. Real-time timer, so it can't get stuck.
func hit_stop(duration: float, time_scale: float = 0.05) -> void:
	if _hit_stop_active or get_tree().paused or _changing:
		return
	_hit_stop_active = true
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_hit_stop_active = false


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
