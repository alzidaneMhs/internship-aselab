extends Control

const KIT := preload("res://scripts/ui/ui_kit.gd")

var _time := 0.0
var _warn := 0.0
var _alarm := 0.0
var _timer_visible := false
var _time_left := 0.0
var _time_total := 10.0

var _warn_title: Label
var _warn_sub: Label
var _timer_box: Control
var _timer_label: Label
var _timer_caption: Label
var _timer_hint: Label
var _banner: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_warn_title = _make_label("WARNING", 120, Color(1.0, 0.15, 0.12))
	_warn_sub = _make_label("FINAL PHASE", 46, Color(1.0, 0.92, 0.8))
	_timer_box = Control.new()
	_timer_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_timer_box)
	_timer_caption = _make_label("BERTAHAN SELAMA", 30, Color(1.0, 0.85, 0.6), _timer_box)
	_timer_label = _make_label("10.0", 104, Color.WHITE, _timer_box)
	_timer_hint = _make_label("HINDARI SEMUA SERANGAN SCOTT!", 34, Color(1.0, 0.3, 0.25), _timer_box)
	_banner = _make_label("", 90, Color.WHITE)
	_warn_title.modulate.a = 0.0
	_warn_sub.modulate.a = 0.0
	_banner.modulate.a = 0.0
	_timer_box.visible = false
	_layout()
	get_viewport().size_changed.connect(_layout)


func _make_label(text: String, font_size: int, color: Color, parent: Node = null) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_font_override("font", get_theme_font("font", "Button"))
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.0, 0.02))
	l.add_theme_constant_override("outline_size", maxi(floori(font_size / 8.0), 5))
	(parent if parent != null else self).add_child(l)
	return l


func _layout() -> void:
	var s := get_viewport_rect().size
	_warn_title.position = Vector2(0.0, s.y * 0.5 - 130.0)
	_warn_title.size = Vector2(s.x, 150.0)
	_warn_sub.position = Vector2(0.0, s.y * 0.5 + 10.0)
	_warn_sub.size = Vector2(s.x, 60.0)
	_timer_box.position = Vector2.ZERO
	_timer_box.size = s
	_timer_caption.position = Vector2(0.0, 18.0)
	_timer_caption.size = Vector2(s.x, 36.0)
	_timer_label.position = Vector2(0.0, 50.0)
	_timer_label.size = Vector2(s.x, 120.0)
	_timer_hint.position = Vector2(0.0, 182.0)
	_timer_hint.size = Vector2(s.x, 44.0)
	_banner.position = Vector2(0.0, s.y * 0.5 - 70.0)
	_banner.size = Vector2(s.x, 120.0)


func _process(delta: float) -> void:
	_time += delta
	if _timer_visible:
		var urgent := _time_left <= 3.0
		var pulse := 0.5 + 0.5 * sin(_time * (14.0 if urgent else 7.0))
		_timer_label.text = "%.1f" % maxf(_time_left, 0.0)
		_timer_label.add_theme_color_override("font_color",
			Color(1.0, 0.25, 0.2).lerp(Color.WHITE, pulse) if urgent else Color(1.0, 0.92, 0.7))
		_timer_hint.modulate.a = 0.55 + 0.45 * pulse
		var s := 1.0 + (0.06 * pulse if urgent else 0.0)
		_timer_label.pivot_offset = _timer_label.size / 2.0
		_timer_label.scale = Vector2(s, s)
	if _warn > 0.01:
		_warn_title.add_theme_color_override("font_color",
			Color(1.0, 0.15, 0.12).lerp(Color(1.0, 0.85, 0.8), 0.5 + 0.5 * sin(_time * 18.0)))
	queue_redraw()


