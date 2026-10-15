extends ParallaxBackground

@export_enum("Cave", "Surface") var style_id: int = 0
@export var seed_value: int = 1
@export var ice: bool = false

var _layers: Array[Node2D] = []
var _items: Array = []
var _time := 0.0


func _ready() -> void:
	layer = -9
	var bounds := _platform_bounds()
	_add_layer(0.35, bounds, 0)
	_add_layer(0.65, bounds, 1)


var _redraw_acc := 0.0


func _process(delta: float) -> void:
	_time += delta
	_redraw_acc += delta
	if _redraw_acc >= 1.0 / 30.0:
		_redraw_acc = 0.0
		for n in _layers:
			n.queue_redraw()


func _platform_bounds() -> Vector2:
	var x_min := -500.0
	var x_max := 3500.0
	var platforms := get_node_or_null("../Platforms")
	if platforms != null:
		x_min = INF
		x_max = -INF
		for p in platforms.get_children():
			var sz: Variant = p.get("size")
			if typeof(sz) == TYPE_VECTOR2:
				x_min = minf(x_min, p.position.x)
				x_max = maxf(x_max, p.position.x + sz.x)
		if x_min == INF:
			x_min = -500.0
			x_max = 3500.0
	return Vector2(x_min, x_max)


func _add_layer(motion_x: float, bounds: Vector2, depth: int) -> void:
	var pl := ParallaxLayer.new()
	pl.motion_scale = Vector2(motion_x, 0.0)
	add_child(pl)
	var canvas := Node2D.new()
	pl.add_child(canvas)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 977 + depth * 131
	var l_min := (bounds.x - 640.0) * motion_x - 500.0
	var l_max := (bounds.y - 640.0) * motion_x + 1280.0 + 500.0
	var items: Array = []
	if style_id == 0:
		_gen_cave(items, rng, l_min, l_max, depth)
	else:
		_gen_surface(items, rng, l_min, l_max, depth)
	_layers.append(canvas)
	canvas.draw.connect(_draw_layer.bind(canvas, items))


func _crystal_colors() -> Array:
	if ice:
		return [Color(0.55, 0.75, 1.0), Color(0.75, 0.92, 1.0), Color(0.4, 0.6, 1.0)]
	return [Color(0.7, 0.45, 1.0), Color(0.45, 0.8, 1.0), Color(0.95, 0.5, 0.85)]


func _gen_cave(items: Array, rng: RandomNumberGenerator, l_min: float, l_max: float, depth: int) -> void:
	var x := l_min
	while x < l_max:
		var far := depth == 0
		items.append({
			"t": "stalactite", "x": x, "w": rng.randf_range(60.0, 140.0) * (1.2 if far else 1.0),
			"len": rng.randf_range(90.0, 250.0) * (1.2 if far else 0.8), "lean": rng.randf_range(-18.0, 18.0),
			"a": 0.62 if far else 0.9,
		})
		x += rng.randf_range(70.0, 200.0)
	x = l_min
	while x < l_max:
		if depth == 0:
			items.append({
				"t": "crystal", "x": x, "h": rng.randf_range(70.0, 190.0), "w": rng.randf_range(24.0, 48.0),
				"col": _crystal_colors()[rng.randi() % 3],
				"ph": rng.randf() * TAU,
			})
			x += rng.randf_range(150.0, 360.0)
		else:
			items.append({"t": "stalagmite", "x": x, "w": rng.randf_range(50.0, 110.0), "len": rng.randf_range(60.0, 170.0)})
			x += rng.randf_range(120.0, 320.0)
	if depth == 1:
		x = l_min
		while x < l_max:
			items.append({"t": "lamp", "x": x, "len": rng.randf_range(70.0, 190.0), "ph": rng.randf() * TAU})
			x += rng.randf_range(380.0, 700.0)


