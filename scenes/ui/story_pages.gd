extends Control

@export_enum("intro", "ending") var mode: String = "intro"

const CHARS_PER_SECOND := 34.0

@onready var text_label: Label = $Center/TextLabel
@onready var hint_label: Label = $HintLabel
@onready var isme: Node2D = $Isme
@onready var result_panel: Control = get_node_or_null("ResultPanel")

var _pages: Array = []
var _page := -1
var _chars := 0.0
var _typing := false
var _busy := true
var _finished := false
var _time := 0.0


func _ready() -> void:
	_pages = Story.INTRO_PAGES if mode == "intro" else Story.get_ending_pages()
	text_label.text = ""
	hint_label.modulate.a = 0.0
	if result_panel != null:
		result_panel.visible = false
	if mode == "intro":
		isme.modulate = Color(0, 0, 0, 0)
	else:
		isme.modulate = Color(0.12, 0.12, 0.18, 0.0)
		create_tween().tween_property(isme, "modulate", Color.WHITE, 2.5)
	AudioManager.play_music("intro" if mode == "intro" else "ending")
	await get_tree().create_timer(0.9).timeout
	_next_page()


func _process(delta: float) -> void:
	_time += delta
	if _typing:
		_chars += delta * CHARS_PER_SECOND
		text_label.visible_characters = int(_chars)
		if text_label.visible_characters >= text_label.get_total_character_count():
			_typing = false
			_busy = false
	if not _typing and not _busy and not _finished:
		hint_label.modulate.a = 0.3 + 0.7 * (0.5 + 0.5 * sin(_time * 4.0))
	else:
		hint_label.modulate.a = move_toward(hint_label.modulate.a, 0.0, delta * 3.0)


func _input(event: InputEvent) -> void:
	if _finished:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish()
		return
	var advance: bool = event.is_action_pressed("interact") or event.is_action_pressed("jump") \
		or event.is_action_pressed("ui_accept") \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not advance:
		return
	get_viewport().set_input_as_handled()
	if _typing:
		text_label.visible_characters = -1
		_typing = false
		_busy = false
	elif not _busy:
		_busy = true
		var tw := create_tween()
		tw.tween_property(text_label, "modulate:a", 0.0, 0.35)
		tw.tween_callback(_next_page)


func _next_page() -> void:
	_page += 1
	if _page >= _pages.size():
		_finish()
		return
	text_label.text = _pages[_page]
	text_label.visible_characters = 0
	text_label.modulate.a = 0.0
	create_tween().tween_property(text_label, "modulate:a", 1.0, 0.3)
	_chars = 0.0
	_typing = true
	_busy = true
	if mode == "intro":
		if _page == 4:
			create_tween().tween_property(isme, "modulate", Color(0.1, 0.1, 0.16, 1.0), 1.8)
		elif _page == 5:
			create_tween().tween_property(isme, "modulate", Color.WHITE, 1.6)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if mode == "intro":
		GameManager.goto_stage(GameState.DEFAULT_STAGE_PATH, false)
		return
	text_label.visible = false
	hint_label.visible = false
	_show_results()


func _show_results() -> void:
	if result_panel == null:
		GameManager.goto_main_menu()
		return
	var stats: Label = result_panel.get_node("Panel/VBoxContainer/StatsLabel")
	stats.text = tr("Vonic terkumpul: %d\nReputasi: %d  (%s)\nRobot dibebaskan: %d / 2\nSecret room: %d / 5\nItem boss: %d") % [
		GameState.points, GameState.reputation, GameState.get_reputation_title(),
		GameState.bosses_freed.size(), GameState.secrets_found.size(), GameState.items.size(),
	]
	var menu_button: Button = result_panel.get_node("Panel/VBoxContainer/MenuButton")
	menu_button.pressed.connect(GameManager.goto_main_menu)
	result_panel.modulate.a = 0.0
	result_panel.visible = true
	create_tween().tween_property(result_panel, "modulate:a", 1.0, 0.8)
	menu_button.grab_focus()
