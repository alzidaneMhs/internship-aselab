extends Control

var stage_pos := Vector2(1010, 640)
var planet_pos := Vector2(1120, 70)
var background_mat: ShaderMaterial

var _time := 0.0
var _motes: Array = []
var _meteor := {}
var _meteor_wait := 2.5
var _bolt: PackedVector2Array = PackedVector2Array()
var _bolt_life := 0.0
var _flash := 0.0
var _bolt_wait := 6.0
var _mouse := Vector2.ZERO
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.randomize()
	for i in 26:
		_motes.append(_new_mote(true))


func _new_mote(anywhere: bool) -> Dictionary:
	return {
		"pos": stage_pos + Vector2(_rng.randf_range(-150.0, 150.0), _rng.randf_range(-330.0, 0.0) if anywhere else 0.0),
		"speed": _rng.randf_range(18.0, 46.0),
		"size": _rng.randf_range(2.0, 4.5),
		"phase": _rng.randf() * TAU,
	}


func _process(delta: float) -> void:
	_time += delta
	var vp := get_viewport()
	var size_v := vp.get_visible_rect().size
	var m := vp.get_mouse_position()
	var target := Vector2(clampf(m.x / maxf(size_v.x, 1.0) * 2.0 - 1.0, -1.0, 1.0), clampf(m.y / maxf(size_v.y, 1.0) * 2.0 - 1.0, -1.0, 1.0))
	_mouse = _mouse.lerp(target, minf(1.0, delta * 2.5))
	if background_mat != null:
		var intro := 1.0 - pow(clampf(1.0 - _time / 2.6, 0.0, 1.0), 3.0)
		var zoom := lerpf(0.78, 0.93 + 0.025 * sin(_time * 0.11), intro)
		background_mat.set_shader_parameter("zoom", zoom)
		background_mat.set_shader_parameter("drift", Vector2(-_mouse.x * 0.012 + sin(_time * 0.07) * 0.01, -_mouse.y * 0.008))
	for mote in _motes:
		mote["pos"].y -= mote["speed"] * delta
		mote["pos"].x += sin(_time * 1.3 + mote["phase"]) * 8.0 * delta
		if mote["pos"].y < stage_pos.y - 360.0:
			var fresh := _new_mote(false)
			mote["pos"] = fresh["pos"]
			mote["speed"] = fresh["speed"]
	_meteor_wait -= delta
	if _meteor.is_empty() and _meteor_wait <= 0.0:
		var start := Vector2(_rng.randf_range(80.0, 900.0), _rng.randf_range(-20.0, 120.0))
		_meteor = {"pos": start, "vel": Vector2(_rng.randf_range(520.0, 760.0), _rng.randf_range(160.0, 260.0)), "life": 0.0}
	if not _meteor.is_empty():
		_meteor["life"] += delta
		_meteor["pos"] += _meteor["vel"] * delta
		if _meteor["life"] > 1.3:
			_meteor = {}
			_meteor_wait = _rng.randf_range(2.5, 6.0)
	_bolt_wait -= delta
	if _bolt_wait <= 0.0:
		_bolt_wait = _rng.randf_range(7.0, 13.0)
		_make_bolt()
	_bolt_life = maxf(_bolt_life - delta, 0.0)
	_flash = maxf(_flash - delta * 1.8, 0.0)
	queue_redraw()


func _make_bolt() -> void:
	_bolt = PackedVector2Array()
	var p := Vector2(_rng.randf_range(820.0, 1240.0), -10.0)
	_bolt.append(p)
	while p.y < 300.0:
		p += Vector2(_rng.randf_range(-38.0, 38.0), _rng.randf_range(20.0, 44.0))
		_bolt.append(p)
	_bolt_life = 0.35
	_flash = 0.5


func _draw() -> void:
	var size_v := get_viewport_rect().size
	var shift := -_mouse * Vector2(14.0, 8.0)
	_draw_aurora(size_v, shift * 0.6)
	_draw_planet_glow(shift * 0.5)
	if not _meteor.is_empty():
		var a: float = 1.0 - float(_meteor["life"]) / 1.3
		var head: Vector2 = _meteor["pos"] + shift * 0.4
		var tail: Vector2 = head - (_meteor["vel"] as Vector2).normalized() * 170.0
		for k in 5:
			var t0 := float(k) / 5.0
			var t1 := float(k + 1) / 5.0
			draw_line(tail.lerp(head, t0), tail.lerp(head, t1), Color(1.0, 0.95, 0.85, a * t1 * 0.9), 1.0 + t1 * 2.4)
		draw_circle(head, 3.2, Color(1.0, 1.0, 1.0, a))
		draw_circle(head, 9.0, Color(1.0, 0.85, 0.6, a * 0.25))
	if _bolt_life > 0.0 and _bolt.size() > 1:
		var ba := _bolt_life / 0.35
		var moved := PackedVector2Array()
		for p in _bolt:
			moved.append(p + shift * 0.5)
		draw_polyline(moved, Color(0.8, 0.6, 1.0, 0.35 * ba), 9.0)
		draw_polyline(moved, Color(1.0, 0.95, 1.0, 0.95 * ba), 2.4)
	_draw_beam()
	_draw_rings()
	for mote in _motes:
		var p: Vector2 = mote["pos"]
		var life := clampf((stage_pos.y - p.y) / 360.0, 0.0, 1.0)
		var alpha := sin(life * PI) * 0.85
		var s: float = mote["size"]
		draw_rect(Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s)), Color(0.45, 0.95, 1.0, alpha))
		draw_circle(p, s * 2.2, Color(0.4, 0.9, 1.0, alpha * 0.18))
	if _flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size_v), Color(0.75, 0.65, 1.0, _flash * 0.22))