func _gen_surface(items: Array, rng: RandomNumberGenerator, l_min: float, l_max: float, depth: int) -> void:
	var x := l_min
	if depth == 0:
		while x < l_max:
			items.append({"t": "pylon", "x": x, "w": rng.randf_range(46.0, 96.0), "h": rng.randf_range(220.0, 460.0), "ph": rng.randf() * TAU})
			x += rng.randf_range(160.0, 380.0)
	else:
		while x < l_max:
			items.append({"t": "mast", "x": x, "h": rng.randf_range(220.0, 420.0), "ph": rng.randf() * TAU})
			x += rng.randf_range(300.0, 620.0)
		x = l_min
		while x < l_max:
			items.append({"t": "hill", "x": x, "w": rng.randf_range(200.0, 420.0), "h": rng.randf_range(50.0, 130.0)})
			x += rng.randf_range(180.0, 380.0)


func _draw_layer(canvas: Node2D, items: Array) -> void:
	var inv := canvas.get_global_transform_with_canvas().affine_inverse()
	var view: Rect2 = inv * canvas.get_viewport_rect()
	var x_lo := view.position.x - 520.0
	var x_hi := view.end.x + 520.0
	for it in items:
		var ix := float(it["x"])
		if ix < x_lo or ix > x_hi:
			continue
		match it["t"]:
			"stalactite":
				_draw_stalactite(canvas, it)
			"crystal":
				_draw_crystal(canvas, it)
			"stalagmite":
				_draw_stalagmite(canvas, it)
			"lamp":
				_draw_lamp(canvas, it)
			"pylon":
				_draw_pylon(canvas, it)
			"mast":
				_draw_mast(canvas, it)
			"hill":
				_draw_hill(canvas, it)


func _draw_stalactite(c: Node2D, it: Dictionary) -> void:
	var x: float = it["x"]
	var w: float = it["w"]
	var length: float = it["len"]
	var a: float = it["a"]
	var tip := Vector2(x + float(it["lean"]), -10.0 + length)
	c.draw_colored_polygon(PackedVector2Array([Vector2(x - w / 2.0, -20.0), Vector2(x + w / 2.0, -20.0), tip]), Color(0.1, 0.05, 0.17, a))
	c.draw_colored_polygon(PackedVector2Array([Vector2(x, -20.0), Vector2(x + w / 2.0, -20.0), tip]), Color(0.06, 0.03, 0.11, a))
	c.draw_line(Vector2(x - w / 2.0 + 4.0, -14.0), tip, Color(0.6, 0.4, 0.9, 0.18 * a), 2.0)


func _draw_stalagmite(c: Node2D, it: Dictionary) -> void:
	var x: float = it["x"]
	var w: float = it["w"]
	var length: float = it["len"]
	c.draw_colored_polygon(PackedVector2Array([Vector2(x - w / 2.0, 730.0), Vector2(x + w / 2.0, 730.0), Vector2(x + 4.0, 730.0 - length)]), Color(0.08, 0.04, 0.14, 0.92))
	c.draw_line(Vector2(x - w / 2.0 + 3.0, 726.0), Vector2(x + 4.0, 730.0 - length), Color(0.6, 0.4, 0.9, 0.2), 2.0)


func _draw_crystal(c: Node2D, it: Dictionary) -> void:
	var x: float = it["x"]
	var h: float = it["h"]
	var w: float = it["w"]
	var col: Color = it["col"]
	var pulse := 0.5 + 0.5 * sin(_time * 1.6 + float(it["ph"]))
	var base_y := 730.0
	c.draw_circle(Vector2(x, base_y - h * 0.4), h * 0.55, Color(col, 0.05 + 0.05 * pulse))
	for k in 3:
		var off := (k - 1) * w * 0.7
		var hk := h * (0.55 + 0.45 * (1.0 if k == 1 else 0.7))
		var tip := Vector2(x + off + (k - 1) * 8.0, base_y - hk)
		c.draw_colored_polygon(PackedVector2Array([Vector2(x + off - w * 0.5, base_y), tip, Vector2(x + off, base_y)]), Color(col.darkened(0.45), 0.55))
		c.draw_colored_polygon(PackedVector2Array([Vector2(x + off, base_y), tip, Vector2(x + off + w * 0.5, base_y)]), Color(col.darkened(0.2), 0.55))
		c.draw_line(Vector2(x + off - w * 0.4, base_y - 6.0), tip, Color(1, 1, 1, 0.12 + 0.1 * pulse), 2.0)


