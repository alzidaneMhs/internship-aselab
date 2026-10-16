extends Control

signal finished(won: bool)

const KIT := preload("res://scripts/ui/ui_kit.gd")

const COLUMNS := 8
const ROWS := 8
const CELL := 40
const GAP := 3
const SETTINGS := {
	"kind": {"colors": 3, "target": 30, "moves": 20, "label": "Baik Hati (mudah)"},
	"normal": {"colors": 4, "target": 40, "moves": 15, "label": "Seimbang (normal)"},
	"hardcore": {"colors": 5, "target": 55, "moves": 12, "label": "Genosida (hardcore)"},
}
const CELL_COLORS := [
	Color(1.0, 0.3, 0.3),
	Color(0.3, 0.62, 1.0),
	Color(1.0, 0.725, 0.22),
	Color(0.35, 0.88, 0.54),
	Color(0.69, 0.38, 1.0),
]

var difficulty: String = "normal"

@onready var mode_label: Label = $Panel/VBoxContainer/ModeLabel
@onready var virus_bar: ProgressBar = $Panel/VBoxContainer/VirusRow/VirusBar
@onready var virus_percent: Label = $Panel/VBoxContainer/VirusRow/PercentLabel
@onready var score_label: Label = $Panel/VBoxContainer/HeaderRow/ScoreLabel
@onready var moves_label: Label = $Panel/VBoxContainer/HeaderRow/MovesLabel
@onready var hint_label: Label = $Panel/VBoxContainer/HintLabel
@onready var board: Control = $Panel/VBoxContainer/Board

var _color_count := 4
var _target := 40
var _moves_left := 15
var _board: Array = []
var _score := 0
var _finished := false
var _hover := Vector2i(-1, -1)
var _hover_group: Array = []
var _cursor_mode := false
var _fading: Array = []
var _time := 0.0
var _cell_style := StyleBoxFlat.new()


func _ready() -> void:
	var cfg: Dictionary = SETTINGS.get(difficulty, SETTINGS["normal"])
	_color_count = cfg["colors"]
	_target = cfg["target"]
	_moves_left = cfg["moves"]
	mode_label.text = tr("Mode: %s") % tr(cfg["label"])
	_cell_style.set_corner_radius_all(2)
	_cell_style.set_border_width_all(2)
	board.custom_minimum_size = Vector2(COLUMNS * (CELL + GAP) - GAP, ROWS * (CELL + GAP) - GAP)
	board.draw.connect(_on_board_draw)
	board.gui_input.connect(_on_board_input)
	board.mouse_exited.connect(_on_board_mouse_exited)
	_generate_board()
	_update_labels()
	hint_label.text = "Arahkan kursor ke blok untuk melihat kelompoknya"


func _generate_board() -> void:
	_board.resize(COLUMNS)
	for x in COLUMNS:
		var col: Array = []
		col.resize(ROWS)
		for y in ROWS:
			col[y] = randi() % _color_count
		_board[x] = col


func _process(delta: float) -> void:
	_time += delta
	for f in _fading:
		f["t"] += delta * 4.0
	_fading = _fading.filter(func(f): return f["t"] < 1.0)
	board.queue_redraw()


func _cell_at(pos: Vector2) -> Vector2i:
	var step := CELL + GAP
	var cx := int(pos.x / step)
	var cy := int(pos.y / step)
	if cx < 0 or cx >= COLUMNS or cy < 0 or cy >= ROWS:
		return Vector2i(-1, -1)
	if fposmod(pos.x, step) > CELL or fposmod(pos.y, step) > CELL:
		return Vector2i(-1, -1)
	return Vector2i(cx, cy)


func _on_board_input(event: InputEvent) -> void:
	if _finished:
		return
	if event is InputEventMouseMotion:
		_cursor_mode = false
		_set_hover(_cell_at(event.position))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := _cell_at(event.position)
		if cell.x >= 0:
			_on_cell_pressed(cell.x, cell.y)
			_set_hover(cell)


