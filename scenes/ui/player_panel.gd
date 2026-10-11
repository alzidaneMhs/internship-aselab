extends Control

## Player status panel, drawn in code: portrait, animated HP bar with a damage
## trail, Vonic counter, reputation badge and owned-item badges.

const FRAMES := preload("res://scenes/player/isme_frames.tres")

const GOLD := Color(0.95, 0.72, 0.2)
const DARK := Color(0.07, 0.05, 0.1, 0.88)

const ITEM_BADGES := {
	"anti_interrupt": {"code": "AI", "color": Color(0.5, 0.65, 0.95)},
	"vampire": {"code": "VP", "color": Color(0.85, 0.3, 0.4)},
	"glass_hp": {"code": "HP", "color": Color(0.4, 0.8, 0.5)},
	"glass_atk": {"code": "AT", "color": Color(0.95, 0.55, 0.25)},
	"bounty": {"code": "$", "color": Color(0.95, 0.8, 0.25)},
	"volatile_core": {"code": "VC", "color": Color(0.8, 0.4, 0.95)},
	"double_jump": {"code": "DJ", "color": Color(0.4, 0.85, 0.95)},
	"dash": {"code": "DS", "color": Color(0.95, 0.95, 0.5)},
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

var _frame_box := StyleBoxFlat.new()
var _bar_back := StyleBoxFlat.new()
var _bar_border := StyleBoxFlat.new()
var _fill := StyleBoxFlat.new()
var _trail := StyleBoxFlat.new()
var _pill := StyleBoxFlat.new()


func _ready() -> void:
	custom_minimum_size = Vector2(480, 130)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_make_box(_frame_box, DARK, GOLD, 3, 12)
	_make_box(_bar_back, Color(0.04, 0.03, 0.06, 0.95), Color(0, 0, 0, 0), 0, 8)
	_make_box(_bar_border, Color(0, 0, 0, 0), GOLD, 3, 8)
	_make_box(_fill, Color.WHITE, Color(0, 0, 0, 0), 0, 6)
	_make_box(_trail, Color(1.0, 0.95, 0.8, 0.85), Color(0, 0, 0, 0), 0, 6)
	_make_box(_pill, Color.WHITE, Color(0, 0, 0, 0.6), 2, 12)


func _make_box(box: StyleBoxFlat, bg: Color, border: Color, width: int, radius: int) -> void:
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)


func set_health(current: float, maximum: float) -> void:
	if current < hp:
		_damage_flash = 1.0
		_trail_delay = 0.45
	hp = current
	hp_max = maxf(maximum, 1.0)
	if hp > _hp_trail:
		_hp_trail = hp  # healing/upgrades fill the trail immediately
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
		return Color(0.32, 0.82, 0.42)
	if ratio > 0.28:
		return Color(0.95, 0.78, 0.22)
	return Color(0.92, 0.25, 0.25)


