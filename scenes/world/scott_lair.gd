extends Node2D

## Scott's lair: a dark brick hall, drawn entirely in code. Blue steel pillars with
## dark caps, hanging lanterns throwing cones of light on the wall, swaying chains,
## a central cross-braced structure, ceiling rocket hatches that flash when Scott
## launches his barrage, and two big monitors that keep Isme in their crosshair.
## Everything sits behind the platforms and the fight.

@export var x_min: float = -900.0
@export var x_max: float = 3000.0
@export var floor_y: float = 600.0
@export var ceiling_y: float = -240.0
@export var arena_left: float = 400.0
@export var arena_right: float = 2600.0

const BRICK_W := 56.0
const BRICK_H := 28.0
const STEEL := Color(0.2, 0.26, 0.5)
const STEEL_LIGHT := Color(0.36, 0.44, 0.72)
const STEEL_DARK := Color(0.1, 0.13, 0.28)

var _back: Node2D
var _dyn: Node2D
var _add: Node2D
var _time := 0.0
var _alert := 0.0
var _power := 1.0      # 1 = lit, 0 = dead (the power-down at Scott's defeat)
var _lost := 0.0       # 1 = the monitors have lost their target
var _flicker := 0.0    # > 0 = lights stutter (power coming on)
var _pillars: Array = []
var _hatches: Array = []
var _lamps: Array = []


func _ready() -> void:
	add_to_group("scott_lair")
	var mid := (arena_left + arena_right) / 2.0
	var span := arena_right - arena_left
	for i in 5:
		_pillars.append(arena_left + span * i / 4.0)
	for i in 5:
		_hatches.append(mid + (i - 2) * span / 5.0)
	for px in _pillars:
		_lamps.append(Vector2(px, floor_y - 262.0))
	_lamps.append(Vector2(mid - 120.0, floor_y - 170.0))
	_lamps.append(Vector2(mid + 120.0, floor_y - 170.0))

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


## Called by Scott when the rocket barrage starts: hatch lights blink red.
func set_alert(duration: float) -> void:
	_alert = duration


## The monitors lose their target ("lost") - used when Scott falls.
func set_mode(mode: String) -> void:
	if mode == "lost":
		create_tween().tween_property(self, "_lost", 1.0, 0.5)


## Lanterns and monitors fade to black.
func power_down(duration: float) -> void:
	create_tween().tween_property(self, "_power", 0.0, duration)


## Lights and monitors stutter on (Scott's entrance).
func power_on() -> void:
	_flicker = 1.4


func _lamp_power() -> float:
	if _flicker > 0.0:
		return _power * (1.0 if sin(_time * 70.0) > 0.0 else 0.25)
	return _power


func _process(delta: float) -> void:
	_time += delta
	_alert = maxf(_alert - delta, 0.0)
	_flicker = maxf(_flicker - delta, 0.0)
	_dyn.queue_redraw()
	_add.queue_redraw()


# --- Static: wall, ceiling, pillars --------------------------------------------------

