extends Control

const KIT := preload("res://scripts/ui/ui_kit.gd")
const RED := Color(1.0, 0.28, 0.24)

var _label: Label
var _time := 0.0
var _total := 0
var _typed := 0.0
var _speed := 40.0
var _alpha := 0.0
var _burst := 1.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_label.position = Vector2(140, 150)
	_label.size = Vector2(1000, 440)
	_label.add_theme_font_size_override("font_size", 24)
	_label.add_theme_color_override("font_color", RED)
	_label.add_theme_color_override("font_outline_color", Color(0.2, 0.0, 0.0))
	_label.add_theme_constant_override("outline_size", 6)
	add_child(_label)


func run(lines: Array, hold: float = 1.6) -> void:
	_label.text = "\n".join(PackedStringArray(lines))
	_label.visible_characters = 0
	_total = _label.text.length()
	_typed = 0.0
	DisplayServer.window_set_title(tr("SCOTT.EXE  -  OPERATOR TERDETEKSI"))
	AudioManager.play_sfx("glitch")
	get_tree().call_group("main_camera", "shake", 10.0)
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(self, "_alpha", 1.0, 0.25)
	await tw.finished
	while _typed < _total:
		await get_tree().process_frame
	await get_tree().create_timer(hold, true, false, true).timeout
	_burst = 1.0
	get_tree().call_group("main_camera", "shake", 14.0)
	var out := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	out.tween_property(self, "_alpha", 0.0, 0.35)
	await out.finished
	DisplayServer.window_set_title(String(ProjectSettings.get_setting("application/config/name", "H.A.R")))


func _process(delta: float) -> void:
	_time += delta
	_burst = maxf(_burst - delta * 1.5, 0.0)
	if _typed < _total:
		_typed = minf(_typed + delta * _speed, float(_total))
		_label.visible_characters = int(_typed)
	var jitter := 3.0 * _burst + (2.0 if _rng.randf() < 0.08 else 0.0)
	_label.position = Vector2(140, 150) + Vector2(_rng.randf_range(-jitter, jitter), _rng.randf_range(-jitter, jitter) * 0.5)
	_label.modulate.a = _alpha * (0.75 if _rng.randf() < 0.05 else 1.0)
	queue_redraw()


func _draw() -> void:
	if _alpha <= 0.01:
		return
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.02, 0.0, 0.01, 0.9 * _alpha))
	var y := 0.0
	while y < s.y:
		draw_rect(Rect2(0, y, s.x, 1.0), Color(1, 0.2, 0.2, 0.05 * _alpha))
		y += 4.0
	for i in 7:
		if _rng.randf() < 0.55:
			var by := _rng.randf_range(0.0, s.y)
			var bh := _rng.randf_range(3.0, 22.0)
			var bx := _rng.randf_range(-80.0, 80.0)
			draw_rect(Rect2(bx, by, s.x, bh), Color(RED, _rng.randf_range(0.04, 0.16) * _alpha))
			draw_rect(Rect2(-bx * 0.5, by + 2.0, s.x, bh * 0.4), Color(0.3, 0.9, 1.0, 0.06 * _alpha))
	var pulse := 0.5 + 0.5 * sin(_time * 3.0)
	draw_rect(Rect2(110, 120, 1060, 480), Color(RED, (0.25 + 0.2 * pulse) * _alpha), false, 2.0)
	draw_rect(Rect2(110, 120, 1060, 30), Color(RED, 0.18 * _alpha))
	var font := get_theme_default_font()
	draw_string(font, Vector2(124, 142), "// SCOTT.EXE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.8, 0.75, 0.9 * _alpha))
	if int(_time * 2.0) % 2 == 0:
		draw_circle(Vector2(1150, 135), 6.0, Color(RED, _alpha))
	var eye := Vector2(s.x * 0.5, s.y * 0.86)
	draw_circle(eye, 60.0 + 8.0 * pulse, Color(RED, 0.06 * _alpha))
	draw_circle(eye, 18.0, Color(RED, 0.5 * _alpha))
	draw_circle(eye, 6.0, Color(1, 0.9, 0.85, _alpha))
