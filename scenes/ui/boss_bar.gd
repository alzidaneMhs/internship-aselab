extends Control

## Boss health bar, drawn in code: ornate nameplate, HP bar with a damage trail,
## a shield bar underneath, and a STUN countdown that replaces the shield bar.

const KIT := preload("res://scripts/ui/ui_kit.gd")

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



func _ready() -> void:
	custom_minimum_size = Vector2(640, 86)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


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
	var head: Font = get_theme_font("font", "Button")
	var w := size.x
	var ratio := clampf(hp / hp_max, 0.0, 1.0)
	var stunned := stun_remaining > 0.0

	# --- Nameplate: a chip in the middle with amber rails running outward -------
	var name_text := boss_name.to_upper()
	var text_w := head.get_string_size(name_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 26).x
	var plate := Rect2((w - text_w) / 2.0 - 26.0, 0.0, text_w + 52.0, 32.0)
	KIT.draw_tag(self, plate, KIT.AMBER, Color(KIT.INK_900, 0.95))
	draw_string_outline(head, Vector2(plate.position.x, 25), name_text, HORIZONTAL_ALIGNMENT_CENTER, plate.size.x, 24, 6, Color(0, 0, 0, 0.9))
	draw_string(head, Vector2(plate.position.x, 25), name_text, HORIZONTAL_ALIGNMENT_CENTER, plate.size.x, 24, Color(1.0, 0.9, 0.62))
	for side in [-1.0, 1.0]:
		var sx: float = plate.position.x if side < 0.0 else plate.end.x
		draw_line(Vector2(sx + side * 8.0, 16), Vector2(sx + side * 130.0, 16), KIT.AMBER, 3.0)
		draw_rect(Rect2(sx + side * 138.0 - 3.0, 12.0, 8.0, 8.0), KIT.AMBER)

	# --- HP bar ----------------------------------------------------------------
	var bar := Rect2(0, 38, w, 26)
	var col := Color(0.92, 0.22, 0.24).lerp(Color(1.0, 0.45, 0.15), 1.0 - ratio)
	if stunned:
		col = col.lerp(Color(1.0, 0.9, 0.3), 0.35 + 0.35 * sin(_time * 12.0))
	KIT.draw_bar(self, bar, ratio, col, Color(KIT.INK_950, 0.95), KIT.AMBER if stunned else KIT.STEEL, _hp_trail)
	var inner := bar.grow(-3.0)
	for i in range(1, 10):
		var tick_x := inner.position.x + inner.size.x * i / 10.0
		draw_line(Vector2(tick_x, inner.position.y + 3), Vector2(tick_x, inner.end.y - 3), Color(0, 0, 0, 0.3), 1.5)

	# --- Shield / stun bar -------------------------------------------------------
	var small := Rect2(24, 70, w - 48, 14)
	if stunned:
		KIT.draw_bar(self, small, stun_remaining / stun_duration, KIT.AMBER, Color(KIT.INK_950, 0.95), KIT.AMBER_DK)
		var stun_text := "PINGSAN  %.1fs   -   SERANG SEKARANG!" % stun_remaining
		draw_string_outline(font, Vector2(small.position.x, small.position.y + 12), stun_text,
				HORIZONTAL_ALIGNMENT_CENTER, small.size.x, 13, 5, Color(0, 0, 0, 0.9))
		draw_string(font, Vector2(small.position.x, small.position.y + 12), stun_text,
				HORIZONTAL_ALIGNMENT_CENTER, small.size.x, 13, Color.WHITE)
	elif shield_max > 0.0:
		var s_ratio := clampf(shield / shield_max, 0.0, 1.0)
		KIT.draw_bar(self, small, s_ratio, KIT.CYAN, Color(KIT.INK_950, 0.95), Color(KIT.CYAN, 0.55), _shield_trail, Color(1.0, 0.95, 0.8, 0.8))
		var sheen := fposmod(_time * 0.6, 1.4) - 0.2
		var sw := (small.size.x - 6.0) * s_ratio
		if sw > 6.0:
			draw_rect(Rect2(small.position + Vector2(3.0 + maxf(sw * sheen - 14.0, 0.0), 3.0), Vector2(minf(14.0, sw), small.size.y - 6.0)), Color(1, 1, 1, 0.35))
		draw_string_outline(font, Vector2(small.position.x, small.position.y + 12), "SHIELD",
				HORIZONTAL_ALIGNMENT_CENTER, small.size.x, 12, 4, Color(0, 0, 0, 0.9))
		draw_string(font, Vector2(small.position.x, small.position.y + 12), "SHIELD",
				HORIZONTAL_ALIGNMENT_CENTER, small.size.x, 12, Color(0.85, 0.97, 1.0))
