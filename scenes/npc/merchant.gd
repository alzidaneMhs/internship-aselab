extends Area2D

const SHOP_UI_SCENE := preload("res://scenes/ui/shop_ui.tscn")

@onready var prompt: Label = $Prompt

var _player_in_range := false
var _shop_open := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt.visible = false


func _draw() -> void:
	draw_rect(Rect2(-24, -84, 48, 84), Color(0.55, 0.42, 0.2))
	draw_rect(Rect2(-24, -84, 48, 12), Color(0.8, 0.65, 0.3))
	draw_circle(Vector2(0, -102), 22.0, Color(0.85, 0.72, 0.4))
	draw_circle(Vector2(-8, -104), 4.0, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(8, -104), 4.0, Color(0.1, 0.1, 0.1))


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		prompt.visible = not _shop_open


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
