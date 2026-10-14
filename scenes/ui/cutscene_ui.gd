extends Control

## Cinematic overlay used by every cutscene: black letterbox bars that slide in,
## a boss name card, a full-screen fade, and a small "Esc: lewati" hint.

const BAR_HEIGHT := 92.0

var _top: ColorRect
var _bottom: ColorRect
var _hint: Label
var _fade: ColorRect
var _card: Control
var _card_name: Label
var _card_sub: Label
var _card_line: ColorRect
var _bars := 0.0
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	add_child(_fade)
	_top = ColorRect.new()
	_top.color = Color.BLACK
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top)
	_bottom = ColorRect.new()
	_bottom.color = Color.BLACK
	_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bottom)
	_hint = Label.new()
	_hint.text = "Esc  :  lewati"
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	_hint.modulate.a = 0.0
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)

	_card = Control.new()
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.modulate.a = 0.0
	add_child(_card)
	_card_line = ColorRect.new()
	_card_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(_card_line)
	_card_name = _make_label(96)
	_card_sub = _make_label(34)
	_card.add_child(_card_name)
	_card.add_child(_card_sub)
	_layout()
	get_viewport().size_changed.connect(_layout)


func _make_label(font_size: int) -> Label:
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_font_override("font", get_theme_font("font", "Button"))
	l.add_theme_color_override("font_outline_color", Color(0.03, 0.0, 0.03))
	l.add_theme_constant_override("outline_size", maxi(font_size / 9, 5))
	return l


func _layout() -> void:
	var s := get_viewport_rect().size
	_fade.size = s
	_set_bars(_bars)
	_hint.position = Vector2(s.x - 190.0, s.y - BAR_HEIGHT + 30.0)
	_card_name.position = Vector2(110.0, s.y - 330.0)
	_card_name.size = Vector2(s.x - 220.0, 110.0)
	_card_line.position = Vector2(114.0, s.y - 214.0)
	_card_line.size = Vector2(520.0, 6.0)
	_card_sub.position = Vector2(114.0, s.y - 196.0)
	_card_sub.size = Vector2(s.x - 220.0, 46.0)


func _set_bars(k: float) -> void:
	_bars = k
	var s := get_viewport_rect().size
	_top.size = Vector2(s.x, BAR_HEIGHT)
	_bottom.size = Vector2(s.x, BAR_HEIGHT)
	_top.position = Vector2(0.0, -BAR_HEIGHT * (1.0 - k))
	_bottom.position = Vector2(0.0, s.y - BAR_HEIGHT * k)


func _process(delta: float) -> void:
	_time += delta


func bars_in(duration: float = 0.6) -> void:
	var tw := create_tween()
	tw.tween_method(_set_bars, _bars, 1.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	create_tween().tween_property(_hint, "modulate:a", 1.0, duration)
	await tw.finished


func bars_out(duration: float = 0.5) -> void:
	var tw := create_tween()
	tw.tween_method(_set_bars, _bars, 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	create_tween().tween_property(_hint, "modulate:a", 0.0, duration * 0.6)
	await tw.finished


## Big name card in the lower left, like a boss reveal.
func show_title(title: String, subtitle: String, color: Color, seconds: float = 2.4) -> void:
	_card_name.text = title
	_card_name.add_theme_color_override("font_color", color.lightened(0.15))
	_card_sub.text = subtitle
	_card_sub.add_theme_color_override("font_color", Color(1.0, 0.95, 0.88))
	_card_line.color = color
	_card.pivot_offset = Vector2(110.0, get_viewport_rect().size.y - 260.0)
	_card.scale = Vector2(1.18, 1.18)
	_card.position = Vector2(-50.0, 0.0)
	_card.modulate.a = 0.0
	_card_line.size.x = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(_card, "modulate:a", 1.0, 0.25)
	tw.tween_property(_card, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card, "position:x", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card_line, "size:x", 520.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(seconds, true, false, true).timeout
	var out := create_tween().set_parallel()
	out.tween_property(_card, "modulate:a", 0.0, 0.4)
	out.tween_property(_card, "position:x", 60.0, 0.4)
	await out.finished


func fade(color: Color, alpha: float, duration: float) -> void:
	_fade.color = Color(color, 1.0)
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", alpha, duration)
	await tw.finished
