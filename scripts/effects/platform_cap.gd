extends Node2D

const COIN := preload("res://assets/sprites/items/vonic_coin_spin.png")

var kind := "moss"
var width := 400.0
var height := 200.0
var accent := Color(0.4, 1.0, 1.0)

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = int(absf(global_position.x) * 13.0 + absf(global_position.y) * 7.0) + 17
	if kind == "coins":
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	queue_redraw()


func _draw() -> void:
	match kind:
		"moss":
			_draw_moss()
		"grass":
			_draw_grass()
		"snow":
			_draw_snow()
		"crystal":
			_draw_moss()
			_draw_crystals()
		"coins":
			_draw_coins()
		"neon":
			_draw_neon()
		"web":
			_draw_web()


func _tuft(x: float, h: float, col: Color, blades: int) -> void:
	for b in blades:
		var lean := _rng.randf_range(-5.0, 5.0)
		var bh := h * _rng.randf_range(0.6, 1.0)
		var bx := x + _rng.randf_range(-4.0, 4.0)
		draw_colored_polygon(PackedVector2Array([Vector2(bx - 2.0, 1.0), Vector2(bx + 2.0, 1.0), Vector2(bx + lean, -bh)]), col)


func _draw_moss() -> void:
	var x := 4.0
	while x < width - 4.0:
		var seg := _rng.randf_range(20.0, 70.0)
		var thick := _rng.randf_range(2.0, 5.0)
		var col := Color(0.28, 0.42, 0.36, 0.85).lerp(Color(0.38, 0.3, 0.5, 0.85), _rng.randf())
		draw_rect(Rect2(x, -thick * 0.5, minf(seg, width - 4.0 - x), thick), col)
		x += seg + _rng.randf_range(10.0, 60.0)
	var count := int(width / 70.0)
	for i in count:
		var tx := _rng.randf_range(8.0, width - 8.0)
		_tuft(tx, _rng.randf_range(6.0, 13.0), Color(0.32, 0.5, 0.44, 0.9), 3)
	var shrooms := int(width / 260.0)
	for i in shrooms:
		if _rng.randf() < 0.55:
			continue
		var mx := _rng.randf_range(14.0, width - 14.0)
		for k in _rng.randi_range(1, 3):
			var sx := mx + k * 7.0
			var sh := _rng.randf_range(5.0, 11.0)
			draw_line(Vector2(sx, 0.0), Vector2(sx, -sh), Color(0.75, 0.85, 0.9, 0.9), 1.6)
			draw_circle(Vector2(sx, -sh), 3.2, Color(accent.r * 1.8, accent.g * 1.8, accent.b * 1.8, 1.0))
			draw_circle(Vector2(sx, -sh), 6.0, Color(accent.r, accent.g, accent.b, 0.18))


func _draw_crystals() -> void:
	var count := int(width / 220.0)
	for i in count:
		if _rng.randf() < 0.4:
			continue
		var cx := _rng.randf_range(16.0, width - 16.0)
		for k in _rng.randi_range(2, 4):
			var h := _rng.randf_range(10.0, 26.0)
			var w := _rng.randf_range(4.0, 7.0)
			var x := cx + (k - 1.5) * 7.0
			var tilt := _rng.randf_range(-6.0, 6.0)
			var col := Color(0.75, 0.45, 1.4, 0.95)
			draw_colored_polygon(PackedVector2Array([Vector2(x - w, 1.0), Vector2(x + w, 1.0), Vector2(x + tilt * 0.4 + w * 0.3, -h * 0.75), Vector2(x + tilt, -h)]), col)
			draw_line(Vector2(x - w * 0.3, 0.0), Vector2(x + tilt, -h), Color(1.6, 1.2, 2.0, 0.9), 1.2)


func _draw_grass() -> void:
	draw_rect(Rect2(0.0, -2.0, width, 4.0), Color(0.55, 0.52, 0.22, 0.75))
	var count := int(width / 9.0)
	for i in count:
		var gx := 3.0 + i * 9.0 + _rng.randf_range(-3.0, 3.0)
		if gx > width - 3.0:
			break
		var g := Color(0.62, 0.6, 0.25, 0.95).lerp(Color(0.78, 0.58, 0.22, 0.95), _rng.randf())
		_tuft(gx, _rng.randf_range(5.0, 12.0), g, 2)
	for i in int(width / 120.0):
		if _rng.randf() < 0.5:
			continue
		var fx := _rng.randf_range(10.0, width - 10.0)
		var fh := _rng.randf_range(9.0, 15.0)
		draw_line(Vector2(fx, 0.0), Vector2(fx, -fh), Color(0.5, 0.55, 0.25), 1.4)
		var pc := Color(1.6, 0.75, 1.1) if _rng.randf() < 0.5 else Color(1.7, 1.4, 0.5)
		draw_circle(Vector2(fx, -fh), 2.6, pc)


