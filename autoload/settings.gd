extends Node

signal language_changed
signal prompts_changed

const PATH := "user://settings.cfg"
const EN_STRINGS := preload("res://localization/strings_en.gd")
const LANGUAGES := ["id", "en"]
const LANGUAGE_NAMES := {"id": "Bahasa Indonesia", "en": "English"}
const REBINDABLE := ["move_left", "move_right", "move_up", "move_down", "jump", "dash", "attack", "interact", "pause"]
const ACTION_NAMES := {
	"move_left": "Gerak kiri",
	"move_right": "Gerak kanan",
	"move_up": "Atas",
	"move_down": "Bawah",
	"jump": "Lompat",
	"dash": "Dash",
	"attack": "Serang / Charge",
	"interact": "Interaksi",
	"pause": "Jeda",
}
const PAD_BUTTONS := {
	0: "A", 1: "B", 2: "X", 3: "Y", 4: "Back", 5: "Guide", 6: "Start",
	7: "L3", 8: "R3", 9: "LB", 10: "RB", 11: "D-Pad Up", 12: "D-Pad Down", 13: "D-Pad Left", 14: "D-Pad Right",
}
const KEY_SHORT := {"Escape": "Esc", "Space": "Spasi", "Enter": "Enter", "Shift": "Shift"}
const KEY_SHORT_EN := {"Escape": "Esc", "Space": "Space"}

var language := "id"
var master_volume := 1.0
var fullscreen := false
var using_pad := false

var _defaults: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_translations()
	for action in REBINDABLE:
		if InputMap.has_action(action):
			_defaults[action] = InputMap.action_get_events(action).duplicate()
	fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	load_settings()
	_apply_audio_video()
	TranslationServer.set_locale(language)


func _register_translations() -> void:
	var en := Translation.new()
	en.locale = "en"
	var ident := Translation.new()
	ident.locale = "id"
	for key in EN_STRINGS.TEXT.keys():
		en.add_message(key, EN_STRINGS.TEXT[key])
		ident.add_message(key, key)
	TranslationServer.add_translation(en)
	TranslationServer.add_translation(ident)


func t(text: String) -> String:
	return String(TranslationServer.translate(text))


func set_language(code: String) -> void:
	if not LANGUAGES.has(code) or code == language:
		return
	language = code
	TranslationServer.set_locale(code)
	save_settings()
	language_changed.emit()
	prompts_changed.emit()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_audio_video()
	save_settings()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_audio_video()
	save_settings()


func _apply_audio_video() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.0001)))
	AudioServer.set_bus_mute(0, master_volume <= 0.001)
	var current := DisplayServer.window_get_mode()
	if fullscreen and current != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not fullscreen and current == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)