func _draw_static() -> void:
	var top := ceiling_y - 220.0
	var bottom := floor_y + 360.0
	var width := x_max - x_min
	_back.draw_rect(Rect2(x_min, top, width, bottom - top), Color(0.07, 0.065, 0.08))

	# Brick wall.
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210
	var y := ceiling_y
	var row := 0
	while y < floor_y + 40.0:
		var x := x_min - (BRICK_W * 0.5 if row % 2 == 1 else 0.0)
		while x < x_max:
			var s := rng.randf_range(-0.014, 0.016)
			var c := Color(0.118 + s, 0.108 + s, 0.128 + s)
			_back.draw_rect(Rect2(x + 1.5, y + 1.5, BRICK_W - 3.0, BRICK_H - 3.0), c)
			if rng.randf() < 0.25:
				_back.draw_rect(Rect2(x + 3.0, y + 3.0, BRICK_W - 8.0, 3.0), Color(1, 1, 1, 0.025))
			x += BRICK_W
		y += BRICK_H
		row += 1

	# Dark ceiling with steel girders and ribs.
	_back.draw_rect(Rect2(x_min, top, width, ceiling_y - top), Color(0.045, 0.045, 0.06))
	_back.draw_rect(Rect2(x_min, ceiling_y - 38.0, width, 38.0), STEEL_DARK)
	_back.draw_rect(Rect2(x_min, ceiling_y - 38.0, width, 4.0), STEEL)
	_back.draw_rect(Rect2(x_min, ceiling_y - 4.0, width, 4.0), Color(0, 0, 0, 0.5))
	var rx := x_min + 120.0
	while rx < x_max:
		_back.draw_rect(Rect2(rx, ceiling_y, 24.0, 64.0), STEEL_DARK)
		_back.draw_rect(Rect2(rx, ceiling_y, 4.0, 64.0), STEEL)
		_back.draw_colored_polygon(PackedVector2Array([
			Vector2(rx - 22.0, ceiling_y), Vector2(rx + 46.0, ceiling_y), Vector2(rx + 24.0, ceiling_y + 64.0), Vector2(rx, ceiling_y + 64.0),
		]), Color(0.08, 0.1, 0.2, 0.7))
		rx += 380.0

	# Wainscot band along the bottom of the wall.
	_back.draw_rect(Rect2(x_min, floor_y - 26.0, width, 26.0), Color(0.06, 0.055, 0.075))
	_back.draw_rect(Rect2(x_min, floor_y - 26.0, width, 3.0), Color(0.3, 0.3, 0.4, 0.4))

	for px in _pillars:
		_draw_pillar(px, ceiling_y + 38.0, 48.0, true)
	_draw_centerpiece()

	# Dark vignette at both ends.
	var edge := Color(0, 0, 0, 0.75)
	var clear := Color(0, 0, 0, 0.0)
	_back.draw_polygon(PackedVector2Array([Vector2(x_min, top), Vector2(x_min + 520.0, top), Vector2(x_min + 520.0, bottom), Vector2(x_min, bottom)]),
		PackedColorArray([edge, clear, clear, edge]))
	_back.draw_polygon(PackedVector2Array([Vector2(x_max - 520.0, top), Vector2(x_max, top), Vector2(x_max, bottom), Vector2(x_max - 520.0, bottom)]),
		PackedColorArray([clear, edge, edge, clear]))


func _draw_pillar(px: float, top_y: float, w: float, with_cap: bool) -> void:
	var h := floor_y - top_y
	_back.draw_rect(Rect2(px - w / 2.0, top_y, w, h), STEEL)
	_back.draw_rect(Rect2(px - w / 2.0, top_y, w * 0.28, h), STEEL_LIGHT)
	_back.draw_rect(Rect2(px + w * 0.28, top_y, w * 0.22, h), STEEL_DARK)
	var ry := top_y + 30.0
	while ry < floor_y - 40.0:
		_back.draw_circle(Vector2(px - w * 0.32, ry), 2.2, Color(1, 1, 1, 0.22))
		_back.draw_circle(Vector2(px + w * 0.32, ry), 2.2, Color(0, 0, 0, 0.35))
		ry += 90.0
	_back.draw_rect(Rect2(px - w * 0.8, floor_y - 40.0, w * 1.6, 40.0), STEEL_DARK)
	_back.draw_rect(Rect2(px - w * 0.8, floor_y - 40.0, w * 1.6, 4.0), STEEL)
	if with_cap:
		# Dark trapezoid ledge with a lantern hanging underneath.
		var cy := floor_y - 300.0
		_back.draw_colored_polygon(PackedVector2Array([
			Vector2(px - 86.0, cy), Vector2(px + 86.0, cy), Vector2(px + 56.0, cy + 18.0), Vector2(px - 56.0, cy + 18.0),
		]), Color(0.03, 0.03, 0.05))
		_back.draw_line(Vector2(px - 86.0, cy), Vector2(px + 86.0, cy), Color(0.4, 0.45, 0.65, 0.5), 2.0)


func _draw_centerpiece() -> void:
	# Two thick pillars joined by a cross-brace, holding the central platform.
	var mid := (arena_left + arena_right) / 2.0
	for sx in [-150.0, 150.0]:
		_draw_pillar(mid + sx, floor_y - 330.0, 56.0, false)
	_back.draw_rect(Rect2(mid - 150.0, floor_y - 190.0, 300.0, 28.0), STEEL)
	_back.draw_rect(Rect2(mid - 150.0, floor_y - 190.0, 300.0, 6.0), STEEL_LIGHT)
	_back.draw_rect(Rect2(mid - 150.0, floor_y - 168.0, 300.0, 6.0), STEEL_DARK)
	for k in 6:
		_back.draw_circle(Vector2(mid - 120.0 + k * 48.0, floor_y - 176.0), 2.6, Color(1, 1, 1, 0.25))
	# Diagonal struts under the platform.
	for sx in [-150.0, 150.0]:
		var dir := 1.0 if sx < 0.0 else -1.0
		_back.draw_line(Vector2(mid + sx + dir * 28.0, floor_y - 330.0), Vector2(mid + sx + dir * 104.0, floor_y - 250.0), STEEL_DARK, 10.0)