func _draw() -> void:
	var s := get_viewport_rect().size
	if _alarm > 0.01:
		var pulse := 0.5 + 0.5 * sin(_time * 5.0)
		var a := (0.12 + 0.2 * pulse) * _alarm
		var edge := Color(1.0, 0.05, 0.05, a * 2.0)
		var clear := Color(1.0, 0.05, 0.05, 0.0)
		var d := 230.0
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(d, 0), Vector2(d, s.y), Vector2(0, s.y)]), PackedColorArray([edge, clear, clear, edge]))
		draw_polygon(PackedVector2Array([Vector2(s.x - d, 0), Vector2(s.x, 0), Vector2(s.x, s.y), Vector2(s.x - d, s.y)]), PackedColorArray([clear, edge, edge, clear]))
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(s.x, 0), Vector2(s.x, d * 0.6), Vector2(0, d * 0.6)]), PackedColorArray([edge, edge, clear, clear]))
		draw_polygon(PackedVector2Array([Vector2(0, s.y - d * 0.6), Vector2(s.x, s.y - d * 0.6), Vector2(s.x, s.y), Vector2(0, s.y)]), PackedColorArray([clear, clear, edge, edge]))
	if _warn > 0.01:
		var cy := s.y * 0.5
		draw_rect(Rect2(0.0, cy - 135.0, s.x, 240.0), Color(0.0, 0.0, 0.0, 0.62 * _warn))
		_draw_stripes(cy - 160.0, 26.0, s.x, 1.0)
		_draw_stripes(cy + 108.0, 26.0, s.x, -1.0)
	if _timer_visible:
		var w := minf(s.x * 0.5, 620.0)
		var x := (s.x - w) / 2.0
		var k := clampf(_time_left / maxf(_time_total, 0.01), 0.0, 1.0)
		var col := Color(1.0, 0.725, 0.22).lerp(Color(1.0, 0.2, 0.15), 1.0 - k)
		KIT.draw_bar(self, Rect2(x - 4.0, 236.0, w + 8.0, 24.0), k, col, Color(KIT.INK_950, 0.95), col.darkened(0.3))


func _draw_stripes(y: float, h: float, width: float, dir: float) -> void:
	draw_rect(Rect2(0.0, y, width, h), Color(0.08, 0.06, 0.03, _warn))
	var step := 44.0
	var x := -step * 2.0 + fposmod(_time * 90.0 * dir, step * 2.0)
	while x < width + step:
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, y + h), Vector2(x + step * 0.5, y + h), Vector2(x + step * 0.5 + h, y), Vector2(x + h, y),
		]), Color(1.0, 0.8, 0.1, _warn))
		x += step * 2.0 * 0.5 + step * 0.5


func show_warning(duration: float = 2.2) -> void:
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "_warn", 1.0, 0.25)
	tw.tween_property(self, "_alarm", 1.0, 0.4)
	tw.tween_property(_warn_title, "modulate:a", 1.0, 0.2)
	tw.tween_property(_warn_sub, "modulate:a", 1.0, 0.4)
	_warn_title.pivot_offset = _warn_title.size / 2.0
	_warn_title.scale = Vector2(1.6, 1.6)
	tw.tween_property(_warn_title, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var out := create_tween()
	out.tween_interval(maxf(duration - 0.4, 0.2))
	out.tween_callback(_fade_warning)


func _fade_warning() -> void:
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "_warn", 0.0, 0.4)
	tw.tween_property(_warn_title, "modulate:a", 0.0, 0.4)
	tw.tween_property(_warn_sub, "modulate:a", 0.0, 0.4)


func start_timer(total: float) -> void:
	_time_total = total
	_time_left = total
	_timer_visible = true
	_timer_box.visible = true
	_timer_box.modulate.a = 0.0
	create_tween().tween_property(_timer_box, "modulate:a", 1.0, 0.3)


func set_time_left(t: float) -> void:
	_time_left = t


func stop_timer() -> void:
	_timer_visible = false
	var tw := create_tween()
	tw.tween_property(_timer_box, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func(): _timer_box.visible = false)


func fade_alarm() -> void:
	create_tween().tween_property(self, "_alarm", 0.0, 0.8)


func show_banner(text: String, color: Color, seconds: float = 1.8) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.pivot_offset = _banner.size / 2.0
	_banner.scale = Vector2(1.7, 1.7)
	_banner.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.15)
	tw.tween_property(_banner, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(seconds)
	tw.chain().tween_property(_banner, "modulate:a", 0.0, 0.4)