func _on_board_mouse_exited() -> void:
	if not _cursor_mode:
		_set_hover(Vector2i(-1, -1))


func _unhandled_input(event: InputEvent) -> void:
	if _finished:
		return
	var dir := Vector2i.ZERO
	if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		dir = Vector2i(-1, 0)
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		dir = Vector2i(1, 0)
	elif event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		dir = Vector2i(0, -1)
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		dir = Vector2i(0, 1)
	if dir != Vector2i.ZERO:
		_cursor_mode = true
		var cell := _hover
		if cell.x < 0:
			cell = Vector2i(COLUMNS / 2, ROWS / 2)
		else:
			cell = Vector2i(clampi(cell.x + dir.x, 0, COLUMNS - 1), clampi(cell.y + dir.y, 0, ROWS - 1))
		_set_hover(cell)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("jump") or event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		if _hover.x >= 0:
			var keep := _hover
			_on_cell_pressed(keep.x, keep.y)
			_set_hover(keep)
		get_viewport().set_input_as_handled()


func _set_hover(cell: Vector2i) -> void:
	_hover = cell
	_hover_group = []
	if cell.x < 0 or _board[cell.x][cell.y] < 0:
		hint_label.text = "Arahkan kursor ke blok untuk melihat kelompoknya"
		return
	var group := _find_group(cell.x, cell.y, _board[cell.x][cell.y])
	if group.size() >= 2:
		_hover_group = group
		hint_label.text = Settings.fill(tr("Klik / {jump} untuk hapus %d blok  (-%d%% virus)")) % [group.size(), roundi(100.0 * group.size() / _target)]
	else:
		hint_label.text = "Blok sendirian tidak bisa dihapus. Cari yang bergandengan!"


func _on_cell_pressed(x: int, y: int) -> void:
	var color_index: int = _board[x][y]
	if color_index < 0:
		return
	var group := _find_group(x, y, color_index)
	if group.size() < 2:
		return
	for cell in group:
		_fading.append({"pos": Vector2(cell.x * (CELL + GAP), cell.y * (CELL + GAP)), "color": color_index, "t": 0.0})
		_board[cell.x][cell.y] = -1
	_score += group.size()
	_moves_left -= 1
	_apply_gravity()
	_update_labels()
	_check_end()


func _find_group(sx: int, sy: int, color_index: int) -> Array:
	var visited: Dictionary = {}
	var stack: Array = [Vector2i(sx, sy)]
	var group: Array = []
	while not stack.is_empty():
		var cell: Vector2i = stack.pop_back()
		if visited.has(cell):
			continue
		if cell.x < 0 or cell.x >= COLUMNS or cell.y < 0 or cell.y >= ROWS:
			continue
		if _board[cell.x][cell.y] != color_index:
			continue
		visited[cell] = true
		group.append(cell)
		stack.append(Vector2i(cell.x + 1, cell.y))
		stack.append(Vector2i(cell.x - 1, cell.y))
		stack.append(Vector2i(cell.x, cell.y + 1))
		stack.append(Vector2i(cell.x, cell.y - 1))
	return group


func _apply_gravity() -> void:
	for x in COLUMNS:
		var stack: Array = []
		for y in ROWS:
			if _board[x][y] >= 0:
				stack.append(_board[x][y])
		var new_col: Array = []
		for _i in ROWS - stack.size():
			new_col.append(-1)
		new_col.append_array(stack)
		_board[x] = new_col

	var non_empty: Array = []
	for x in COLUMNS:
		var has_any := false
		for y in ROWS:
			if _board[x][y] >= 0:
				has_any = true
				break
		if has_any:
			non_empty.append(_board[x])
	while non_empty.size() < COLUMNS:
		var empty_col: Array = []
		for _i in ROWS:
			empty_col.append(-1)
		non_empty.append(empty_col)
	_board = non_empty


