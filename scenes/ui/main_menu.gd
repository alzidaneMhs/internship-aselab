extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var quit_button: Button = $VBoxContainer/QuitButton


func _ready() -> void:
	continue_button.disabled = not GameState.has_save_file()
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	AudioManager.play_music("main_menu")


func _on_start_pressed() -> void:
	GameState.reset_new_game()
	GameManager.goto_stage(GameState.current_stage_path, false)


func _on_continue_pressed() -> void:
	GameState.load_game()
	GameManager.goto_stage(GameState.current_stage_path, true)


func _on_quit_pressed() -> void:
	get_tree().quit()
