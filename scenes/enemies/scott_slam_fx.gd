extends Node2D

const LIFE := 2.8

var power: float = 1.0

var _t := 0.0
var _add: Node2D
var _cracks: Array = []
var _debris: Array = []
var _dust: Array = []
var _embers: Array = []


func _ready() -> void:
	z_index = 6
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_build()
	_add = Node2D.new()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_add.material = mat
	add_child(_add)
	_add.draw.connect(_draw_glow)


func _build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for side in [-1.0, 1.0]:
		for i in 7:
			var pts := PackedVector2Array()
			var p := Vector2(side * rng.randf_range(0.0, 36.0), rng.randf_range(0.0, 6.0))
			pts.append(p)
			var segments := rng.randi_range(5, 9)
			var dir_bias := rng.randf_range(0.5, 1.6)
			for s in segments:
				p += Vector2(side * rng.randf_range(22.0, 52.0) * dir_bias * power, rng.randf_range(-6.0, 26.0))
				pts.append(p)
			_cracks.append({"pts": pts, "delay": rng.randf_range(0.0, 0.14) + i * 0.012, "speed": rng.randf_range(0.18, 0.3)})
	for i in 20:
		var ang := rng.randf_range(-PI * 0.88, -PI * 0.12)
		var spd := rng.randf_range(420.0, 980.0) * power
		var shape := PackedVector2Array()
		var r := rng.randf_range(8.0, 22.0) * (0.8 + 0.4 * power)
		for k in 5:
			var a := k * TAU / 5.0 + rng.randf_range(-0.3, 0.3)
			shape.append(Vector2.from_angle(a) * r * rng.randf_range(0.6, 1.1))
		_debris.append({
			"pos": Vector2(rng.randf_range(-90.0, 90.0), -6.0), "vel": Vector2.from_angle(ang) * spd,
			"rot": rng.randf() * TAU, "spin": rng.randf_range(-9.0, 9.0), "shape": shape, "rested": false,
		})
	for i in 18:
		var side := -1.0 if i % 2 == 0 else 1.0
		_dust.append({
			"pos": Vector2(side * rng.randf_range(10.0, 110.0), -rng.randf_range(0.0, 18.0)),
			"vel": Vector2(side * rng.randf_range(120.0, 420.0) * power, -rng.randf_range(8.0, 60.0)),
			"r": rng.randf_range(18.0, 34.0), "grow": rng.randf_range(60.0, 130.0), "life": rng.randf_range(1.3, 2.0),
		})
	for i in 40:
		_embers.append({
			"pos": Vector2(rng.randf_range(-260.0, 260.0) * power, -rng.randf_range(0.0, 24.0)),
			"vel": Vector2(rng.randf_range(-70.0, 70.0), -rng.randf_range(160.0, 460.0)),
			"size": rng.randf_range(3.0, 7.0), "life": rng.randf_range(1.1, 2.3), "delay": rng.randf_range(0.0, 0.25),
		})


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	for d in _debris:
		if d["rested"]:
			continue
		var vel: Vector2 = d["vel"]
		vel.y += 1700.0 * delta
		var pos: Vector2 = d["pos"] + vel * delta
		d["rot"] = float(d["rot"]) + float(d["spin"]) * delta
		if pos.y >= 0.0 and vel.y > 0.0:
			pos.y = 0.0
			vel = Vector2(vel.x * 0.55, -vel.y * 0.32)
			d["spin"] = float(d["spin"]) * 0.5
			if absf(vel.y) < 70.0:
				d["rested"] = true
				vel = Vector2.ZERO
		d["pos"] = pos
		d["vel"] = vel
	for e in _embers:
		if _t >= float(e["delay"]):
			var ev: Vector2 = e["vel"]
			ev.y += 140.0 * delta
			e["vel"] = ev
			e["pos"] = Vector2(e["pos"]) + ev * delta
	queue_redraw()
	_add.queue_redraw()


