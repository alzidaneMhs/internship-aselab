class_name VirusWireEffects
extends Control


var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _particles: Array[Dictionary] = []

var _running: bool = false
var _won: bool = false
var _elapsed: float = 0.0
var _duration: float = 0.65
var _origin: Vector2 = Vector2.ZERO
var _effect_color: Color = Color.WHITE
var _gravity: float = 100.0
var _last_second: int = -1

var _result_label: Label
var _timer_label: Label
var _result_tween: Tween
var _timer_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.randomize()

	resized.connect(queue_redraw)

	set_process(false)
	queue_redraw()


func reset_effects() -> void:
	_running = false
	_particles.clear()
	_last_second = -1

	if _result_tween != null and _result_tween.is_valid():
		_result_tween.kill()

	if _timer_tween != null and _timer_tween.is_valid():
		_timer_tween.kill()

	if is_instance_valid(_result_label):
		_result_label.modulate = Color.WHITE
		_result_label.scale = Vector2.ONE

	if is_instance_valid(_timer_label):
		_timer_label.scale = Vector2.ONE

	set_process(false)
	queue_redraw()


func update_countdown(remaining: float, label: Label) -> void:
	var second: int = int(ceilf(remaining))

	if second < 1 or second > 5:
		return

	if second == _last_second:
		return

	_last_second = second
	_timer_label = label

	if _timer_tween != null and _timer_tween.is_valid():
		_timer_tween.kill()

	label.pivot_offset = label.size * 0.5
	label.scale = Vector2.ONE * 1.12

	_timer_tween = create_tween()
	_timer_tween.tween_property(
		label,
		"scale",
		Vector2.ONE,
		0.16
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func play_result(
	won: bool,
	wires: VirusWireLayer,
	result_label: Label
) -> void:
	reset_effects()

	_won = won
	_elapsed = 0.0
	_duration = 0.65 if won else 0.95
	_gravity = 50.0 if won else 180.0
	_origin = size * 0.5

	_effect_color = (
		Color("#8BEAA0") if won else Color("#FF873F")
	)

	var cut_index: int = wires.cut_wire_index
	var cut_happened: bool = (
		cut_index >= 0
		and cut_index < wires.wire_paths.size()
	)

	# Letakkan efek pada posisi kabel yang dipotong.
	if cut_happened:
		var path: PackedVector2Array = wires.wire_paths[
			cut_index
		]

		var point_position: float = (
			clampf(wires.cut_ratio, 0.0, 1.0)
			* float(path.size() - 1)
		)

		var left_index: int = int(floorf(point_position))
		var right_index: int = mini(
			left_index + 1,
			path.size() - 1
		)

		_origin = path[left_index].lerp(
			path[right_index],
			point_position - float(left_index)
		)

	var count: int = 24 if won else 42

	for _index in range(count):
		var angle: float = _rng.randf_range(0.0, TAU)
		var speed: float = _rng.randf_range(
			80.0 if won else 120.0,
			190.0 if won else 300.0
		)

		_particles.append({
			"position": _origin,
			"velocity": Vector2.RIGHT.rotated(angle) * speed,
			"age": 0.0,
			"life": _rng.randf_range(0.25, _duration),
		})

	# Tulisan hasil muncul perlahan dengan sedikit perubahan ukuran.
	_result_label = result_label
	result_label.pivot_offset = result_label.size * 0.5
	result_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	result_label.scale = Vector2.ONE * 1.035

	_result_tween = create_tween()
	_result_tween.set_parallel(true)

	_result_tween.tween_property(
		result_label,
		"modulate",
		Color.WHITE,
		0.22
	)

	_result_tween.tween_property(
		result_label,
		"scale",
		Vector2.ONE,
		0.26
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_running = true
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta

	for particle in _particles:
		var velocity: Vector2 = particle["velocity"]
		var position: Vector2 = particle["position"]

		velocity.y += _gravity * delta

		particle["velocity"] = velocity
		particle["position"] = position + velocity * delta
		particle["age"] = float(particle["age"]) + delta

	if _elapsed >= _duration:
		_running = false
		_particles.clear()
		set_process(false)

	queue_redraw()


func _draw() -> void:
	_draw_corner_accents()

	if not _running:
		return

	var progress: float = clampf(
		_elapsed / _duration,
		0.0,
		1.0
	)

	# Kilatan singkat setelah hasil ditentukan.
	var flash: Color = _effect_color
	flash.a = (
		(0.12 if _won else 0.24)
		* maxf(1.0 - _elapsed / 0.18, 0.0)
	)
	draw_rect(Rect2(Vector2.ZERO, size), flash)

	# Lingkaran energi yang membesar.
	var ring_color: Color = _effect_color
	ring_color.a = 0.8 * (1.0 - progress)

	draw_arc(
		_origin,
		lerpf(8.0, 90.0 if _won else 150.0, progress),
		0.0,
		TAU,
		64,
		ring_color,
		2.5,
		true
	)

	# Percikan kabel atau ledakan.
	for particle in _particles:
		var age: float = float(particle["age"])
		var life: float = float(particle["life"])

		if age >= life:
			continue

		var position: Vector2 = particle["position"]
		var velocity: Vector2 = particle["velocity"]
		var color: Color = _effect_color
		color.a = 1.0 - age / life

		draw_line(
			position - velocity * 0.025,
			position,
			color,
			2.0,
			true
		)
		draw_circle(position, 1.8, color)


func _draw_corner_accents() -> void:
	var corners: Array[Vector2] = [
		Vector2(4.0, 4.0),
		Vector2(size.x - 4.0, 4.0),
		Vector2(4.0, size.y - 4.0),
		Vector2(size.x - 4.0, size.y - 4.0),
	]

	var directions: Array[Vector2] = [
		Vector2(1.0, 1.0),
		Vector2(-1.0, 1.0),
		Vector2(1.0, -1.0),
		Vector2(-1.0, -1.0),
	]

	for index in range(4):
		draw_line(
			corners[index],
			corners[index] + Vector2(
				directions[index].x * 14.0, 0.0
			),
			Color("#FFB72E"),
			2.0,
			true
		)

		draw_line(
			corners[index],
			corners[index] + Vector2(
				0.0, directions[index].y * 14.0
			),
			Color("#FFB72E"),
			2.0,
			true
		)
