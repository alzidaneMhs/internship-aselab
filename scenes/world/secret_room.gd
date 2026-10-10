extends Area2D

## Hidden room behind a dark curtain. Entering it unlocks an achievement and
## shows a lore image. Origin is the top-left corner of the room.

const LORE_VIEWER := preload("res://scenes/ui/lore_viewer.tscn")

@export var secret_id: String = ""
@export var room_size: Vector2 = Vector2(420, 220):
	set(value):
		room_size = value
		if is_node_ready():
			_rebuild()
@export var achievement_title: String = "Secret Room Ditemukan"
@export var lore_title: String = ""
@export_multiline var lore_text: String = ""
@export var lore_texture: Texture2D

var curtain_alpha: float = 0.93:
	set(value):
		curtain_alpha = value
		queue_redraw()

var _triggered := false


func _ready() -> void:
	z_index = 5
	_rebuild()
	if GameState.is_secret_found(secret_id):
		curtain_alpha = 0.0
		_triggered = true
	body_entered.connect(_on_body_entered)


func _rebuild() -> void:
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null:
		var rect := RectangleShape2D.new()
		rect.size = room_size
		cs.shape = rect
		cs.position = room_size / 2.0
	queue_redraw()


func _draw() -> void:
	if curtain_alpha > 0.0:
		draw_rect(Rect2(Vector2.ZERO, room_size), Color(0.04, 0.02, 0.07, curtain_alpha))


func _on_body_entered(body: Node) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	var tw := create_tween()
	tw.tween_property(self, "curtain_alpha", 0.0, 0.6)
	GameState.discover_secret(secret_id, achievement_title)
	GameState.save_game()
	await get_tree().create_timer(0.9).timeout
	_open_lore()


func _open_lore() -> void:
	var ui: Control = LORE_VIEWER.instantiate()
	ui.call("setup", lore_title, lore_text, lore_texture)
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(ui)
	get_tree().current_scene.add_child(layer)
	ui.connect("closed", _on_lore_closed.bind(layer))
	get_tree().paused = true


func _on_lore_closed(layer: CanvasLayer) -> void:
	get_tree().paused = false
	layer.queue_free()
