extends Node2D

@export var shaft_left: float = 0.0
@export var shaft_right: float = 1100.0
@export var y_top: float = -3400.0
@export var floor_y: float = 600.0
@export var seed_value: int = 5150

const STONE := Color(0.075, 0.095, 0.105)
const STEEL := Color(0.17, 0.2, 0.26)
const STEEL_LIGHT := Color(0.3, 0.36, 0.44)
const STEEL_DARK := Color(0.07, 0.085, 0.11)
const GLASS := Color(0.07, 0.18, 0.16)
const GHOST := Color(0.55, 0.95, 0.8)
const BLOOD := Color(0.36, 0.04, 0.06)
const BRICK_W := 56.0
const BRICK_H := 28.0
const WINDOW_SPACING := 520.0
const BAND_H := 644.0
const DYN_STEP := 1.0 / 30.0

var _bands: Array = []
var _time := 0.0
var _acc := 0.0
var _windows: Array = []
var _lanterns: Array = []
var _banners: Array = []
var _chains: Array = []
var _eyes: Array = []
var _wisps: Array = []
var _webs: Array = []
var _stains: Array = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var k := 0
	var y := floor_y - 260.0
	while y > y_top:
		var on_left := k % 2 == 0
		_windows.append(Vector2(shaft_left + 190.0 if on_left else shaft_right - 190.0, y))
		_lanterns.append(Vector2(shaft_left + 78.0 if not on_left else shaft_right - 78.0, y + 120.0))
		y -= WINDOW_SPACING
		k += 1
	var by := floor_y - 520.0
	var bi := 0
	while by > y_top:
		_banners.append(Vector2(lerpf(shaft_left + 260.0, shaft_right - 260.0, 0.5 + 0.34 * (1.0 if bi % 2 == 0 else -1.0)), by))
		_chains.append({"p": Vector2(lerpf(shaft_left + 180.0, shaft_right - 180.0, 0.5 + 0.36 * (-1.0 if bi % 2 == 0 else 1.0)), by), "cage": bi % 2 == 0})
		by -= 880.0
		bi += 1
	var ey := floor_y - 300.0
	while ey > y_top:
		var left := rng.randf() < 0.5
		_eyes.append({"p": Vector2(shaft_left + 108.0 if left else shaft_right - 108.0, ey + rng.randf_range(-60.0, 60.0)), "ph": rng.randf() * 10.0, "r": rng.randf_range(0.8, 1.2)})
		ey -= rng.randf_range(360.0, 700.0)
	var wy := floor_y - 400.0
	while wy > y_top:
		_wisps.append({"p": Vector2(rng.randf_range(shaft_left + 220.0, shaft_right - 220.0), wy), "ph": rng.randf() * TAU, "amp": rng.randf_range(50.0, 110.0)})
		wy -= rng.randf_range(500.0, 780.0)
	var gy := floor_y - 520.0
	while gy > y_top:
		_webs.append({"p": Vector2(shaft_left, gy + 24.0), "s": 1.0, "size": rng.randf_range(90.0, 150.0)})
		_webs.append({"p": Vector2(shaft_right, gy + 24.0), "s": -1.0, "size": rng.randf_range(90.0, 150.0)})
		gy -= 520.0
	var sy := y_top + 120.0
	while sy < floor_y - 200.0:
		_stains.append({"x": rng.randf_range(shaft_left + 150.0, shaft_right - 150.0), "y": sy, "len": rng.randf_range(60.0, 220.0), "w": rng.randf_range(4.0, 9.0)})
		sy += rng.randf_range(260.0, 520.0)
	var origin_y := y_top - BRICK_H * 11.0
	var bottom := floor_y + 400.0
	var count := int(ceil((bottom - origin_y) / BAND_H))
	for i in count:
		var y0 := origin_y + i * BAND_H
		var y1 := y0 + BAND_H
		var back := _make_layer(-20, false)
		back.draw.connect(_draw_static.bind(back, y0, y1, i))
		var dyn := _make_layer(-15, false)
		dyn.draw.connect(_draw_dynamic.bind(dyn, y0, y1))
		var add := _make_layer(-14, true)
		add.draw.connect(_draw_glow.bind(add, y0, y1))
		_bands.append({"y0": y0, "y1": y1, "dyn": dyn, "add": add})


