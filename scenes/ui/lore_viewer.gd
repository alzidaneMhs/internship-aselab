extends Control

signal closed

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var image: TextureRect = $Panel/MarginContainer/VBoxContainer/Image
@onready var caption: Label = $Panel/MarginContainer/VBoxContainer/Caption
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton

var _title := ""
var _caption := ""
var _texture: Texture2D


func setup(title: String, caption_text: String, texture: Texture2D) -> void:
	_title = title
	_caption = caption_text
	_texture = texture


func _ready() -> void:
	title_label.text = _title
	caption.text = _caption
	image.texture = _texture
	close_button.pressed.connect(func(): closed.emit())
	close_button.grab_focus()
