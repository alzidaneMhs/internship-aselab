@tool
class_name VirusWireLayer
extends Control


signal wire_cut(wire_index: int, infected: bool)


const WIRE_COLORS: Array[Color] = [
	Color("#FF5C64"),
	Color("#6395FF"),
	Color("#FFD166"),
	Color("#56D99C"),
	Color("#BC60FF"),
	Color("#F48EC8"),
	Color("#E8EDF8"),
	Color("#C28B56"),
]

const SAMPLES: int = 64
const INFECTED_COUNT: int = 3
const CLICK_DISTANCE: float = 10.0
const CUT_HALF_WIDTH: float = 10.0

var wire_paths: Array[PackedVector2Array] = []
var infected_wires: Array[int] = []
var virus_point_indices: Dictionary = {}

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var interaction_enabled: bool = false
var cut_wire_index: int = -1
var cut_ratio: float = 0.5


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_CROSS

	if not resized.is_connected(_build_wires):
		resized.connect(_build_wires)

	rng.randomize()
	new_round()
	_build_wires()


func new_round() -> void:
	interaction_enabled = false
	cut_wire_index = -1
	cut_ratio = 0.5

	infected_wires.clear()
	virus_point_indices.clear()

	var candidates: Array[int] = []

	for index in range(WIRE_COLORS.size()):
		candidates.append(index)

	for _slot in range(INFECTED_COUNT):
		var pick: int = rng.randi_range(
			0, candidates.size() - 1
		)
		var wire_index: int = candidates[pick]
		candidates.remove_at(pick)

		infected_wires.append(wire_index)
		virus_point_indices[wire_index] = rng.randi_range(
			18, SAMPLES - 18
		)

	queue_redraw()


func set_interaction_enabled(enabled: bool) -> void:
	interaction_enabled = enabled and cut_wire_index == -1


func is_wire_infected(wire_index: int) -> bool:
	return infected_wires.has(wire_index)


func _gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not interaction_enabled:
		return

	if not event is InputEventMouseButton:
		return

	var mouse_event: InputEventMouseButton = (
		event as InputEventMouseButton
	)

	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	if not mouse_event.pressed:
		return

	var wire_index: int = _find_wire_at(mouse_event.position)

	# Klik ruang kosong tidak memotong apa pun.
	if wire_index == -1:
		return

	# Kunci pilihan sebelum mengirim hasil.
	interaction_enabled = false
	cut_wire_index = wire_index

	var path: PackedVector2Array = wire_paths[wire_index]
	var start_x: float = path[0].x
	var end_x: float = path[path.size() - 1].x

	cut_ratio = clampf(
		(mouse_event.position.x - start_x) / (end_x - start_x),
		0.0,
		1.0
	)

	queue_redraw()
	accept_event()

	wire_cut.emit(wire_index, is_wire_infected(wire_index))


func _find_wire_at(point: Vector2) -> int:
	var nearest_index: int = -1
	var best_distance_squared: float = (
		CLICK_DISTANCE * CLICK_DISTANCE
	)

	for wire_index in range(wire_paths.size()):
		var path: PackedVector2Array = wire_paths[wire_index]

		# Bagian yang dipotong adalah badan kabel.
		if point.x < path[0].x + 16.0:
			continue

		if point.x > path[path.size() - 1].x - 16.0:
			continue

		for segment_index in range(path.size() - 1):
			var closest: Vector2 = (
				Geometry2D.get_closest_point_to_segment(
					point,
					path[segment_index],
					path[segment_index + 1]
				)
			)

			var distance_squared: float = (
				point.distance_squared_to(closest)
			)

			if distance_squared < best_distance_squared:
				best_distance_squared = distance_squared
				nearest_index = wire_index

	return nearest_index


func _build_wires() -> void:
	wire_paths.clear()

	if size.x < 200.0 or size.y < 120.0:
		queue_redraw()
		return

	var lane_height: float = (
		(size.y - 36.0) / float(WIRE_COLORS.size())
	)
	var amplitude: float = minf(lane_height * 0.18, 6.0)

	for wire_index in range(WIRE_COLORS.size()):
		var points: PackedVector2Array = PackedVector2Array()

		var base_y: float = (
			18.0 + lane_height * (float(wire_index) + 0.5)
		)

		for point_index in range(SAMPLES + 1):
			var t: float = float(point_index) / float(SAMPLES)
			var x: float = lerpf(68.0, size.x - 68.0, t)

			var wave: float = sin(
				t * TAU * 2.0 + float(wire_index) * 0.7
			)
			wave *= sin(t * PI) * amplitude

			points.append(Vector2(x, base_y + wave))

		wire_paths.append(points)

	queue_redraw()