func _make_layer(z: int, additive: bool) -> Node2D:
	var n := Node2D.new()
	n.z_index = z
	n.z_as_relative = false
	if additive:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		n.material = mat
	add_child(n)
	return n


func _process(delta: float) -> void:
	_time += delta
	_acc += delta
	if _acc < DYN_STEP:
		return
	_acc = 0.0
	var view: Rect2 = get_viewport().get_canvas_transform().affine_inverse() * get_viewport_rect()
	for b in _bands:
		if float(b["y1"]) + 420.0 < view.position.y or float(b["y0"]) - 420.0 > view.end.y:
			continue
		(b["dyn"] as Node2D).queue_redraw()
		(b["add"] as Node2D).queue_redraw()


func _in_band(y: float, y0: float, y1: float) -> bool:
	return y >= y0 and y < y1


func _draw_static(n: Node2D, y0: float, y1: float, index: int) -> void:
	var x_min := shaft_left - 900.0
	var x_max := shaft_right + 900.0
	n.draw_rect(Rect2(x_min, y0, x_max - x_min, y1 - y0 + 1.0), Color(0.02, 0.025, 0.04))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + index
	var y := maxf(y0, y_top)
	var row := int(round((y - y_top) / BRICK_H))
	while y < minf(y1, floor_y + 60.0):
		var x := shaft_left - (BRICK_W * 0.5 if row % 2 == 1 else 0.0)
		while x < shaft_right:
			var s := rng.randf_range(-0.014, 0.016)
			var moss := rng.randf() < 0.07
			var c := Color(STONE.r + s, STONE.g + s, STONE.b + s)
			if moss:
				c = Color(0.05 + s, 0.11 + s, 0.08 + s)
			n.draw_rect(Rect2(x + 1.5, y + 1.5, BRICK_W - 3.0, BRICK_H - 3.0), c)
			if rng.randf() < 0.18:
				n.draw_rect(Rect2(x + 3.0, y + 3.0, BRICK_W - 8.0, 3.0), Color(1, 1, 1, 0.02))
			if rng.randf() < 0.05:
				n.draw_line(Vector2(x + rng.randf_range(8.0, 40.0), y + 2.0), Vector2(x + rng.randf_range(8.0, 40.0), y + BRICK_H - 2.0), Color(0, 0, 0, 0.55), 1.5)
			x += BRICK_W
		y += BRICK_H
		row += 1
	var seg_top := maxf(y0, y_top)
	var seg_bottom := minf(y1, floor_y)
	if seg_bottom > seg_top:
		var seg_h := seg_bottom - seg_top
		for side in [0, 1]:
			var px := shaft_left + 48.0 if side == 0 else shaft_right - 48.0
			n.draw_rect(Rect2(px - 17.0, seg_top, 34.0, seg_h), STEEL_DARK)
			n.draw_rect(Rect2(px - 17.0, seg_top, 7.0, seg_h), STEEL)
			n.draw_rect(Rect2(px + 10.0, seg_top, 7.0, seg_h), Color(0.03, 0.04, 0.07))
			var cy := floor_y - 140.0
			while cy > y_top:
				if _in_band(cy, y0, y1):
					n.draw_rect(Rect2(px - 26.0, cy, 52.0, 18.0), STEEL_DARK)
					n.draw_rect(Rect2(px - 26.0, cy, 52.0, 3.0), STEEL_LIGHT)
				cy -= 360.0
		var edge := Color(0, 0, 0, 0.82)
		var clear := Color(0, 0, 0, 0.0)
		n.draw_polygon(PackedVector2Array([Vector2(shaft_left, seg_top), Vector2(shaft_left + 200.0, seg_top), Vector2(shaft_left + 200.0, seg_bottom), Vector2(shaft_left, seg_bottom)]),
			PackedColorArray([edge, clear, clear, edge]))
		n.draw_polygon(PackedVector2Array([Vector2(shaft_right - 200.0, seg_top), Vector2(shaft_right, seg_top), Vector2(shaft_right, seg_bottom), Vector2(shaft_right - 200.0, seg_bottom)]),
			PackedColorArray([clear, edge, edge, clear]))
	for st in _stains:
		var sp: Dictionary = st
		if not _in_band(float(sp["y"]), y0, y1):
			continue
		var sx: float = sp["x"]
		var sy: float = sp["y"]
		var length: float = sp["len"]
		var w: float = sp["w"]
		n.draw_rect(Rect2(sx - w * 0.5, sy, w, length), Color(BLOOD, 0.55))
		n.draw_rect(Rect2(sx - w * 0.2, sy, w * 0.4, length), Color(BLOOD.lightened(0.15), 0.35))
		n.draw_circle(Vector2(sx, sy + length), w * 0.85, Color(BLOOD, 0.6))
		n.draw_circle(Vector2(sx, sy), w * 1.5, Color(BLOOD, 0.3))
	var gy := floor_y - 520.0
	while gy > y_top:
		if _in_band(gy, y0, y1):
			n.draw_rect(Rect2(shaft_left, gy, shaft_right - shaft_left, 24.0), STEEL_DARK)
			n.draw_rect(Rect2(shaft_left, gy, shaft_right - shaft_left, 4.0), STEEL)
			var rx := shaft_left + 40.0
			while rx < shaft_right:
				n.draw_circle(Vector2(rx, gy + 12.0), 2.4, Color(1, 1, 1, 0.16))
				rx += 70.0
			for bx in [shaft_left + 280.0, shaft_left + 820.0]:
				n.draw_line(Vector2(bx, gy + 24.0), Vector2(bx + 80.0, gy + 90.0), STEEL_DARK, 8.0)
				n.draw_line(Vector2(bx, gy + 24.0), Vector2(bx - 80.0, gy + 90.0), STEEL_DARK, 8.0)
		gy -= 520.0
	for w in _windows:
		var wp: Vector2 = w
		if not _in_band(wp.y, y0, y1):
			continue
		n.draw_rect(Rect2(wp.x - 46.0, wp.y - 8.0, 92.0, 180.0), STEEL_DARK)
		n.draw_circle(Vector2(wp.x, wp.y - 8.0), 46.0, STEEL_DARK)
		n.draw_rect(Rect2(wp.x - 36.0, wp.y - 6.0, 72.0, 172.0), GLASS)
		n.draw_circle(Vector2(wp.x, wp.y - 6.0), 36.0, GLASS)
		n.draw_rect(Rect2(wp.x - 2.0, wp.y - 40.0, 4.0, 206.0), STEEL_DARK)
		n.draw_rect(Rect2(wp.x - 36.0, wp.y + 60.0, 72.0, 4.0), STEEL_DARK)
		n.draw_line(Vector2(wp.x - 30.0, wp.y + 20.0), Vector2(wp.x + 8.0, wp.y + 70.0), Color(0, 0, 0, 0.7), 2.0)
		n.draw_line(Vector2(wp.x + 8.0, wp.y + 70.0), Vector2(wp.x + 2.0, wp.y + 120.0), Color(0, 0, 0, 0.7), 2.0)
	for e in _eyes:
		var ep: Dictionary = e
		var pos: Vector2 = ep["p"]
		if not _in_band(pos.y, y0, y1):
			continue
		n.draw_rect(Rect2(pos.x - 34.0, pos.y - 22.0, 68.0, 44.0), Color(0, 0, 0, 0.88))
		n.draw_circle(Vector2(pos.x, pos.y - 22.0), 34.0, Color(0, 0, 0, 0.88))
	for wb in _webs:
		var wd: Dictionary = wb
		var wpos: Vector2 = wd["p"]
		if not _in_band(wpos.y, y0, y1):
			continue
		_draw_web(n, wpos, float(wd["s"]), float(wd["size"]))


