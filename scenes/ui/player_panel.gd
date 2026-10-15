extends Control

const FRAMES := preload("res://scenes/player/isme_frames.tres")

const KIT := preload("res://scripts/ui/ui_kit.gd")

const ITEM_BADGES := {
	"anti_interrupt": {"code": "AI", "color": Color(0.5, 0.65, 0.95)},
	"vampire": {"code": "VP", "color": Color(0.85, 0.3, 0.4)},
	"glass_hp": {"code": "HP", "color": Color(0.4, 0.8, 0.5)},
	"glass_atk": {"code": "AT", "color": Color(0.95, 0.55, 0.25)},
	"bounty": {"code": "$", "color": Color(0.95, 0.8, 0.25)},
	"volatile_core": {"code": "VC", "color": Color(0.8, 0.4, 0.95)},
	"double_jump": {"code": "DJ", "color": Color(0.4, 0.85, 0.95)},
	"dash": {"code": "DS", "color": Color(0.95, 0.95, 0.5)},
	"skill_emergency_shield": {"code": "SH", "color": Color(0.275, 0.851, 0.91)},
	"skill_swift_feet": {"code": "SP", "color": Color(0.35, 0.88, 0.54)},
	"skill_double_dash": {"code": "DD", "color": Color(1.0, 0.725, 0.22)},
}

var hp: float = 100.0
var hp_max: float = 100.0
var vonic: int = 0
var reputation: int = 0
var reputation_title: String = "Seimbang"
var difficulty: String = "normal"
var item_ids: Array = []

var _hp_trail := 100.0
var _trail_delay := 0.0
var _damage_flash := 0.0
var _time := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(480, 130)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_health(current: float, maximum: float) -> void:
	if current < hp:
		_damage_flash = 1.0
		_trail_delay = 0.45
	hp = current
	hp_max = maxf(maximum, 1.0)
	if hp > _hp_trail:
		_hp_trail = hp
	queue_redraw()


func set_vonic(value: int) -> void:
	vonic = value
	queue_redraw()


func set_reputation(value: int, title: String, diff: String) -> void:
	reputation = value
	reputation_title = title
	difficulty = diff
	queue_redraw()


func set_items(ids: Array) -> void:
	item_ids = ids.duplicate()
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	_damage_flash = move_toward(_damage_flash, 0.0, delta * 3.0)
	if _trail_delay > 0.0:
		_trail_delay -= delta
	elif _hp_trail > hp:
		_hp_trail = move_toward(_hp_trail, hp, hp_max * 0.45 * delta)
	elif _hp_trail < hp:
		_hp_trail = hp
	queue_redraw()


func _hp_color(ratio: float) -> Color:
	if ratio > 0.55:
		return KIT.GREEN
	if ratio > 0.28:
		return KIT.AMBER
	return KIT.RED


func _draw() -> void:
	var font := get_theme_default_font()
	var head: Font = get_theme_font("font", "Button")
	var ratio := clampf(hp / hp_max, 0.0, 1.0)

	var frame := Rect2(0, 0, 88, 88)
	KIT.draw_panel(self, frame, Color(KIT.INK_900, 0.94), KIT.STEEL, 9.0, KIT.AMBER, true)
	var atlas := FRAMES.get_frame_texture("idle", 0) as AtlasTexture
	if atlas != null:
		draw_texture_rect_region(atlas.atlas, Rect2(10, 10, 68, 68),
				Rect2(atlas.region.position + Vector2(230, 130), Vector2(700, 700)))
	if _damage_flash > 0.0:
		draw_rect(Rect2(10, 10, 68, 68), Color(1, 0.1, 0.1, 0.45 * _damage_flash))

	var bar := Rect2(104, 8, 368, 34)
	var col := _hp_color(ratio)
	if ratio <= 0.28:
		col = col.lerp(Color.WHITE, 0.25 * (0.5 + 0.5 * sin(_time * 10.0)))
	KIT.draw_bar(self, bar, ratio, col, Color(KIT.INK_950, 0.95), KIT.STEEL, _hp_trail / hp_max)
	var inner := bar.grow(-3.0)
	for i in range(1, 4):
		var tick_x := inner.position.x + inner.size.x * i / 4.0
		draw_line(Vector2(tick_x, inner.position.y + 2), Vector2(tick_x, inner.end.y - 2), Color(0, 0, 0, 0.4), 2.0)
	draw_string(head, Vector2(bar.position.x + 12.0, bar.position.y + 24), "HP", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(KIT.TEXT, 0.85))
	var hp_text := "%d / %d" % [roundi(hp), roundi(hp_max)]
	draw_string_outline(head, Vector2(bar.position.x, bar.position.y + 25), hp_text,
			HORIZONTAL_ALIGNMENT_RIGHT, bar.size.x - 14.0, 20, 6, Color(0, 0, 0, 0.9))
	draw_string(head, Vector2(bar.position.x, bar.position.y + 25), hp_text,
			HORIZONTAL_ALIGNMENT_RIGHT, bar.size.x - 14.0, 20, Color.WHITE)

	var coin := Vector2(124, 70)
	draw_colored_polygon(PackedVector2Array([coin + Vector2(0, -15), coin + Vector2(14, 0), coin + Vector2(0, 15), coin + Vector2(-14, 0)]), KIT.AMBER_DK)
	draw_colored_polygon(PackedVector2Array([coin + Vector2(0, -11), coin + Vector2(10, 0), coin + Vector2(0, 11), coin + Vector2(-10, 0)]), KIT.AMBER)
	draw_colored_polygon(PackedVector2Array([coin + Vector2(0, -6), coin + Vector2(3, 0), coin + Vector2(0, 6), coin + Vector2(-3, 0)]), Color(1.0, 0.95, 0.75))
	var vonic_text := str(vonic)
	draw_string_outline(head, Vector2(148, 79), vonic_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 6, Color(0, 0, 0, 0.9))
	draw_string(head, Vector2(148, 79), vonic_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1.0, 0.92, 0.6))

	var rep_color := KIT.CYAN
	if difficulty == "normal":
		rep_color = KIT.STEEL
	elif difficulty == "hardcore":
		rep_color = KIT.RED
	var pill_rect := Rect2(232, 54, 240, 32)
	KIT.draw_tag(self, pill_rect, rep_color, Color(rep_color.darkened(0.78), 0.95))
	draw_rect(Rect2(pill_rect.position.x + 8.0, pill_rect.position.y + 8.0, 4.0, pill_rect.size.y - 16.0), rep_color)
	var rep_text := "REPUTASI %d  -  %s" % [reputation, reputation_title.to_upper()]
	draw_string(font, Vector2(pill_rect.position.x + 14.0, pill_rect.position.y + 22), rep_text,
			HORIZONTAL_ALIGNMENT_CENTER, pill_rect.size.x - 14.0, 16, KIT.TEXT)

	var x := 104.0
	for id in item_ids:
		var info: Dictionary = ITEM_BADGES.get(id, {"code": "?", "color": Color.GRAY})
		var icol: Color = info["color"]
		var r := Rect2(x, 98, 42, 26)
		KIT.draw_tag(self, r, icol, Color(icol.darkened(0.75), 0.95))
		draw_string(head, Vector2(r.position.x, r.position.y + 19), info["code"],
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 15, Color.WHITE)
		x += 48.0
