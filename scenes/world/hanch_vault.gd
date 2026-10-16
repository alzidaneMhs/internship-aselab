extends Node2D

@export var left_x: float = -960.0
@export var right_x: float = 5060.0
@export var ceiling_y: float = -500.0
@export var floor_y: float = 600.0
@export var door_x: float = -560.0

const GOLD := Color(1.0, 0.78, 0.28)
const GOLD_DK := Color(0.62, 0.42, 0.12)
const WOOD := Color(0.13, 0.07, 0.05)
const WOOD_DK := Color(0.07, 0.035, 0.03)
const CHUNK_W := 1000.0
const DYN_STEP := 1.0 / 24.0

var _chunks: Array = []
var _time := 0.0
var _acc := 0.0
var _chandeliers: Array = []
var _glints: Array = []
var _sparkle: CPUParticles2D


func _ready() -> void:
	z_index = -10
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var x := left_x + 500.0
	while x < right_x - 200.0:
		_chandeliers.append(Vector2(x, ceiling_y + 40.0))
		x += 900.0
	for i in 70:
		_glints.append({"p": Vector2(rng.randf_range(left_x + 40.0, right_x - 40.0), rng.randf_range(floor_y - 120.0, floor_y - 6.0)), "ph": rng.randf() * TAU})
	var cx := left_x
	var idx := 0
	while cx < right_x:
		var back := Node2D.new()
		back.z_index = -12
		back.z_as_relative = false
		add_child(back)
		back.draw.connect(_draw_static.bind(back, cx, minf(cx + CHUNK_W, right_x), idx))
		var dyn := Node2D.new()
		dyn.z_index = -11
		dyn.z_as_relative = false
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		dyn.material = mat
		add_child(dyn)
		dyn.draw.connect(_draw_dynamic.bind(dyn, cx, minf(cx + CHUNK_W, right_x)))
		_chunks.append({"x0": cx, "x1": minf(cx + CHUNK_W, right_x), "dyn": dyn})
		cx += CHUNK_W
		idx += 1
	_build_sparkle()


func _build_sparkle() -> void:
	_sparkle = CPUParticles2D.new()
	_sparkle.amount = 40
	_sparkle.lifetime = 5.0
	_sparkle.preprocess = 5.0
	_sparkle.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_sparkle.emission_rect_extents = Vector2(820.0, 460.0)
	_sparkle.direction = Vector2(0, 1)
	_sparkle.spread = 25.0
	_sparkle.gravity = Vector2(0, 14)
	_sparkle.initial_velocity_min = 6.0
	_sparkle.initial_velocity_max = 20.0
	_sparkle.scale_amount_min = 1.5
	_sparkle.scale_amount_max = 3.2
	_sparkle.local_coords = false
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	ramp.colors = PackedColorArray([Color(GOLD, 0.0), Color(GOLD, 0.8), Color(GOLD, 0.0)])
	_sparkle.color_ramp = ramp
	_sparkle.z_index = 3
	add_child(_sparkle)


func _process(delta: float) -> void:
	_time += delta
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		_sparkle.global_position = cam.get_screen_center_position()
	_acc += delta
	if _acc < DYN_STEP:
		return
	_acc = 0.0
	var view: Rect2 = get_viewport().get_canvas_transform().affine_inverse() * get_viewport_rect()
	for c in _chunks:
		if float(c["x1"]) + 300.0 < view.position.x or float(c["x0"]) - 300.0 > view.end.x:
			continue
		(c["dyn"] as Node2D).queue_redraw()


func _in(x: float, x0: float, x1: float) -> bool:
	return x >= x0 and x < x1