func _draw_web(n: Node2D, p: Vector2, s: float, size: float) -> void:
	var col := Color(0.8, 0.85, 0.85, 0.32)
	var rays := 5
	for i in rays:
		var a := lerpf(0.0, PI * 0.5, float(i) / (rays - 1))
		var end := p + Vector2(cos(a) * s, sin(a)) * size
		n.draw_line(p, end, col, 1.0)
	for ring in 4:
		var r := size * (0.25 + 0.25 * ring)
		var pts := PackedVector2Array()
		for i in rays:
			var a := lerpf(0.0, PI * 0.5, float(i) / (rays - 1))
			var sag := 1.0 - 0.1 * sin(float(i) * 1.7 + ring)
			pts.append(p + Vector2(cos(a) * s, sin(a)) * r * sag)
		n.draw_polyline(pts, col, 1.0)


func _draw_dynamic(n: Node2D, y0: float, y1: float) -> void:
	for c in _chains:
		var cd: Dictionary = c
		var cp: Vector2 = cd["p"]
		if not _in_band(cp.y, y0, y1):
			continue
		var yy := cp.y + 24.0
		var i := 0
		var sway_end := 0.0
		while yy < cp.y + 280.0:
			var t := (yy - cp.y) / 280.0
			var sway := sin(_time * 0.9 + cp.x * 0.01) * 8.0 * t
			sway_end = sway
			var p := Vector2(cp.x + sway, yy)
			if i % 2 == 0:
				n.draw_arc(p, 5.0, 0.0, TAU, 8, Color(0.42, 0.42, 0.5), 2.4)
			else:
				n.draw_line(p + Vector2(-5.0, 0.0), p + Vector2(5.0, 0.0), Color(0.32, 0.33, 0.4), 3.0)
			yy += 15.0
			i += 1
		if bool(cd["cage"]):
			_draw_cage(n, Vector2(cp.x + sway_end, cp.y + 290.0))
		else:
			_draw_shackle(n, Vector2(cp.x + sway_end, cp.y + 290.0))
	for b in _banners:
		var bp: Vector2 = b
		if not _in_band(bp.y, y0, y1):
			continue
		var sway := sin(_time * 0.7 + bp.x * 0.02) * 10.0
		n.draw_rect(Rect2(bp.x - 36.0, bp.y + 24.0, 72.0, 6.0), STEEL_LIGHT)
		n.draw_colored_polygon(PackedVector2Array([
			Vector2(bp.x - 32.0, bp.y + 30.0), Vector2(bp.x + 32.0, bp.y + 30.0),
			Vector2(bp.x + 32.0 + sway * 0.4, bp.y + 150.0), Vector2(bp.x + 18.0 + sway * 0.6, bp.y + 176.0), Vector2(bp.x + 6.0 + sway * 0.7, bp.y + 150.0),
			Vector2(bp.x - 4.0 + sway * 0.8, bp.y + 214.0), Vector2(bp.x - 16.0 + sway * 0.6, bp.y + 160.0), Vector2(bp.x - 32.0 + sway * 0.4, bp.y + 190.0),
		]), Color(0.2, 0.04, 0.07))
		var sk := Vector2(bp.x + sway * 0.25, bp.y + 84.0)
		n.draw_circle(sk, 14.0, Color(0.72, 0.72, 0.66, 0.85))
		n.draw_rect(Rect2(sk + Vector2(-8.0, 8.0), Vector2(16.0, 10.0)), Color(0.72, 0.72, 0.66, 0.85))
		n.draw_circle(sk + Vector2(-5.0, -1.0), 3.6, Color(0.05, 0.02, 0.03))
		n.draw_circle(sk + Vector2(5.0, -1.0), 3.6, Color(0.05, 0.02, 0.03))
		n.draw_line(sk + Vector2(-4.0, 13.0), sk + Vector2(-4.0, 18.0), Color(0.05, 0.02, 0.03), 1.5)
		n.draw_line(sk + Vector2(0.0, 13.0), sk + Vector2(0.0, 18.0), Color(0.05, 0.02, 0.03), 1.5)
		n.draw_line(sk + Vector2(4.0, 13.0), sk + Vector2(4.0, 18.0), Color(0.05, 0.02, 0.03), 1.5)
	for l in _lanterns:
		var lp: Vector2 = l
		if not _in_band(lp.y, y0, y1):
			continue
		var flicker := _lantern_flicker(lp)
		n.draw_line(lp + Vector2(0, -18.0), lp + Vector2(0, -2.0), Color(0.25, 0.27, 0.32), 3.0)
		n.draw_rect(Rect2(lp + Vector2(-12.0, -2.0), Vector2(24.0, 32.0)), Color(0.05, 0.06, 0.08))
		n.draw_rect(Rect2(lp + Vector2(-8.0, 2.0), Vector2(16.0, 24.0)), Color(0.35, 0.95, 0.65, flicker))
		n.draw_rect(Rect2(lp + Vector2(-8.0, 2.0), Vector2(5.0, 24.0)), Color(0.8, 1.0, 0.9, 0.55 * flicker))


