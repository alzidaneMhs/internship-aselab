extends Area3D

const SHOP_UI_SCENE := preload("res://scenes/ui/shop_ui.tscn")

@onready var prompt: Label3D = $Prompt

var _player_in_range := false
var _shop_open := false


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
	if _player_in_range and not _shop_open and event.is_action_pressed("interact"):
		_open_shop()


func _open_shop() -> void:
	_shop_open = true
	prompt.visible = false
	var ui: Control = SHOP_UI_SCENE.instantiate()
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(ui)
	get_tree().current_scene.add_child(layer)
	ui.closed.connect(_on_shop_closed.bind(layer))
	get_tree().paused = true


func _on_shop_closed(layer: CanvasLayer) -> void:
	get_tree().paused = false
	_shop_open = false
	prompt.visible = _player_in_range
	layer.queue_free()
