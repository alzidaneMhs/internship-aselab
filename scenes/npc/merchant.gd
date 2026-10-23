extends Area2D

const SHOP_UI_SCENE := preload("res://scenes/ui/shop_ui.tscn")

enum Face { IDLE, WAVE, HAPPY, COIN, CONFUSED }

@export var sells_skills: bool = false

@onready var prompt: Label = $Prompt
@onready var sprite: Sprite2D = $Sprite

var _player_in_range := false
var _shop_open := false
var _time := 0.0
var _wave_time := 0.0
var _face := Face.IDLE
var _face_time := 0.0
var _base_scale := Vector2.ONE
var _base_y := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt.visible = false
	_base_scale = sprite.scale
	_base_y = sprite.position.y
	_time = randf() * 10.0


func _process(delta: float) -> void:
	_time += delta
	var breath := sin(_time * 2.1)
	sprite.position.y = _base_y + breath * 1.5
	sprite.scale = _base_scale * Vector2(1.0 - breath * 0.008, 1.0 + breath * 0.012)
	if _wave_time > 0.0:
		_wave_time -= delta
		sprite.frame = Face.WAVE if int(_wave_time / 0.2) % 2 == 0 else Face.IDLE
		return
	if _face_time > 0.0:
		_face_time -= delta
		sprite.frame = _face
		return
	sprite.frame = Face.HAPPY if _player_in_range else Face.IDLE


func show_face(face: Face, duration: float) -> void:
	_wave_time = 0.0
	_face = face
	_face_time = duration


func _draw() -> void:
	draw_set_transform(Vector2(0.0, -2.0), 0.0, Vector2(1.0, 0.24))
	draw_circle(Vector2.ZERO, 50.0, Color(0, 0, 0, 0.28))
	draw_circle(Vector2.ZERO, 34.0, Color(0, 0, 0, 0.2))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		prompt.visible = not _shop_open
		if not _shop_open:
			_face_time = 0.0
			_wave_time = 1.4


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		prompt.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and not _shop_open and event.is_action_pressed("interact"):
		_open_shop()


func _open_shop() -> void:
	_shop_open = true
	prompt.visible = false
	await Story.play_once("hanch_intro")
	if sells_skills:
		await Story.play_once("hanch_skills")
	AudioManager.play_sfx("shop_open")
	var ui: Control = SHOP_UI_SCENE.instantiate()
	ui.set("show_skills", sells_skills)
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(ui)
	get_tree().current_scene.add_child(layer)
	ui.closed.connect(_on_shop_closed.bind(layer, ui))
	get_tree().paused = true


func _on_shop_closed(layer: CanvasLayer, ui: Control) -> void:
	AudioManager.play_sfx("pause_close", -4.0)
	get_tree().paused = false
	_shop_open = false
	prompt.visible = _player_in_range
	var bought := int(ui.get("purchases"))
	if bought > 0:
		show_face(Face.COIN, 2.2)
	else:
		show_face(Face.CONFUSED, 1.8)
	layer.queue_free()
