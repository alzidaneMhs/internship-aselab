extends Node2D

@export_enum("Cave", "Surface") var style_id: int = 0
@export var seed_value: int = 1
@export var ice: bool = false
@export var haunted: bool = false
@export var platforms_path: NodePath = NodePath("../Platforms")

var _items: Array = []
var _time := 0.0
var _redraw_acc := 0.0
var _dust: CPUParticles2D

const CAVE_CRYSTALS := [Color(0.75, 0.45, 1.0), Color(0.45, 0.85, 1.0), Color(0.95, 0.5, 0.85)]
const SURFACE_CRYSTALS := [Color(0.8, 0.5, 1.0), Color(1.0, 0.8, 0.3)]
const HAUNTED_CRYSTALS := [Color(0.45, 0.95, 0.7), Color(0.62, 0.45, 0.95), Color(0.3, 0.75, 0.65)]
const ICE_CRYSTALS := [Color(0.55, 0.75, 1.0), Color(0.75, 0.92, 1.0), Color(0.4, 0.6, 1.0)]


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + 17
	var platforms := get_node_or_null(platforms_path)
	var x_min := INF
	var x_max := -INF
	var y_mid := 400.0
	if platforms != null:
		for p in platforms.get_children():
			var sz: Variant = p.get("size")
			if typeof(sz) != TYPE_VECTOR2:
				continue
			x_min = minf(x_min, p.position.x)
			x_max = maxf(x_max, p.position.x + sz.x)
			y_mid = p.position.y
			var style_value: Variant = p.get("style")
			if style_value != null and int(style_value) == 1:
				continue
			_decorate_platform(p.position, sz, rng)
	if x_min != INF:
		_build_dust((x_min + x_max) / 2.0, y_mid - 150.0, (x_max - x_min) / 2.0 + 200.0)


func _process(delta: float) -> void:
	_time += delta
	_redraw_acc += delta
	if _redraw_acc >= 1.0 / 30.0:
		_redraw_acc = 0.0
		queue_redraw()
	if _dust != null:
		var cam := get_viewport().get_camera_2d()
		if cam != null:
			_dust.global_position = cam.get_screen_center_position() + Vector2(0.0, -40.0)


func _view_rect() -> Rect2:
	var inv := get_global_transform_with_canvas().affine_inverse()
	var r: Rect2 = inv * get_viewport_rect()
	return r.grow(340.0)


func _item_y(it: Dictionary) -> float:
	if it.has("p"):
		var p: Vector2 = it["p"]
		return p.y
	return float(it["y0"])


func _item_x(it: Dictionary) -> float:
	if it.has("p"):
		var p: Vector2 = it["p"]
		return p.x
	return float(it["x"])


func _palette() -> Array:
	if haunted:
		return HAUNTED_CRYSTALS
	if ice:
		return ICE_CRYSTALS
	return CAVE_CRYSTALS if style_id == 0 else SURFACE_CRYSTALS


func _decorate_platform(pos: Vector2, size: Vector2, rng: RandomNumberGenerator) -> void:
	var top := pos.y
	if size.y <= 40.0:
		_items.append(_make_crystal(Vector2(pos.x + rng.randf_range(10.0, size.x - 10.0), top), rng, 0.6))
		return

	var x := 30.0 + rng.randf_range(0.0, 60.0)
	while x < size.x - 40.0:
		var roll := rng.randf()
		var p := Vector2(pos.x + x, top)
		if roll < 0.34:
			_items.append(_make_crystal(p, rng, 1.0))
		elif roll < 0.55:
			_items.append({"t": "rock", "p": p, "w": rng.randf_range(18.0, 40.0), "h": rng.randf_range(10.0, 22.0), "seed": rng.randi()})
		elif roll < 0.95:
			_items.append({"t": "tuft", "p": p, "n": rng.randi_range(5, 9), "seed": rng.randi()})
		else:
			_items.append({"t": "lamp", "p": p, "ph": rng.randf() * TAU})
		x += rng.randf_range(110.0, 250.0)
	if size.x > 380.0:
		_items.append({"t": "lamp", "p": Vector2(pos.x + rng.randf_range(60.0, size.x - 60.0), top), "ph": rng.randf() * TAU})

	var wall_h := minf(size.y - 20.0, 300.0)
	var cracks := maxi(1, int(size.x / 320.0))
	for i in cracks:
		_items.append({"t": "crack", "p": Vector2(pos.x + rng.randf_range(30.0, size.x - 30.0), top + 30.0), "len": rng.randf_range(60.0, minf(wall_h, 180.0)), "seed": rng.randi()})
	for side in [-1.0, 1.0]:
		var wx := pos.x if side < 0.0 else pos.x + size.x
		_items.append({"t": "pipe", "x": wx + side * -9.0, "y0": top + 18.0, "y1": top + minf(wall_h, 220.0)})
		for k in rng.randi_range(1, 2):
			var c := _make_crystal(Vector2(wx, top + rng.randf_range(50.0, maxf(wall_h - 20.0, 60.0))), rng, 0.8)
			c["t"] = "wall_crystal"
			c["side"] = side
			_items.append(c)