func _draw_aurora(size_v: Vector2, shift: Vector2) -> void:
	var bands := [
		{"y": 160.0, "amp": 42.0, "h": 120.0, "col": Color(0.3, 1.0, 0.85), "a": 0.32, "f": 0.006, "s": 0.35},
		{"y": 235.0, "amp": 55.0, "h": 90.0, "col": Color(0.78, 0.45, 1.0), "a": 0.28, "f": 0.0045, "s": -0.25},
		{"y": 100.0, "amp": 30.0, "h": 80.0, "col": Color(1.0, 0.6, 0.88), "a": 0.2, "f": 0.008, "s": 0.5},
	]
	for b in bands:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var steps := 32
		var top := PackedVector2Array()
		var bottom := PackedVector2Array()
		for i in steps + 1:
			var x := -40.0 + (size_v.x + 80.0) * float(i) / steps
			var wave := sin(x * float(b["f"]) + _time * float(b["s"])) * float(b["amp"]) + sin(x * float(b["f"]) * 2.3 - _time * 0.4) * float(b["amp"]) * 0.35
			var y := float(b["y"]) + wave
			top.append(Vector2(x, y - float(b["h"])) + shift)
			bottom.append(Vector2(x, y) + shift)
		var col: Color = b["col"]
		for i in steps:
			var flick := 0.75 + 0.25 * sin(_time * 1.7 + i * 0.6)
			var a := float(b["a"]) * flick
			pts = PackedVector2Array([top[i], top[i + 1], bottom[i + 1], bottom[i]])
			cols = PackedColorArray([Color(col, 0.0), Color(col, 0.0), Color(col, a), Color(col, a)])
			draw_polygon(pts, cols)


func _draw_planet_glow(shift: Vector2) -> void:
	var pulse := 0.8 + 0.2 * sin(_time * 0.9)
	var c := planet_pos + shift
	for i in 6:
		var r := 140.0 + i * 55.0
		draw_circle(c, r, Color(0.85, 0.45, 1.0, 0.06 * pulse * (1.0 - i / 6.0)))
	var flare := 0.7 + 0.3 * sin(_time * 1.3)
	for k in 4:
		var hh := 2.0 + k * 5.0
		draw_rect(Rect2(c.x - 900.0, c.y + 30.0 - hh * 0.5, 1800.0, hh), Color(0.75, 0.6, 1.0, 0.09 * flare / (k + 1)))
	draw_rect(Rect2(c.x - 520.0, c.y + 29.0, 1040.0, 2.0), Color(1.0, 0.92, 1.0, 0.45 * flare))
	for k in 5:
		draw_circle(c + Vector2(0.0, 30.0), 10.0 + k * 9.0, Color(1.0, 0.9, 1.0, 0.12 * flare / (k + 1)))
	var title_c := Vector2(430.0, 175.0) + shift * 0.3
	for k in 5:
		draw_circle(title_c, 120.0 + k * 55.0, Color(1.0, 0.6, 0.18, 0.045 * (0.85 + 0.15 * sin(_time * 1.6)) * (1.0 - k / 5.0)))


func _draw_beam() -> void:
	var flick := 0.85 + 0.15 * sin(_time * 7.0) * sin(_time * 2.3)
	var top_l := Vector2(stage_pos.x - 40.0, -20.0)
	var top_r := Vector2(stage_pos.x + 40.0, -20.0)
	var bot_l := Vector2(stage_pos.x - 230.0, stage_pos.y + 10.0)
	var bot_r := Vector2(stage_pos.x + 230.0, stage_pos.y + 10.0)
	var c := Color(0.55, 0.9, 1.0)
	draw_polygon(PackedVector2Array([top_l, top_r, bot_r, bot_l]), PackedColorArray([Color(c, 0.0), Color(c, 0.0), Color(c, 0.26 * flick), Color(c, 0.26 * flick)]))
	var inner_l := Vector2(stage_pos.x - 110.0, stage_pos.y + 10.0)
	var inner_r := Vector2(stage_pos.x + 110.0, stage_pos.y + 10.0)
	draw_polygon(PackedVector2Array([top_l + Vector2(25, 0), top_r - Vector2(25, 0), inner_r, inner_l]), PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.14 * flick), Color(1, 1, 1, 0.14 * flick)]))


func _draw_rings() -> void:
	for i in 3:
		var r := 210.0 + i * 38.0 + sin(_time * 1.5 + i) * 6.0
		var segs := 40
		var rot := _time * (0.35 + i * 0.15) * (1.0 if i % 2 == 0 else -1.0)
		for k in segs:
			if (k + i) % 3 == 0:
				continue
			var a0 := rot + TAU * k / segs
			var a1 := rot + TAU * (k + 0.6) / segs
			var p0 := stage_pos + Vector2(cos(a0) * r, sin(a0) * r * 0.16)
			var p1 := stage_pos + Vector2(cos(a1) * r, sin(a1) * r * 0.16)
			var front := 0.5 + 0.5 * sin(a0)
			draw_line(p0, p1, Color(0.45, 1.0, 1.0, (0.35 + 0.6 * front) * (1.0 - i * 0.22)), 2.6)
