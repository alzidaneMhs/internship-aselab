extends Control

const SPIN := preload("res://assets/sprites/items/vonic_coin_spin.png")
const FRAMES := 7
const CELL := 128.0

var icon_size := 32.0
var fps := 12.0
var idle_gap := 3.5

var _frame := 0.0
var _spinning := false
var _wait := 1.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(icon_size, icon_size)
	size = custom_minimum_size


func bump() -> void:
	_spinning = true
	_frame = 0.0


func _process(delta: float) -> void:
	if _spinning:
		_frame += delta * fps
		if _frame >= FRAMES:
			_frame = 0.0
			_spinning = false
			_wait = idle_gap
		queue_redraw()
	else:
		_wait -= delta
		if _wait <= 0.0:
			bump()


func _draw() -> void:
	var f := int(_frame) % FRAMES
	draw_texture_rect_region(SPIN, Rect2(Vector2.ZERO, Vector2(icon_size, icon_size)), Rect2(f * CELL, 0.0, CELL, CELL))
