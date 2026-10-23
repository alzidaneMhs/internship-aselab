extends Control

const SETTINGS_MENU := preload("res://scenes/ui/settings_menu.gd")

@onready var main_panel: Control = $MainPanel
@onready var resume_button: Button = $MainPanel/VBoxContainer/ResumeButton
@onready var restart_button: Button = $MainPanel/VBoxContainer/RestartButton
@onready var controls_button: Button = $MainPanel/VBoxContainer/ControlsButton
@onready var menu_button: Button = $MainPanel/VBoxContainer/MenuButton
@onready var quit_button: Button = $MainPanel/VBoxContainer/QuitButton

var _settings: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(_close)
	restart_button.pressed.connect(_on_restart)
	controls_button.pressed.connect(_open_settings)
	menu_button.pressed.connect(_on_main_menu)
	quit_button.pressed.connect(get_tree().quit)


func _unhandled_input(event: InputEvent) -> void:
	if Cutscene.active or _settings != null:
		return
	if visible:
		if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
			_close()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause") and not get_tree().paused:
		_open()
		get_viewport().set_input_as_handled()


func _open() -> void:
	main_panel.visible = true
	visible = true
	get_tree().paused = true
	AudioManager.play_sfx("pause_open", -3.0)
	resume_button.grab_focus()


func _close() -> void:
	if _settings != null:
		_settings.queue_free()
		_settings = null
	visible = false
	get_tree().paused = false
	AudioManager.play_sfx("pause_close", -3.0)


func _open_settings() -> void:
	main_panel.visible = false
	_settings = SETTINGS_MENU.new()
	add_child(_settings)
	_settings.closed.connect(_on_settings_closed)


func _on_settings_closed() -> void:
	_settings = null
	main_panel.visible = true
	controls_button.grab_focus()


func _on_restart() -> void:
	_close()
	GameManager.goto_stage(GameState.current_stage_path, true)


func _on_main_menu() -> void:
	_close()
	GameManager.goto_main_menu()