func _draw_lamp(c: Node2D, it: Dictionary) -> void:
	var x: float = it["x"]
	var length: float = it["len"]
	var flicker := 0.8 + 0.2 * sin(_time * 9.0 + float(it["ph"]))
	var sway := sin(_time * 0.8 + float(it["ph"])) * 3.0
	var lamp := Vector2(x + sway, length)
	c.draw_line(Vector2(x, -10.0), lamp, Color(0.25, 0.22, 0.3, 0.9), 3.0)
	c.draw_circle(lamp, 46.0, Color(1.0, 0.75, 0.35, 0.07 * flicker))
	c.draw_circle(lamp, 24.0, Color(1.0, 0.75, 0.35, 0.14 * flicker))
	c.draw_rect(Rect2(lamp + Vector2(-9, -10), Vector2(18, 22)), Color(0.2, 0.17, 0.22))
	c.draw_rect(Rect2(lamp + Vector2(-6, -6), Vector2(12, 14)), Color(1.0, 0.82, 0.45, flicker))


func _draw_pylon(c: Node2D, it: Dictionary) -> void:
	var x: float = it["x"]
	var w: float = it["w"]
	var h: float = it["h"]
	var top := 730.0 - h
	c.draw_rect(Rect2(x - w / 2.0, top, w, h), Color(0.22, 0.12, 0.2, 0.5))
	c.draw_rect(Rect2(x - w / 2.0, top, w * 0.3, h), Color(0.3, 0.18, 0.28, 0.35))
	c.draw_colored_polygon(PackedVector2Array([Vector2(x - w / 2.0 - 6.0, top), Vector2(x + w / 2.0 + 6.0, top), Vector2(x, top - 40.0)]), Color(0.2, 0.1, 0.18, 0.5))
	var rows := int(h / 46.0)
	for r in rows:
		if sin(float(r) * 3.1 + float(it["ph"])) > 0.15:
			c.draw_rect(Rect2(x - 6.0, top + 18.0 + r * 46.0, 12.0, 14.0), Color(1.0, 0.85, 0.5, 0.4))


func _draw_mast(c: Node2D, it: Dictionary) -> void:
	var x: float = it["x"]
	var h: float = it["h"]
	var top := 730.0 - h
	c.draw_line(Vector2(x, 730.0), Vector2(x, top), Color(0.18, 0.1, 0.18, 0.85), 5.0)
	c.draw_line(Vector2(x - 20.0, top + 40.0), Vector2(x + 20.0, top + 40.0), Color(0.18, 0.1, 0.18, 0.85), 3.0)
	c.draw_line(Vector2(x - 12.0, top + 80.0), Vector2(x + 12.0, top + 80.0), Color(0.18, 0.1, 0.18, 0.85), 3.0)
	if sin(_time * 2.2 + float(it["ph"])) > 0.0:
		c.draw_circle(Vector2(x, top), 9.0, Color(1.0, 0.2, 0.2, 0.25))
		c.draw_circle(Vector2(x, top), 4.0, Color(1.0, 0.35, 0.3, 0.95))


func _draw_hill(c: Node2D, it: Dictionary) -> void:
	var x: float = it["x"]
	var w: float = it["w"]
	var h: float = it["h"]
	var pts := PackedVector2Array([Vector2(x - w / 2.0, 735.0)])
	for k in 9:
		var t := k / 8.0
		pts.append(Vector2(x - w / 2.0 + w * t, 735.0 - sin(t * PI) * h))
	pts.append(Vector2(x + w / 2.0, 735.0))
	c.draw_colored_polygon(pts, Color(0.28, 0.17, 0.12, 0.88))