func _draw_static(n: Node2D, x0: float, x1: float, index: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 900 + index
	var h := floor_y - ceiling_y
	n.draw_rect(Rect2(x0, ceiling_y - 400.0, x1 - x0 + 1.0, h + 800.0), WOOD_DK)
	var px := x0
	while px < x1:
		var shade := rng.randf_range(-0.012, 0.012)
		n.draw_rect(Rect2(px + 2.0, ceiling_y, 156.0, h), Color(WOOD.r + shade, WOOD.g + shade, WOOD.b + shade))
		n.draw_rect(Rect2(px + 2.0, ceiling_y, 4.0, h), Color(0, 0, 0, 0.35))
		n.draw_rect(Rect2(px + 20.0, ceiling_y + 160.0, 120.0, 240.0), Color(0, 0, 0, 0.18), false, 3.0)
		n.draw_rect(Rect2(px + 26.0, ceiling_y + 166.0, 108.0, 228.0), Color(GOLD_DK, 0.25), false, 1.5)
		px += 160.0
	var gy := ceiling_y + 440.0
	var bx := x0
	while bx < x1:
		var col := 0
		while col < 3:
			var by := gy + col * 46.0
			n.draw_rect(Rect2(bx + 4.0, by, 62.0, 40.0), Color(0.22, 0.17, 0.1))
			n.draw_rect(Rect2(bx + 4.0, by, 62.0, 40.0), Color(GOLD_DK, 0.7), false, 2.0)
			n.draw_circle(Vector2(bx + 35.0, by + 20.0), 4.0, GOLD)
			col += 1
		bx += 70.0
	n.draw_rect(Rect2(x0, gy - 10.0, x1 - x0, 6.0), GOLD_DK)
	n.draw_rect(Rect2(x0, gy + 140.0, x1 - x0, 6.0), GOLD_DK)
	var column_x := left_x + 350.0
	while column_x < right_x:
		if _in(column_x, x0 - 60.0, x1 + 60.0):
			n.draw_rect(Rect2(column_x - 46.0, ceiling_y, 92.0, h), Color(0.2, 0.15, 0.13))
			n.draw_rect(Rect2(column_x - 46.0, ceiling_y, 12.0, h), Color(0.32, 0.25, 0.2))
			n.draw_rect(Rect2(column_x + 34.0, ceiling_y, 12.0, h), Color(0.1, 0.07, 0.06))
			n.draw_rect(Rect2(column_x - 62.0, ceiling_y + 20.0, 124.0, 30.0), GOLD_DK)
			n.draw_rect(Rect2(column_x - 62.0, ceiling_y + 20.0, 124.0, 6.0), GOLD)
			n.draw_rect(Rect2(column_x - 62.0, floor_y - 40.0, 124.0, 40.0), GOLD_DK)
			n.draw_rect(Rect2(column_x - 62.0, floor_y - 40.0, 124.0, 6.0), GOLD)
		column_x += 700.0
	var sigil_x := left_x + 1400.0
	while sigil_x < right_x:
		if _in(sigil_x, x0, x1):
			_draw_sigil(n, Vector2(sigil_x, ceiling_y + 260.0), 120.0)
			_draw_banner(n, Vector2(sigil_x - 300.0, ceiling_y + 60.0))
			_draw_banner(n, Vector2(sigil_x + 300.0, ceiling_y + 60.0))
		sigil_x += 1400.0
	if _in(door_x, x0 - 300.0, x1 + 300.0):
		_draw_vault_door(n, Vector2(door_x, floor_y - 300.0))
	var mx := x0 + rng.randf_range(0.0, 200.0)
	while mx < x1:
		_draw_pile(n, Vector2(mx, floor_y), rng.randf_range(80.0, 190.0), rng)
		mx += rng.randf_range(260.0, 520.0)
	n.draw_rect(Rect2(x0, ceiling_y - 60.0, x1 - x0, 60.0), Color(0.09, 0.05, 0.04))
	n.draw_rect(Rect2(x0, ceiling_y - 6.0, x1 - x0, 6.0), GOLD_DK)


func _draw_sigil(n: Node2D, c: Vector2, r: float) -> void:
	n.draw_circle(c, r + 14.0, Color(GOLD_DK, 0.5))
	n.draw_circle(c, r, Color(0.16, 0.1, 0.05))
	n.draw_arc(c, r, 0.0, TAU, 48, GOLD, 6.0)
	n.draw_arc(c, r - 18.0, 0.0, TAU, 48, Color(GOLD, 0.6), 2.0)
	for i in 12:
		var a := i * TAU / 12.0
		n.draw_line(c + Vector2.from_angle(a) * (r - 14.0), c + Vector2.from_angle(a) * (r + 10.0), GOLD, 3.0)
	var font := ThemeDB.fallback_font
	n.draw_string(font, c + Vector2(-r * 0.62, r * 0.22), "VoC", HORIZONTAL_ALIGNMENT_CENTER, r * 1.24, int(r * 0.62), GOLD)


func _draw_banner(n: Node2D, top: Vector2) -> void:
	n.draw_rect(Rect2(top.x - 60.0, top.y - 8.0, 120.0, 10.0), GOLD_DK)
	n.draw_colored_polygon(PackedVector2Array([
		top + Vector2(-50, 0), top + Vector2(50, 0), top + Vector2(50, 300), top + Vector2(0, 340), top + Vector2(-50, 300),
	]), Color(0.45, 0.06, 0.07))
	n.draw_polyline(PackedVector2Array([
		top + Vector2(-50, 0), top + Vector2(-50, 300), top + Vector2(0, 340), top + Vector2(50, 300), top + Vector2(50, 0),
	]), GOLD, 3.0)
	var font := ThemeDB.fallback_font
	n.draw_string(font, top + Vector2(-50, 180), "VoC", HORIZONTAL_ALIGNMENT_CENTER, 100.0, 40, GOLD)


func _draw_vault_door(n: Node2D, c: Vector2) -> void:
	n.draw_circle(c, 290.0, Color(0.08, 0.06, 0.05))
	n.draw_circle(c, 270.0, Color(0.3, 0.26, 0.22))
	n.draw_circle(c, 240.0, Color(0.42, 0.37, 0.3))
	n.draw_arc(c, 255.0, 0.0, TAU, 64, GOLD_DK, 8.0)
	for i in 16:
		var a := i * TAU / 16.0
		n.draw_circle(c + Vector2.from_angle(a) * 255.0, 9.0, Color(0.6, 0.55, 0.45))
	n.draw_circle(c, 120.0, Color(0.34, 0.3, 0.25))
	n.draw_arc(c, 120.0, 0.0, TAU, 40, GOLD, 5.0)
	for i in 3:
		var a := i * TAU / 3.0 + 0.4
		n.draw_line(c, c + Vector2.from_angle(a) * 105.0, Color(0.7, 0.62, 0.45), 16.0)
		n.draw_circle(c + Vector2.from_angle(a) * 105.0, 14.0, GOLD)
	n.draw_circle(c, 30.0, GOLD)
	n.draw_rect(Rect2(c.x + 250.0, c.y - 40.0, 70.0, 80.0), Color(0.3, 0.26, 0.22))


func _draw_pile(n: Node2D, base: Vector2, w: float, rng: RandomNumberGenerator) -> void:
	var hgt := w * 0.45
	n.draw_colored_polygon(PackedVector2Array([
		base + Vector2(-w, 0), base + Vector2(-w * 0.5, -hgt * 0.7), base + Vector2(0, -hgt), base + Vector2(w * 0.55, -hgt * 0.65), base + Vector2(w, 0),
	]), GOLD_DK)
	for i in int(w / 9.0):
		var p := base + Vector2(rng.randf_range(-w * 0.85, w * 0.85), 0.0)
		var top := hgt * (1.0 - absf(p.x - base.x) / w)
		p.y -= rng.randf_range(4.0, maxf(top, 6.0))
		n.draw_circle(p, rng.randf_range(5.0, 8.0), Color(1.0, 0.8, 0.3).darkened(rng.randf_range(0.0, 0.3)))
		n.draw_circle(p + Vector2(-2, -2), 2.0, Color(1, 1, 0.85, 0.7))


func _draw_dynamic(n: Node2D, x0: float, x1: float) -> void:
	for c in _chandeliers:
		var cp: Vector2 = c
		if not _in(cp.x, x0, x1):
			continue
		var sway := sin(_time * 0.8 + cp.x * 0.01) * 6.0
		var hub := cp + Vector2(sway, 120.0)
		n.draw_line(cp, hub, Color(GOLD_DK, 0.6), 3.0)
		n.draw_circle(hub, 90.0, Color(1.0, 0.7, 0.3, 0.06))
		for k in 7:
			var a := PI + k * PI / 6.0
			var tip := hub + Vector2(cos(a) * 70.0, 20.0 + sin(a) * -10.0)
			var flick := 0.7 + 0.3 * sin(_time * 12.0 + k * 1.3 + cp.x)
			n.draw_line(hub, tip, Color(GOLD, 0.5), 3.0)
			n.draw_circle(tip + Vector2(0, -12), 6.0 * flick, Color(1.0, 0.8, 0.4, 0.9))
			n.draw_circle(tip + Vector2(0, -12), 18.0 * flick, Color(1.0, 0.6, 0.2, 0.18))
	for g in _glints:
		var gd: Dictionary = g
		var gp: Vector2 = gd["p"]
		if not _in(gp.x, x0, x1):
			continue
		var tw := pow(maxf(sin(_time * 1.7 + float(gd["ph"])), 0.0), 8.0)
		if tw < 0.05:
			continue
		n.draw_line(gp + Vector2(-9.0 * tw, 0), gp + Vector2(9.0 * tw, 0), Color(1, 1, 0.85, tw), 2.0)
		n.draw_line(gp + Vector2(0, -9.0 * tw), gp + Vector2(0, 9.0 * tw), Color(1, 1, 0.85, tw), 2.0)