# --- Dynamic: chains, screens, lanterns, hatches ----------------------------------

func _draw_dynamic() -> void:
	var mid := (arena_left + arena_right) / 2.0
	var span := arena_right - arena_left
	# Hanging chains.
	_draw_hanging_chain(mid - span * 0.38, ceiling_y, floor_y - 440.0, 0.0)
	_draw_hanging_chain(mid + span * 0.38, ceiling_y, floor_y - 440.0, 1.7)
	_draw_hanging_chain(mid - span * 0.22, ceiling_y, floor_y - 560.0, 3.1)
	_draw_hanging_chain(mid + span * 0.22, ceiling_y, floor_y - 560.0, 4.4)
	_draw_draped_chain(Vector2(mid - 330.0, ceiling_y + 8.0), Vector2(mid + 330.0, ceiling_y + 8.0), 150.0)
	# Monitors that keep Isme in their sights.
	_draw_screen(Vector2(mid - span * 0.30, floor_y - 440.0), 0.0)
	_draw_screen(Vector2(mid + span * 0.30, floor_y - 440.0), 2.0)
	# Lanterns and the ceiling hatches.
	for lamp in _lamps:
		_draw_lantern(lamp)
	for hx in _hatches:
		_draw_hatch(hx)


func _draw_hanging_chain(x: float, top_y: float, end_y: float, phase: float) -> void:
	_back_ring(Vector2(x, top_y + 4.0))
	var y := top_y + 8.0
	var i := 0
	var length := end_y - top_y
	while y < end_y:
		var t := (y - top_y) / maxf(length, 1.0)
		var sway := sin(_time * 0.9 + phase) * 7.0 * t
		_draw_link(Vector2(x + sway, y), i % 2 == 0)
		y += 15.0
		i += 1


func _draw_draped_chain(a: Vector2, b: Vector2, sag: float) -> void:
	var steps := 38
	_back_ring(a)
	_back_ring(b)
	for i in steps + 1:
		var t := float(i) / steps
		var p := a.lerp(b, t)
		p.y += sin(t * PI) * sag + sin(_time * 1.1 + t * 5.0) * 2.5 * sin(t * PI)
		_draw_link(p, i % 2 == 0)


func _back_ring(p: Vector2) -> void:
	_dyn.draw_arc(p, 9.0, 0.0, TAU, 12, Color(0.45, 0.47, 0.55), 3.0)


func _draw_link(p: Vector2, round_link: bool) -> void:
	var c := Color(0.5, 0.52, 0.6)
	if round_link:
		_dyn.draw_arc(p, 5.0, 0.0, TAU, 8, c, 2.4)
	else:
		_dyn.draw_line(p + Vector2(-5.0, 0.0), p + Vector2(5.0, 0.0), c.darkened(0.2), 3.0)


func _draw_lantern(p: Vector2) -> void:
	var flicker := (0.85 + 0.15 * sin(_time * 11.0 + p.x * 0.07)) * _lamp_power()
	_dyn.draw_line(p + Vector2(0, -18.0), p + Vector2(0, -2.0), Color(0.3, 0.3, 0.38), 3.0)
	_dyn.draw_rect(Rect2(p + Vector2(-12.0, -2.0), Vector2(24.0, 32.0)), Color(0.1, 0.09, 0.11))
	_dyn.draw_rect(Rect2(p + Vector2(-8.0, 2.0), Vector2(16.0, 24.0)), Color(1.0, 0.78, 0.4, flicker))
	_dyn.draw_rect(Rect2(p + Vector2(-8.0, 2.0), Vector2(5.0, 24.0)), Color(1.0, 0.95, 0.75, 0.6 * flicker))
	_dyn.draw_line(p + Vector2(-12.0, 14.0), p + Vector2(12.0, 14.0), Color(0.1, 0.09, 0.11), 2.0)


