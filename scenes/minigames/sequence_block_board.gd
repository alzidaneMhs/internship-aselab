class_name SequenceBlockBoard
extends Control

signal block_pressed(number: int)

const BLOCK_SIZE: Vector2 = Vector2(88.0, 56.0)
const COMPLETED_COLOR: Color = Color("#8BEAA0")

@export_range(1, 21, 1)
var preview_block_count: int = 7

@onready var block_grid: GridContainer = (
	$GridCenter/BlockGrid
)

var interaction_enabled: bool = true
var _buttons_by_number: Array[Button] = []


func _ready() -> void:
	build_blocks(preview_block_count)


func build_blocks(block_count: int) -> void:
	interaction_enabled = false
	_clear_blocks()

	var total: int = clampi(block_count, 1, 21)
	var numbers: Array[int] = []

	for number in range(1, total + 1):
		numbers.append(number)

	numbers.shuffle()

	_buttons_by_number.resize(total)

	for number in numbers:
		var block_button: Button = Button.new()

		block_button.name = "Block%02d" % number
		block_button.text = str(number)
		block_button.custom_minimum_size = BLOCK_SIZE

		block_button.add_theme_font_size_override(
		"font_size", 24
		)

		block_button.focus_mode = Control.FOCUS_NONE
		block_button.mouse_default_cursor_shape = (
			Control.CURSOR_POINTING_HAND
		)

		block_button.pressed.connect(
			_on_block_pressed.bind(number)
		)

		block_grid.add_child(block_button)

		_buttons_by_number[number - 1] = block_button

	set_interaction_enabled(true)


func set_interaction_enabled(enabled: bool) -> void:
	interaction_enabled = enabled

	for block_button in _buttons_by_number:
		if is_instance_valid(block_button):
			block_button.disabled = not enabled


func mark_completed(number: int) -> void:
	if number < 1 or number > _buttons_by_number.size():
		return

	var block_button: Button = _buttons_by_number[number - 1]

	block_button.add_theme_color_override(
		"font_color", COMPLETED_COLOR
	)
	block_button.add_theme_color_override(
		"font_hover_color", COMPLETED_COLOR
	)
	block_button.add_theme_color_override(
		"font_pressed_color", COMPLETED_COLOR
	)


func _on_block_pressed(number: int) -> void:
	if not interaction_enabled:
		return

	print("Blok ditekan: ", number)

	block_pressed.emit(number)


func _clear_blocks() -> void:
	_buttons_by_number.clear()

	for child in block_grid.get_children():
		block_grid.remove_child(child)
		child.queue_free()