func _make_crystal(p: Vector2, rng: RandomNumberGenerator, scale_factor: float) -> Dictionary:
	var pal := _palette()
	var shards: Array = []
	for i in rng.randi_range(2, 4):
		shards.append({
			"dx": (i - 1.0) * rng.randf_range(6.0, 11.0),
			"h": rng.randf_range(26.0, 68.0) * scale_factor,
			"w": rng.randf_range(7.0, 13.0) * scale_factor,
			"tilt": rng.randf_range(-9.0, 9.0),
		})
	return {"t": "crystal", "p": p, "shards": shards, "col": pal[rng.randi() % pal.size()], "ph": rng.randf() * TAU}


func _build_dust(_cx: float, _cy: float, _half_w: float) -> void:
	var d := CPUParticles2D.new()
	var player := get_node_or_null("../Player") as Node2D
	d.position = (player.position if player != null else Vector2(_cx, _cy)) + Vector2(0.0, -40.0)
	d.amount = 56
	d.lifetime = 8.0
	d.preprocess = 8.0
	d.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	d.emission_rect_extents = Vector2(760.0, 380.0)
	d.direction = Vector2(0.3, -1.0)
	d.spread = 70.0
	d.gravity = Vector2.ZERO
	d.initial_velocity_min = 4.0
	d.initial_velocity_max = 14.0
	d.scale_amount_min = 1.2
	d.scale_amount_max = 2.6
	var base := Color(0.85, 0.7, 1.0) if style_id == 0 else Color(1.0, 0.85, 0.5)
	if ice:
		base = Color(0.8, 0.92, 1.0)
	if haunted:
		base = Color(0.7, 0.95, 0.85)
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	grad.colors = PackedColorArray([Color(base, 0.0), Color(base, 0.55), Color(base, 0.0)])
	d.color_ramp = grad
	add_child(d)
	_dust = d


func _draw() -> void:
	var view := _view_rect()
	for it in _items:
		var ix := _item_x(it)
		if ix < view.position.x or ix > view.end.x:
			continue
		var iy := _item_y(it)
		if iy < view.position.y - 120.0 or iy > view.end.y + 120.0:
			continue
		match it["t"]:
			"crystal":
				_draw_crystal(it)
			"wall_crystal":
				_draw_wall_crystal(it)
			"rock":
				_draw_rock(it)
			"tuft":
				_draw_tuft(it)
			"lamp":
				_draw_lamp(it)
			"crack":
				_draw_crack(it)
			"pipe":
				_draw_pipe(it)


func _draw_crystal(it: Dictionary) -> void:
	var p: Vector2 = it["p"]
	var col: Color = it["col"]
	var pulse := 0.5 + 0.5 * sin(_time * 1.8 + float(it["ph"]))
	draw_circle(p + Vector2(0, -22), 34.0, Color(col, 0.06 + 0.05 * pulse))
	for s in it["shards"]:
		var bx: float = p.x + float(s["dx"])
		var w: float = s["w"]
		var tip := Vector2(bx + float(s["tilt"]), p.y - float(s["h"]))
		draw_colored_polygon(PackedVector2Array([Vector2(bx - w, p.y + 1.0), tip, Vector2(bx, p.y + 1.0)]), col.darkened(0.35))
		draw_colored_polygon(PackedVector2Array([Vector2(bx, p.y + 1.0), tip, Vector2(bx + w, p.y + 1.0)]), col.lightened(0.05))
		draw_line(Vector2(bx - w * 0.6, p.y - 4.0), tip, Color(1, 1, 1, 0.3 + 0.2 * pulse), 1.5)


func _draw_wall_crystal(it: Dictionary) -> void:
	var p: Vector2 = it["p"]
	var side: float = it["side"]
	var col: Color = it["col"]
	var pulse := 0.5 + 0.5 * sin(_time * 1.8 + float(it["ph"]))
	draw_circle(p + Vector2(side * 18.0, 0), 28.0, Color(col, 0.07 + 0.05 * pulse))
	for s in it["shards"]:
		var h: float = float(s["h"]) * 0.8
		var w: float = s["w"]
		var dir := Vector2(side, -0.35 + float(s["tilt"]) * 0.03).normalized()
		var base := p + Vector2(0, float(s["dx"]) * 1.3)
		var tip := base + dir * h
		var normal := Vector2(-dir.y, dir.x)
		draw_colored_polygon(PackedVector2Array([base + normal * w, tip, base]), col.lightened(0.05))
		draw_colored_polygon(PackedVector2Array([base, tip, base - normal * w]), col.darkened(0.35))