func _has_valid_move() -> bool:
	for x in COLUMNS:
		for y in ROWS:
			if _board[x][y] >= 0 and _find_group(x, y, _board[x][y]).size() >= 2:
				return true
	return false


func _update_labels() -> void:
	var remaining := 1.0 - minf(float(_score) / _target, 1.0)
	virus_bar.value = remaining * 100.0
	virus_percent.text = "%d%%" % roundi(remaining * 100.0)
	score_label.text = "Dihapus: %d / %d" % [_score, _target]
	moves_label.text = "Sisa langkah: %d" % _moves_left


func _check_end() -> void:
	if _score >= _target:
		_end(true)
	elif _moves_left <= 0 or not _has_valid_move():
		_end(false)


func _end(won: bool) -> void:
	_finished = true
	_hover_group = []
	hint_label.text = ""
	mode_label.text = "VIRUS DIHAPUS! Robot dibebaskan." if won else "GAGAL... virus masih ada. Coba lagi!"
	await get_tree().create_timer(1.5, true, false, true).timeout
	finished.emit(won)


func _on_board_draw() -> void:
	var step := CELL + GAP
	KIT.draw_panel(board, Rect2(Vector2(-10, -10), board.size + Vector2(20, 20)), Color(KIT.INK_950, 0.96), KIT.STEEL, 10.0, KIT.AMBER, true)
	for x in COLUMNS:
		for y in ROWS:
			var rect := Rect2(x * step, y * step, CELL, CELL)
			var c: int = _board[x][y]
			if c < 0:
				board.draw_rect(rect, Color(1, 1, 1, 0.04))
				continue
			_draw_block(rect, c, _hover_group.has(Vector2i(x, y)))
	for f in _fading:
		var k: float = f["t"]
		var rect := Rect2(f["pos"], Vector2(CELL, CELL))
		var shrink: float = CELL * 0.5 * k
		var col: Color = CELL_COLORS[f["color"]]
		board.draw_rect(rect.grow(-shrink), Color(col.lightened(0.4), 1.0 - k))
	if not _hover_group.is_empty():
		for cell in _hover_group:
			var r := Rect2(cell.x * step, cell.y * step, CELL, CELL)
			board.draw_rect(r.grow(1.0), Color(1, 1, 1, 0.9), false, 3.0)
	if _cursor_mode and _hover.x >= 0:
		var pulse := 0.6 + 0.4 * sin(_time * 8.0)
		var cr := Rect2(_hover.x * step, _hover.y * step, CELL, CELL).grow(4.0)
		board.draw_rect(cr, Color(KIT.AMBER, pulse), false, 4.0)


func _draw_block(rect: Rect2, color_index: int, highlighted: bool) -> void:
	var base: Color = CELL_COLORS[color_index]
	if highlighted:
		base = base.lightened(0.18 + 0.08 * sin(_time * 8.0))
	_cell_style.bg_color = base
	_cell_style.border_color = base.darkened(0.4)
	board.draw_style_box(_cell_style, rect)
	board.draw_rect(Rect2(rect.position + Vector2(5, 4), Vector2(CELL - 10, 7)), Color(1, 1, 1, 0.28))
	var c := rect.get_center() + Vector2(0, 2)
	var ink := Color(1, 1, 1, 0.55)
	match color_index:
		0:
			board.draw_circle(c, 7.0, ink)
		1:
			board.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -8), c + Vector2(8, 0), c + Vector2(0, 8), c + Vector2(-8, 0)]), ink)
		2:
			board.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -8), c + Vector2(8, 7), c + Vector2(-8, 7)]), ink)
		3:
			board.draw_rect(Rect2(c - Vector2(6, 6), Vector2(12, 12)), ink)
		4:
			board.draw_arc(c, 7.0, 0.0, TAU, 16, ink, 3.0)
