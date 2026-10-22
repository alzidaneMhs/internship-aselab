extends Control

signal selected(kind: String)
signal cancelled

const GAME_TITLES := {
	"block_blast": "Block Blast",
	"snake": "Snake",
	"brick_breaker": "Brick Breaker",
	"virus_wire": "Virus Wire",
	"block_sequence": "Block Sequence",
}

@onready var menu_box: VBoxContainer = (
	$Panel/VBoxContainer
)

@onready var mode_label: Label = (
	$Panel/VBoxContainer/ModeLabel
)

@onready var cancel_button: Button = (
	$Panel/VBoxContainer/CancelButton
)

var _submitted: bool = false


func _ready() -> void:
	mode_label.hide()
	var mode_names := {
		"kind": "Baik Hati",
		"normal": "Seimbang",
		"hardcore": "Genosida",
	}

	var current_mode: String = (GameState.get_minigame_difficulty())

	var mode_name: String = mode_names.get(current_mode, "Seimbang (normal)")

	mode_label.text = ("Mode umum: %s | Reputasi %d\n" + "Virus Wire dan Block Sequence: Normal") % [mode_name, GameState.reputation]

	mode_label.add_theme_font_size_override("font_size", 16)
	mode_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	menu_box.add_theme_constant_override("separation", 8)

	for child in menu_box.get_children():
		if child is Button and child != cancel_button:
			menu_box.remove_child(child)
			child.queue_free()

	var first_button: Button = null

	for key in GameManager.MINIGAME_SCENES:
		var kind: String = str(key)
		var button: Button = Button.new()

		button.name = kind.to_pascal_case() + "Button"
		button.text = GAME_TITLES.get(kind, kind.capitalize())

		button.custom_minimum_size = Vector2(0.0, 54.0)

		button.add_theme_font_size_override("font_size", 20)

		button.mouse_default_cursor_shape = (Control.CURSOR_POINTING_HAND)

		button.pressed.connect(_pick.bind(kind))

		menu_box.add_child(button)

		if first_button == null:
			first_button = button

	menu_box.move_child(
		cancel_button,
		menu_box.get_child_count() - 1
	)
	
	cancel_button.custom_minimum_size = Vector2(0.0, 48.0)
	cancel_button.add_theme_font_size_override(
		"font_size", 20
	)
	cancel_button.pressed.connect(_cancel)

	if first_button != null:
		first_button.grab_focus()

func _pick(kind: String) -> void:
	if _submitted:
		return

	_submitted = true
	selected.emit(kind)
	queue_free()


func _cancel() -> void:
	if _submitted:
		return

	_submitted = true
	cancelled.emit()
	queue_free()
