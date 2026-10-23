extends Control

signal finished(won: bool)

const KIT := preload("res://scripts/ui/ui_kit.gd")

const FIELD := Vector2(480, 360)
const PADDLE_SPEED := 520.0
const PADDLE_SIZE := Vector2(96, 14)
const BALL_SIZE := 14.0
const BRICK_COLS := 8
const SETTINGS := {
	"kind": {"lives": 5, "ball": 290.0, "rows": 3, "label": "Baik Hati (mudah)"},
	"normal": {"lives": 3, "ball": 330.0, "rows": 4, "label": "Seimbang (normal)"},
	"hardcore": {"lives": 2, "ball": 410.0, "rows": 5, "label": "Genosida (hardcore)"},
}

var difficulty: String = "normal"

@onready var mode_label: Label = $Panel/VBoxContainer/ModeLabel
@onready var lives_label: Label = $Panel/VBoxContainer/HeaderRow/LivesLabel
@onready var bricks_label: Label = $Panel/VBoxContainer/HeaderRow/BricksLabel
@onready var field: Control = $Panel/VBoxContainer/Field
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel

var _ball_speed := 330.0
var _brick_rows := 4
var _lives := 3
var _bricks: Array = []
var _bricks_remaining := 0
var _paddle_x := 0.0
var _ball_pos := Vector2.ZERO
var _ball_vel := Vector2.ZERO
var _trail: Array[Vector2] = []
var _bursts: Array = []
var _launched := false
var _finished := false
var _time := 0.0
var _brick_style := StyleBoxFlat.new()
var _paddle_style := StyleBoxFlat.new()


func _ready() -> void:
	var cfg: Dictionary = SETTINGS.get(difficulty, SETTINGS["normal"])
	_lives = cfg["lives"]
	_ball_speed = cfg["ball"]
	_brick_rows = cfg["rows"]
	mode_label.text = tr("Mode: %s") % tr(cfg["label"])
	_brick_style.set_corner_radius_all(2)
	_brick_style.set_border_width_all(2)
	_paddle_style.set_corner_radius_all(2)
	_paddle_style.bg_color = Color(0.85, 0.9, 1.0)
	_paddle_style.border_color = Color(0.35, 0.5, 0.8)
	_paddle_style.set_border_width_all(2)
	field.custom_minimum_size = FIELD
	field.draw.connect(_on_field_draw)
	_paddle_x = (FIELD.x - PADDLE_SIZE.x) / 2.0
	_build_bricks()
	_reset_ball()
	_update_labels()


func _build_bricks() -> void:
	var gap := 4.0
	var brick_w: float = (FIELD.x - gap * (BRICK_COLS + 1)) / BRICK_COLS
	var brick_h := 22.0
	for row in _brick_rows:
		for col in BRICK_COLS:
			_bricks.append({
				"rect": Rect2(gap + col * (brick_w + gap), 14.0 + gap + row * (brick_h + gap), brick_w, brick_h),
				"color": Color.from_hsv(0.78 - 0.1 * row, 0.62, 0.92),
				"alive": true,
			})
			_bricks_remaining += 1


func _reset_ball() -> void:
	_launched = false
	_ball_vel = Vector2.ZERO
	_trail.clear()
	_stick_ball_to_paddle()
	status_label.text = Settings.fill(tr("Tekan {jump} untuk meluncurkan bola"))


func _stick_ball_to_paddle() -> void:
	_ball_pos = Vector2(_paddle_x + PADDLE_SIZE.x / 2.0 - BALL_SIZE / 2.0, FIELD.y - 40.0 - BALL_SIZE)


func _process(delta: float) -> void:
	_time += delta
	for b in _bursts:
		b["t"] += delta * 3.0
	_bursts = _bursts.filter(func(b): return b["t"] < 1.0)
	if not _finished:
		_update_game(delta)
	field.queue_redraw()