func _lantern_flicker(lp: Vector2) -> float:
	var f := 0.55 + 0.45 * absf(sin(_time * 3.7 + lp.y * 0.05))
	if sin(_time * 1.3 + lp.y) > 0.93:
		f *= 0.2
	return f


func _draw_cage(n: Node2D, p: Vector2) -> void:
	var w := 34.0
	var h := 62.0
	n.draw_rect(Rect2(p + Vector2(-w, 0.0), Vector2(w * 2.0, h)), Color(0, 0, 0, 0.45))
	var skull := p + Vector2(0.0, h * 0.62)
	n.draw_circle(skull, 11.0, Color(0.7, 0.7, 0.64, 0.8))
	n.draw_circle(skull + Vector2(-4.0, -1.0), 3.0, Color(0.03, 0.02, 0.03))
	n.draw_circle(skull + Vector2(4.0, -1.0), 3.0, Color(0.03, 0.02, 0.03))
	n.draw_line(p + Vector2(-w, 0.0), p + Vector2(0.0, -16.0), Color(0.3, 0.3, 0.36), 2.0)
	n.draw_line(p + Vector2(w, 0.0), p + Vector2(0.0, -16.0), Color(0.3, 0.3, 0.36), 2.0)
	n.draw_rect(Rect2(p + Vector2(-w, 0.0), Vector2(w * 2.0, 4.0)), Color(0.28, 0.28, 0.34))
	n.draw_rect(Rect2(p + Vector2(-w, h), Vector2(w * 2.0, 5.0)), Color(0.28, 0.28, 0.34))
	var i := 0
	while i <= 6:
		var bx := -w + i * (w * 2.0 / 6.0)
		n.draw_line(p + Vector2(bx, 0.0), p + Vector2(bx, h), Color(0.34, 0.34, 0.4), 2.0)
		i += 1