func _draw() -> void:
	if wire_paths.is_empty():
		return

	var font: Font = get_theme_font("font", "Label")
	var lane_height: float = (
		(size.y - 36.0) / float(WIRE_COLORS.size())
	)

	for index in range(wire_paths.size()):
		if index % 2 == 0:
			var center_y: float = wire_paths[index][0].y
			var stripe: Rect2 = Rect2(
				Vector2(0.0, center_y - lane_height * 0.5),
				Vector2(size.x, lane_height)
			)
			draw_rect(stripe, Color(1.0, 1.0, 1.0, 0.025))

	for index in range(wire_paths.size()):
		var path: PackedVector2Array = wire_paths[index]
		var cable_color: Color = WIRE_COLORS[index]

		if index == cut_wire_index:
			var pieces: Array[PackedVector2Array] = (
				_get_cut_pieces(path)
			)

			for piece in pieces:
				if piece.size() < 2:
					continue

				_draw_cable(piece, cable_color)
				_draw_cut_end(piece[0], path)
				_draw_cut_end(piece[piece.size() - 1], path)
		else:
			_draw_cable(path, cable_color)

		_draw_terminal(path[0], cable_color)
		_draw_terminal(path[path.size() - 1], cable_color)

		draw_string(
			font,
			Vector2(10.0, path[0].y + 5.0),
			"%02d" % (index + 1),
			HORIZONTAL_ALIGNMENT_CENTER,
			28.0,
			14,
			Color("#B7ABCE")
		)

	for wire_index in infected_wires:
		if wire_index == cut_wire_index:
			continue

		var infected_path: PackedVector2Array = wire_paths[
			wire_index
		]
		var point_index: int = int(
			virus_point_indices[wire_index]
		)

		_draw_virus(infected_path[point_index])


func _get_cut_pieces(
	path: PackedVector2Array
) -> Array[PackedVector2Array]:
	var cut_x: float = lerpf(
		path[0].x,
		path[path.size() - 1].x,
		cut_ratio
	)

	var cutting_polygon: PackedVector2Array = (
		PackedVector2Array([
			Vector2(cut_x - CUT_HALF_WIDTH, -20.0),
			Vector2(cut_x + CUT_HALF_WIDTH, -20.0),
			Vector2(cut_x + CUT_HALF_WIDTH, size.y + 20.0),
			Vector2(cut_x - CUT_HALF_WIDTH, size.y + 20.0),
		])
	)

	return Geometry2D.clip_polyline_with_polygon(
		path, cutting_polygon
	)


func _draw_cable(
	path: PackedVector2Array,
	cable_color: Color
) -> void:
	draw_polyline(
		_shift_path(path, Vector2(0.0, 3.0)),
		Color("#05040A"),
		16.0,
		true
	)
	draw_polyline(
		path, cable_color.darkened(0.6), 13.0, true
	)
	draw_polyline(path, cable_color, 9.0, true)
	draw_polyline(
		_shift_path(path, Vector2(0.0, -2.0)),
		cable_color.lightened(0.45),
		2.0,
		true
	)


func _draw_cut_end(
	point: Vector2,
	original_path: PackedVector2Array
) -> void:
	if point.distance_squared_to(original_path[0]) < 1.0:
		return

	if point.distance_squared_to(
		original_path[original_path.size() - 1]
	) < 1.0:
		return

	draw_circle(point, 3.0, Color("#FFC98C"))


func _shift_path(
	points: PackedVector2Array,
	offset: Vector2
) -> PackedVector2Array:
	var shifted: PackedVector2Array = PackedVector2Array()

	for point in points:
		shifted.append(point + offset)

	return shifted


func _draw_terminal(
	center: Vector2,
	cable_color: Color
) -> void:
	draw_rect(
		Rect2(
			center - Vector2(11.0, 10.0),
			Vector2(22.0, 20.0)
		),
		Color("#777088")
	)
	draw_rect(
		Rect2(
			center - Vector2(7.0, 6.0),
			Vector2(14.0, 12.0)
		),
		Color("#211B31")
	)
	draw_circle(center, 3.0, cable_color)


func _draw_virus(center: Vector2) -> void:
	var virus_color: Color = Color("#95F542")
	var dark_color: Color = Color("#10200B")

	draw_circle(center, 13.0, Color("#080B12"))

	for spike_index in range(8):
		var angle: float = TAU * float(spike_index) / 8.0
		var direction: Vector2 = Vector2.RIGHT.rotated(angle)
		var inner_point: Vector2 = center + direction * 6.0
		var outer_point: Vector2 = center + direction * 10.0

		draw_line(
			inner_point, outer_point, virus_color, 2.0, true
		)
		draw_circle(outer_point, 1.8, virus_color)

	draw_circle(center, 8.0, virus_color.darkened(0.45))
	draw_circle(center, 6.5, virus_color)

	draw_circle(
		center + Vector2(-2.3, -1.2), 1.2, dark_color
	)
	draw_circle(
		center + Vector2(2.3, -1.2), 1.2, dark_color
	)
	draw_line(
		center + Vector2(-2.0, 2.5),
		center + Vector2(2.0, 2.5),
		dark_color,
		1.5,
		true
	)
