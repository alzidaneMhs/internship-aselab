extends RefCounted

const BODY := Color(0.2, 0.15, 0.22, 1.0)
const STRIP := Color(0.62, 0.5, 0.32, 1.0)
const SEAM_STEP := 128.0


static func shade_at(y: float, block: Rect2) -> Color:
	var t := clampf((y - block.position.y) / maxf(block.size.y, 1.0), 0.0, 1.0)
	return BODY.lightened(0.07).lerp(BODY.darkened(0.4), t)


static func draw_rock(canvas: CanvasItem, rect: Rect2, block: Rect2, alpha: float = 1.0) -> void:
	var top_c := shade_at(rect.position.y, block)
	var bottom_c := shade_at(rect.end.y, block)
	top_c.a = alpha
	bottom_c.a = alpha
	canvas.draw_polygon(
		PackedVector2Array([
			rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y),
		]),
		PackedColorArray([top_c, top_c, bottom_c, bottom_c])
	)
	var sx := block.position.x + SEAM_STEP
	while sx < block.end.x:
		if sx > rect.position.x + 4.0 and sx < rect.end.x - 4.0:
			canvas.draw_line(Vector2(sx, rect.position.y), Vector2(sx, rect.end.y), Color(0, 0, 0, 0.22 * alpha), 2.0)
			canvas.draw_line(Vector2(sx + 2.0, rect.position.y), Vector2(sx + 2.0, rect.end.y), Color(1, 1, 1, 0.05 * alpha), 1.0)
		sx += SEAM_STEP
	canvas.draw_rect(Rect2(rect.position.x, rect.position.y, 3.0, rect.size.y), Color(0, 0, 0, 0.18 * alpha))
	canvas.draw_rect(Rect2(rect.end.x - 3.0, rect.position.y, 3.0, rect.size.y), Color(0, 0, 0, 0.18 * alpha))


static func draw_top_strip(canvas: CanvasItem, block: Rect2, alpha: float = 1.0) -> void:
	var strip := STRIP
	strip.a = alpha
	canvas.draw_rect(Rect2(block.position.x, block.position.y, block.size.x, 10.0), strip)
	canvas.draw_rect(Rect2(block.position.x, block.position.y, block.size.x, 3.0), strip.lightened(0.35))
	canvas.draw_rect(Rect2(block.position.x, block.position.y + 10.0, block.size.x, 4.0), Color(0, 0, 0, 0.22 * alpha))
