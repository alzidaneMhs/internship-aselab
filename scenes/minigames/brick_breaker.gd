extends Control

## Brick Breaker - the bricks are the virus. Difficulty follows reputation.

signal finished(won: bool)

const PADDLE_SPEED := 500.0
const BRICK_COLS := 8
const SETTINGS := {
	"kind": {"lives": 5, "ball": 280.0, "rows": 3, "label": "Baik Hati"},
	"normal": {"lives": 3, "ball": 320.0, "rows": 4, "label": "Seimbang"},
	"hardcore": {"lives": 2, "ball": 400.0, "rows": 5, "label": "Hardcore"},
}

var difficulty: String = "normal"

@onready var play_area: Control = $Panel/PlayArea
@onready var paddle: ColorRect = $Panel/PlayArea/Paddle
@onready var ball: ColorRect = $Panel/PlayArea/Ball
@onready var bricks_container: Control = $Panel/PlayArea/BricksContainer
@onready var lives_label: Label = $Panel/HeaderRow/LivesLabel
@onready var title_label: Label = $Panel/HeaderRow/TitleLabel

var _ball_speed := 320.0
var _brick_rows := 4
var _ball_velocity: Vector2 = Vector2.ZERO
var _lives := 3
var _bricks_remaining := 0
var _finished := false
var _play_area_size: Vector2


func _ready() -> void:
	var cfg: Dictionary = SETTINGS.get(difficulty, SETTINGS["normal"])
	_lives = cfg["lives"]
	_ball_speed = cfg["ball"]
	_brick_rows = cfg["rows"]
	title_label.text = "Brick Breaker - %s" % cfg["label"]
	_play_area_size = play_area.size
	_build_bricks()
	_reset_ball()
	_update_labels()


func _build_bricks() -> void:
	var gap := 4.0
	var brick_w: float = (_play_area_size.x - gap * (BRICK_COLS + 1)) / BRICK_COLS
	var brick_h := 22.0
	for row in _brick_rows:
		for col in BRICK_COLS:
			var brick := ColorRect.new()
			brick.size = Vector2(brick_w, brick_h)
			brick.position = Vector2(gap + col * (brick_w + gap), gap + row * (brick_h + gap))
			brick.color = Color.from_hsv(0.25 + 0.12 * row, 0.65, 0.85)
			bricks_container.add_child(brick)
			_bricks_remaining += 1


func _reset_ball() -> void:
	ball.position = Vector2(_play_area_size.x / 2.0 - ball.size.x / 2.0, _play_area_size.y - 90.0)
	var dir_x := 1.0 if randi() % 2 == 0 else -1.0
	_ball_velocity = Vector2(_ball_speed * dir_x, -_ball_speed)


func _process(delta: float) -> void:
	if _finished:
		return

	var input_dir := Input.get_axis("move_left", "move_right")
	paddle.position.x = clampf(
		paddle.position.x + input_dir * PADDLE_SPEED * delta,
		0.0,
		_play_area_size.x - paddle.size.x
	)

	ball.position += _ball_velocity * delta

	if ball.position.x <= 0.0:
		ball.position.x = 0.0
		_ball_velocity.x = absf(_ball_velocity.x)
	elif ball.position.x + ball.size.x >= _play_area_size.x:
		ball.position.x = _play_area_size.x - ball.size.x
		_ball_velocity.x = -absf(_ball_velocity.x)
	if ball.position.y <= 0.0:
		ball.position.y = 0.0
		_ball_velocity.y = absf(_ball_velocity.y)

	var ball_rect := Rect2(ball.position, ball.size)
	var paddle_rect := Rect2(paddle.position, paddle.size)
	if _ball_velocity.y > 0.0 and ball_rect.intersects(paddle_rect):
		_ball_velocity.y = -absf(_ball_velocity.y)
		var hit_offset := (ball_rect.get_center().x - paddle_rect.get_center().x) / (paddle.size.x / 2.0)
		_ball_velocity.x = clampf(hit_offset, -1.0, 1.0) * _ball_speed

	for brick in bricks_container.get_children():
		var brick_rect := Rect2(brick.position, brick.size)
		if ball_rect.intersects(brick_rect):
			brick.queue_free()
			_bricks_remaining -= 1
			var dx := absf(ball_rect.get_center().x - brick_rect.get_center().x)
			var dy := absf(ball_rect.get_center().y - brick_rect.get_center().y)
			if dx > dy:
				_ball_velocity.x = -_ball_velocity.x
			else:
				_ball_velocity.y = -_ball_velocity.y
			break

	if ball.position.y > _play_area_size.y:
		_lives -= 1
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


func _end(won: bool) -> void:
	_finished = true
	title_label.text = "Virus dihapus!" if won else "Gagal... virus masih ada"
	await get_tree().create_timer(1.2, true, false, true).timeout
	finished.emit(won)
