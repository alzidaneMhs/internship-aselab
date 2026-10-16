extends Control

signal closed

const KIT := preload("res://scripts/ui/ui_kit.gd")
const SLOT_HEADERS := ["Keyboard", "Keyboard 2", "Controller"]

var _language: OptionButton
var _volume: HSlider
var _fullscreen: CheckButton
var _hint: Label
var _back: Button
var _reset: Button
var _slot_buttons: Array = []
var _capture: Dictionary = {}
var _capture_msec := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	Settings.prompts_changed.connect(_refresh_slots)
	_refresh_slots()
	_language.grab_focus()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(940, 660)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var title := Label.new()
	title.text = "PENGATURAN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", KIT.AMBER)
	box.add_child(title)

	var general := GridContainer.new()
	general.columns = 2
	general.add_theme_constant_override("h_separation", 24)
	general.add_theme_constant_override("v_separation", 8)
	box.add_child(general)

	general.add_child(_row_label("Bahasa"))
	_language = OptionButton.new()
	_language.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	for code in Settings.LANGUAGES:
		_language.add_item(Settings.LANGUAGE_NAMES[code])
	_language.selected = Settings.LANGUAGES.find(Settings.language)
	_language.custom_minimum_size = Vector2(320, 0)
	_language.item_selected.connect(_on_language_selected)
	general.add_child(_language)

	general.add_child(_row_label("Volume"))
	_volume = HSlider.new()
	_volume.min_value = 0.0
	_volume.max_value = 1.0
	_volume.step = 0.05
	_volume.custom_minimum_size = Vector2(320, 30)
	_volume.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_volume.value = Settings.master_volume
	_volume.value_changed.connect(Settings.set_master_volume)
	general.add_child(_volume)

	general.add_child(_row_label("Layar penuh"))
	_fullscreen = CheckButton.new()
	_fullscreen.button_pressed = Settings.fullscreen
	_fullscreen.toggled.connect(Settings.set_fullscreen)
	general.add_child(_fullscreen)

	box.add_child(HSeparator.new())

	var controls_title := Label.new()
	controls_title.text = "KONTROL"
	controls_title.add_theme_font_size_override("font_size", 22)
	controls_title.add_theme_color_override("font_color", KIT.CYAN)
	box.add_child(controls_title)

	_hint = Label.new()
	_hint.text = "Pilih slot lalu tekan tombol baru. Esc untuk batal."
	_hint.add_theme_color_override("font_color", KIT.TEXT_DIM)
	_hint.add_theme_font_size_override("font_size", 16)
	box.add_child(_hint)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 250)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)

	var head := _row_label("Aksi")
	head.add_theme_color_override("font_color", KIT.AMBER)
	grid.add_child(head)
	for h in SLOT_HEADERS:
		var l := _row_label(h)
		l.add_theme_color_override("font_color", KIT.AMBER)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(l)

	for action in Settings.REBINDABLE:
		var name_label := _row_label(Settings.ACTION_NAMES[action])
		name_label.custom_minimum_size = Vector2(220, 0)
		grid.add_child(name_label)
		for slot in 3:
			var b := Button.new()
			b.custom_minimum_size = Vector2(190, 40)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			b.add_theme_font_size_override("font_size", 17)
			b.pressed.connect(_begin_capture.bind(action, slot, b))
			grid.add_child(b)
			_slot_buttons.append({"action": action, "slot": slot, "button": b})

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 18)
	box.add_child(bottom)
	_reset = Button.new()
	_reset.text = "Reset Kontrol"
	_reset.custom_minimum_size = Vector2(240, 46)
	_reset.pressed.connect(_on_reset)
	bottom.add_child(_reset)
	_back = Button.new()
	_back.text = "Kembali"
	_back.custom_minimum_size = Vector2(240, 46)
	_back.pressed.connect(close)
	bottom.add_child(_back)


func _row_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 19)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


func _refresh_slots() -> void:
	for entry in _slot_buttons:
		var b: Button = entry["button"]
		if not _capture.is_empty() and _capture["button"] == b:
			b.text = Settings.t("Tekan tombol...")
			continue
		var e: InputEvent = Settings.get_slot(entry["action"], entry["slot"])
		b.text = Settings.event_text(e) if e != null else "-"


func _begin_capture(action: String, slot: int, button: Button) -> void:
	_capture = {"action": action, "slot": slot, "button": button}
	_capture_msec = Time.get_ticks_msec()
	_hint.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_hint.text = Settings.t("Tekan tombol baru untuk \"%s\". Esc untuk batal.") % Settings.t(Settings.ACTION_NAMES[action])
	_refresh_slots()


func _end_capture() -> void:
	var b: Button = _capture.get("button")
	_capture = {}
	_hint.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_INHERIT
	_hint.text = "Pilih slot lalu tekan tombol baru. Esc untuk batal."
	_refresh_slots()
	if b != null:
		b.grab_focus()


func _input(event: InputEvent) -> void:
	if _capture.is_empty():
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			close()
		return
	get_viewport().set_input_as_handled()
	if Time.get_ticks_msec() - _capture_msec < 200:
		return
	var action: String = _capture["action"]
	var slot: int = _capture["slot"]
	if event is InputEventKey and event.pressed and not event.echo:
		var is_escape: bool = event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE
		if is_escape and not (action == "pause" and slot < 2):
			_end_capture()
			return
		if slot == 2:
			return
		var k := InputEventKey.new()
		k.physical_keycode = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		Settings.set_slot(action, slot, k)
		_end_capture()
	elif slot == 2 and event is InputEventJoypadButton and event.pressed:
		var jb := InputEventJoypadButton.new()
		jb.button_index = event.button_index
		Settings.set_slot(action, slot, jb)
		_end_capture()
	elif slot == 2 and event is InputEventJoypadMotion and absf(event.axis_value) > 0.6:
		var jm := InputEventJoypadMotion.new()
		jm.axis = event.axis
		jm.axis_value = signf(event.axis_value)
		Settings.set_slot(action, slot, jm)
		_end_capture()


func _on_language_selected(index: int) -> void:
	Settings.set_language(Settings.LANGUAGES[index])


func _on_reset() -> void:
	Settings.reset_bindings()
	_reset.grab_focus()


func close() -> void:
	if not _capture.is_empty():
		_end_capture()
		return
	closed.emit()
	queue_free()