func _draw_shackle(n: Node2D, p: Vector2) -> void:
	n.draw_arc(p + Vector2(0.0, 8.0), 9.0, 0.0, TAU, 12, Color(0.4, 0.4, 0.46), 3.0)
	n.draw_line(p + Vector2(-9.0, 8.0), p + Vector2(-16.0, 34.0), Color(0.34, 0.34, 0.4), 3.0)
	n.draw_line(p + Vector2(9.0, 8.0), p + Vector2(16.0, 34.0), Color(0.34, 0.34, 0.4), 3.0)
	n.draw_arc(p + Vector2(-16.0, 40.0), 8.0, 0.0, TAU, 10, Color(0.4, 0.4, 0.46), 3.0)
	n.draw_arc(p + Vector2(16.0, 40.0), 8.0, 0.0, TAU, 10, Color(0.4, 0.4, 0.46), 3.0)


func _draw_glow(n: Node2D, y0: float, y1: float) -> void:
	for w in _windows:
		var wp: Vector2 = w
		if not _in_band(wp.y, y0, y1):
			continue
		var drift := 0.5 + 0.5 * sin(_time * 0.5 + wp.y * 0.01)
		var dir := 1.0 if wp.x < (shaft_left + shaft_right) / 2.0 else -1.0
		var pulse := 0.12 + 0.05 * drift
		if sin(_time * 0.9 + wp.y * 0.7) > 0.96:
			pulse *= 0.3
		n.draw_polygon(
			PackedVector2Array([Vector2(wp.x - 30.0, wp.y), Vector2(wp.x + 30.0, wp.y), Vector2(wp.x + dir * 330.0 + 80.0, wp.y + 380.0), Vector2(wp.x + dir * 330.0 - 120.0, wp.y + 380.0)]),
			PackedColorArray([Color(GHOST, pulse), Color(GHOST, pulse), Color(GHOST, 0.0), Color(GHOST, 0.0)]))
		n.draw_circle(Vector2(wp.x, wp.y + 60.0), 60.0, Color(GHOST, 0.05))
	for l in _lanterns:
		var lp: Vector2 = l + Vector2(0.0, 14.0)
		if not _in_band(lp.y, y0, y1):
			continue
		var flicker := _lantern_flicker(lp)
		n.draw_circle(lp, 74.0, Color(0.35, 0.95, 0.65, 0.07 * flicker))
		n.draw_circle(lp, 30.0, Color(0.5, 1.0, 0.8, 0.14 * flicker))
	for e in _eyes:
		var ed: Dictionary = e
		var pos: Vector2 = ed["p"]
		if not _in_band(pos.y, y0, y1):
			continue
		var cycle := fposmod(_time * 0.18 + float(ed["ph"]), 1.0)
		if cycle > 0.62:
			continue
		var open := smoothstep(0.0, 0.05, cycle) * (1.0 - smoothstep(0.58, 0.62, cycle))
		var r: float = ed["r"]
		for sx in [-1.0, 1.0]:
			var ep := pos + Vector2(sx * 11.0 * r, -2.0)
			n.draw_circle(ep, 9.0 * r, Color(1.0, 0.1, 0.1, 0.12 * open))
			n.draw_circle(ep, 3.4 * r, Color(1.0, 0.25, 0.2, 0.95 * open))
	for wsp in _wisps:
		var wd: Dictionary = wsp
		var base: Vector2 = wd["p"]
		if not _in_band(base.y, y0, y1):
			continue
		var ph: float = wd["ph"]
		var amp: float = wd["amp"]
		var pos := base + Vector2(sin(_time * 0.35 + ph) * amp, sin(_time * 0.6 + ph * 1.7) * amp * 0.5)
		var bob := 0.6 + 0.4 * sin(_time * 1.8 + ph)
		n.draw_circle(pos, 26.0, Color(GHOST, 0.05 * bob))
		n.draw_circle(pos, 11.0, Color(GHOST, 0.16 * bob))
		n.draw_circle(pos, 4.0, Color(0.9, 1.0, 0.95, 0.8 * bob))
		for t in 5:
			var tp := pos - Vector2(cos(_time * 0.35 + ph) * amp * 0.1, -6.0) * float(t + 1) * 0.8 + Vector2(0.0, float(t) * 7.0)
			n.draw_circle(tp, 3.2 - 0.5 * t, Color(GHOST, 0.12 * bob * (1.0 - t * 0.18)))