func _draw_hatch(x: float) -> void:
	var y := ceiling_y
	_dyn.draw_rect(Rect2(x - 56.0, y, 112.0, 30.0), Color(0.03, 0.03, 0.045))
	_dyn.draw_rect(Rect2(x - 56.0, y, 112.0, 3.0), Color(0.4, 0.45, 0.62, 0.6))
	_dyn.draw_rect(Rect2(x - 44.0, y + 8.0, 88.0, 16.0), Color(0.07, 0.07, 0.1))
	# Hazard stripes.
	for k in 6:
		var sx := x - 44.0 + k * 16.0
		_dyn.draw_colored_polygon(PackedVector2Array([Vector2(sx, y + 24.0), Vector2(sx + 8.0, y + 24.0), Vector2(sx + 14.0, y + 8.0), Vector2(sx + 6.0, y + 8.0)]),
			Color(0.9, 0.7, 0.15, 0.55))
	var on := _alert > 0.0 and int(_time * 8.0) % 2 == 0 and _power > 0.05
	var col := Color(1.0, 0.2, 0.15) if on else Color(0.35, 0.3, 0.15) * _lamp_power()
	_dyn.draw_circle(Vector2(x - 36.0, y + 15.0), 4.5, col)
	_dyn.draw_circle(Vector2(x + 36.0, y + 15.0), 4.5, col)


func _draw_screen(c: Vector2, phase: float) -> void:
	var w := 250.0
	var h := 170.0
	var r := Rect2(c - Vector2(w, h) / 2.0, Vector2(w, h))
	var blink := 0.5 + 0.5 * sin(_time * 5.0 + phase)
	# Frame and glass.
	_dyn.draw_rect(r.grow(10.0), Color(0.05, 0.05, 0.08))
	_dyn.draw_rect(r.grow(10.0), Color(0.5, 0.55, 0.68, 0.7), false, 3.0)
	_dyn.draw_rect(Rect2(r.position + Vector2(-10.0, -10.0), Vector2(w + 20.0, 5.0)), Color(1.0, 0.2, 0.15, 0.4 + 0.5 * blink))
	_dyn.draw_rect(r, Color(0.02, 0.05, 0.05))
	if _lost > 0.5:
		_draw_screen_lost(r, c, phase)
		_screen_dim(r)
		return
	# Isme's silhouette, drawn like a schematic.
	var amber := Color(1.0, 0.72, 0.25, 0.8)
	var ic := c + Vector2(0.0, 12.0)
	_dyn.draw_arc(ic + Vector2(0, -26.0), 24.0, PI, TAU, 14, amber, 2.5)
	_dyn.draw_circle(ic + Vector2(-9.0, -26.0), 5.0, amber)
	_dyn.draw_circle(ic + Vector2(9.0, -26.0), 5.0, amber)
	_dyn.draw_rect(Rect2(ic + Vector2(-20.0, -4.0), Vector2(40.0, 30.0)), amber, false, 2.5)
	_dyn.draw_rect(Rect2(ic + Vector2(-32.0, 26.0), Vector2(64.0, 14.0)), amber, false, 2.5)
	# Spinning crosshair with ticks.
	var red := Color(1.0, 0.22, 0.18, 0.85)
	_dyn.draw_arc(ic + Vector2(0, -2.0), 62.0, 0.0, TAU, 32, Color(red, 0.5), 2.0)
	for k in 4:
		var a := _time * 0.9 + k * PI / 2.0 + phase
		_dyn.draw_line(ic + Vector2(0, -2.0) + Vector2.from_angle(a) * 52.0, ic + Vector2(0, -2.0) + Vector2.from_angle(a) * 76.0, red, 3.0)
	_dyn.draw_line(ic + Vector2(-80.0, -2.0), ic + Vector2(80.0, -2.0), Color(red, 0.35), 1.5)
	_dyn.draw_line(ic + Vector2(0, -80.0), ic + Vector2(0, 76.0), Color(red, 0.35), 1.5)
	# Text readout.
	var font := ThemeDB.fallback_font
	_dyn.draw_string(font, r.position + Vector2(10.0, 20.0), "TARGET : ISME", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.35, 0.3, 0.95))
	if blink > 0.35:
		_dyn.draw_string(font, r.position + Vector2(10.0, h - 10.0), "STATUS : HUNTING", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.72, 0.25, 0.9))
	# Scanline sweeping down, and the odd glitch band.
	var sy := r.position.y + fposmod(_time * 60.0 + phase * 40.0, h)
	_dyn.draw_rect(Rect2(r.position.x, sy, w, 3.0), Color(0.6, 1.0, 0.9, 0.18))
	var g := fposmod(_time * 0.7 + phase, 3.0)
	if g < 0.12:
		_dyn.draw_rect(Rect2(r.position.x, r.position.y + 40.0 + g * 400.0, w, 10.0), Color(1.0, 1.0, 1.0, 0.18))
	_screen_dim(r)


