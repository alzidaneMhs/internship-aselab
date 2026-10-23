extends Node2D

const TILE := 1800.0

var kind := "rocks"
var tint := Color(0.04, 0.02, 0.06)
var speed := 1.45

var _strip: Node2D
var _rng := RandomNumberGenerator.new()
var _screen := Vector2(1280, 720)


func _ready() -> void:
	_rng.seed = hash(kind) + 7
	_screen = get_viewport().get_visible_rect().size
	_strip = Node2D.new()
	add_child(_strip)
	for i in 3:
		var tile := Node2D.new()
		tile.position.x = i * TILE
		_strip.add_child(tile)
		_build_tile(tile)


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null or _strip == null:
		return
	var c := cam.get_screen_center_position()
	_strip.position.x = -fposmod(c.x * speed, TILE)
	_strip.position.y = clampf(-c.y * 0.04, -30.0, 30.0) * 0.0


func _poly(parent: Node2D, pts: PackedVector2Array, col: Color) -> void:
	var soft := Polygon2D.new()
	soft.polygon = pts
	soft.color = Color(col, col.a * 0.35)
	soft.scale = Vector2(1.04, 1.06)
	var center := Vector2.ZERO
	for p in pts:
		center += p
	center /= maxf(pts.size(), 1)
	soft.position = center * -0.04
	parent.add_child(soft)
	var solid := Polygon2D.new()
	solid.polygon = pts
	solid.color = col
	solid.antialiased = true
	parent.add_child(solid)


func _spike_down(parent: Node2D, x: float, w: float, h: float, col: Color) -> void:
	var pts := PackedVector2Array([Vector2(x - w, -20.0), Vector2(x + w, -20.0), Vector2(x + w * 0.35, h * 0.55), Vector2(x + _rng.randf_range(-4.0, 4.0), h)])
	_poly(parent, pts, col)


func _mound(parent: Node2D, x: float, w: float, h: float, col: Color) -> void:
	var base := _screen.y + 20.0
	var pts := PackedVector2Array()
	pts.append(Vector2(x - w, base))
	var steps := 7
	for i in steps + 1:
		var t := float(i) / steps
		var px := x - w + t * w * 2.0
		var py := _screen.y - sin(t * PI) * h * _rng.randf_range(0.75, 1.05)
		pts.append(Vector2(px, py))
	pts.append(Vector2(x + w, base))
	_poly(parent, pts, col)


func _blades(parent: Node2D, x: float, count: int, h: float, col: Color) -> void:
	for i in count:
		var bx := x + i * _rng.randf_range(6.0, 12.0)
		var bh := h * _rng.randf_range(0.5, 1.0)
		var lean := _rng.randf_range(-18.0, 18.0)
		_poly(parent, PackedVector2Array([Vector2(bx - 4.0, _screen.y + 10.0), Vector2(bx + 4.0, _screen.y + 10.0), Vector2(bx + lean, _screen.y - bh)]), col)


func _chain(parent: Node2D, x: float, length: float, col: Color) -> void:
	var y := -10.0
	while y < length:
		var link := PackedVector2Array()
		for k in 10:
			var a := TAU * k / 10.0
			link.append(Vector2(x + cos(a) * 6.0, y + 9.0 + sin(a) * 11.0))
		_poly(parent, link, col)
		y += 18.0
	_poly(parent, PackedVector2Array([Vector2(x - 14.0, length), Vector2(x + 14.0, length), Vector2(x + 10.0, length + 26.0), Vector2(x - 10.0, length + 26.0)]), col)


func _cable(parent: Node2D, x0: float, x1: float, sag: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var steps := 16
	for i in steps + 1:
		var t := float(i) / steps
		pts.append(Vector2(lerpf(x0, x1, t), -10.0 + sin(t * PI) * sag))
	for i in range(steps, -1, -1):
		var t2 := float(i) / steps
		pts.append(Vector2(lerpf(x0, x1, t2), -2.0 + sin(t2 * PI) * sag))
	_poly(parent, pts, col)


func _build_tile(tile: Node2D) -> void:
	var col := Color(tint, 0.94)
	match kind:
		"rocks", "crystal":
			var x := _rng.randf_range(0.0, 200.0)
			while x < TILE:
				if _rng.randf() < 0.6:
					_spike_down(tile, x, _rng.randf_range(22.0, 60.0), _rng.randf_range(60.0, 150.0), col)
				x += _rng.randf_range(160.0, 420.0)
			x = _rng.randf_range(0.0, 300.0)
			while x < TILE:
				if _rng.randf() < 0.55:
					_mound(tile, x, _rng.randf_range(70.0, 170.0), _rng.randf_range(40.0, 85.0), col)
					if kind == "crystal" and _rng.randf() < 0.6:
						_spike_up(tile, x + _rng.randf_range(-40.0, 40.0), col)
				x += _rng.randf_range(380.0, 760.0)
		"ice":
			var xi := _rng.randf_range(0.0, 150.0)
			while xi < TILE:
				if _rng.randf() < 0.7:
					_spike_down(tile, xi, _rng.randf_range(10.0, 30.0), _rng.randf_range(70.0, 190.0), col)
				xi += _rng.randf_range(90.0, 300.0)
			xi = _rng.randf_range(0.0, 300.0)
			while xi < TILE:
				if _rng.randf() < 0.5:
					_mound(tile, xi, _rng.randf_range(80.0, 180.0), _rng.randf_range(35.0, 70.0), col)
				xi += _rng.randf_range(420.0, 800.0)
		"grass":
			var xg := _rng.randf_range(0.0, 200.0)
			while xg < TILE:
				if _rng.randf() < 0.6:
					_blades(tile, xg, _rng.randi_range(6, 14), _rng.randf_range(50.0, 110.0), col)
				xg += _rng.randf_range(220.0, 520.0)
		"chains":
			var xc := _rng.randf_range(80.0, 300.0)
			while xc < TILE:
				if _rng.randf() < 0.65:
					_chain(tile, xc, _rng.randf_range(90.0, 220.0), col)
				xc += _rng.randf_range(300.0, 620.0)
		"cables":
			var xk := 0.0
			while xk < TILE:
				var w := _rng.randf_range(300.0, 600.0)
				if _rng.randf() < 0.7:
					_cable(tile, xk, xk + w, _rng.randf_range(40.0, 110.0), col)
				xk += w * _rng.randf_range(0.6, 1.0)
		"coins":
			var xv := _rng.randf_range(0.0, 300.0)
			while xv < TILE:
				if _rng.randf() < 0.55:
					_mound(tile, xv, _rng.randf_range(90.0, 200.0), _rng.randf_range(35.0, 75.0), col)
				xv += _rng.randf_range(380.0, 760.0)


func _spike_up(parent: Node2D, x: float, col: Color) -> void:
	var h := _rng.randf_range(60.0, 120.0)
	var w := _rng.randf_range(10.0, 20.0)
	var y := _screen.y - 30.0
	_poly(parent, PackedVector2Array([Vector2(x - w, y + 40.0), Vector2(x + w, y + 40.0), Vector2(x + w * 0.3, y - h * 0.6), Vector2(x, y - h)]), col)
