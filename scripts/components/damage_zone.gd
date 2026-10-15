extends Area2D

enum Kind { GENERIC, SPIKE, ACID }

const FX := preload("res://scripts/effects/laser_fx.gd")
const ACID_SURFACE := 26.0
const FLOOR_THICKNESS := 40.0

@export var size: Vector2 = Vector2(96, 28):
	set(value):
		size = value
		if is_node_ready():
			_rebuild()
@export var damage: float = 1.0
@export var show_right_tape: bool = true
@export var tick_interval: float = 0.5
@export var color: Color = Color(0.75, 0.2, 0.2, 1.0)
@export var kind: Kind = Kind.GENERIC:
	set(value):
		kind = value
		queue_redraw()

@onready var tick_timer: Timer = $TickTimer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _time := 0.0
var _phase := 0.0


func _ready() -> void:
	_phase = randf() * TAU
	_rebuild()
	if kind == Kind.ACID:
		_build_floor()
	tick_timer.wait_time = tick_interval
	tick_timer.timeout.connect(_on_tick)
	tick_timer.start()


func _process(delta: float) -> void:
	_time += delta
	if kind != Kind.GENERIC and FX.on_screen(self, 400.0):
		queue_redraw()


func _rebuild() -> void:
	var rect := RectangleShape2D.new()
	if kind == Kind.ACID:
		rect.size = Vector2(size.x, maxf(size.y - ACID_SURFACE, 4.0))
		collision_shape.position = Vector2(size.x / 2.0, ACID_SURFACE + rect.size.y / 2.0)
	else:
		rect.size = size
		collision_shape.position = size / 2.0
	collision_shape.shape = rect
	queue_redraw()


func _build_floor() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(size.x + 8.0, FLOOR_THICKNESS)
	shape.shape = rect
	shape.position = Vector2(size.x / 2.0, size.y + FLOOR_THICKNESS / 2.0)
	body.add_child(shape)
	add_child(body)


func _draw() -> void:
	match kind:
		Kind.SPIKE:
			_draw_spikes()
		Kind.ACID:
			_draw_acid()
		_:
			draw_rect(Rect2(Vector2.ZERO, size), color)


func _draw_spikes() -> void:
	var count: int = maxi(1, int(size.x / 24.0))
	var w: float = size.x / count
	var base_y := size.y - 6.0
	var pulse := 0.5 + 0.5 * sin(_time * 3.0 + _phase)
	draw_rect(Rect2(-4.0, base_y - 4.0, size.x + 8.0, 12.0), Color(1.0, 0.2, 0.15, 0.1 + 0.1 * pulse))
	draw_rect(Rect2(-2.0, base_y, size.x + 4.0, 9.0), Color(0.16, 0.15, 0.2))
	draw_rect(Rect2(-2.0, base_y, size.x + 4.0, 2.0), Color(0.42, 0.42, 0.52))
	for i in count + 1:
		draw_circle(Vector2(i * w, base_y + 5.0), 1.6, Color(0.6, 0.6, 0.7))
	for i in count:
		var x0 := i * w
		var mid := x0 + w * 0.5
		var tip := Vector2(mid, -2.0)
		var left := Vector2(x0 + 2.0, base_y + 1.0)
		var right := Vector2(x0 + w - 2.0, base_y + 1.0)
		var foot := Vector2(mid, base_y + 1.0)
		draw_colored_polygon(PackedVector2Array([left, tip, foot]), Color(0.86, 0.88, 0.95))
		draw_colored_polygon(PackedVector2Array([foot, tip, right]), Color(0.42, 0.44, 0.55))
		draw_line(left + Vector2(1, -1), tip, Color(1, 1, 1, 0.55), 1.5)
		draw_colored_polygon(PackedVector2Array([tip + Vector2(-3.2, 9.0), tip, tip + Vector2(3.2, 9.0)]), Color(0.95, 0.22, 0.2))
		if sin(_time * 2.4 - i * 0.7 + _phase) > 0.93:
			draw_circle(tip, 3.4, Color(1, 1, 1, 0.9))


