extends Control

signal finished

const CHARS_PER_SECOND := 48.0
const ISME_FRAMES := preload("res://scenes/player/isme_frames.tres")
const KIT := preload("res://scripts/ui/ui_kit.gd")
const HANCH_SHEET := preload("res://assets/sprites/npc/hanch/hanch_sheet.png")
const HANCH_FRAMES := 5

const SPEAKERS := {
	"Isme": {"color": Color(1.0, 0.725, 0.22), "portrait": "isme"},
	"Lushte": {"color": Color(0.6, 0.85, 1.0), "portrait": "lushte"},
	"Krums": {"color": Color(1.0, 0.6, 0.35), "portrait": "krums"},
	"Scott": {"color": Color(0.65, 0.85, 1.0), "portrait": "scott"},
	"Hanch": {"color": Color(0.95, 0.85, 0.4), "portrait": "hanch"},
	"Narator": {"color": Color(0.85, 0.82, 0.95), "portrait": ""},
}

@onready var panel: PanelContainer = $Panel
@onready var portrait: Control = $Panel/MarginContainer/HBoxContainer/Portrait
@onready var name_label: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/NameLabel
@onready var text_label: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/TextLabel
@onready var hint_label: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/HintLabel

var _lines: Array = []
var _index := 0
var _chars := 0.0
var _typing := false
var _closing := false
var _time := 0.0
var _portrait_kind := ""
var _portrait_color := Color.WHITE
var _portrait_face := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	portrait.draw.connect(_draw_portrait)
	panel.modulate.a = 0.0
	panel.position.y += 30.0


func run(lines: Array) -> void:
	_lines = lines
	_index = 0
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel()
	tw.tween_property(panel, "modulate:a", 1.0, 0.25)
	tw.tween_property(panel, "position:y", panel.position.y - 30.0, 0.25)
	_show_line()
	await finished


func _show_line() -> void:
	var line: Dictionary = _lines[_index]
	var who: String = line.get("who", "Narator")
	var info: Dictionary = SPEAKERS.get(who, SPEAKERS["Narator"])
	name_label.text = who
	name_label.add_theme_color_override("font_color", info["color"])
	text_label.text = line["text"]
	text_label.visible_characters = 0
	_chars = 0.0
	_typing = true
	_portrait_kind = info["portrait"]
	_portrait_color = info["color"]
	_portrait_face = int(line.get("face", 0))
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if _portrait_kind == "hanch" else CanvasItem.TEXTURE_FILTER_PARENT_NODE
	portrait.visible = _portrait_kind != ""
	portrait.queue_redraw()
	AudioManager.play_sfx("dialogue_open")


func _process(delta: float) -> void:
	_time += delta
	if _typing:
		_chars += delta * CHARS_PER_SECOND
		text_label.visible_characters = int(_chars)
		if text_label.visible_characters >= text_label.get_total_character_count():
			_typing = false
	hint_label.modulate.a = 0.35 + 0.65 * (0.5 + 0.5 * sin(_time * 5.0)) if not _typing else 0.0
	if portrait.visible:
		portrait.queue_redraw()


func _input(event: InputEvent) -> void:
	if _closing:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish()
		return
	var advance: bool = event.is_action_pressed("interact") or event.is_action_pressed("jump") \
		or event.is_action_pressed("ui_accept") \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not advance:
		return
	get_viewport().set_input_as_handled()
	if _typing:
		text_label.visible_characters = -1
		_typing = false
		return
	_index += 1
	if _index >= _lines.size():
		_finish()
	else:
		_show_line()


func _finish() -> void:
	_closing = true
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(panel, "modulate:a", 0.0, 0.2)
	await tw.finished
	finished.emit()


func _draw_portrait() -> void:
	var box_size := portrait.size
	KIT.draw_panel(portrait, Rect2(Vector2.ZERO, box_size), Color(KIT.INK_950, 0.95), _portrait_color, 12.0, _portrait_color, true)
	var inner := Rect2(Vector2(14, 14), box_size - Vector2(28, 28))
	match _portrait_kind:
		"isme":
			var atlas := ISME_FRAMES.get_frame_texture("idle", 0) as AtlasTexture
			if atlas != null:
				var bob := sin(_time * 2.0) * 2.0
				portrait.draw_texture_rect_region(atlas.atlas, Rect2(inner.position + Vector2(0, bob), inner.size),
						Rect2(atlas.region.position + Vector2(230, 130), Vector2(700, 700)))
		"lushte":
			var tex := load("res://assets/sprites/enemies/winged/musuh_bersayap.png") as Texture2D
			portrait.draw_texture_rect_region(tex, inner, Rect2(190, 10, 300, 300))
		"krums":
			var tex2 := load("res://assets/sprites/enemies/shielded/musuh_bertameng.png") as Texture2D
			portrait.draw_texture_rect_region(tex2, inner, Rect2(330, 40, 420, 420))
		"scott":
			var tex3 := load("res://assets/sprites/bosses/scott/scott.png") as Texture2D
			portrait.draw_texture_rect_region(tex3, inner, Rect2(130, 40, 640, 640))
		"hanch":
			var cell_w := float(HANCH_SHEET.get_width()) / HANCH_FRAMES
			var src_h := minf(cell_w * inner.size.y / inner.size.x, float(HANCH_SHEET.get_height()))
			var hbob := sin(_time * 2.2) * 1.5
			portrait.draw_texture_rect_region(HANCH_SHEET, Rect2(inner.position + Vector2(0.0, hbob), inner.size),
					Rect2(clampi(_portrait_face, 0, HANCH_FRAMES - 1) * cell_w, 0.0, cell_w, src_h))