func _input(event: InputEvent) -> void:
	var pad := using_pad
	if event is InputEventJoypadButton and event.pressed:
		pad = true
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.5:
		pad = true
	elif (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
		pad = false
	if pad != using_pad:
		using_pad = pad
		prompts_changed.emit()


func fill(text: String) -> String:
	if text.find("{") < 0:
		return text
	var out := text
	var guard := 0
	while guard < 16:
		guard += 1
		var a := out.find("{")
		if a < 0:
			break
		var b := out.find("}", a)
		if b < 0:
			break
		var action := out.substr(a + 1, b - a - 1)
		out = out.substr(0, a) + binding_text(action) + out.substr(b + 1)
	return out


func binding_text(action: String) -> String:
	if not InputMap.has_action(action):
		return action
	var events := InputMap.action_get_events(action)
	for e in events:
		if using_pad and (e is InputEventJoypadButton or e is InputEventJoypadMotion):
			return event_text(e)
		if not using_pad and e is InputEventKey:
			return event_text(e)
	if events.is_empty():
		return "-"
	return event_text(events[0])


func event_text(e: InputEvent) -> String:
	if e is InputEventKey:
		var code: int = e.keycode
		if e.physical_keycode != 0:
			code = DisplayServer.keyboard_get_keycode_from_physical(e.physical_keycode)
		var name := OS.get_keycode_string(code)
		if name.is_empty():
			name = OS.get_keycode_string(e.physical_keycode)
		var table: Dictionary = KEY_SHORT_EN if language == "en" else KEY_SHORT
		return table.get(name, name)
	if e is InputEventJoypadButton:
		return PAD_BUTTONS.get(e.button_index, "Pad %d" % e.button_index)
	if e is InputEventJoypadMotion:
		var neg: bool = e.axis_value < 0.0
		match e.axis:
			0:
				return "L-Stick Left" if neg else "L-Stick Right"
			1:
				return "L-Stick Up" if neg else "L-Stick Down"
			2:
				return "R-Stick Left" if neg else "R-Stick Right"
			3:
				return "R-Stick Up" if neg else "R-Stick Down"
			4:
				return "LT"
			5:
				return "RT"
		return "Axis %d" % e.axis
	if e is InputEventMouseButton:
		return "Mouse %d" % e.button_index
	return "?"


func is_pad_event(e: InputEvent) -> bool:
	return e is InputEventJoypadButton or e is InputEventJoypadMotion


func get_slot(action: String, slot: int) -> InputEvent:
	var keys: Array = []
	var pads: Array = []
	for e in InputMap.action_get_events(action):
		if is_pad_event(e):
			pads.append(e)
		elif e is InputEventKey:
			keys.append(e)
	if slot == 2:
		return pads[0] if not pads.is_empty() else null
	return keys[slot] if slot < keys.size() else null


func set_slot(action: String, slot: int, event: InputEvent) -> void:
	var keys: Array = []
	var pads: Array = []
	for e in InputMap.action_get_events(action):
		if is_pad_event(e):
			pads.append(e)
		elif e is InputEventKey:
			keys.append(e)
	if event != null:
		_remove_from_others(action, event)
	if slot == 2:
		if pads.is_empty():
			if event != null:
				pads.append(event)
		elif event == null:
			pads.remove_at(0)
		else:
			pads[0] = event
	else:
		while keys.size() <= slot and event != null:
			keys.append(null)
		if slot < keys.size():
			keys[slot] = event
	InputMap.action_erase_events(action)
	for e in keys:
		if e != null:
			InputMap.action_add_event(action, e)
	for e in pads:
		InputMap.action_add_event(action, e)
	save_settings()
	prompts_changed.emit()


func _remove_from_others(action: String, event: InputEvent) -> void:
	for other in REBINDABLE:
		if other == action or not InputMap.has_action(other):
			continue
		for e in InputMap.action_get_events(other):
			if _same_input(e, event):
				InputMap.action_erase_event(other, e)


func _same_input(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		var ka: int = a.physical_keycode if a.physical_keycode != 0 else a.keycode
		var kb: int = b.physical_keycode if b.physical_keycode != 0 else b.keycode
		return ka == kb
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index
	if a is InputEventJoypadMotion and b is InputEventJoypadMotion:
		return a.axis == b.axis and signf(a.axis_value) == signf(b.axis_value)
	return false


func reset_bindings() -> void:
	for action in _defaults.keys():
		InputMap.action_erase_events(action)
		for e in _defaults[action]:
			InputMap.action_add_event(action, e)
	save_settings()
	prompts_changed.emit()


func _serialize(e: InputEvent) -> Dictionary:
	if e is InputEventKey:
		return {"t": "key", "p": e.physical_keycode, "k": e.keycode}
	if e is InputEventJoypadButton:
		return {"t": "btn", "b": e.button_index}
	if e is InputEventJoypadMotion:
		return {"t": "axis", "a": e.axis, "v": signf(e.axis_value)}
	return {}


func _deserialize(d: Dictionary) -> InputEvent:
	match String(d.get("t", "")):
		"key":
			var k := InputEventKey.new()
			k.physical_keycode = int(d.get("p", 0))
			k.keycode = int(d.get("k", 0))
			return k
		"btn":
			var b := InputEventJoypadButton.new()
			b.button_index = int(d.get("b", 0))
			return b
		"axis":
			var m := InputEventJoypadMotion.new()
			m.axis = int(d.get("a", 0))
			m.axis_value = float(d.get("v", 1.0))
			return m
	return null


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("general", "language", language)
	cfg.set_value("general", "master_volume", master_volume)
	cfg.set_value("general", "fullscreen", fullscreen)
	for action in REBINDABLE:
		if not InputMap.has_action(action):
			continue
		var list: Array = []
		for e in InputMap.action_get_events(action):
			var d := _serialize(e)
			if not d.is_empty():
				list.append(d)
		cfg.set_value("input", action, list)
	cfg.save(PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	language = String(cfg.get_value("general", "language", language))
	if not LANGUAGES.has(language):
		language = "id"
	master_volume = float(cfg.get_value("general", "master_volume", master_volume))
	fullscreen = bool(cfg.get_value("general", "fullscreen", fullscreen))
	for action in REBINDABLE:
		if not InputMap.has_action(action) or not cfg.has_section_key("input", action):
			continue
		var list: Array = cfg.get_value("input", action, [])
		var events: Array = []
		for d in list:
			if typeof(d) == TYPE_DICTIONARY:
				var e := _deserialize(d)
				if e != null:
					events.append(e)
		if events.is_empty():
			continue
		InputMap.action_erase_events(action)
		for e in events:
			InputMap.action_add_event(action, e)