func _draw_rock(it: Dictionary) -> void:
	var p: Vector2 = it["p"]
	var w: float = it["w"]
	var h: float = it["h"]
	var rng := RandomNumberGenerator.new()
	rng.seed = it["seed"]
	var pts := PackedVector2Array([p + Vector2(-w * 0.5, 1.0)])
	pts.append(p + Vector2(-w * 0.4, -h * rng.randf_range(0.5, 0.9)))
	pts.append(p + Vector2(-w * 0.1, -h))
	pts.append(p + Vector2(w * 0.3, -h * rng.randf_range(0.6, 0.9)))
	pts.append(p + Vector2(w * 0.5, 1.0))
	draw_colored_polygon(pts, Color(0.3, 0.26, 0.34) if style_id == 0 else Color(0.45, 0.33, 0.24))
	draw_line(pts[1], pts[2], Color(1, 1, 1, 0.18), 2.0)


func _draw_tuft(it: Dictionary) -> void:
	var p: Vector2 = it["p"]
	var rng := RandomNumberGenerator.new()
	rng.seed = it["seed"]
	var col := Color(0.4, 1.0, 0.8, 0.8) if style_id == 0 else Color(1.0, 0.85, 0.35, 0.9)
	if haunted:
		col = Color(0.35, 0.5, 0.42, 0.85)
	for i in int(it["n"]):
		var lean := rng.randf_range(-12.0, 12.0) + sin(_time * 1.5 + p.x * 0.05 + i) * 2.0
		var h := rng.randf_range(10.0, 22.0)
		draw_line(p + Vector2((i - 3.0) * 3.0, 1.0), p + Vector2((i - 3.0) * 3.0 + lean, -h), col, 2.0)


func _draw_lamp(it: Dictionary) -> void:
	var p: Vector2 = it["p"]
	var flicker := 0.82 + 0.18 * sin(_time * 11.0 + float(it["ph"]))
	if haunted:
		flicker *= 0.55 + 0.45 * absf(sin(_time * 3.1 + float(it["ph"]) * 2.0))
	var lamp_color := Color(0.55, 1.0, 0.75) if haunted else Color(1.0, 0.8, 0.4)
	var top := p + Vector2(0, -92)
	draw_line(p, top, Color(0.16, 0.14, 0.2), 5.0)
	draw_line(top, top + Vector2(18, -6), Color(0.16, 0.14, 0.2), 4.0)
	var bulb := top + Vector2(20, 0)
	draw_circle(bulb, 52.0, Color(lamp_color, 0.07 * flicker))
	draw_circle(bulb, 28.0, Color(lamp_color, 0.14 * flicker))
	draw_circle(bulb, 10.0, Color(lamp_color.lightened(0.2), flicker))
	draw_circle(bulb, 4.0, Color.WHITE)
	draw_rect(Rect2(p + Vector2(-9, -6), Vector2(18, 7)), Color(0.22, 0.2, 0.28))


func _draw_crack(it: Dictionary) -> void:
	var p: Vector2 = it["p"]
	var rng := RandomNumberGenerator.new()
	rng.seed = it["seed"]
	var pts := PackedVector2Array([p])
	var cur := p
	var travelled := 0.0
	while travelled < float(it["len"]):
		var step := rng.randf_range(12.0, 24.0)
		cur += Vector2(rng.randf_range(-12.0, 12.0), step)
		pts.append(cur)
		travelled += step
	var accent := Color(0.75, 0.5, 1.0) if style_id == 0 else Color(1.0, 0.65, 0.25)
	if haunted:
		accent = Color(0.9, 0.2, 0.25)
	var pulse := 0.5 + 0.5 * sin(_time * 1.3 + p.x * 0.01)
	draw_polyline(pts, Color(accent, 0.12 + 0.08 * pulse), 6.0)
	draw_polyline(pts, Color(accent, 0.55 + 0.25 * pulse), 2.0)


func _draw_pipe(it: Dictionary) -> void:
	var x: float = it["x"]
	var y0: float = it["y0"]
	var y1: float = it["y1"]
	var pipe_col := Color(0.2, 0.19, 0.27)
	draw_rect(Rect2(x - 5.0, y0, 10.0, y1 - y0), pipe_col)
	draw_rect(Rect2(x - 5.0, y0, 3.0, y1 - y0), Color(0.45, 0.43, 0.58))
	var y := y0 + 24.0
	while y < y1:
		draw_rect(Rect2(x - 8.0, y, 16.0, 6.0), Color(0.3, 0.28, 0.38))
		draw_circle(Vector2(x - 5.0, y + 3.0), 1.4, Color(0.7, 0.7, 0.8))
		y += 56.0
	draw_circle(Vector2(x, y1), 7.0, Color(0.14, 0.13, 0.19))
	var t := fposmod(_time * 0.7 + x * 0.013, 1.0)
	draw_circle(Vector2(x, y1 + 6.0 + t * 40.0), 2.4, Color(0.7, 0.85, 1.0, 1.0 - t))
