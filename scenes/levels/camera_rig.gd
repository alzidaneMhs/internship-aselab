extends Camera2D

@export var target_path: NodePath
@export var follow_offset: Vector2 = Vector2(0.0, -120.0)

@onready var target: Node2D = get_node_or_null(target_path)

var _shake_strength := 0.0
var _shake_decay := 40.0

# Cutscene focus: the camera leaves the player and glides to a point of interest.
var _focus_active := false
var _focus_pos := Vector2.ZERO
var _normal_speed := 14.0
var _zoom_tween: Tween


func _ready() -> void:
	add_to_group("main_camera")
	if target != null:
		global_position = target.global_position + follow_offset
		reset_smoothing()


# With physics interpolation on, Godot runs Camera2D in the physics step and
# interpolates it, so following the player's physics position here stays in sync.
func _physics_process(_delta: float) -> void:
	if _focus_active:
		global_position = _focus_pos
	elif target != null:
		global_position = target.global_position + follow_offset


func _process(delta: float) -> void:
	if _shake_strength > 0.0:
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength
		_shake_strength = maxf(_shake_strength - _shake_decay * delta, 0.0)
		if _shake_strength == 0.0:
			offset = Vector2.ZERO


func shake(strength: float) -> void:
	_shake_strength = maxf(_shake_strength, strength)


## Glide to `pos` (world). `pan_speed` is the smoothing speed: low = slow, cinematic pan.
func focus_on(pos: Vector2, pan_speed: float = 2.4, zoom_to: float = 0.0, zoom_time: float = 1.2) -> void:
	if not _focus_active:
		_normal_speed = position_smoothing_speed if position_smoothing_speed > 3.0 else 14.0
	_focus_active = true
	_focus_pos = pos
	position_smoothing_speed = pan_speed
	if zoom_to > 0.0:
		_tween_zoom(zoom_to, zoom_time)


func move_focus(pos: Vector2) -> void:
	_focus_pos = pos


## Back to following the player, easing home slowly and then restoring normal tracking.
func release_focus(rest_zoom: float = 1.0, zoom_time: float = 1.2) -> void:
	_focus_active = false
	position_smoothing_speed = 3.0
	_tween_zoom(rest_zoom, zoom_time)
	await get_tree().create_timer(1.4, true, false, true).timeout
	if not _focus_active:
		position_smoothing_speed = _normal_speed


func _tween_zoom(to: float, duration: float) -> void:
	if _zoom_tween != null and _zoom_tween.is_valid():
		_zoom_tween.kill()
	_zoom_tween = create_tween()
	_zoom_tween.tween_property(self, "zoom", Vector2.ONE * to, duration).set_trans(Tween.TRANS_SINE)
