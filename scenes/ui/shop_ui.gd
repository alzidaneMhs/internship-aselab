extends Control

signal closed

const CATALOG_PATH := "res://resources/economy/upgrade_catalog.tres"

const KIT := preload("res://scripts/ui/ui_kit.gd")
const HANCH_SHEET := preload("res://assets/sprites/npc/hanch/hanch_sheet.png")
const HANCH_FRAMES := 5
const FACE_IDLE := 0
const FACE_HAPPY := 2
const FACE_COIN := 3
const FACE_CONFUSED := 4
const DEFAULT_FLAVOR := "Mantan pejabat yang rakus. Ia menjual upgrade, tentu saja dengan harga Vonic."
const THANKS_LINES := [
	"Hehe, Vonic-mu kuterima dengan senang hati.",
	"Transaksi yang menyenangkan! Kembali lagi, ya.",
	"Bagus, bagus... dompetku makin tebal.",
]
const BROKE_LINES := [
	"Hmm? Vonic-mu kurang, robot kecil.",
	"Eh? Uangnya tidak cukup. Aku tidak memberi utang.",
]

var show_skills := false
var purchases := 0

@onready var rows_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/Scroll/RowsContainer
@onready var points_label: Label = $Panel/MarginContainer/VBoxContainer/Header/HeaderText/PointsLabel
@onready var flavor_label: Label = $Panel/MarginContainer/VBoxContainer/Header/HeaderText/FlavorLabel
@onready var portrait: Control = $Panel/MarginContainer/VBoxContainer/Header/Portrait
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton

var _catalog: Resource
var _rows: Dictionary = {}
var _skill_rows: Dictionary = {}
var _face := FACE_HAPPY
var _face_time := 1.6
var _time := 0.0
var _default_flavor := DEFAULT_FLAVOR


func _ready() -> void:
	_catalog = load(CATALOG_PATH)
	close_button.pressed.connect(func(): closed.emit())
	GameState.points_changed.connect(_refresh)
	GameState.skills_changed.connect(_on_skills_changed)
	_build_rows()
	if show_skills:
		_build_skill_rows()
	_refresh(GameState.points)
	close_button.grab_focus()
	portrait.draw.connect(_draw_portrait)
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if show_skills:
		_default_flavor = "Dagangan baru: upgrade tubuh dan teknik. Semua dibayar dengan Vonic."
	flavor_label.text = _default_flavor


func _process(delta: float) -> void:
	_time += delta
	if _face_time > 0.0:
		_face_time -= delta
		if _face_time <= 0.0:
			_face = FACE_IDLE
			flavor_label.text = _default_flavor
	portrait.queue_redraw()


func _set_face(face: int, duration: float, line: String) -> void:
	_face = face
	_face_time = duration
	flavor_label.text = line


func _draw_portrait() -> void:
	var box_size := portrait.size
	KIT.draw_panel(portrait, Rect2(Vector2.ZERO, box_size), Color(KIT.INK_950, 0.95), KIT.AMBER, 12.0, KIT.AMBER, true)
	var cell_w := float(HANCH_SHEET.get_width()) / HANCH_FRAMES
	var inner := Rect2(Vector2(8, 8), box_size - Vector2(16, 16))
	var src_h := cell_w * inner.size.y / inner.size.x
	var bob := sin(_time * 2.2) * 1.5
	if _face == FACE_COIN:
		bob += absf(sin(_time * 12.0)) * -3.0
	var src := Rect2(_face * cell_w, 2.0, cell_w, minf(src_h, float(HANCH_SHEET.get_height()) - 2.0))
	portrait.draw_texture_rect_region(HANCH_SHEET, Rect2(inner.position + Vector2(0.0, bob), inner.size), src)


func _build_rows() -> void:
	for def in _catalog.upgrades:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)

		var name_label := Label.new()
		name_label.custom_minimum_size = Vector2(340, 0)
		row.add_child(name_label)

		var cost_label := Label.new()
		cost_label.custom_minimum_size = Vector2(110, 0)
		row.add_child(cost_label)

		var buy_button := Button.new()
		buy_button.text = "Beli"
		buy_button.add_theme_font_size_override("font_size", 22)
		buy_button.pressed.connect(_on_buy_pressed.bind(def.id))
		row.add_child(buy_button)

		rows_container.add_child(row)
		_rows[def.id] = {"name": name_label, "cost": cost_label, "button": buy_button}


