@tool
extends StaticBody2D

## Blockout platform. Origin is the top-left corner; `size` is in pixels.

@export var size: Vector2 = Vector2(400, 200):
	set(value):
		size = value
		if is_inside_tree():
			_rebuild()
@export var color: Color = Color(0.2, 0.15, 0.22, 1.0):
	set(value):
		color = value
		queue_redraw()
@export var top_color: Color = Color(0.62, 0.5, 0.32, 1.0):
	set(value):
		top_color = value
		queue_redraw()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null:
		var rect := RectangleShape2D.new()
		rect.size = size
		cs.shape = rect
		cs.position = size / 2.0
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, minf(10.0, size.y))), top_color)
