extends Control

## Classic paddle-and-ball Brick Breaker, built entirely from ColorRect nodes
## with manual AABB collision — no physics bodies needed for a game this simple.

signal finished(won: bool)

const PADDLE_SPEED := 500.0
const BALL_SPEED := 320.0
const BRICK_ROWS := 4
const BRICK_COLS := 8
const LIVES_START := 3

@onready var play_area: Control = $Panel/PlayArea
@onready var paddle: ColorRect = $Panel/PlayArea/Paddle
@onready var ball: ColorRect = $Panel/PlayArea/Ball
@onready var bricks_container: Control = $Panel/PlayArea/BricksContainer
@onready var lives_label: Label = $Panel/HeaderRow/LivesLabel

var _ball_velocity: Vector2 = Vector2.ZERO
var _lives := LIVES_START
var _bricks_remaining := 0
var _finished := false
var _play_area_size: Vector2


func _ready() -> void:
	_play_area_size = play_area.size
	_build_bricks()
	_reset_ball()
	_update_labels()


func _build_bricks() -> void:
	var gap := 4.0
	var brick_w: float = (_play_area_size.x - gap * (BRICK_COLS + 1)) / BRICK_COLS
	var brick_h := 22.0
	for row in BRICK_ROWS:
		for col in BRICK_COLS:
			var brick := ColorRect.new()
			brick.size = Vector2(brick_w, brick_h)
			brick.position = Vector2(gap + col * (brick_w + gap), gap + row * (brick_h + gap))
			brick.color = Color.from_hsv(float(row) / BRICK_ROWS, 0.6, 0.9)
			bricks_container.add_child(brick)
			_bricks_remaining += 1


func _reset_ball() -> void:
	ball.position = Vector2(_play_area_size.x / 2.0 - ball.size.x / 2.0, _play_area_size.y - 90.0)
	var dir_x := 1.0 if randi() % 2 == 0 else -1.0
	_ball_velocity = Vector2(BALL_SPEED * dir_x, -BALL_SPEED)


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
		_ball_velocity.x = clampf(hit_offset, -1.0, 1.0) * BALL_SPEED

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
	lives_label.text = "Lives: %d" % _lives


func _end(won: bool) -> void:
	_finished = true
	finished.emit(won)
