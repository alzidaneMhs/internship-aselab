extends Node2D

const SPIN := preload("res://assets/sprites/items/vonic_coin_spin.png")
const FRAMES := 7
const CELL := 128.0
const LIFE := 0.95

var velocity := Vector2.ZERO
var coin_size := 30.0

var _t := 0.0
var _frame := 0.0


static func spawn(parent: Node, pos: Vector2, count: int) -> void:
	if parent == null:
		return
	for i in clampi(count, 1, 4):
		var c := Node2D.new()
		c.set_script(load("res://scripts/effects/vonic_pop.gd"))
		c.set("velocity", Vector2(randf_range(-120.0, 120.0), randf_range(-520.0, -380.0)))
		c.set("coin_size", randf_range(26.0, 32.0))
		parent.add_child(c)
		c.global_position = pos + Vector2(randf_range(-10.0, 10.0), 0.0)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	z_index = 30
	_frame = randf() * FRAMES


func _process(delta: float) -> void:
	_t += delta
	_frame += delta * 16.0
	velocity.y += 1300.0 * delta
	position += velocity * delta
	if _t > LIFE:
		queue_free()
		return
	modulate.a = clampf((LIFE - _t) / 0.3, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var f := int(_frame) % FRAMES
	var s := coin_size
	draw_circle(Vector2.ZERO, s * 0.75, Color(1.0, 0.85, 0.3, 0.18))
	draw_texture_rect_region(SPIN, Rect2(Vector2(-s, -s) * 0.5, Vector2(s, s)), Rect2(f * CELL, 0.0, CELL, CELL))