func _update_game(delta: float) -> void:
	var input_dir := Input.get_axis("move_left", "move_right")
	_paddle_x = clampf(_paddle_x + input_dir * PADDLE_SPEED * delta, 0.0, FIELD.x - PADDLE_SIZE.x)

	if not _launched:
		_stick_ball_to_paddle()
		if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("ui_accept"):
			_launched = true
			AudioManager.play_sfx("mg_bounce", -6.0)
			var dir_x := 1.0 if randi() % 2 == 0 else -1.0
			_ball_vel = Vector2(_ball_speed * 0.6 * dir_x, -_ball_speed)
			status_label.text = "Hancurkan semua brick virus! Jangan biarkan bola jatuh."
		return

	_trail.append(_ball_pos)
	if _trail.size() > 7:
		_trail.pop_front()
	_ball_pos += _ball_vel * delta

	if _ball_pos.x <= 0.0:
		_ball_pos.x = 0.0
		_ball_vel.x = absf(_ball_vel.x)
	elif _ball_pos.x + BALL_SIZE >= FIELD.x:
		_ball_pos.x = FIELD.x - BALL_SIZE
		_ball_vel.x = -absf(_ball_vel.x)
	if _ball_pos.y <= 0.0:
		_ball_pos.y = 0.0
		_ball_vel.y = absf(_ball_vel.y)

	var ball_rect := Rect2(_ball_pos, Vector2(BALL_SIZE, BALL_SIZE))
	var paddle_rect := Rect2(Vector2(_paddle_x, FIELD.y - 40.0), PADDLE_SIZE)
	if _ball_vel.y > 0.0 and ball_rect.intersects(paddle_rect):
		_ball_vel.y = -absf(_ball_vel.y)
		var hit_offset := (ball_rect.get_center().x - paddle_rect.get_center().x) / (PADDLE_SIZE.x / 2.0)
		_ball_vel.x = clampf(hit_offset, -1.0, 1.0) * _ball_speed
		_ball_pos.y = paddle_rect.position.y - BALL_SIZE
		AudioManager.play_sfx("mg_bounce", -6.0, 0.05)

	for brick in _bricks:
		if not brick["alive"]:
			continue
		var brick_rect: Rect2 = brick["rect"]
		if ball_rect.intersects(brick_rect):
			brick["alive"] = false
			AudioManager.play_sfx("mg_brick", -4.0, 0.1)
			_bricks_remaining -= 1
			_bursts.append({"rect": brick_rect, "color": brick["color"], "t": 0.0})
			var dx := absf(ball_rect.get_center().x - brick_rect.get_center().x) / brick_rect.size.x
			var dy := absf(ball_rect.get_center().y - brick_rect.get_center().y) / brick_rect.size.y
			if dx > dy:
				_ball_vel.x = -_ball_vel.x
			else:
				_ball_vel.y = -_ball_vel.y
			_update_labels()
			break

	if _ball_pos.y > FIELD.y:
		_lives -= 1
		AudioManager.play_sfx("mg_wrong", -3.0)
		_update_labels()
		if _lives <= 0:
			_end(false)
		else:
			_reset_ball()
		return

	if _bricks_remaining <= 0:
		_end(true)


func _update_labels() -> void:
	lives_label.text = "Nyawa: %d" % _lives
	bricks_label.text = "Brick virus tersisa: %d" % _bricks_remaining


func _end(won: bool) -> void:
	_finished = true
	status_label.text = "VIRUS DIHAPUS! Robot dibebaskan." if won else "GAGAL... bola jatuh terlalu sering. Coba lagi!"
	await get_tree().create_timer(1.5, true, false, true).timeout
	finished.emit(won)


func _on_field_draw() -> void:
	KIT.draw_panel(field, Rect2(Vector2(-10, -10), FIELD + Vector2(20, 20)), Color(KIT.INK_950, 0.96), KIT.STEEL, 10.0, KIT.AMBER, true)
	for y in 12:
		field.draw_rect(Rect2(0, y * 30, FIELD.x, 30), Color(0.07, 0.06, 0.12) if y % 2 == 0 else Color(0.08, 0.07, 0.14))

	for brick in _bricks:
		if brick["alive"]:
			var col: Color = brick["color"]
			_brick_style.bg_color = col
			_brick_style.border_color = col.darkened(0.45)
			field.draw_style_box(_brick_style, brick["rect"])
			var r: Rect2 = brick["rect"]
			field.draw_rect(Rect2(r.position + Vector2(4, 3), Vector2(r.size.x - 8, 5)), Color(1, 1, 1, 0.3))
	for b in _bursts:
		var k: float = b["t"]
		var r: Rect2 = b["rect"]
		field.draw_rect(r.grow(6.0 * k), Color(Color(b["color"]).lightened(0.5), 1.0 - k))

	for i in _trail.size():
		var a := float(i + 1) / (_trail.size() + 1) * 0.35
		field.draw_circle(_trail[i] + Vector2(BALL_SIZE, BALL_SIZE) / 2.0, BALL_SIZE * 0.5, Color(1, 1, 1, a))
	var ball_center := _ball_pos + Vector2(BALL_SIZE, BALL_SIZE) / 2.0
	field.draw_circle(ball_center, BALL_SIZE * 0.95, Color(1, 1, 1, 0.18))
	field.draw_circle(ball_center, BALL_SIZE * 0.5, Color.WHITE)

	field.draw_style_box(_paddle_style, Rect2(Vector2(_paddle_x, FIELD.y - 40.0), PADDLE_SIZE))
	field.draw_rect(Rect2(_paddle_x + 8.0, FIELD.y - 38.0, PADDLE_SIZE.x - 16.0, 3.0), Color(1, 1, 1, 0.55))

	for i in _lives:
		_draw_heart(Vector2(FIELD.x - 20.0 - i * 24.0, 12.0))

	if not _launched and not _finished:
		var font := get_theme_default_font()
		var box := Rect2(Vector2(FIELD.x / 2.0 - 190.0, FIELD.y / 2.0 + 20.0), Vector2(380, 40))
		field.draw_rect(box, Color(0, 0, 0, 0.7))
		field.draw_string(font, box.position + Vector2(0, 27), Settings.fill(tr("Tekan {jump} untuk meluncurkan bola")),
				HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 21, Color(1, 0.9, 0.5))


func _draw_heart(c: Vector2) -> void:
	var red := Color(0.95, 0.25, 0.35)
	field.draw_circle(c + Vector2(-4, -2), 5.0, red)
	field.draw_circle(c + Vector2(4, -2), 5.0, red)
	field.draw_colored_polygon(PackedVector2Array([c + Vector2(-9, 0), c + Vector2(9, 0), c + Vector2(0, 10)]), red)
