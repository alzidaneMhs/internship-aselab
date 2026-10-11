extends Control

## Boss health bar, drawn in code: ornate nameplate, HP bar with a damage trail,
## a shield bar underneath, and a STUN countdown that replaces the shield bar.

const GOLD := Color(0.95, 0.72, 0.2)
const DARK := Color(0.07, 0.04, 0.09, 0.92)

var boss_name: String = "Boss"
var hp: float = 1.0
var hp_max: float = 1.0
var shield: float = 0.0
var shield_max: float = 0.0
var stun_remaining: float = 0.0
var stun_duration: float = 5.0

var _hp_trail := 1.0
var _shield_trail := 0.0
var _time := 0.0

var _back := StyleBoxFlat.new()
var _border := StyleBoxFlat.new()
var _fill := StyleBoxFlat.new()
var _trail := StyleBoxFlat.new()
var _small_back := StyleBoxFlat.new()
var _small_fill := StyleBoxFlat.new()


func _ready() -> void:
	custom_minimum_size = Vector2(640, 86)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_box(_back, DARK, GOLD, 3, 10)
	_set_box(_border, Color(0, 0, 0, 0), GOLD, 3, 10)
	_set_box(_fill, Color.WHITE, Color(0, 0, 0, 0), 0, 7)
	_set_box(_trail, Color(1.0, 0.95, 0.75, 0.85), Color(0, 0, 0, 0), 0, 7)
	_set_box(_small_back, Color(0.03, 0.05, 0.09, 0.95), Color(0.2, 0.55, 0.7, 0.9), 2, 6)
	_set_box(_small_fill, Color.WHITE, Color(0, 0, 0, 0), 0, 4)


func _set_box(box: StyleBoxFlat, bg: Color, border: Color, width: int, radius: int) -> void:
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)


func update_state(p_hp: float, p_hp_max: float, p_shield: float, p_shield_max: float,
		p_stun: float, p_stun_duration: float) -> void:
	hp = p_hp
	hp_max = maxf(p_hp_max, 1.0)
	shield = p_shield
	shield_max = p_shield_max
	stun_remaining = p_stun
	stun_duration = maxf(p_stun_duration, 0.01)


func _process(delta: float) -> void:
	_time += delta
	var target := hp / hp_max
	_hp_trail = move_toward(_hp_trail, target, 0.35 * delta) if _hp_trail > target else target
	var s_target := shield / shield_max if shield_max > 0.0 else 0.0
	_shield_trail = move_toward(_shield_trail, s_target, 0.8 * delta) if _shield_trail > s_target else s_target
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	var w := size.x
	var ratio := clampf(hp / hp_max, 0.0, 1.0)
	var stunned := stun_remaining > 0.0

	# --- Nameplate -------------------------------------------------------------
	var name_text := boss_name.to_upper()
	draw_string_outline(font, Vector2(0, 24), name_text, HORIZONTAL_ALIGNMENT_CENTER, w, 26, 8, Color(0.15, 0.05, 0.02))
	draw_string(font, Vector2(0, 24), name_text, HORIZONTAL_ALIGNMENT_CENTER, w, 26, Color(1.0, 0.82, 0.3))
	var text_w := font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 26).x
	for side in [-1.0, 1.0]:
		var cx: float = w / 2.0 + side * (text_w / 2.0 + 30.0)
		draw_line(Vector2(cx, 14), Vector2(cx + side * 110.0, 14), GOLD, 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 6, 14), Vector2(cx, 8), Vector2(cx + 6, 14), Vector2(cx, 20)]), GOLD)

	# --- HP bar ----------------------------------------------------------------
	var bar := Rect2(0, 32, w, 26)
	draw_style_box(_back, bar)
	var inner := Rect2(bar.position + Vector2(4, 4), bar.size - Vector2(8, 8))
	var trail_w := inner.size.x * clampf(_hp_trail, 0.0, 1.0)
	if trail_w > 2.0:
		draw_style_box(_trail, Rect2(inner.position, Vector2(trail_w, inner.size.y)))
	var fill_w := inner.size.x * ratio
	if fill_w > 2.0:
		var col := Color(0.88, 0.2, 0.22).lerp(Color(1.0, 0.45, 0.15), 1.0 - ratio)
		if stunned:
			col = col.lerp(Color(1.0, 0.9, 0.3), 0.35 + 0.35 * sin(_time * 12.0))
		_fill.bg_color = col
		draw_style_box(_fill, Rect2(inner.position, Vector2(fill_w, inner.size.y)))
		draw_rect(Rect2(inner.position + Vector2(3, 2), Vector2(maxf(fill_w - 6.0, 0.0), inner.size.y * 0.35)), Color(1, 1, 1, 0.25))
	for i in range(1, 10):
		var tick_x := inner.position.x + inner.size.x * i / 10.0
		draw_line(Vector2(tick_x, inner.position.y + 3), Vector2(tick_x, inner.end.y - 3), Color(0, 0, 0, 0.3), 1.5)
	_border.border_color = Color(1.0, 0.9, 0.4) if stunned else GOLD
	draw_style_box(_border, bar)

	# --- Shield / stun bar -------------------------------------------------------
	var small := Rect2(24, 64, w - 48, 16)
	if stunned:
		draw_style_box(_small_back, small)
		var s_inner := Rect2(small.position + Vector2(3, 3), small.size - Vector2(6, 6))
		_small_fill.bg_color = Color(1.0, 0.8, 0.2)
		draw_style_box(_small_fill, Rect2(s_inner.position, Vector2(s_inner.size.x * clampf(stun_remaining / stun_duration, 0.0, 1.0), s_inner.size.y)))
		var stun_text := "PINGSAN  %.1fs   (damage x1.5)" % stun_remaining
		draw_string_outline(font, Vector2(small.position.x, small.position.y + 13), stun_text,
				HORIZONTAL_ALIGNMENT_CENTER, small.size.x, 13, 5, Color(0, 0, 0, 0.9))
		draw_string(font, Vector2(small.position.x, small.position.y + 13), stun_text,
				HORIZONTAL_ALIGNMENT_CENTER, small.size.x, 13, Color.WHITE)
	elif shield_max > 0.0:
		draw_style_box(_small_back, small)
		var s_inner := Rect2(small.position + Vector2(3, 3), small.size - Vector2(6, 6))
		var tw := s_inner.size.x * clampf(_shield_trail, 0.0, 1.0)
		if tw > 2.0:
			draw_style_box(_trail, Rect2(s_inner.position, Vector2(tw, s_inner.size.y)))
		var sw := s_inner.size.x * clampf(shield / shield_max, 0.0, 1.0)
		if sw > 2.0:
			_small_fill.bg_color = Color(0.3, 0.85, 1.0)
			draw_style_box(_small_fill, Rect2(s_inner.position, Vector2(sw, s_inner.size.y)))
			var sheen := fposmod(_time * 0.6, 1.4) - 0.2
			draw_rect(Rect2(s_inner.position + Vector2(maxf(sw * sheen - 14.0, 0.0), 0), Vector2(minf(14.0, sw), s_inner.size.y)), Color(1, 1, 1, 0.35))
		var shield_text := "SHIELD"
		draw_string_outline(font, Vector2(small.position.x, small.position.y + 13), shield_text,
				HORIZONTAL_ALIGNMENT_CENTER, small.size.x, 12, 4, Color(0, 0, 0, 0.9))
		draw_string(font, Vector2(small.position.x, small.position.y + 13), shield_text,
				HORIZONTAL_ALIGNMENT_CENTER, small.size.x, 12, Color(0.85, 0.97, 1.0))