## Static noise and a collapsing crosshair: the monitor has lost Isme.
func _draw_screen_lost(r: Rect2, c: Vector2, phase: float) -> void:
	var step := floorf(_time * 18.0)
	for k in 46:
		var nx := fposmod(sin(k * 12.9898 + step * 7.7) * 43758.5, 1.0)
		var ny := fposmod(sin(k * 78.233 + step * 3.1) * 12345.6, 1.0)
		var shade := 0.25 + 0.5 * fposmod(sin(k * 3.7 + step) * 999.0, 1.0)
		_dyn.draw_rect(Rect2(r.position.x + nx * (r.size.x - 40.0), r.position.y + ny * (r.size.y - 8.0), 14.0 + shade * 40.0, 3.0), Color(shade, shade, shade, 0.5))
	var red := Color(1.0, 0.22, 0.18, 0.85)
	var shrink := 1.0 - 0.7 * clampf((_lost - 0.5) * 2.0, 0.0, 1.0)
	_dyn.draw_arc(c, 62.0 * shrink, 0.0, TAU, 28, Color(red, 0.5), 2.0)
	var font := ThemeDB.fallback_font
	if int(_time * 3.0 + phase) % 2 == 0:
		_dyn.draw_string(font, c + Vector2(-96.0, 8.0), "SIGNAL LOST", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, red)
	_dyn.draw_string(font, r.position + Vector2(10.0, 20.0), "TARGET : ---", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.35, 0.3, 0.9))


func _screen_dim(r: Rect2) -> void:
	var pw := _lamp_power()
	if pw < 0.99:
		_dyn.draw_rect(r.grow(10.0), Color(0.0, 0.0, 0.0, 1.0 - pw))


# --- Additive glow: lantern cones and halos, hatch lights, screen bloom -------------

func _draw_glow() -> void:
	for lamp in _lamps:
		var p: Vector2 = lamp + Vector2(0.0, 14.0)
		var flicker := (0.85 + 0.15 * sin(_time * 11.0 + p.x * 0.07)) * _lamp_power()
		_add.draw_polygon(
			PackedVector2Array([p + Vector2(-14.0, 0.0), p + Vector2(14.0, 0.0), p + Vector2(170.0, 300.0), p + Vector2(-170.0, 300.0)]),
			PackedColorArray([Color(1.0, 0.8, 0.45, 0.2 * flicker), Color(1.0, 0.8, 0.45, 0.2 * flicker), Color(1.0, 0.8, 0.45, 0.0), Color(1.0, 0.8, 0.45, 0.0)]))
		_add.draw_circle(p, 70.0, Color(1.0, 0.75, 0.4, 0.08 * flicker))
		_add.draw_circle(p, 30.0, Color(1.0, 0.8, 0.5, 0.14 * flicker))
	var mid := (arena_left + arena_right) / 2.0
	var span := arena_right - arena_left
	for sx in [mid - span * 0.30, mid + span * 0.30]:
		_add.draw_circle(Vector2(sx, floor_y - 440.0), 190.0, Color(1.0, 0.25, 0.2, (0.05 + 0.02 * sin(_time * 3.0)) * _lamp_power()))
	if _alert > 0.0:
		for hx in _hatches:
			var pulse := 0.5 + 0.5 * sin(_time * 16.0)
			_add.draw_polygon(
				PackedVector2Array([Vector2(hx - 44.0, ceiling_y + 30.0), Vector2(hx + 44.0, ceiling_y + 30.0), Vector2(hx + 90.0, ceiling_y + 260.0), Vector2(hx - 90.0, ceiling_y + 260.0)]),
				PackedColorArray([Color(1.0, 0.2, 0.12, 0.28 * pulse), Color(1.0, 0.2, 0.12, 0.28 * pulse), Color(1.0, 0.2, 0.12, 0.0), Color(1.0, 0.2, 0.12, 0.0)]))
