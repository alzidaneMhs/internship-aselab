extends Control

const ACHIEVEMENT_PANEL := preload("res://scenes/ui/achievement_panel.gd")
const SETTINGS_MENU := preload("res://scenes/ui/settings_menu.gd")
const SECRET_STAGE := "res://scenes/levels/stage_13.tscn"

@onready var title_box: Control = $TitleBox
@onready var buttons_box: VBoxContainer = $Buttons
@onready var new_game_button: Button = $Buttons/NewGameButton
@onready var continue_button: Button = $Buttons/ContinueButton
@onready var achievements_button: Button = $Buttons/AchievementsButton
@onready var credits_button: Button = $Buttons/CreditsButton
@onready var settings_button: Button = $Buttons/SettingsButton
@onready var quit_button: Button = $Buttons/QuitButton
@onready var sound_button: Button = $SoundButton
@onready var secret_button: Button = $SecretButton
@onready var sound_icon: Control = $SoundButton/Icon
@onready var credits_panel: Control = $CreditsPanel
@onready var back_button: Button = $CreditsPanel/Panel/MarginContainer/VBoxContainer/BackButton
@onready var isme: Node2D = $Isme

var _achievement_panel: Control


func _ready() -> void:
	continue_button.disabled = not GameState.has_save_file()
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	achievements_button.pressed.connect(_open_achievements)
	credits_button.pressed.connect(_set_credits_visible.bind(true))
	settings_button.pressed.connect(_open_settings)
	back_button.pressed.connect(_set_credits_visible.bind(false))
	quit_button.pressed.connect(_on_quit_pressed)
	sound_button.pressed.connect(_on_sound_pressed)
	secret_button.visible = GameState.has_all_achievements() and GameState.scott_beaten
	secret_button.pressed.connect(_on_secret_pressed)
	sound_icon.draw.connect(_draw_sound_icon)
	_achievement_panel = Control.new()
	_achievement_panel.set_script(ACHIEVEMENT_PANEL)
	_achievement_panel.visible = false
	add_child(_achievement_panel)
	_achievement_panel.connect("closed", _on_achievements_closed)
	AudioManager.play_music("main_menu")

	var focus_target: Button = continue_button if not continue_button.disabled else new_game_button
	focus_target.grab_focus()
	_play_intro()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _achievement_panel.visible:
		_achievement_panel.call("close")
	elif credits_panel.visible:
		_set_credits_visible(false)


func _open_settings() -> void:
	buttons_box.visible = false
	var menu: Control = SETTINGS_MENU.new()
	add_child(menu)
	menu.closed.connect(_on_settings_closed)


func _on_settings_closed() -> void:
	buttons_box.visible = true
	sound_icon.queue_redraw()
	settings_button.grab_focus()


func _open_achievements() -> void:
	buttons_box.visible = false
	_achievement_panel.call("open")


func _on_achievements_closed() -> void:
	buttons_box.visible = true
	achievements_button.grab_focus()


func _play_intro() -> void:
	title_box.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(title_box, "modulate:a", 1.0, 0.7)
	var delay := 0.25
	for child in buttons_box.get_children():
		child.modulate.a = 0.0
		var btn_tween := create_tween()
		btn_tween.tween_interval(delay)
		btn_tween.tween_property(child, "modulate:a", 1.0, 0.35)
		delay += 0.12

	var bob := create_tween().set_loops()
	bob.tween_property(isme, "position:y", isme.position.y - 6.0, 1.1).set_trans(Tween.TRANS_SINE)
	bob.tween_property(isme, "position:y", isme.position.y, 1.1).set_trans(Tween.TRANS_SINE)
	_glitch_loop()


func _glitch_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(4.0, 8.0)).timeout
		if not is_inside_tree():
			return
		var home := title_box.position
		for i in 4:
			title_box.position = home + Vector2(randf_range(-7.0, 7.0), randf_range(-2.0, 2.0))
			title_box.modulate = Color(1.0, 0.8 + randf() * 0.3, 1.0 + randf() * 0.4, 0.75 + randf() * 0.25)
			await get_tree().create_timer(0.045).timeout
		title_box.position = home
		title_box.modulate = Color.WHITE


func _set_credits_visible(value: bool) -> void:
	credits_panel.visible = value
	buttons_box.visible = not value
	if value:
		back_button.grab_focus()
	else:
		credits_button.grab_focus()


func _on_new_game_pressed() -> void:
	_lock_buttons()
	GameManager.start_new_game()


func _on_continue_pressed() -> void:
	_lock_buttons()
	GameState.load_game()
	GameManager.goto_stage(GameState.current_stage_path, true, "plain")


func _lock_buttons() -> void:
	new_game_button.disabled = true
	continue_button.disabled = true
	achievements_button.disabled = true
	credits_button.disabled = true
	settings_button.disabled = true
	quit_button.disabled = true


func _on_secret_pressed() -> void:
	_lock_buttons()
	secret_button.disabled = true
	GameState.set_checkpoint(SECRET_STAGE, "", Vector2.ZERO)
	GameState.save_game()
	GameManager.goto_stage(SECRET_STAGE, false)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_sound_pressed() -> void:
	Settings.set_master_volume(0.0 if Settings.master_volume > 0.001 else 1.0)
	sound_icon.queue_redraw()


func _draw_sound_icon() -> void:
	var c := sound_icon.size / 2.0
	var white := Color(0.957, 0.933, 0.867)
	sound_icon.draw_colored_polygon(PackedVector2Array([
		c + Vector2(-16, -7), c + Vector2(-8, -7), c + Vector2(2, -17),
		c + Vector2(2, 17), c + Vector2(-8, 7), c + Vector2(-16, 7),
	]), white)
	if AudioServer.is_bus_mute(0):
		sound_icon.draw_line(c + Vector2(8, -10), c + Vector2(22, 10), Color(1.0, 0.3, 0.3), 4.0)
		sound_icon.draw_line(c + Vector2(22, -10), c + Vector2(8, 10), Color(1.0, 0.3, 0.3), 4.0)
	else:
		sound_icon.draw_arc(c + Vector2(4, 0), 10.0, -0.9, 0.9, 12, white, 3.0)
		sound_icon.draw_arc(c + Vector2(4, 0), 17.0, -0.9, 0.9, 12, white, 3.0)