func _ellipse(rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 41:
		var a := i * TAU / 40.0
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _draw() -> void:
	var fade := clampf((LIFE - _t) / 0.9, 0.0, 1.0)
	draw_colored_polygon(_ellipse(190.0 * power, 14.0 * power), Color(0.0, 0.0, 0.0, 0.35 * fade))
	for c in _cracks:
		var pts: PackedVector2Array = c["pts"]
		var prog := clampf((_t - float(c["delay"])) / float(c["speed"]), 0.0, 1.0)
		var upto := int(ceil(prog * (pts.size() - 1)))
		if upto < 1:
			continue
		var part := PackedVector2Array()
		for i in upto + 1:
			part.append(pts[i])
		draw_polyline(part, Color(0.02, 0.0, 0.04, 0.9 * fade), 5.0 * power)
	for d in _dust:
		var life := float(d["life"])
		var u := clampf(_t / life, 0.0, 1.0)
		if u >= 1.0:
			continue
		var pos: Vector2 = Vector2(d["pos"]) + Vector2(d["vel"]) * _t * (1.0 - 0.5 * u)
		var r := float(d["r"]) + float(d["grow"]) * u
		draw_circle(pos, r, Color(0.48, 0.42, 0.42, 0.42 * (1.0 - u)))
		draw_circle(pos + Vector2(0.0, -r * 0.2), r * 0.7, Color(0.62, 0.56, 0.55, 0.22 * (1.0 - u)))
	for d in _debris:
		var shape: PackedVector2Array = d["shape"]
		var rot := float(d["rot"])
		var pts := PackedVector2Array()
		for p in shape:
			pts.append(Vector2(d["pos"]) + p.rotated(rot))
		var heat := clampf(1.0 - _t / 0.9, 0.0, 1.0)
		draw_colored_polygon(pts, Color(0.2 + 0.7 * heat, 0.15 + 0.3 * heat, 0.24, fade))
		var closed := PackedVector2Array(pts)
		closed.append(pts[0])
		draw_polyline(closed, Color(1.0, 0.55, 0.2, 0.7 * heat * fade), 2.0)


func _draw_glow() -> void:
	var fade := clampf((LIFE - _t) / 0.9, 0.0, 1.0)
	if _t < 0.2:
		var k := 1.0 - _t / 0.2
		_add.draw_circle(Vector2(0.0, -40.0), 260.0 * power * (1.0 + (1.0 - k) * 0.6), Color(1.0, 0.85, 0.6, 0.8 * k))
		_add.draw_circle(Vector2(0.0, -40.0), 110.0 * power, Color(1.0, 1.0, 1.0, 0.9 * k))
	if _t < 0.55:
		var k2 := _t / 0.55
		var h := 560.0 * power * sin(minf(k2 * 2.0, 1.0) * PI * 0.5)
		var w := (110.0 - 70.0 * k2) * power
		_add.draw_polygon(
			PackedVector2Array([Vector2(-w, 0.0), Vector2(w, 0.0), Vector2(w * 0.25, -h), Vector2(-w * 0.25, -h)]),
			PackedColorArray([Color(1.0, 0.75, 0.4, 0.75 * (1.0 - k2)), Color(1.0, 0.75, 0.4, 0.75 * (1.0 - k2)), Color(1.0, 0.4, 0.15, 0.0), Color(1.0, 0.4, 0.15, 0.0)]))
		_add.draw_polygon(
			PackedVector2Array([Vector2(-w * 0.35, 0.0), Vector2(w * 0.35, 0.0), Vector2(0.0, -h * 0.85)]),
			PackedColorArray([Color(1.0, 1.0, 0.9, 0.9 * (1.0 - k2)), Color(1.0, 1.0, 0.9, 0.9 * (1.0 - k2)), Color(1.0, 0.9, 0.6, 0.0)]))
	for i in 3:
		var rt := (_t - i * 0.08) / 0.75
		if rt <= 0.0 or rt >= 1.0:
			continue
		var rx := 90.0 + rt * 620.0 * power
		var a := pow(1.0 - rt, 1.4)
		_add.draw_polyline(_ellipse(rx, rx * 0.16), Color(1.0, 0.7 - 0.2 * i, 0.35, 0.9 * a), 12.0 * (1.0 - rt) + 3.0)
		_add.draw_polyline(_ellipse(rx * 0.93, rx * 0.15), Color(1.0, 0.95, 0.8, 0.5 * a), 3.0)
	var sk := clampf(_t / 0.45, 0.0, 1.0)
	if sk < 1.0:
		_add.draw_arc(Vector2(0.0, -40.0), 40.0 + 420.0 * power * sk, PI, TAU, 40, Color(1.0, 0.85, 0.6, 0.55 * (1.0 - sk)), 14.0 * (1.0 - sk) + 2.0)
	for c in _cracks:
		var pts: PackedVector2Array = c["pts"]
		var prog := clampf((_t - float(c["delay"])) / float(c["speed"]), 0.0, 1.0)
		var upto := int(ceil(prog * (pts.size() - 1)))
		if upto < 1:
			continue
		var part := PackedVector2Array()
		for i in upto + 1:
			part.append(pts[i])
		var glow := clampf(1.3 - (_t - float(c["delay"])) / 2.2, 0.0, 1.0)
		var flick := 0.8 + 0.2 * sin(_t * 18.0 + pts[0].x)
		_add.draw_polyline(part, Color(1.0, 0.45, 0.1, 0.5 * glow * flick), 11.0 * power)
		_add.draw_polyline(part, Color(1.0, 0.85, 0.5, 0.9 * glow * flick), 4.0 * power)
	for e in _embers:
		var el := _t - float(e["delay"])
		var life := float(e["life"])
		if el < 0.0 or el >= life:
			continue
		var u := el / life
		_add.draw_circle(Vector2(e["pos"]), float(e["size"]) * (1.0 - 0.6 * u), Color(1.0, 0.65 - 0.3 * u, 0.2, 0.9 * (1.0 - u)))
