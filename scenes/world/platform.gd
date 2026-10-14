@tool
extends StaticBody2D

## Blockout platform. Origin is the top-left corner; `size` is in pixels.
## Style ARENA is the dark, glowing metal used for boss floors.

enum Style { NORMAL, ARENA }

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
@export var style: Style = Style.NORMAL:
	set(value):
		style = value
		queue_redraw()
@export var accent: Color = Color(1.0, 0.55, 0.2, 1.0):
	set(value):
		accent = value
		queue_redraw()

## Optional stone texture for the ground (tiled and mirrored, so no visible seams).
@export var ground_texture: Texture2D:
	set(value):
		ground_texture = value
		queue_redraw()
@export var texture_scale: float = 0.5:
	set(value):
		texture_scale = value
		queue_redraw()
@export var texture_tint: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		texture_tint = value
		queue_redraw()

const SEAM_STEP := 128.0


func _ready() -> void:
	if ground_texture != null:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_rebuild()


func _rebuild() -> void:
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null:
		var rect := RectangleShape2D.new()
		rect.size = size
		cs.shape = rect
		cs.position = size / 2.0
	queue_redraw()


func _draw_textured() -> void:
	var sc := texture_scale
	var tw := ground_texture.get_width() * sc
	var th := ground_texture.get_height() * sc
	var y := 0.0
	var row := 0
	while y < size.y:
		var h := minf(th, size.y - y)
		var shade := Color(texture_tint.r, texture_tint.g, texture_tint.b, texture_tint.a).darkened(0.12 * row)
		var x := 0.0
		var tile := 0
		while x < size.x:
			var w := minf(tw, size.x - x)
			var src := Rect2(0.0, 0.0, w / sc, h / sc)
			if tile % 2 == 0:
				draw_texture_rect_region(ground_texture, Rect2(x, y, w, h), src, shade)
			else:
				# Mirrored tile: its left edge shows the previous tile's right edge.
				draw_set_transform(Vector2(x + w, y), 0.0, Vector2(-1.0, 1.0))
				draw_texture_rect_region(ground_texture, Rect2(0.0, 0.0, w, h), src, shade)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			x += tw
			tile += 1
		y += th
		row += 1
	# Fade into darkness toward the bottom, and a lit edge on top.
	if size.y > 120.0:
		var dark := Color(0.02, 0.015, 0.05, 0.0)
		var deep := Color(0.02, 0.015, 0.05, 0.8)
		var fade_top := maxf(size.y - 110.0, 30.0)
		draw_polygon(
			PackedVector2Array([Vector2(0.0, fade_top), Vector2(size.x, fade_top), Vector2(size.x, size.y), Vector2(0.0, size.y)]),
			PackedColorArray([dark, dark, deep, deep]))
	draw_rect(Rect2(0.0, 0.0, size.x, 2.0), Color(1, 1, 1, 0.28))
	draw_rect(Rect2(0.0, 2.0, size.x, 6.0), Color(0, 0, 0, 0.18))
	draw_rect(Rect2(0.0, 0.0, 3.0, size.y), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(size.x - 3.0, 0.0, 3.0, size.y), Color(0, 0, 0, 0.25))


func _draw() -> void:
	if ground_texture != null:
		_draw_textured()
		return
	var body := color
	var strip := top_color
	if style == Style.ARENA:
		body = Color(0.12, 0.09, 0.17)
		strip = Color(0.24, 0.22, 0.3)
	var top_c := body.lightened(0.07)
	var bottom_c := body.darkened(0.4)
	draw_polygon(
		PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0.0), size, Vector2(0.0, size.y)]),
		PackedColorArray([top_c, top_c, bottom_c, bottom_c])
	)

	# Panel seams and rivets.
	var sx := SEAM_STEP
	while sx < size.x - 4.0:
		draw_line(Vector2(sx, 14.0), Vector2(sx, size.y), Color(0, 0, 0, 0.25), 2.0)
		draw_line(Vector2(sx + 2.0, 14.0), Vector2(sx + 2.0, size.y), Color(1, 1, 1, 0.05), 1.0)
		sx += SEAM_STEP
	if size.y > 40.0:
		draw_line(Vector2(0.0, 44.0), Vector2(size.x, 44.0), Color(0, 0, 0, 0.2), 2.0)
		var px := 0.0
		while px < size.x:
			var rivet := Color(1, 1, 1, 0.18)
			draw_circle(Vector2(px + 14.0, 28.0), 2.2, rivet)
			draw_circle(Vector2(minf(px + SEAM_STEP - 14.0, size.x - 6.0), 28.0), 2.2, rivet)
			px += SEAM_STEP

	# Top strip with a highlight, plus a soft shadow under it.
	draw_rect(Rect2(0.0, 0.0, size.x, minf(10.0, size.y)), strip)
	draw_rect(Rect2(0.0, 0.0, size.x, 3.0), strip.lightened(0.35))
	draw_rect(Rect2(0.0, 10.0, size.x, 4.0), Color(0, 0, 0, 0.22))

	if style == Style.ARENA:
		draw_rect(Rect2(0.0, 10.0, size.x, 3.0), accent)
		draw_rect(Rect2(0.0, 13.0, size.x, 9.0), Color(accent, 0.16))
		# Glowing circuit line with nodes.
		if size.y > 80.0:
			var y := 70.0
			draw_line(Vector2(0.0, y), Vector2(size.x, y), Color(accent, 0.35), 3.0)
			var nx := SEAM_STEP / 2.0
			while nx < size.x:
				draw_circle(Vector2(nx, y), 5.0, Color(accent, 0.55))
				draw_circle(Vector2(nx, y), 2.2, Color(1, 1, 1, 0.8))
				nx += SEAM_STEP

	# Side shading.
	draw_rect(Rect2(0.0, 0.0, 3.0, size.y), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(size.x - 3.0, 0.0, 3.0, size.y), Color(0, 0, 0, 0.25))