func _draw_acid() -> void:
	var w := size.x
	var h := size.y
	var top := ACID_SURFACE

	draw_rect(Rect2(0.0, 0.0, w, h), Color(0.03, 0.045, 0.06))
	var edge := Color(0, 0, 0, 0.6)
	var clear := Color(0, 0, 0, 0.0)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(22, 0), Vector2(22, h), Vector2(0, h)]),
		PackedColorArray([edge, clear, clear, edge]))
	draw_polygon(PackedVector2Array([Vector2(w - 22, 0), Vector2(w, 0), Vector2(w, h), Vector2(w - 22, h)]),
		PackedColorArray([clear, edge, edge, clear]))

	draw_rect(Rect2(-4.0, h, w + 8.0, FLOOR_THICKNESS), Color(0.12, 0.1, 0.15))
	draw_rect(Rect2(-4.0, h, w + 8.0, 3.0), Color(0.3, 0.27, 0.36))
	var gear := Vector2(w * 0.68, h - 6.0)
	draw_circle(gear, 13.0, Color(0.22, 0.2, 0.25))
	draw_circle(gear, 5.0, Color(0.06, 0.08, 0.08))
	for k in 8:
		var a := k * TAU / 8.0 + 0.3
		draw_line(gear + Vector2.from_angle(a) * 12.0, gear + Vector2.from_angle(a) * 17.0, Color(0.22, 0.2, 0.25), 5.0)

	var wave := PackedVector2Array()
	var x := 0.0
	while x <= w + 0.1:
		var y := top + sin(x * 0.085 + _time * 2.3 + _phase) * 2.6 + sin(x * 0.19 - _time * 1.7) * 1.4
		wave.append(Vector2(x, y))
		x += 6.0

	draw_polygon(
		PackedVector2Array([Vector2(-8, top - 70.0), Vector2(w + 8, top - 70.0), Vector2(w + 8, top), Vector2(-8, top)]),
		PackedColorArray([Color(0.5, 1.0, 0.3, 0.0), Color(0.5, 1.0, 0.3, 0.0), Color(0.5, 1.0, 0.3, 0.22), Color(0.5, 1.0, 0.3, 0.22)])
	)
	for i in 5:
		var prog := fposmod(_time * 0.22 + i * 0.2 + _phase, 1.0)
		var sx := fposmod(i * 53.0 + _phase * 11.0, maxf(w - 30.0, 1.0)) + 15.0 + sin(prog * 6.0 + i) * 7.0
		draw_circle(Vector2(sx, top - 4.0 - prog * 80.0), 6.0 + 9.0 * prog, Color(0.65, 1.0, 0.5, 0.13 * (1.0 - prog)))

	var body := PackedVector2Array(wave)
	body.append(Vector2(w, h))
	body.append(Vector2(0.0, h))
	var colors := PackedColorArray()
	for i in wave.size():
		colors.append(Color(0.58, 1.0, 0.3, 0.94))
	colors.append(Color(0.06, 0.3, 0.12, 0.97))
	colors.append(Color(0.06, 0.3, 0.12, 0.97))
	draw_polygon(body, colors)
	for layer in 2:
		var cur := PackedVector2Array()
		var cx := 0.0
		while cx <= w + 0.1:
			cur.append(Vector2(cx, top + 11.0 + layer * 12.0 + sin(cx * 0.06 + _time * (1.1 + layer * 0.5) + layer * 2.0) * 3.0))
			cx += 8.0
		draw_polyline(cur, Color(0.85, 1.0, 0.5, 0.2 - layer * 0.06), 2.0)

	draw_polyline(wave, Color(0.92, 1.0, 0.58), 3.0)
	draw_polyline(wave, Color(1, 1, 1, 0.4), 1.2)

	for i in 9:
		var t := fposmod(_time * 0.42 + i * 0.23 + _phase, 1.0)
		var bx := fposmod(i * 37.0 + _phase * 17.0, maxf(w - 20.0, 1.0)) + 10.0
		var by := h - 4.0 - t * (h - 4.0 - top)
		var r := 2.0 + (i % 3)
		draw_circle(Vector2(bx, by), r, Color(0.85, 1.0, 0.6, 0.6 * (1.0 - t * 0.5)))
		draw_arc(Vector2(bx, by), r, 0.0, TAU, 8, Color(1, 1, 1, 0.5), 1.0)
		if t > 0.9:
			draw_arc(Vector2(bx, top), (t - 0.9) * 90.0, PI, TAU, 10, Color(1, 1, 0.8, (1.0 - t) * 8.0), 1.5)
	for i in 4:
		var u := fposmod(_time * 0.7 + i * 0.25 + _phase, 1.0)
		if u < 0.4:
			var k2 := u / 0.4
			var dx := fposmod(i * 71.0 + _phase * 5.0, maxf(w - 30.0, 1.0)) + 15.0
			draw_circle(Vector2(dx, top - sin(k2 * PI) * 22.0), 2.0, Color(0.8, 1.0, 0.5, 0.85 * (1.0 - k2)))

	for side in 2:
		for k in 3:
			var sx2 := 3.0 + k * 5.0 if side == 0 else w - 3.0 - k * 5.0
			var streak := 14.0 + fposmod(k * 17.0 + side * 9.0, 22.0)
			draw_line(Vector2(sx2, 0.0), Vector2(sx2, minf(streak, top - 2.0)), Color(0.5, 0.9, 0.25, 0.45), 2.0)

	_draw_tape(Rect2(-40.0, -5.0, 40.0, 5.0))
	if show_right_tape:
		_draw_tape(Rect2(w, -5.0, 40.0, 5.0))
	_draw_warning_sign(Vector2(-28.0, -6.0))


func _draw_tape(rect: Rect2) -> void:
	draw_rect(rect, Color(0.09, 0.09, 0.11))
	var sx := rect.position.x
	while sx < rect.end.x:
		var x1 := minf(sx + 6.0, rect.end.x)
		draw_colored_polygon(PackedVector2Array([
			Vector2(sx, rect.end.y), Vector2(sx + 4.0, rect.position.y),
			Vector2(minf(sx + 9.0, rect.end.x), rect.position.y), Vector2(x1, rect.end.y),
		]), Color(0.98, 0.8, 0.15))
		sx += 12.0


func _draw_warning_sign(base: Vector2) -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 3.0 + _phase)
	draw_line(base, base + Vector2(0, -52), Color(0.3, 0.3, 0.36), 4.0)
	var c := base + Vector2(0, -70)
	draw_circle(c + Vector2(0, 4), 30.0 + 3.0 * pulse, Color(1.0, 0.85, 0.2, 0.08 + 0.08 * pulse))
	var tri := PackedVector2Array([c + Vector2(0, -24), c + Vector2(-26, 18), c + Vector2(26, 18)])
	draw_colored_polygon(tri, Color(0.98, 0.8, 0.15))
	draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), Color(0.12, 0.1, 0.05), 3.0)
	draw_line(c + Vector2(0, -10), c + Vector2(0, 4), Color(0.12, 0.1, 0.05), 4.0)
	draw_circle(c + Vector2(0, 11), 2.6, Color(0.12, 0.1, 0.05))


func _on_tick() -> void:
	for area in get_overlapping_areas():
		if area.has_method("take_damage"):
			area.take_damage(damage * GameState.get_trap_multiplier())
