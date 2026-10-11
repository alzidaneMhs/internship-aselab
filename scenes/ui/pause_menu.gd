extends Control

## Pause menu. Esc opens/closes it (ignored while another overlay such as the
## shop or a minigame already has the game paused).

@onready var main_panel: Control = $MainPanel
@onready var controls_panel: Control = $ControlsPanel
@onready var resume_button: Button = $MainPanel/VBoxContainer/ResumeButton
@onready var restart_button: Button = $MainPanel/VBoxContainer/RestartButton
@onready var controls_button: Button = $MainPanel/VBoxContainer/ControlsButton
@onready var volume_slider: HSlider = $MainPanel/VBoxContainer/VolumeRow/VolumeSlider
@onready var fullscreen_check: CheckButton = $MainPanel/VBoxContainer/FullscreenCheck
@onready var menu_button: Button = $MainPanel/VBoxContainer/MenuButton
@onready var quit_button: Button = $MainPanel/VBoxContainer/QuitButton
@onready var back_button: Button = $ControlsPanel/VBoxContainer/BackButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(_close)
	restart_button.pressed.connect(_on_restart)
	controls_button.pressed.connect(_show_controls.bind(true))
	back_button.pressed.connect(_show_controls.bind(false))
	menu_button.pressed.connect(_on_main_menu)
	quit_button.pressed.connect(get_tree().quit)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if visible:
		if controls_panel.visible:
			_show_controls(false)
		else:
			_close()
		get_viewport().set_input_as_handled()
	elif not get_tree().paused:
		_open()
		get_viewport().set_input_as_handled()


func _open() -> void:
	volume_slider.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(0)))
	fullscreen_check.set_pressed_no_signal(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	_show_controls(false)
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()


func _close() -> void:
	visible = false
	get_tree().paused = false


func _show_controls(value: bool) -> void:
	controls_panel.visible = value
	main_panel.visible = not value
	if value:
		back_button.grab_focus()
	else:
		controls_button.grab_focus()


func _on_restart() -> void:
	_close()
	GameManager.goto_stage(GameState.current_stage_path, true)


func _on_main_menu() -> void:
	_close()
	GameManager.goto_main_menu()


func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value, 0.0001)))
	AudioServer.set_bus_mute(0, value <= 0.001)


func _on_fullscreen_toggled(pressed: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if pressed else DisplayServer.WINDOW_MODE_WINDOWED)
