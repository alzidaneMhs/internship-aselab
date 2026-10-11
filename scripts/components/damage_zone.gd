extends Area2D

## Shared by spike.tscn and acid_pool.tscn. Origin is the top-left corner of the
## zone. Deals `damage` to anything overlapping it every `tick_interval` seconds.

enum Kind { GENERIC, SPIKE, ACID }

@export var size: Vector2 = Vector2(96, 28):
	set(value):
		size = value
		if is_node_ready():
			_rebuild()
@export var damage: float = 1.0
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
	tick_timer.wait_time = tick_interval
	tick_timer.timeout.connect(_on_tick)
	tick_timer.start()


func _process(delta: float) -> void:
	_time += delta
	if kind != Kind.GENERIC:
		queue_redraw()


func _rebuild() -> void:
	var rect := RectangleShape2D.new()
	rect.size = size
	collision_shape.shape = rect
	collision_shape.position = size / 2.0
	queue_redraw()


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
	# Warning glow on the floor.
	draw_rect(Rect2(-4.0, base_y - 4.0, size.x + 8.0, 12.0), Color(1.0, 0.2, 0.15, 0.1 + 0.1 * pulse))
	# Metal base plate with rivets.
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
		# Red-hot tip.
		draw_colored_polygon(PackedVector2Array([tip + Vector2(-3.2, 9.0), tip, tip + Vector2(3.2, 9.0)]), Color(0.95, 0.22, 0.2))
		# Occasional glint sweeping across the row.
		if sin(_time * 2.4 - i * 0.7 + _phase) > 0.93:
			draw_circle(tip, 3.4, Color(1, 1, 1, 0.9))


func _draw_acid() -> void:
	var depth := size.y + 18.0
	var top := 5.0
	# Wave surface points.
	var wave := PackedVector2Array()
	var x := 0.0
	while x <= size.x + 0.1:
		var y := top + sin(x * 0.085 + _time * 2.3 + _phase) * 2.6 + sin(x * 0.19 - _time * 1.7) * 1.4
		wave.append(Vector2(x, y))
		x += 6.0
	# Glow rising above the pool.
	draw_polygon(
		PackedVector2Array([Vector2(-6, top - 34.0), Vector2(size.x + 6, top - 34.0), Vector2(size.x + 6, top), Vector2(-6, top)]),
		PackedColorArray([Color(0.5, 1.0, 0.3, 0.0), Color(0.5, 1.0, 0.3, 0.0), Color(0.5, 1.0, 0.3, 0.24), Color(0.5, 1.0, 0.3, 0.24)])
	)
	# Liquid body (top edge follows the waves).
	var body := PackedVector2Array(wave)
	body.append(Vector2(size.x, depth))
	body.append(Vector2(0.0, depth))
	var colors := PackedColorArray()
	for i in wave.size():
		colors.append(Color(0.55, 1.0, 0.28, 0.93))
	colors.append(Color(0.08, 0.34, 0.14, 0.97))
	colors.append(Color(0.08, 0.34, 0.14, 0.97))
	draw_polygon(body, colors)
	# Bright foam line on the surface.
	draw_polyline(wave, Color(0.9, 1.0, 0.55), 3.0)
	draw_polyline(wave, Color(1, 1, 1, 0.35), 1.2)
	# Rising bubbles.
	for i in 7:
		var t := fposmod(_time * 0.45 + i * 0.29 + _phase, 1.0)
		var bx := fposmod(i * 41.0 + _phase * 17.0, maxf(size.x - 10.0, 1.0)) + 5.0
		var by := depth - 4.0 - t * (depth - 10.0)
		draw_circle(Vector2(bx, by), 2.0 + (i % 3), Color(0.85, 1.0, 0.6, 0.65 * (1.0 - t)))
		draw_arc(Vector2(bx, by), 2.0 + (i % 3), 0.0, TAU, 8, Color(1, 1, 1, 0.5 * (1.0 - t)), 1.0)
	# Stone rim at both ends.
	var rim := Color(0.2, 0.17, 0.24)
	draw_rect(Rect2(-8.0, 0.0, 9.0, depth + 2.0), rim)
	draw_rect(Rect2(size.x - 1.0, 0.0, 9.0, depth + 2.0), rim)
	draw_rect(Rect2(-8.0, 0.0, 9.0, 3.0), rim.lightened(0.3))
	draw_rect(Rect2(size.x - 1.0, 0.0, 9.0, 3.0), rim.lightened(0.3))


func _on_tick() -> void:
	for area in get_overlapping_areas():
		if area.has_method("take_damage"):
			area.take_damage(damage * GameState.get_trap_multiplier())
