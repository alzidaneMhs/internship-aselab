extends Node2D

@export var shaft_left: float = 0.0
@export var shaft_right: float = 1100.0
@export var y_top: float = -3400.0
@export var floor_y: float = 600.0

const STEEL := Color(0.2, 0.26, 0.5)
const STEEL_LIGHT := Color(0.36, 0.44, 0.72)
const STEEL_DARK := Color(0.1, 0.13, 0.26)
const BRICK_W := 56.0
const BRICK_H := 28.0
const WINDOW_SPACING := 440.0

var _back: Node2D
var _dyn: Node2D
var _add: Node2D
var _time := 0.0
var _windows: Array = []
var _lanterns: Array = []
var _banners: Array = []
var _chains: Array = []


func _ready() -> void:
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
		_chains.append(Vector2(lerpf(shaft_left + 180.0, shaft_right - 180.0, 0.5 + 0.36 * (-1.0 if bi % 2 == 0 else 1.0)), by))
		by -= 880.0
		bi += 1
	_back = _make_layer(-20, false)
	_back.draw.connect(_draw_static)
	_dyn = _make_layer(-15, false)
	_dyn.draw.connect(_draw_dynamic)
	_add = _make_layer(-14, true)
	_add.draw.connect(_draw_glow)


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
	_dyn.queue_redraw()
	_add.queue_redraw()


func _draw_static() -> void:
	var bottom := floor_y + 400.0
	var x_min := shaft_left - 900.0
	var x_max := shaft_right + 900.0
	_back.draw_rect(Rect2(x_min, y_top - 300.0, x_max - x_min, bottom - y_top + 300.0), Color(0.03, 0.035, 0.07))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5150
	var y := y_top
	var row := 0
	while y < floor_y + 60.0:
		var x := shaft_left - (BRICK_W * 0.5 if row % 2 == 1 else 0.0)
		while x < shaft_right:
			var s := rng.randf_range(-0.012, 0.016)
			_back.draw_rect(Rect2(x + 1.5, y + 1.5, BRICK_W - 3.0, BRICK_H - 3.0), Color(0.085 + s, 0.1 + s, 0.16 + s))
			if rng.randf() < 0.2:
				_back.draw_rect(Rect2(x + 3.0, y + 3.0, BRICK_W - 8.0, 3.0), Color(1, 1, 1, 0.025))
			x += BRICK_W
		y += BRICK_H
		row += 1
	for side in [0, 1]:
		var px := shaft_left + 48.0 if side == 0 else shaft_right - 48.0
		_back.draw_rect(Rect2(px - 17.0, y_top, 34.0, floor_y - y_top), STEEL_DARK)
		_back.draw_rect(Rect2(px - 17.0, y_top, 7.0, floor_y - y_top), STEEL)
		_back.draw_rect(Rect2(px + 10.0, y_top, 7.0, floor_y - y_top), Color(0.04, 0.05, 0.12))
		var cy := floor_y - 140.0
		while cy > y_top:
			_back.draw_rect(Rect2(px - 26.0, cy, 52.0, 18.0), STEEL_DARK)
			_back.draw_rect(Rect2(px - 26.0, cy, 52.0, 3.0), STEEL_LIGHT)
			cy -= 360.0
	var gy := floor_y - 520.0
	while gy > y_top:
		_back.draw_rect(Rect2(shaft_left, gy, shaft_right - shaft_left, 24.0), STEEL_DARK)
		_back.draw_rect(Rect2(shaft_left, gy, shaft_right - shaft_left, 4.0), STEEL)
		var rx := shaft_left + 40.0
		while rx < shaft_right:
			_back.draw_circle(Vector2(rx, gy + 12.0), 2.4, Color(1, 1, 1, 0.22))
			rx += 70.0
		for bx in [shaft_left + 280.0, shaft_left + 820.0]:
			_back.draw_line(Vector2(bx, gy + 24.0), Vector2(bx + 80.0, gy + 90.0), STEEL_DARK, 8.0)
			_back.draw_line(Vector2(bx, gy + 24.0), Vector2(bx - 80.0, gy + 90.0), STEEL_DARK, 8.0)
		gy -= 520.0
	for w in _windows:
		var wp: Vector2 = w
		_back.draw_rect(Rect2(wp.x - 46.0, wp.y - 8.0, 92.0, 180.0), STEEL_DARK)
		_back.draw_circle(Vector2(wp.x, wp.y - 8.0), 46.0, STEEL_DARK)
		_back.draw_rect(Rect2(wp.x - 36.0, wp.y - 6.0, 72.0, 172.0), Color(0.12, 0.2, 0.42))
		_back.draw_circle(Vector2(wp.x, wp.y - 6.0), 36.0, Color(0.12, 0.2, 0.42))
		_back.draw_rect(Rect2(wp.x - 2.0, wp.y - 40.0, 4.0, 206.0), STEEL_DARK)
		_back.draw_rect(Rect2(wp.x - 36.0, wp.y + 60.0, 72.0, 4.0), STEEL_DARK)
	var edge := Color(0, 0, 0, 0.7)
	var clear := Color(0, 0, 0, 0.0)
	_back.draw_polygon(PackedVector2Array([Vector2(shaft_left, y_top), Vector2(shaft_left + 180.0, y_top), Vector2(shaft_left + 180.0, floor_y), Vector2(shaft_left, floor_y)]),
		PackedColorArray([edge, clear, clear, edge]))
	_back.draw_polygon(PackedVector2Array([Vector2(shaft_right - 180.0, y_top), Vector2(shaft_right, y_top), Vector2(shaft_right, floor_y), Vector2(shaft_right - 180.0, floor_y)]),
		PackedColorArray([clear, edge, edge, clear]))


