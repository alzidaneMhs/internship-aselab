extends Control

signal chosen(id: String)

@onready var options: VBoxContainer = $Panel/MarginContainer/VBoxContainer/Options

var _choices: Array = []
var _picked := false


func setup(choices: Array) -> void:
	_choices = choices


func _ready() -> void:
	for id in _choices:
		var info: Dictionary = GameState.ITEMS[id]
		var button := Button.new()
		button.text = "%s\n%s" % [info["name"], info["desc"]]
		button.custom_minimum_size = Vector2(560, 84)
		button.add_theme_font_size_override("font_size", 20)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_pick.bind(id))
		options.add_child(button)
	if options.get_child_count() > 0:
		(options.get_child(0) as Button).grab_focus()


func _on_pick(id: String) -> void:
	if _picked:
		return
	_picked = true
	chosen.emit(id)
