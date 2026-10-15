extends Control

signal closed

const GOLD := Color(1.0, 0.725, 0.22)

var _back_button: Button
var _rows: VBoxContainer
var _count_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


func open() -> void:
	_rebuild_rows()
	visible = true
	_back_button.grab_focus()


func close() -> void:
	visible = false
	closed.emit()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(820, 600)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Achievement"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	box.add_child(title)

	_count_label = Label.new()
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.add_theme_font_size_override("font_size", 18)
	_count_label.add_theme_color_override("font_color", GOLD)
	box.add_child(_count_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 8)
	scroll.add_child(_rows)

	_back_button = Button.new()
	_back_button.text = "Kembali"
	_back_button.custom_minimum_size = Vector2(0, 54)
	_back_button.pressed.connect(close)
	box.add_child(_back_button)


func _rebuild_rows() -> void:
	for child in _rows.get_children():
		child.queue_free()
	var unlocked := 0
	var ids: Array = GameState.SECRETS.keys()
	ids.append(GameState.ALL_SECRETS_ID)
	for id in ids:
		var done := GameState.has_achievement(id)
		if done:
			unlocked += 1
		_rows.add_child(_make_row(id, done))
	_count_label.text = "%d / %d terbuka" % [unlocked, ids.size()]


func _make_row(id: String, done: bool) -> Control:
	var info := GameState.get_secret_info(id)
	var is_meta := id == GameState.ALL_SECRETS_ID

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.098, 0.078, 0.184, 0.95) if done else Color(0.059, 0.047, 0.11, 0.9)
	style.border_color = GOLD if done else Color(0.28, 0.255, 0.45)
	style.border_width_left = 6
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", style)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	row.add_child(h)

	var thumb_holder := Control.new()
	thumb_holder.custom_minimum_size = Vector2(124, 70)
	h.add_child(thumb_holder)
	var thumb_bg := ColorRect.new()
	thumb_bg.color = Color(0.03, 0.02, 0.06)
	thumb_holder.add_child(thumb_bg)
	thumb_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if done and info.has("image"):
		var tex := TextureRect.new()
		tex.texture = load(info["image"]) as Texture2D
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		thumb_holder.add_child(tex)
		tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		var mark := Label.new()
		mark.text = "ALL" if (done and is_meta) else "?"
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mark.add_theme_font_size_override("font_size", 34)
		mark.add_theme_color_override("font_color", GOLD if done else Color(0.4, 0.36, 0.5))
		thumb_holder.add_child(mark)
		mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override("separation", 2)
	h.add_child(texts)

	var name_label := Label.new()
	name_label.add_theme_font_size_override("font_size", 22)
	if is_meta:
		name_label.text = GameState.ALL_SECRETS_TITLE if done else "???"
	else:
		name_label.text = str(info.get("title", id)) if done else "???"
	name_label.add_theme_color_override("font_color", GOLD if done else Color(0.55, 0.5, 0.65))
	texts.add_child(name_label)

	var desc := Label.new()
	desc.add_theme_font_size_override("font_size", 14)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_meta:
		desc.text = GameState.ALL_SECRETS_DESC if done else "Temukan semua secret room."
	elif done:
		desc.text = str(info.get("lore", ""))
	else:
		desc.text = "Secret room tersembunyi di Stage %d." % int(info.get("stage", 0))
	desc.add_theme_color_override("font_color", Color(0.85, 0.82, 0.95) if done else Color(0.5, 0.46, 0.6))
	texts.add_child(desc)
	return row
