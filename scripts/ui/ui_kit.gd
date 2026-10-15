extends RefCounted

const INK_950 := Color(0.035, 0.027, 0.07)
const INK_900 := Color(0.059, 0.047, 0.11)
const INK_800 := Color(0.098, 0.078, 0.184)
const INK_700 := Color(0.157, 0.125, 0.298)
const STEEL := Color(0.455, 0.416, 0.714)
const STEEL_DIM := Color(0.28, 0.255, 0.45)
const AMBER := Color(1.0, 0.725, 0.22)
const AMBER_DK := Color(0.667, 0.424, 0.086)
const CYAN := Color(0.275, 0.851, 0.91)
const VIOLET := Color(0.69, 0.38, 1.0)
const RED := Color(1.0, 0.3, 0.3)
const GREEN := Color(0.35, 0.88, 0.54)
const TEXT := Color(0.957, 0.933, 0.867)
const TEXT_DIM := Color(0.6, 0.576, 0.722)


static func chamfer(rect: Rect2, tl: float, tr: float, br: float, bl: float) -> PackedVector2Array:
	var p := rect.position
	var e := rect.end
	var pts := PackedVector2Array()
	pts.append(Vector2(p.x + tl, p.y))
	pts.append(Vector2(e.x - tr, p.y))
	if tr > 0.0:
		pts.append(Vector2(e.x, p.y + tr))
	pts.append(Vector2(e.x, e.y - br))
	if br > 0.0:
		pts.append(Vector2(e.x - br, e.y))
	pts.append(Vector2(p.x + bl, e.y))
	if bl > 0.0:
		pts.append(Vector2(p.x, e.y - bl))
	if tl > 0.0:
		pts.append(Vector2(p.x, p.y + tl))
	return pts


static func draw_panel(c: CanvasItem, rect: Rect2, fill: Color = Color(INK_900, 0.92), border: Color = STEEL,
		cut: float = 10.0, accent: Color = AMBER, brackets: bool = true) -> void:
	var pts := chamfer(rect, cut, cut, cut, cut)
	c.draw_colored_polygon(pts, fill)
	var closed := PackedVector2Array(pts)
	closed.append(pts[0])
	c.draw_polyline(closed, border, 2.0)
	if brackets:
		draw_brackets(c, rect, cut, accent)


static func draw_brackets(c: CanvasItem, rect: Rect2, cut: float, accent: Color, length: float = 14.0) -> void:
	var p := rect.position
	var e := rect.end
	var w := 3.0
	for corner in 4:
		var sx := -1.0 if corner == 1 or corner == 2 else 1.0
		var sy := -1.0 if corner == 2 or corner == 3 else 1.0
		var o := Vector2(p.x if sx > 0.0 else e.x, p.y if sy > 0.0 else e.y)
		c.draw_line(o + Vector2(sx * cut, 0.0), o + Vector2(0.0, sy * cut), accent, w)
		c.draw_line(o + Vector2(sx * cut, 0.0), o + Vector2(sx * (cut + length), 0.0), accent, w)
		c.draw_line(o + Vector2(0.0, sy * cut), o + Vector2(0.0, sy * (cut + length)), accent, w)


static func draw_bar(c: CanvasItem, rect: Rect2, ratio: float, fill: Color, back: Color = Color(INK_950, 0.95),
		border: Color = STEEL_DIM, trail_ratio: float = -1.0, trail: Color = Color(1.0, 0.95, 0.8, 0.85)) -> void:
	var cut := minf(rect.size.y * 0.45, 8.0)
	c.draw_colored_polygon(chamfer(rect, cut, 0.0, cut, 0.0), back)
	var inner := rect.grow(-3.0)
	var ratio_c := clampf(ratio, 0.0, 1.0)
	if trail_ratio > ratio_c:
		var tr_rect := Rect2(inner.position, Vector2(inner.size.x * clampf(trail_ratio, 0.0, 1.0), inner.size.y))
		c.draw_rect(tr_rect, trail)
	if ratio_c > 0.0:
		var fr := Rect2(inner.position, Vector2(inner.size.x * ratio_c, inner.size.y))
		c.draw_rect(fr, fill)
		c.draw_rect(Rect2(fr.position, Vector2(fr.size.x, maxf(fr.size.y * 0.32, 2.0))), Color(1, 1, 1, 0.22))
	var pts := chamfer(rect, cut, 0.0, cut, 0.0)
	var closed := PackedVector2Array(pts)
	closed.append(pts[0])
	c.draw_polyline(closed, border, 2.0)


static func draw_tag(c: CanvasItem, rect: Rect2, color: Color = AMBER_DK, fill: Color = Color(INK_800, 0.95)) -> void:
	var pts := chamfer(rect, 6.0, 0.0, 6.0, 0.0)
	c.draw_colored_polygon(pts, fill)
	var closed := PackedVector2Array(pts)
	closed.append(pts[0])
	c.draw_polyline(closed, color, 2.0)


static func draw_hazard(c: CanvasItem, rect: Rect2, color: Color = AMBER, back: Color = Color(INK_950, 0.9),
		offset: float = 0.0, step: float = 22.0) -> void:
	c.draw_rect(rect, back)
	var h := rect.size.y
	var x := rect.position.x - h + fposmod(offset, step * 2.0) - step * 2.0
	while x < rect.end.x:
		var x0 := maxf(x, rect.position.x)
		var x1 := minf(x + step, rect.end.x)
		if x1 > x0:
			var pts := PackedVector2Array([
				Vector2(x, rect.end.y), Vector2(x + step, rect.end.y), Vector2(x + step + h, rect.position.y), Vector2(x + h, rect.position.y),
			])
			var clipped := Geometry2D.intersect_polygons(pts, PackedVector2Array([
				rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y),
			]))
			for poly in clipped:
				c.draw_colored_polygon(poly, color)
		x += step * 2.0


static func box(fill: Color = Color(INK_900, 0.94), border: Color = STEEL, width: int = 2) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.border_color = border
	b.set_border_width_all(width)
	b.set_corner_radius_all(0)
	return b
