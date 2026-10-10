extends Control

## "Block Blast" - clear same-colored groups to shrink the virus bar to zero
## before running out of moves. Difficulty comes from the player's reputation.

signal finished(won: bool)

const COLUMNS := 8
const ROWS := 8
const SETTINGS := {
	"kind": {"colors": 3, "target": 30, "moves": 20, "label": "Baik Hati"},
	"normal": {"colors": 4, "target": 40, "moves": 15, "label": "Seimbang"},
	"hardcore": {"colors": 5, "target": 55, "moves": 12, "label": "Hardcore"},
}
const CELL_COLORS := [
	Color(0.85, 0.25, 0.3),
	Color(0.25, 0.55, 0.9),
	Color(0.95, 0.75, 0.2),
	Color(0.35, 0.8, 0.4),
	Color(0.7, 0.4, 0.9),
]

var difficulty: String = "normal"

@onready var grid: GridContainer = $Panel/VBoxContainer/GridContainer
@onready var mode_label: Label = $Panel/VBoxContainer/ModeLabel
@onready var virus_bar: ProgressBar = $Panel/VBoxContainer/VirusBar
@onready var score_label: Label = $Panel/VBoxContainer/HeaderRow/ScoreLabel
@onready var moves_label: Label = $Panel/VBoxContainer/HeaderRow/MovesLabel

var _color_count := 4
var _target := 40
var _moves_left := 15
var _board: Array = []
var _buttons: Array = []
var _score := 0
var _finished := false


func _ready() -> void:
	var cfg: Dictionary = SETTINGS.get(difficulty, SETTINGS["normal"])
	_color_count = cfg["colors"]
	_target = cfg["target"]
	_moves_left = cfg["moves"]
	mode_label.text = "Mode: %s" % cfg["label"]
	grid.columns = COLUMNS
	_generate_board()
	_build_buttons()
	_redraw()


func _generate_board() -> void:
	_board.resize(COLUMNS)
	for x in COLUMNS:
		var col: Array = []
		col.resize(ROWS)
		for y in ROWS:
			col[y] = randi() % _color_count
		_board[x] = col


func _build_buttons() -> void:
	_buttons.resize(COLUMNS)
	for x in COLUMNS:
		var col: Array = []
		col.resize(ROWS)
		_buttons[x] = col
	for y in ROWS:
		for x in COLUMNS:
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(36, 36)
			btn.pressed.connect(_on_cell_pressed.bind(x, y))
			grid.add_child(btn)
			_buttons[x][y] = btn


func _redraw() -> void:
	for x in COLUMNS:
		for y in ROWS:
			var btn: Button = _buttons[x][y]
			var color_index: int = _board[x][y]
			if color_index < 0:
				btn.modulate = Color(0.18, 0.18, 0.2)
				btn.disabled = true
			else:
				btn.modulate = CELL_COLORS[color_index]
				btn.disabled = false
	virus_bar.value = 100.0 * (1.0 - minf(float(_score) / _target, 1.0))
	score_label.text = "Skor: %d / %d" % [_score, _target]
	moves_label.text = "Langkah: %d" % _moves_left


func _on_cell_pressed(x: int, y: int) -> void:
	if _finished:
		return
	var color_index: int = _board[x][y]
	if color_index < 0:
		return
	var group := _find_group(x, y, color_index)
	if group.size() < 2:
		return
	for cell in group:
		_board[cell.x][cell.y] = -1
	_score += group.size()
	_moves_left -= 1
	_apply_gravity()
	_redraw()
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
			if _board[x][y] < 0:
				continue
			if _find_group(x, y, _board[x][y]).size() >= 2:
				return true
	return false


func _check_end() -> void:
	if _score >= _target:
		_end(true)
	elif _moves_left <= 0 or not _has_valid_move():
		_end(false)


func _end(won: bool) -> void:
	_finished = true
	for x in COLUMNS:
		for y in ROWS:
			_buttons[x][y].disabled = true
	mode_label.text = "Virus dihapus!" if won else "Gagal... virus masih ada"
	await get_tree().create_timer(1.2, true, false, true).timeout
	finished.emit(won)
