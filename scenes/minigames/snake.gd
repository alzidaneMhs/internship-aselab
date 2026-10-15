extends Control

signal finished(won: bool)

const KIT := preload("res://scripts/ui/ui_kit.gd")

const CELL := 24
const COLS := 20
const ROWS := 15
const SETTINGS := {
	"kind": {"tick": 0.2, "target": 6, "label": "Baik Hati (mudah)"},
	"normal": {"tick": 0.15, "target": 10, "label": "Seimbang (normal)"},
	"hardcore": {"tick": 0.1, "target": 14, "label": "Genosida (hardcore)"},
}

var difficulty: String = "normal"

@onready var mode_label: Label = $Panel/VBoxContainer/ModeLabel
@onready var progress_bar: ProgressBar = $Panel/VBoxContainer/ProgressRow/ProgressBar
@onready var progress_label: Label = $Panel/VBoxContainer/ProgressRow/ProgressLabel
@onready var field: Control = $Panel/VBoxContainer/Field
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel

var _snake: Array[Vector2i] = []
var _dir := Vector2i.RIGHT
var _next_dir := Vector2i.RIGHT
var _virus := Vector2i.ZERO
var _eaten := 0
var _timer := 0.0
var _time := 0.0
var _tick := 0.15
var _target := 10
var _started := false
var _finished := false
var _body_style := StyleBoxFlat.new()


func _ready() -> void:
	var cfg: Dictionary = SETTINGS.get(difficulty, SETTINGS["normal"])
	_tick = cfg["tick"]
	_target = cfg["target"]
	mode_label.text = "Mode: %s" % cfg["label"]
	_body_style.set_corner_radius_all(2)
	field.custom_minimum_size = Vector2(COLS * CELL, ROWS * CELL)
	field.draw.connect(_on_field_draw)
	_snake = [Vector2i(6, 7), Vector2i(5, 7), Vector2i(4, 7)]
	_place_virus()
	_update_info()
	status_label.text = "Tekan tombol arah (W A S D / panah) untuk mulai"


func _process(delta: float) -> void:
	_time += delta
	if not _finished:
		_read_input()
		if _started:
			_timer += delta
			if _timer >= _tick:
				_timer -= _tick
				_step()
	field.queue_redraw()


func _read_input() -> void:
	var wanted := Vector2i.ZERO
	if Input.is_action_just_pressed("move_up"):
		wanted = Vector2i.UP
	elif Input.is_action_just_pressed("move_down"):
		wanted = Vector2i.DOWN
	elif Input.is_action_just_pressed("move_left"):
		wanted = Vector2i.LEFT
	elif Input.is_action_just_pressed("move_right"):
		wanted = Vector2i.RIGHT
	if wanted == Vector2i.ZERO:
		return
	if wanted != -_dir:
		_next_dir = wanted
	if not _started:
		_started = true
		status_label.text = "Makan virus ungu berduri! Jangan menabrak dinding atau badanmu sendiri."


func _step() -> void:
	_dir = _next_dir
	var head: Vector2i = _snake[0] + _dir
	var tail_leaves := head != _virus
	var body_hit := _snake.slice(0, _snake.size() - 1 if tail_leaves else _snake.size()).has(head)
	if head.x < 0 or head.x >= COLS or head.y < 0 or head.y >= ROWS or body_hit:
		_end(false)
		return
	_snake.insert(0, head)
	if head == _virus:
		_eaten += 1
		_update_info()
		if _eaten >= _target:
			_end(true)
			return
		_place_virus()
	else:
		_snake.pop_back()


func _place_virus() -> void:
	var free_cells: Array[Vector2i] = []
	for x in COLS:
		for y in ROWS:
			var c := Vector2i(x, y)
			if not _snake.has(c):
				free_cells.append(c)
	_virus = free_cells[randi() % free_cells.size()]


func _update_info() -> void:
	progress_bar.value = 100.0 * (1.0 - float(_eaten) / _target)
	progress_label.text = "%d / %d" % [_eaten, _target]


func _end(won: bool) -> void:
	_finished = true
	status_label.text = "VIRUS DIHAPUS! Robot dibebaskan." if won else "GAGAL... ular menabrak. Coba lagi!"
	await get_tree().create_timer(1.5, true, false, true).timeout
	finished.emit(won)


func _on_field_draw() -> void:
	KIT.draw_panel(field, Rect2(Vector2(-10, -10), Vector2(COLS * CELL + 20, ROWS * CELL + 20)), Color(KIT.INK_950, 0.96), KIT.STEEL, 10.0, KIT.AMBER, true)
	for x in COLS:
		for y in ROWS:
			var shade := 0.075 if (x + y) % 2 == 0 else 0.095
			field.draw_rect(Rect2(x * CELL, y * CELL, CELL, CELL), Color(shade, shade + 0.015, shade + 0.05))

	_draw_virus()

	var count := _snake.size()
	for i in count:
		var c: Vector2i = _snake[count - 1 - i]
		var k := float(count - 1 - i) / maxf(count - 1, 1)
		var col := Color(0.35, 1.0, 0.9).lerp(Color(0.1, 0.5, 0.6), k)
		_body_style.bg_color = col
		_body_style.border_color = col.darkened(0.4)
		_body_style.set_border_width_all(2)
		field.draw_style_box(_body_style, Rect2(Vector2(c) * CELL + Vector2.ONE, Vector2(CELL - 2, CELL - 2)))
	var head: Vector2i = _snake[0]
	var hc := Vector2(head) * CELL + Vector2(CELL, CELL) / 2.0
	var side := Vector2(-_dir.y, _dir.x) * 5.0
	var fwd := Vector2(_dir) * 4.0
	for s in [-1.0, 1.0]:
		field.draw_circle(hc + fwd + side * s, 3.6, Color.WHITE)
		field.draw_circle(hc + fwd * 1.5 + side * s, 1.6, Color(0.05, 0.05, 0.1))

	if not _started and not _finished:
		var box := Rect2(Vector2(COLS * CELL / 2.0 - 190.0, ROWS * CELL / 2.0 + 40.0), Vector2(380, 40))
		field.draw_rect(box, Color(0, 0, 0, 0.7))
		field.draw_string(get_theme_default_font(), box.position + Vector2(0, 27), "Tekan tombol arah untuk mulai",
				HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 22, Color(1, 0.9, 0.5))


func _draw_virus() -> void:
	var center := Vector2(_virus) * CELL + Vector2(CELL, CELL) / 2.0
	var pulse := 1.0 + 0.12 * sin(_time * 6.0)
	for i in 8:
		var a := TAU * i / 8.0 + _time * 0.8
		field.draw_line(center + Vector2.from_angle(a) * 7.0, center + Vector2.from_angle(a) * 12.0 * pulse, Color(1.0, 0.8, 0.35), 3.0)
	field.draw_circle(center, 8.5 * pulse, Color(1.0, 0.725, 0.22))
	field.draw_circle(center, 5.0, Color(0.667, 0.424, 0.086))
	field.draw_circle(center + Vector2(-2.5, -2.5), 2.2, Color(1.0, 0.95, 0.75))
