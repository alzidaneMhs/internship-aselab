extends Node

const UI := preload("res://scenes/ui/cutscene_ui.gd")
const FX := preload("res://scripts/effects/laser_fx.gd")

var active := false
var skipped := false

var _ui


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 70
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_ui = Control.new()
	_ui.set_script(UI)
	layer.add_child(_ui)
	add_child(layer)


func _input(event: InputEvent) -> void:
	if active and event.is_action_pressed("ui_cancel"):
		skipped = true


func begin() -> void:
	if active:
		return
	active = true
	skipped = false
	var player := _player()
	if player != null:
		player.set_cutscene(true)
	_set_hud(false)
	await _ui.bars_in(0.6)


func end() -> void:
	if not active:
		return
	await _ui.bars_out(0.5)
	_set_hud(true)
	var player := _player()
	if player != null and is_instance_valid(player):
		player.set_cutscene(false)
	active = false
	skipped = false


func abort() -> void:
	active = false
	skipped = false
	if _ui != null:
		_ui.dismiss(1.0)


func wait(seconds: float) -> void:
	var left := seconds
	while left > 0.0 and not skipped:
		var step := minf(left, 0.05)
		await get_tree().create_timer(step, true, false, true).timeout
		left -= step


func focus(pos: Vector2, pan_speed: float = 2.4, zoom_to: float = 0.0) -> void:
	var cam := _camera()
	if cam != null:
		cam.focus_on(pos, pan_speed, zoom_to)


func release(rest_zoom: float = 1.0) -> void:
	var cam := _camera()
	if cam != null:
		cam.release_focus(rest_zoom)


func title(title_text: String, subtitle: String, color: Color, seconds: float = 2.4) -> void:
	await _ui.show_title(title_text, subtitle, color, 0.6 if skipped else seconds)


func fade(color: Color, alpha: float, duration: float) -> void:
	await _ui.fade(color, alpha, duration)


func walk_player_to(x: float, stop_distance: float, timeout: float = 3.0) -> void:
	var player := _player()
	if player == null:
		return
	var t := 0.0
	while t < timeout and not skipped:
		var dx: float = x - player.global_position.x
		if absf(dx) <= stop_distance:
			break
		player.auto_walk = signf(dx)
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	player.auto_walk = 0.0
	player.cutscene_face(x - player.global_position.x)


func boss_intro(boss: Node, rest_zoom: float = 1.0) -> void:
	var id: String = boss.get("boss_id")
	if GameState.has_seen(id + "_intro"):
		return
	await begin()
	await wait(0.3)
	focus(boss.global_position + Vector2(0.0, -130.0), 2.2, clampf(rest_zoom * 1.25, 1.0, 1.3))
	await wait(1.6)
	if boss.has_method("play_intro"):
		await boss.play_intro()
	else:
		await wait(0.4)
	var info: Dictionary = Story.BOSS_TITLES.get(id, {})
	if not info.is_empty():
		await title(info["name"], info["sub"], info["color"])
	await Story.play_once(id + "_intro")
	release(rest_zoom)
	await wait(1.1)
	await end()


func scott_defeat(scott: Node) -> void:
	await begin()
	await wait(0.4)
	var center: Vector2 = scott.global_position
	focus(center + Vector2(-40.0, -150.0), 2.0, 1.2)
	var player := _player()
	if player != null:
		await walk_player_to(center.x, 380.0, 3.0)
	await scott.play_death_throes()
	get_tree().call_group("scott_lair", "set_mode", "lost")
	await wait(0.6)
	await Story.play(Story.SCRIPTS["scott_defeated"])
	get_tree().call_group("scott_lair", "power_down", 3.0)
	await scott.play_shutdown()
	FX.spawn_screen_flash(get_tree(), Color(1.0, 1.0, 1.0, 0.9), 1.0)
	await wait(0.5)
	await _ui.fade(Color.WHITE, 1.0, 0.9)
	abort()


func _player() -> Node:
	return get_tree().get_first_node_in_group("player")


func _camera() -> Node:
	return get_tree().get_first_node_in_group("main_camera")


func _set_hud(shown: bool) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var hud := scene.get_node_or_null("HUD")
	if hud != null:
		hud.visible = shown
