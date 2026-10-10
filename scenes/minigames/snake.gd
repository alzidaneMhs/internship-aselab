extends Control

## Snake - the classic, but the "apples" are virus elements contaminating the
## robot. Eat enough of them to cleanse it. Difficulty follows reputation.

signal finished(won: bool)

const CELL := 24
const COLS := 20
const ROWS := 15
const SETTINGS := {
	"kind": {"tick": 0.2, "target": 6, "label": "Baik Hati"},
	"normal": {"tick": 0.15, "target": 10, "label": "Seimbang"},
	"hardcore": {"tick": 0.1, "target": 14, "label": "Hardcore"},
}

var difficulty: String = "normal"

@onready var field: Control = $Panel/Field
@onready var title_label: Label = $Panel/TitleLabel
@onready var info_label: Label = $Panel/InfoLabel

var _snake: Array[Vector2i] = []
var _dir := Vector2i.RIGHT
var _next_dir := Vector2i.RIGHT
var _virus := Vector2i.ZERO
var _eaten := 0
var _timer := 0.0
var _tick := 0.15
var _target := 10
var _finished := false


func _ready() -> void:
	var cfg: Dictionary = SETTINGS.get(difficulty, SETTINGS["normal"])
	_tick = cfg["tick"]
	_target = cfg["target"]
	title_label.text = "Snake - %s" % cfg["label"]
	_snake = [Vector2i(6, 7), Vector2i(5, 7), Vector2i(4, 7)]
	field.draw.connect(_on_field_draw)
	_place_virus()
	_update_info()
	field.queue_redraw()


func _process(delta: float) -> void:
	if _finished:
		return
	if Input.is_action_just_pressed("move_up") and _dir != Vector2i.DOWN:
		_next_dir = Vector2i.UP
	elif Input.is_action_just_pressed("move_down") and _dir != Vector2i.UP:
		_next_dir = Vector2i.DOWN
	elif Input.is_action_just_pressed("move_left") and _dir != Vector2i.RIGHT:
		_next_dir = Vector2i.LEFT
	elif Input.is_action_just_pressed("move_right") and _dir != Vector2i.LEFT:
		_next_dir = Vector2i.RIGHT
	_timer += delta
	if _timer >= _tick:
		_timer -= _tick
		_step()


func _step() -> void:
	_dir = _next_dir
	var head: Vector2i = _snake[0] + _dir
	if head.x < 0 or head.x >= COLS or head.y < 0 or head.y >= ROWS or _snake.has(head):
		_end(false)
		return
	_snake.insert(0, head)
	if head == _virus:
		_eaten += 1
		_update_info()
		if _eaten >= _target:
			field.queue_redraw()
			_end(true)
			return
		_place_virus()
	else:
		_snake.pop_back()
	field.queue_redraw()


func _place_virus() -> void:
	var free_cells: Array[Vector2i] = []
	for x in COLS:
		for y in ROWS:
			var c := Vector2i(x, y)
			if not _snake.has(c):
				free_cells.append(c)
	_virus = free_cells[randi() % free_cells.size()]


func _update_info() -> void:
	info_label.text = "Virus dibersihkan: %d / %d" % [_eaten, _target]


func _on_field_draw() -> void:
	field.draw_rect(Rect2(Vector2.ZERO, Vector2(COLS * CELL, ROWS * CELL)), Color(0.05, 0.07, 0.1))
	for i in _snake.size():
		var c: Vector2i = _snake[i]
		var col := Color(0.5, 1.0, 0.95) if i == 0 else Color(0.2, 0.75, 0.8)
		field.draw_rect(Rect2(Vector2(c) * CELL + Vector2.ONE, Vector2(CELL - 2, CELL - 2)), col)
	var center := Vector2(_virus) * CELL + Vector2(CELL, CELL) / 2.0
	for i in 8:
		var a := TAU * i / 8.0
		field.draw_line(center, center + Vector2(cos(a), sin(a)) * (CELL * 0.48), Color(0.9, 0.2, 0.7), 2.0)
	field.draw_circle(center, CELL * 0.3, Color(0.9, 0.2, 0.7))
	field.draw_circle(center - Vector2(2, 2), CELL * 0.1, Color(1.0, 0.8, 0.95))


func _end(won: bool) -> void:
	_finished = true
	title_label.text = "Virus dihapus!" if won else "Gagal... virus masih ada"
	await get_tree().create_timer(1.2, true, false, true).timeout
	finished.emit(won)
