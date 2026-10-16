extends Control

const THEME := preload("res://resources/ui/menu_theme.tres")
const PANEL_WIDTH := 480.0
const HIDDEN_Y := -150.0
const SHOWN_Y := 22.0
const HOLD_TIME := 3.4

var _queue: Array[String] = []
var _busy := false
var _time := 0.0
var _panel: PanelContainer
var _icon: Control
var _title: Label
var _sub: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func _process(delta: float) -> void:
	_time += delta
	if _busy:
		_icon.queue_redraw()


func show_achievement(id: String) -> void:
	_queue.append(id)
	if not _busy:
		_run_queue()


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.modulate.a = 0.0
	add_child(_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(row)

	_icon = Control.new()
	_icon.custom_minimum_size = Vector2(64, 64)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.draw.connect(_draw_trophy)
	row.add_child(_icon)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override("separation", 2)
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(texts)

	var kicker := Label.new()
	kicker.text = "ACHIEVEMENT TERBUKA"
	kicker.add_theme_font_size_override("font_size", 14)
	kicker.add_theme_color_override("font_color", Color(1.0, 0.725, 0.22))
	texts.add_child(kicker)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 26)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(_title)

	_sub = Label.new()
	_sub.add_theme_font_size_override("font_size", 15)
	_sub.add_theme_color_override("font_color", Color(0.78, 0.74, 0.9))
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(_sub)


func _run_queue() -> void:
	_busy = true
	while not _queue.is_empty():
		await _show(_queue.pop_front())
	_busy = false


func _show(id: String) -> void:
	_title.text = _title_for(id)
	_sub.text = _subtitle_for(id)
	_panel.reset_size()
	_panel.size.x = PANEL_WIDTH
	_panel.position = Vector2((get_viewport_rect().size.x - PANEL_WIDTH) / 2.0, HIDDEN_Y)
	_panel.modulate.a = 1.0
	AudioManager.play_sfx("achievement")

	var tw_in := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw_in.tween_property(_panel, "position:y", SHOWN_Y, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw_in.finished
	await get_tree().create_timer(HOLD_TIME, true, false, true).timeout

	var tw_out := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw_out.tween_property(_panel, "position:y", HIDDEN_Y, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tw_out.finished
	_panel.modulate.a = 0.0


func _title_for(id: String) -> String:
	if id == GameState.ALL_SECRETS_ID:
		return GameState.ALL_SECRETS_TITLE
	return str(GameState.get_secret_info(id).get("title", id))


func _subtitle_for(id: String) -> String:
	if id == GameState.ALL_SECRETS_ID:
		return GameState.ALL_SECRETS_DESC
	return tr("Secret room %d / %d ditemukan") % [GameState.secrets_found.size(), GameState.SECRETS.size()]


func _draw_trophy() -> void:
	var c := _icon.size / 2.0
	var gold := Color(1.0, 0.725, 0.22)
	var dark := Color(0.62, 0.42, 0.1)
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	_icon.draw_circle(c, 30.0 + 2.0 * pulse, Color(gold, 0.14))
	_icon.draw_polyline(PackedVector2Array([c + Vector2(-14, -14), c + Vector2(-24, -14), c + Vector2(-22, -2), c + Vector2(-12, 2)]), dark, 3.0)
	_icon.draw_polyline(PackedVector2Array([c + Vector2(14, -14), c + Vector2(24, -14), c + Vector2(22, -2), c + Vector2(12, 2)]), dark, 3.0)
	_icon.draw_colored_polygon(PackedVector2Array([
		c + Vector2(-16, -20), c + Vector2(16, -20), c + Vector2(14, -2), c + Vector2(6, 8), c + Vector2(-6, 8), c + Vector2(-14, -2),
	]), gold)
	_icon.draw_rect(Rect2(c + Vector2(-3, 8), Vector2(6, 9)), dark)
	_icon.draw_rect(Rect2(c + Vector2(-13, 17), Vector2(26, 6)), gold)
	_icon.draw_rect(Rect2(c + Vector2(-13, 21), Vector2(26, 2)), dark)
	_icon.draw_rect(Rect2(c + Vector2(-10, -17), Vector2(4, 14)), Color(1, 1, 1, 0.55))
	for k in 3:
		var a := _time * 1.8 + k * TAU / 3.0
		var p := c + Vector2.from_angle(a) * 28.0
		var s := 2.0 + 1.5 * sin(_time * 6.0 + k)
		_icon.draw_line(p + Vector2(-s, 0), p + Vector2(s, 0), Color(1, 1, 0.8, 0.9), 2.0)
		_icon.draw_line(p + Vector2(0, -s), p + Vector2(0, s), Color(1, 1, 0.8, 0.9), 2.0)
