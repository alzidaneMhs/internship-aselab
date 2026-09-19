extends Area3D

const POPUP_SCENE := preload("res://scenes/ui/minigame_select_popup.tscn")

@onready var prompt: Label3D = $Prompt

var _player_in_range := false
var _popup_open := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt.visible = false


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		prompt.visible = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		prompt.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and not _popup_open and event.is_action_pressed("interact"):
		_open_popup()


func _open_popup() -> void:
	_popup_open = true
	var popup: Control = POPUP_SCENE.instantiate()
	var layer := CanvasLayer.new()
	layer.add_child(popup)
	get_tree().current_scene.add_child(layer)
	popup.tree_exited.connect(_on_popup_closed.bind(layer))


func _on_popup_closed(layer: CanvasLayer) -> void:
	_popup_open = false
	layer.queue_free()
