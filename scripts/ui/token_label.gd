extends Label

var _source := ""


func _ready() -> void:
	_source = text
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	Settings.prompts_changed.connect(refresh)
	refresh()


func set_source(value: String) -> void:
	_source = value
	refresh()


func refresh() -> void:
	text = Settings.fill(Settings.t(_source))
