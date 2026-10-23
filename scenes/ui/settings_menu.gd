extends Control

signal closed

const KIT := preload("res://scripts/ui/ui_kit.gd")
const SLOT_HEADERS := ["Keyboard", "Keyboard 2", "Controller"]
const FPS_LIMITS := [0, 30, 60, 120, 144]

var _language: OptionButton
var _volume: HSlider
var _fullscreen: CheckButton
var _hint: Label
var _back: Button
var _reset: Button
var _slot_buttons: Array = []
var _capture: Dictionary = {}
var _capture_msec := 0
var _tabs: TabContainer
var _gfx_preset: OptionButton
var _gfx_widgets: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	Settings.prompts_changed.connect(_refresh_slots)
	Settings.graphics_changed.connect(_refresh_gfx)
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
	panel.custom_minimum_size = Vector2(980, 660)
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

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_theme_font_size_override("font_size", 19)
	box.add_child(_tabs)

	var general_page := MarginContainer.new()
	general_page.name = "General"
	for side in ["left", "right", "top", "bottom"]:
		general_page.add_theme_constant_override("margin_" + side, 16)
	_tabs.add_child(general_page)
	var general := GridContainer.new()
	general.columns = 2
	general.add_theme_constant_override("h_separation", 24)
	general.add_theme_constant_override("v_separation", 12)
	general_page.add_child(general)

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

	_build_graphics_page()

	var controls_page := VBoxContainer.new()
	controls_page.name = "Controls"
	controls_page.add_theme_constant_override("separation", 8)
	_tabs.add_child(controls_page)

	_hint = Label.new()
	_hint.text = "Pilih slot lalu tekan tombol baru. Esc untuk batal."
	_hint.add_theme_color_override("font_color", KIT.TEXT_DIM)
	_hint.add_theme_font_size_override("font_size", 16)
	controls_page.add_child(_hint)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 250)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	controls_page.add_child(scroll)

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

	_reset = Button.new()
	_reset.text = "Reset Kontrol"
	_reset.custom_minimum_size = Vector2(240, 42)
	_reset.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_reset.pressed.connect(_on_reset)
	controls_page.add_child(_reset)

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 18)
	box.add_child(bottom)
	_back = Button.new()
	_back.text = "Kembali"
	_back.custom_minimum_size = Vector2(240, 46)
	_back.pressed.connect(close)
	bottom.add_child(_back)
	_refresh_tab_titles()
	Settings.language_changed.connect(_refresh_tab_titles)


func _refresh_tab_titles() -> void:
	if _tabs == null:
		return
	_tabs.set_tab_title(0, Settings.t("Umum"))
	_tabs.set_tab_title(1, Settings.t("Grafik"))
	_tabs.set_tab_title(2, Settings.t("Kontrol"))


func _build_graphics_page() -> void:
	var page := VBoxContainer.new()
	page.name = "Graphics"
	page.add_theme_constant_override("separation", 6)
	_tabs.add_child(page)

	var note := Label.new()
	note.text = "Turunkan preset kalau game terasa patah-patah."
	note.add_theme_color_override("font_color", KIT.TEXT_DIM)
	note.add_theme_font_size_override("font_size", 16)
	page.add_child(note)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)

	_gfx_preset = _gfx_option(grid, "Preset kualitas", Settings.GFX_PRESET_NAMES, _on_preset_selected)
	_gfx_preset.set_item_disabled(Settings.GFX_PRESET_NAMES.size() - 1, true)
	_gfx_check(grid, "Bloom / glow", "glow")
	_gfx_check(grid, "Pencahayaan dinamis", "lighting")
	_gfx_widgets["particles"] = _gfx_option(grid, "Partikel atmosfer", ["Mati", "Sedikit", "Sedang", "Banyak"], _on_particles_selected)
	_gfx_check(grid, "Color grading & vignette", "post_fx")
	_gfx_check(grid, "Efek sinematik (grain & aberasi)", "film_fx")
	_gfx_check(grid, "Kabut & background hidup", "bg_fx")
	_gfx_check(grid, "Detail lingkungan", "detail")
	_gfx_check(grid, "Bayangan karakter", "shadows")
	_gfx_widgets["msaa"] = _gfx_option(grid, "Anti-aliasing", ["Mati", "MSAA 2x", "MSAA 4x"], _on_msaa_selected)
	_gfx_check(grid, "VSync", "vsync")
	_gfx_widgets["fps_limit"] = _gfx_option(grid, "Batas FPS", ["Tanpa batas", "30", "60", "120", "144"], _on_fps_selected)
	_gfx_check(grid, "Tampilkan FPS", "show_fps")
	_gfx_widgets["brightness"] = _gfx_slider(grid, "Kecerahan", 0.7, 1.3, "brightness")
	_gfx_widgets["screen_shake"] = _gfx_slider(grid, "Getaran layar", 0.0, 1.0, "screen_shake")
	_refresh_gfx()


func _gfx_option(grid: GridContainer, label: String, items: Array, callback: Callable) -> OptionButton:
	grid.add_child(_row_label(label))
	var ob := OptionButton.new()
	for it in items:
		ob.add_item(String(it))
	ob.custom_minimum_size = Vector2(300, 0)
	ob.item_selected.connect(callback)
	grid.add_child(ob)
	return ob


func _gfx_check(grid: GridContainer, label: String, key: String) -> void:
	grid.add_child(_row_label(label))
	var cb := CheckButton.new()
	cb.toggled.connect(_on_gfx_toggled.bind(key))
	grid.add_child(cb)
	_gfx_widgets[key] = cb


func _gfx_slider(grid: GridContainer, label: String, lo: float, hi: float, key: String) -> HSlider:
	grid.add_child(_row_label(label))
	var sl := HSlider.new()
	sl.min_value = lo
	sl.max_value = hi
	sl.step = 0.05
	sl.custom_minimum_size = Vector2(300, 30)
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sl.value_changed.connect(_on_gfx_slider.bind(key))
	grid.add_child(sl)
	return sl


func _refresh_gfx() -> void:
	_gfx_preset.select(int(Settings.gfx["preset"]))
	for key in _gfx_widgets.keys():
		var w: Control = _gfx_widgets[key]
		var v = Settings.gfx[key]
		if w is CheckButton:
			(w as CheckButton).set_pressed_no_signal(bool(v))
		elif w is OptionButton:
			var idx := int(v)
			if key == "fps_limit":
				idx = maxi(FPS_LIMITS.find(int(v)), 0)
			(w as OptionButton).select(idx)
		elif w is HSlider:
			(w as HSlider).set_value_no_signal(float(v))


func _on_gfx_toggled(on: bool, key: String) -> void:
	Settings.set_gfx(key, on)


func _on_gfx_slider(value: float, key: String) -> void:
	Settings.set_gfx(key, value)


func _on_preset_selected(index: int) -> void:
	Settings.apply_gfx_preset(index)


func _on_particles_selected(index: int) -> void:
	Settings.set_gfx("particles", index)


func _on_msaa_selected(index: int) -> void:
	Settings.set_gfx("msaa", index)


func _on_fps_selected(index: int) -> void:
	Settings.set_gfx("fps_limit", FPS_LIMITS[index])


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