func _draw() -> void:
	var font := get_theme_default_font()
	var ratio := clampf(hp / hp_max, 0.0, 1.0)

	# --- Portrait --------------------------------------------------------
	draw_style_box(_frame_box, Rect2(0, 0, 88, 88))
	var atlas := FRAMES.get_frame_texture("idle", 0) as AtlasTexture
	if atlas != null:
		draw_texture_rect_region(atlas.atlas, Rect2(8, 8, 72, 72),
				Rect2(atlas.region.position + Vector2(230, 130), Vector2(700, 700)))
	if _damage_flash > 0.0:
		draw_rect(Rect2(8, 8, 72, 72), Color(1, 0.1, 0.1, 0.45 * _damage_flash))

	# --- HP bar ------------------------------------------------------------
	var bar := Rect2(102, 8, 370, 34)
	draw_style_box(_frame_box, Rect2(bar.position - Vector2(6, 6), bar.size + Vector2(12, 12)))
	draw_style_box(_bar_back, bar)
	var inner := Rect2(bar.position + Vector2(4, 4), bar.size - Vector2(8, 8))
	var trail_w := inner.size.x * clampf(_hp_trail / hp_max, 0.0, 1.0)
	if trail_w > 2.0:
		draw_style_box(_trail, Rect2(inner.position, Vector2(trail_w, inner.size.y)))
	var fill_w := inner.size.x * ratio
	if fill_w > 2.0:
		var col := _hp_color(ratio)
		if ratio <= 0.28:
			col = col.lerp(Color.WHITE, 0.25 * (0.5 + 0.5 * sin(_time * 10.0)))
		_fill.bg_color = col
		draw_style_box(_fill, Rect2(inner.position, Vector2(fill_w, inner.size.y)))
		draw_rect(Rect2(inner.position + Vector2(3, 3), Vector2(maxf(fill_w - 6.0, 0.0), inner.size.y * 0.32)),
				Color(1, 1, 1, 0.28))
	for i in range(1, 4):
		var tick_x := inner.position.x + inner.size.x * i / 4.0
		draw_line(Vector2(tick_x, inner.position.y + 2), Vector2(tick_x, inner.end.y - 2), Color(0, 0, 0, 0.35), 2.0)
	draw_style_box(_bar_border, bar)
	var hp_text := "%d / %d" % [roundi(hp), roundi(hp_max)]
	draw_string_outline(font, Vector2(bar.position.x, bar.position.y + 25), hp_text,
			HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 20, 6, Color(0, 0, 0, 0.9))
	draw_string(font, Vector2(bar.position.x, bar.position.y + 25), hp_text,
			HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 20, Color.WHITE)

	# --- Vonic coin ----------------------------------------------------------
	var coin := Vector2(122, 70)
	draw_circle(coin, 15.0, Color(0.45, 0.28, 0.05))
	draw_circle(coin, 12.5, Color(1.0, 0.82, 0.25))
	draw_arc(coin, 8.0, 0.0, TAU, 20, Color(0.8, 0.55, 0.1), 2.0)
	draw_rect(Rect2(coin + Vector2(-2, -6), Vector2(4, 12)), Color(0.8, 0.55, 0.1))
	var vonic_text := str(vonic)
	draw_string_outline(font, Vector2(144, 78), vonic_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 6, Color(0, 0, 0, 0.9))
	draw_string(font, Vector2(144, 78), vonic_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1.0, 0.92, 0.55))

	# --- Reputation badge ------------------------------------------------------
	var rep_color := Color(0.3, 0.6, 0.95)
	if difficulty == "normal":
		rep_color = Color(0.6, 0.6, 0.68)
	elif difficulty == "hardcore":
		rep_color = Color(0.9, 0.25, 0.25)
	var pill_rect := Rect2(232, 54, 240, 32)
	_pill.bg_color = rep_color.darkened(0.35)
	_pill.border_color = rep_color.lightened(0.2)
	draw_style_box(_pill, pill_rect)
	var rep_text := "Reputasi %d  -  %s" % [reputation, reputation_title]
	draw_string_outline(font, Vector2(pill_rect.position.x, pill_rect.position.y + 22), rep_text,
			HORIZONTAL_ALIGNMENT_CENTER, pill_rect.size.x, 17, 5, Color(0, 0, 0, 0.8))
	draw_string(font, Vector2(pill_rect.position.x, pill_rect.position.y + 22), rep_text,
			HORIZONTAL_ALIGNMENT_CENTER, pill_rect.size.x, 17, Color.WHITE)

	# --- Item badges -----------------------------------------------------------
	var x := 102.0
	for id in item_ids:
		var info: Dictionary = ITEM_BADGES.get(id, {"code": "?", "color": Color.GRAY})
		_pill.bg_color = (info["color"] as Color).darkened(0.45)
		_pill.border_color = info["color"]
		var r := Rect2(x, 98, 40, 26)
		draw_style_box(_pill, r)
		draw_string(font, Vector2(r.position.x, r.position.y + 19), info["code"],
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 15, Color.WHITE)
		x += 46.0