func _draw_snow() -> void:
	var pts := PackedVector2Array()
	pts.append(Vector2(-3.0, 5.0))
	var x := -3.0
	while x < width + 3.0:
		pts.append(Vector2(x, -_rng.randf_range(3.0, 8.0)))
		x += _rng.randf_range(14.0, 30.0)
	pts.append(Vector2(width + 3.0, -4.0))
	pts.append(Vector2(width + 3.0, 5.0))
	var x2 := width + 3.0
	while x2 > -3.0:
		pts.append(Vector2(x2, _rng.randf_range(4.0, 9.0)))
		x2 -= _rng.randf_range(10.0, 26.0)
	draw_colored_polygon(pts, Color(0.9, 0.96, 1.05, 0.97))
	draw_polyline(pts.slice(1, floori(pts.size() / 2.0)), Color(1.25, 1.35, 1.5, 0.9), 1.5)
	var count := int(width / 46.0)
	for i in count:
		if _rng.randf() < 0.35:
			continue
		var ix := _rng.randf_range(8.0, width - 8.0)
		var il := _rng.randf_range(8.0, 26.0)
		var iw := _rng.randf_range(2.0, 4.5)
		draw_colored_polygon(PackedVector2Array([Vector2(ix - iw, 6.0), Vector2(ix + iw, 6.0), Vector2(ix, 6.0 + il)]), Color(0.78, 0.92, 1.1, 0.85))
		draw_line(Vector2(ix - iw * 0.3, 6.0), Vector2(ix, 6.0 + il), Color(1.3, 1.45, 1.6, 0.7), 1.0)


func _draw_coins() -> void:
	for i in int(width / 60.0):
		if _rng.randf() < 0.35:
			continue
		var cx := _rng.randf_range(10.0, width - 10.0)
		for k in _rng.randi_range(1, 4):
			var p := Vector2(cx + _rng.randf_range(-12.0, 12.0), -9.0 - k * 4.0)
			var frame := _rng.randi_range(0, 6)
			draw_texture_rect_region(COIN, Rect2(p - Vector2(9.0, 9.0), Vector2(18.0, 18.0)), Rect2(frame * 128.0, 0.0, 128.0, 128.0))


func _draw_neon() -> void:
	draw_rect(Rect2(0.0, -1.0, width, 2.5), Color(accent.r * 2.0, accent.g * 2.0, accent.b * 2.0, 0.9))
	draw_rect(Rect2(0.0, -4.0, width, 8.0), Color(accent.r, accent.g, accent.b, 0.14))
	var x := 20.0
	while x < width - 20.0:
		draw_circle(Vector2(x, 0.0), 2.2, Color(2.4, 2.4, 2.4, 1.0))
		x += 64.0


func _draw_web() -> void:
	for side in [0, 1]:
		if _rng.randf() < 0.5:
			continue
		var ox := 0.0 if side == 0 else width
		var dir := 1.0 if side == 0 else -1.0
		var col := Color(0.8, 0.85, 0.85, 0.35)
		var r := _rng.randf_range(18.0, 34.0)
		for k in 4:
			var a := deg_to_rad(10.0 + k * 22.0)
			draw_line(Vector2(ox, 2.0), Vector2(ox + dir * cos(a) * r, 2.0 + sin(a) * r), col, 1.0)
		for ring in [0.4, 0.7, 1.0]:
			var prev := Vector2(ox + dir * r * ring, 2.0)
			for k in range(1, 5):
				var a2 := deg_to_rad(10.0 + k * 22.0)
				var cur := Vector2(ox + dir * cos(a2) * r * ring, 2.0 + sin(a2) * r * ring)
				draw_line(prev, cur, col, 1.0)
				prev = cur
	var x := 6.0
	while x < width - 6.0:
		var seg := _rng.randf_range(30.0, 90.0)
		draw_rect(Rect2(x, -1.5, minf(seg, width - 6.0 - x), 2.0), Color(0.55, 0.6, 0.55, 0.55))
		x += seg + _rng.randf_range(20.0, 80.0)