func _build_skill_rows() -> void:
	var header := Label.new()
	header.text = "SKILL"
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", KIT.CYAN)
	rows_container.add_child(HSeparator.new())
	rows_container.add_child(header)
	for id in GameState.SKILLS.keys():
		var info: Dictionary = GameState.SKILLS[id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)

		var text_box := VBoxContainer.new()
		text_box.custom_minimum_size = Vector2(470, 0)
		var name_label := Label.new()
		name_label.add_theme_font_size_override("font_size", 21)
		name_label.add_theme_color_override("font_color", KIT.AMBER)
		text_box.add_child(name_label)
		var desc_label := Label.new()
		desc_label.add_theme_font_size_override("font_size", 15)
		desc_label.add_theme_color_override("font_color", KIT.TEXT_DIM)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.custom_minimum_size = Vector2(470, 0)
		text_box.add_child(desc_label)
		row.add_child(text_box)

		var cost_label := Label.new()
		cost_label.custom_minimum_size = Vector2(96, 0)
		row.add_child(cost_label)

		var buy_button := Button.new()
		buy_button.add_theme_font_size_override("font_size", 20)
		buy_button.custom_minimum_size = Vector2(130, 0)
		buy_button.pressed.connect(_on_skill_pressed.bind(id))
		row.add_child(buy_button)

		rows_container.add_child(row)
		_skill_rows[id] = {"name": name_label, "desc": desc_label, "cost": cost_label, "button": buy_button}


func _refresh(points: int) -> void:
	points_label.text = tr("Vonic: %d") % points
	_refresh_skills(points)
	for def in _catalog.upgrades:
		var refs: Dictionary = _rows[def.id]
		var tier: int = int(GameState.upgrade_tiers.get(def.id, 0))
		var current_value: int = def.base_value if tier == 0 else def.tier_values[tier - 1]
		if tier >= def.max_tier:
			refs["name"].text = tr("%s  Lv %d/%d (MAX)  %d") % [tr(def.display_name), tier, def.max_tier, current_value]
			refs["cost"].text = "-"
			refs["button"].disabled = true
			refs["button"].modulate.a = 1.0
		else:
			var cost: int = def.tier_costs[tier]
			refs["name"].text = tr("%s  Lv %d/%d   %d -> %d") % [tr(def.display_name), tier, def.max_tier, current_value, def.tier_values[tier]]
			refs["cost"].text = tr("%d Vonic") % cost
			refs["button"].disabled = false
			refs["button"].modulate.a = 1.0 if points >= cost else 0.55


func _on_buy_pressed(id: String) -> void:
	if GameState.purchase_upgrade(id):
		AudioManager.play_sfx("purchase")
		_on_purchased()
	else:
		_on_too_poor()


func _on_purchased() -> void:
	purchases += 1
	_set_face(FACE_COIN, 1.8, THANKS_LINES[randi() % THANKS_LINES.size()])


func _on_too_poor() -> void:
	_set_face(FACE_CONFUSED, 1.8, BROKE_LINES[randi() % BROKE_LINES.size()])


func _refresh_skills(points: int) -> void:
	for id in _skill_rows.keys():
		var info: Dictionary = GameState.SKILLS[id]
		var refs: Dictionary = _skill_rows[id]
		refs["name"].text = info["name"]
		refs["desc"].text = info["desc"]
		var cost: int = int(info["cost"])
		if GameState.has_skill(id):
			refs["cost"].text = "-"
			refs["button"].text = "MILIK"
			refs["button"].disabled = true
			refs["button"].modulate.a = 1.0
		elif not GameState.skill_requirement_met(id):
			refs["cost"].text = "%d Vonic" % cost
			refs["button"].text = "TERKUNCI"
			refs["button"].disabled = true
			refs["button"].modulate.a = 1.0
		else:
			refs["cost"].text = "%d Vonic" % cost
			refs["button"].text = "Beli"
			refs["button"].disabled = false
			refs["button"].modulate.a = 1.0 if points >= cost else 0.55


func _on_skill_pressed(id: String) -> void:
	if GameState.purchase_skill(id):
		AudioManager.play_sfx("purchase")
		_on_purchased()
	else:
		_on_too_poor()


func _on_skills_changed() -> void:
	_refresh(GameState.points)