func _draw_dynamic() -> void:
	for c in _chains:
		var cp: Vector2 = c
		var yy := cp.y + 24.0
		var i := 0
		while yy < cp.y + 280.0:
			var t := (yy - cp.y) / 280.0
			var sway := sin(_time * 0.9 + cp.x * 0.01) * 8.0 * t
			var p := Vector2(cp.x + sway, yy)
			if i % 2 == 0:
				_dyn.draw_arc(p, 5.0, 0.0, TAU, 8, Color(0.5, 0.52, 0.62), 2.4)
			else:
				_dyn.draw_line(p + Vector2(-5.0, 0.0), p + Vector2(5.0, 0.0), Color(0.4, 0.42, 0.52), 3.0)
			yy += 15.0
			i += 1
	for b in _banners:
		var bp: Vector2 = b
		var sway := sin(_time * 0.7 + bp.x * 0.02) * 10.0
		_dyn.draw_rect(Rect2(bp.x - 36.0, bp.y + 24.0, 72.0, 6.0), STEEL_LIGHT)
		_dyn.draw_colored_polygon(PackedVector2Array([
			Vector2(bp.x - 32.0, bp.y + 30.0), Vector2(bp.x + 32.0, bp.y + 30.0),
			Vector2(bp.x + 32.0 + sway * 0.4, bp.y + 190.0), Vector2(bp.x + sway, bp.y + 224.0), Vector2(bp.x - 32.0 + sway * 0.4, bp.y + 190.0),
		]), Color(0.1, 0.22, 0.38))
		_dyn.draw_colored_polygon(PackedVector2Array([
			Vector2(bp.x + sway * 0.2, bp.y + 80.0), Vector2(bp.x + 16.0 + sway * 0.25, bp.y + 108.0),
			Vector2(bp.x + sway * 0.3, bp.y + 136.0), Vector2(bp.x - 16.0 + sway * 0.25, bp.y + 108.0),
		]), Color(1.0, 0.725, 0.22, 0.85))
	for l in _lanterns:
		var lp: Vector2 = l
		var flicker := 0.85 + 0.15 * sin(_time * 11.0 + lp.y * 0.05)
		_dyn.draw_line(lp + Vector2(0, -18.0), lp + Vector2(0, -2.0), Color(0.3, 0.3, 0.38), 3.0)
		_dyn.draw_rect(Rect2(lp + Vector2(-12.0, -2.0), Vector2(24.0, 32.0)), Color(0.08, 0.08, 0.12))
		_dyn.draw_rect(Rect2(lp + Vector2(-8.0, 2.0), Vector2(16.0, 24.0)), Color(1.0, 0.78, 0.4, flicker))
		_dyn.draw_rect(Rect2(lp + Vector2(-8.0, 2.0), Vector2(5.0, 24.0)), Color(1.0, 0.95, 0.75, 0.6 * flicker))


func _draw_glow() -> void:
	for w in _windows:
		var wp: Vector2 = w
		var drift := 0.5 + 0.5 * sin(_time * 0.5 + wp.y * 0.01)
		var dir := 1.0 if wp.x < (shaft_left + shaft_right) / 2.0 else -1.0
		_add.draw_polygon(
			PackedVector2Array([Vector2(wp.x - 30.0, wp.y), Vector2(wp.x + 30.0, wp.y), Vector2(wp.x + dir * 330.0 + 80.0, wp.y + 380.0), Vector2(wp.x + dir * 330.0 - 120.0, wp.y + 380.0)]),
			PackedColorArray([Color(0.5, 0.8, 1.0, 0.16 + 0.05 * drift), Color(0.5, 0.8, 1.0, 0.16 + 0.05 * drift), Color(0.5, 0.8, 1.0, 0.0), Color(0.5, 0.8, 1.0, 0.0)]))
		_add.draw_circle(Vector2(wp.x, wp.y + 60.0), 60.0, Color(0.5, 0.8, 1.0, 0.06))
	for l in _lanterns:
		var lp: Vector2 = l + Vector2(0.0, 14.0)
		var flicker := 0.85 + 0.15 * sin(_time * 11.0 + lp.y * 0.05)
		_add.draw_circle(lp, 74.0, Color(1.0, 0.75, 0.4, 0.08 * flicker))
		_add.draw_circle(lp, 30.0, Color(1.0, 0.8, 0.5, 0.15 * flicker))
