extends CanvasLayer

## Full-screen iris wipe used for every scene change, plus the stage title card.
## Works while the tree is paused (process_mode = ALWAYS).

const WIPE_SHADER := """
shader_type canvas_item;
uniform float progress : hint_range(0.0, 1.0) = 0.0; // 0 = open, 1 = fully closed
uniform vec2 center = vec2(0.5, 0.5);
uniform float aspect = 1.7778;
void fragment() {
	vec2 d = UV - center;
	d.x *= aspect;
	float radius = (1.0 - progress) * 1.35;
	float a = smoothstep(radius, radius + 0.03, length(d));
	float ring = smoothstep(radius - 0.012, radius, length(d)) * (1.0 - a);
	COLOR = vec4(mix(vec3(0.02, 0.01, 0.05), vec3(1.0, 0.75, 0.25), ring * 0.8), max(a, ring * progress));
}
"""

var _rect: ColorRect
var _material: ShaderMaterial
var _progress := 0.0
var _card: Control
var _card_label: Label
var _card_title: Label
var _card_line_top: ColorRect
var _card_line_bottom: ColorRect


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = WIPE_SHADER
	_material = ShaderMaterial.new()
	_material.shader = shader
	_rect.material = _material
	_rect.color = Color.WHITE
	add_child(_rect)
	_build_card()
	_set_progress(0.0)


func _set_progress(value: float) -> void:
	_progress = value
	_material.set_shader_parameter("progress", value)
	_rect.visible = value > 0.001


func set_center(screen_uv: Vector2) -> void:
	_material.set_shader_parameter("center", screen_uv)


## Closes the iris (screen goes dark). Await it.
func close(duration: float = 0.5) -> void:
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_method(_set_progress, _progress, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished


## Opens the iris (reveals the scene). Await it if you need to.
func open(duration: float = 0.6) -> void:
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_method(_set_progress, _progress, 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _build_card() -> void:
	_card = Control.new()
	_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.modulate.a = 0.0
	add_child(_card)

	_card_label = Label.new()
	_card_label.set_anchors_preset(Control.PRESET_CENTER)
	_card_label.position = Vector2(-400, -86)
	_card_label.size = Vector2(800, 36)
	_card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_label.add_theme_font_size_override("font_size", 28)
	_card_label.add_theme_color_override("font_color", Color(1.0, 0.725, 0.22))
	_card_label.add_theme_color_override("font_outline_color", Color(0.035, 0.027, 0.07))
	_card_label.add_theme_constant_override("outline_size", 8)
	_card.add_child(_card_label)

	_card_title = Label.new()
	_card_title.set_anchors_preset(Control.PRESET_CENTER)
	_card_title.position = Vector2(-500, -52)
	_card_title.size = Vector2(1000, 90)
	_card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_title.add_theme_font_size_override("font_size", 64)
	_card_title.add_theme_color_override("font_color", Color(0.957, 0.933, 0.867))
	_card_title.add_theme_color_override("font_outline_color", Color(0.035, 0.027, 0.07))
	_card_title.add_theme_constant_override("outline_size", 14)
	_card.add_child(_card_title)

	_card_line_top = _make_line(-70.0)
	_card_line_bottom = _make_line(52.0)


func _make_line(y: float) -> ColorRect:
	var line := ColorRect.new()
	line.set_anchors_preset(Control.PRESET_CENTER)
	line.position = Vector2(-200, y)
	line.size = Vector2(400, 3)
	line.color = Color(1.0, 0.725, 0.22, 0.95)
	_card.add_child(line)
	return line


## Stage title card: small label ("STAGE 1"), big title, gold lines. Await it.
func show_card(label_text: String, title_text: String, hold: float = 1.5) -> void:
	_card_label.text = label_text
	_card_title.text = title_text
	_card_line_top.size.x = 0.0
	_card_line_top.position.x = 0.0
	_card_line_bottom.size.x = 0.0
	_card_line_bottom.position.x = 0.0
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_card, "modulate:a", 1.0, 0.45)
	tw.parallel().tween_property(_card_line_top, "size:x", 400.0, 0.6)
	tw.parallel().tween_property(_card_line_top, "position:x", -200.0, 0.6)
	tw.parallel().tween_property(_card_line_bottom, "size:x", 400.0, 0.6)
	tw.parallel().tween_property(_card_line_bottom, "position:x", -200.0, 0.6)
	tw.tween_interval(hold)
	tw.tween_property(_card, "modulate:a", 0.0, 0.6)
	await tw.finished
