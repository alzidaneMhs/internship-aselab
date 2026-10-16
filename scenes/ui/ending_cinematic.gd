extends Control

const KIT := preload("res://scripts/ui/ui_kit.gd")
const ISME_FRAMES := preload("res://scenes/player/isme_frames.tres")
const BG_SURFACE := preload("res://assets/sprites/backgrounds/bg_permukaan.png")
const SCOTT_TEX := preload("res://assets/sprites/bosses/scott/scott.png")
const LUSHTE_TEX := preload("res://assets/sprites/enemies/winged/musuh_bersayap.png")
const KRUMS_TEX := preload("res://assets/sprites/enemies/shielded/musuh_bertameng.png")
const CORE_TEX := preload("res://assets/sprites/lore/core_reset.png")
const CHASER_TEX := preload("res://assets/sprites/enemies/regular/chaser_bot.png")
const RANGED_TEX := preload("res://assets/sprites/enemies/regular/ranged_bot.png")
const HANCH_SHEET := preload("res://assets/sprites/npc/hanch/hanch_sheet.png")
const W := 1280.0
const H := 720.0
const GROUND := 640.0
const CREDITS := [
	"H.A.R  -  PLANET CIRCUIT",
	"",
	"Fairus Shafani Nurhanifah",
	"Game Designer",
	"",
	"Nabila Hanif Nurfitriya",
	"Game Artist",
	"",
	"Muhammad Alzidane Mahesa",
	"Game Programmer",
	"",
	"Ahmad Kayla Wirananda",
	"Game Programmer",
	"",
	"TEAM DAPHNE",
	"",
	"Dibuat dengan Godot Engine",
]

var _t := 0.0
var _speed := 1.0
var _a_end := 7.5
var _b_end := 15.0
var _c_end := 23.0
var _d_end := 32.0
var _e_end := 38.5
var _f_end := 58.0
var _results_at := 56.0
var _true_ending := false
var _route := "normal"
var _pages: Array = []
var _captions: Array = []
var _caption_idx := -1
var _caption_label: Label
var _hint: Label
var _results: Control
var _results_shown := false
var _hanch_faces: Array = []
var _screen_off: Array = []
var _crowd: Array = []
var _sparkles: Array = []
var _stars: Array = []
var _chains: Array = []
var _base := Transform2D.IDENTITY
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.seed = 2026
	_true_ending = GameState.ending_kind == "true"
	_route = GameState.get_minigame_difficulty()
	_pages = Story.get_ending_pages()
	_build_timeline()
	_build_data()
	_build_ui()
	AudioManager.play_music("ending")


func _build_timeline() -> void:
	var middle: Array = _pages.slice(4, _pages.size() - 1)
	var true_pages: Array = middle if _true_ending else []
	var teaser: Array = [] if _true_ending else middle
	_d_end = _c_end + 9.0 + 5.5 * true_pages.size()
	_e_end = _d_end + 6.5
	var f_start := _e_end
	_results_at = f_start + 18.0 + 6.0 * teaser.size()
	_f_end = _results_at + 1.0
	_add_caption(0.9, 5.8, _pages[0])
	_add_caption(_a_end + 1.0, 5.6, _pages[2])
	_add_caption(_b_end + 1.0, 6.2, _pages[1])
	_add_caption(_c_end + 1.2, 6.8, _pages[3])
	var t := _c_end + 8.5
	for p in true_pages:
		_add_caption(t, 5.2, p)
		t += 5.5
	var ft := f_start + 4.5
	for p in teaser:
		_add_caption(ft, 5.6, p)
		ft += 6.0
	_add_caption(ft, 5.0, _pages[_pages.size() - 1])


func _add_caption(at: float, dur: float, text: String) -> void:
	_captions.append({"at": at, "dur": dur, "text": text})


func _build_data() -> void:
	for i in 14:
		_screen_off.append(_rng.randf_range(1.4, 5.6))
	var count := 12
	if _route == "hardcore":
		count = 3
	elif _route == "normal":
		count = 7
	for i in count:
		_crowd.append({
			"x": _rng.randf_range(120.0, 1160.0),
			"h": _rng.randf_range(62.0, 92.0),
			"tex": _rng.randi() % 2,
			"ph": _rng.randf() * TAU,
			"delay": _rng.randf_range(0.0, 3.0),
			"flip": _rng.randf() < 0.5,
		})
	for i in 70:
		_sparkles.append({"x": _rng.randf_range(0.0, W), "y": _rng.randf_range(250.0, H), "s": _rng.randf_range(20.0, 60.0), "ph": _rng.randf()})
	for i in 120:
		_stars.append(Vector3(_rng.randf_range(0.0, W), _rng.randf_range(0.0, H), _rng.randf_range(0.5, 2.2)))
	for i in 14:
		_chains.append({"x": _rng.randf_range(-60.0, 60.0), "vy": _rng.randf_range(60.0, 160.0), "rot": _rng.randf() * TAU, "spin": _rng.randf_range(-4.0, 4.0), "who": i % 2})
	var cell := float(HANCH_SHEET.get_width()) / 5.0
	for f in 5:
		var at := AtlasTexture.new()
		at.atlas = HANCH_SHEET
		at.region = Rect2(f * cell, 0.0, cell, float(HANCH_SHEET.get_height()))
		_hanch_faces.append(at)


func _build_ui() -> void:
	_caption_label = Label.new()
	_caption_label.position = Vector2(150, 590)
	_caption_label.size = Vector2(980, 96)
	_caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption_label.add_theme_font_size_override("font_size", 24)
	_caption_label.add_theme_color_override("font_color", KIT.TEXT)
	_caption_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_caption_label.add_theme_constant_override("outline_size", 7)
	_caption_label.modulate.a = 0.0
	add_child(_caption_label)
	_hint = Label.new()
	_hint.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_hint.text = Settings.fill(tr("[Tahan {interact}] percepat     [{ui_cancel}] lewati"))
	_hint.position = Vector2(820, 690)
	_hint.size = Vector2(440, 26)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.add_theme_color_override("font_color", Color(KIT.TEXT_DIM, 0.8))
	add_child(_hint)


func _process(delta: float) -> void:
	if not _results_shown:
		var hold: bool = Input.is_action_pressed("ui_accept") or Input.is_action_pressed("interact") or Input.is_action_pressed("jump")
		_speed = 3.0 if hold else 1.0
		_t += delta * _speed
		if _t >= _results_at:
			_show_results()
	else:
		_t += delta
	_update_caption()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if _results_shown:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_t = _results_at
		_show_results()


func _update_caption() -> void:
	var active := -1
	for i in _captions.size():
		var c: Dictionary = _captions[i]
		var at: float = c["at"]
		var dur: float = c["dur"]
		if _t >= at and _t < at + dur:
			active = i
	if _results_shown:
		active = -1
	if active != _caption_idx:
		_caption_idx = active
		if active >= 0:
			_caption_label.text = String(_captions[active]["text"])
			_caption_label.visible_characters = 0
	if _caption_idx >= 0:
		var c2: Dictionary = _captions[_caption_idx]
		var local := _t - float(c2["at"])
		var dur2: float = c2["dur"]
		_caption_label.visible_characters = int(local * 42.0)
		var fade := clampf(local / 0.35, 0.0, 1.0) * clampf((dur2 - local) / 0.5, 0.0, 1.0)
		_caption_label.modulate.a = fade
	else:
		_caption_label.modulate.a = move_toward(_caption_label.modulate.a, 0.0, 0.05)


func _show_results() -> void:
	if _results_shown:
		return
	_results_shown = true
	_hint.visible = false
	_results = Control.new()
	_results.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_results)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_results.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	var title := Label.new()
	title.text = "TRUE ENDING" if _true_ending else "TAMAT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", KIT.AMBER)
	box.add_child(title)
	var sub := Label.new()
	sub.text = "Terima kasih sudah memainkan H.A.R"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	var stats := Label.new()
	stats.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.text = tr("Vonic terkumpul: %d\nReputasi: %d  (%s)\nRobot dibebaskan: %d / 2\nSecret room: %d / 5\nItem boss: %d") % [
		GameState.points, GameState.reputation, tr(GameState.get_reputation_title()),
		GameState.bosses_freed.size(), GameState.secrets_found.size(), GameState.items.size(),
	]
	box.add_child(stats)
	var button := Button.new()
	button.text = "Menu Utama"
	button.custom_minimum_size = Vector2(0, 54)
	button.pressed.connect(GameManager.goto_main_menu)
	box.add_child(button)
	_results.modulate.a = 0.0
	create_tween().tween_property(_results, "modulate:a", 1.0, 0.8)
	button.grab_focus()


func _set_base(xf: Transform2D) -> void:
	_base = xf
	draw_set_transform_matrix(_base)


func _sprite(tex: Texture2D, feet: Vector2, height: float, flip: bool = false, mod: Color = Color.WHITE, rot: float = 0.0) -> void:
	if tex == null:
		return
	var w := height * float(tex.get_width()) / float(tex.get_height())
	var local := Transform2D(rot, Vector2(-1.0 if flip else 1.0, 1.0), 0.0, feet)
	draw_set_transform_matrix(_base * local)
	draw_texture_rect(tex, Rect2(-w / 2.0, -height, w, height), false, mod)
	draw_set_transform_matrix(_base)


func _isme_frame(anim: String, t: float) -> Texture2D:
	var count := ISME_FRAMES.get_frame_count(anim)
	if count <= 0:
		return null
	var fps := ISME_FRAMES.get_animation_speed(anim)
	return ISME_FRAMES.get_frame_texture(anim, int(t * fps) % count)


func _fade_edges(local: float, length: float) -> float:
	return clampf(local / 0.7, 0.0, 1.0) * clampf((length - local) / 0.7, 0.0, 1.0)


func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color.BLACK)
	var t := _t
	if t < _a_end:
		_shot_shutdown(t, _a_end)
	elif t < _b_end:
		_shot_core(t - _a_end, _b_end - _a_end)
	elif t < _c_end:
		_shot_awaken(t - _b_end, _c_end - _b_end)
	elif t < _d_end:
		_shot_together(t - _c_end, _d_end - _c_end, Transform2D.IDENTITY)
	elif t < _e_end:
		_shot_photo(t - _d_end, _e_end - _d_end)
	else:
		_shot_finale(t - _e_end)
	_set_base(Transform2D.IDENTITY)
	var bar := 40.0
	if _t >= _e_end + 2.0:
		bar = maxf(40.0 - (_t - _e_end - 2.0) * 30.0, 0.0)
	draw_rect(Rect2(0, 0, W, bar), Color.BLACK)
	draw_rect(Rect2(0, H - bar, W, bar), Color.BLACK)
	if _caption_label.modulate.a > 0.01:
		var a := _caption_label.modulate.a
		draw_rect(Rect2(0, 570, W, 130), Color(0, 0, 0, 0.45 * a))
	if _speed > 1.5 and not _results_shown:
		draw_string(get_theme_default_font(), Vector2(40, 30), ">> x3", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(KIT.AMBER, 0.8))


func _shot_shutdown(local: float, length: float) -> void:
	var zoom := 1.0 + 0.06 * (local / length)
	_set_base(Transform2D(0.0, Vector2(zoom, zoom), 0.0, Vector2(W, H) * 0.5 * (1.0 - zoom)))
	draw_rect(Rect2(-40, -40, W + 80, H + 80), Color(0.04, 0.03, 0.06))
	draw_rect(Rect2(-40, GROUND, W + 80, H - GROUND + 40), Color(0.07, 0.06, 0.1))
	draw_rect(Rect2(-40, GROUND, W + 80, 4), Color(0.25, 0.1, 0.12))
	for i in _screen_off.size():
		var col := i % 7
		var row := i / 7
		var r := Rect2(70.0 + col * 166.0, 70.0 + row * 112.0, 146.0, 92.0)
		var off_at: float = _screen_off[i]
		draw_rect(r.grow(5.0), Color(0.12, 0.1, 0.16))
		if local < off_at:
			var flick := 0.8 + 0.2 * sin(local * 40.0 + i)
			draw_rect(r, Color(0.35, 0.05, 0.06, flick))
			var c := r.get_center()
			draw_arc(c, 26.0, 0.0, TAU, 24, Color(1.0, 0.3, 0.25, 0.9), 2.0)
			draw_line(c + Vector2(-38, 0), c + Vector2(38, 0), Color(1.0, 0.3, 0.25, 0.7), 2.0)
			draw_line(c + Vector2(0, -32), c + Vector2(0, 32), Color(1.0, 0.3, 0.25, 0.7), 2.0)
			draw_string(get_theme_default_font(), r.position + Vector2(8, 18), "ISME", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 0.6, 0.5, 0.8))
		else:
			var k := clampf((local - off_at) / 0.25, 0.0, 1.0)
			draw_rect(r, Color(0.02, 0.02, 0.03))
			if k < 1.0:
				var c2 := r.get_center()
				draw_rect(Rect2(c2.x - r.size.x * 0.5 * (1.0 - k), c2.y - 2.0, r.size.x * (1.0 - k), 4.0), Color(1, 1, 1, 1.0 - k))
	var dim := clampf(local / (length * 0.8), 0.0, 1.0)
	var scott_mod := Color.WHITE.lerp(Color(0.32, 0.32, 0.42), dim)
	var sink := 26.0 * dim
	_sprite(SCOTT_TEX, Vector2(840, GROUND + sink), 360.0, false, scott_mod, 0.06 * dim)
	var eye := Vector2(820, GROUND + sink - 300.0)
	var glow := 1.0 - dim
	if glow > 0.02:
		draw_circle(eye, 34.0 * glow + 6.0, Color(1.0, 0.2, 0.15, 0.25 * glow))
		draw_circle(eye, 9.0, Color(1.0, 0.4, 0.3, glow))
	_sprite(_isme_frame("idle", local), Vector2(330, GROUND + 6.0), 190.0, false, Color(0.35, 0.33, 0.42))
	draw_rect(Rect2(-40, -40, W + 80, H + 80), Color(0, 0, 0, 1.0 - _fade_edges(local, length)))


func _shot_core(local: float, length: float) -> void:
	var shake := Vector2.ZERO
	var p := clampf(0.62 + 0.38 * smoothstep(0.8, 4.6, local), 0.0, 1.0)
	var stutter := sin(local * 37.0) > 0.85 and p < 1.0
	if stutter:
		p -= 0.03
		shake = Vector2(_rng.randf_range(-4, 4), _rng.randf_range(-3, 3))
	var done := p >= 0.999
	_set_base(Transform2D(0.0, Vector2.ONE, 0.0, shake))
	draw_rect(Rect2(-20, -20, W + 40, H + 40), Color(0.02, 0.03, 0.04))
	var k := 1.6
	var origin := Vector2((W - 640.0 * k) / 2.0, (H - 360.0 * k) / 2.0 - 20.0)
	draw_texture_rect(CORE_TEX, Rect2(origin, Vector2(640, 360) * k), false)
	var bg := Color(8.0 / 255.0, 24.0 / 255.0, 30.0 / 255.0)
	var bar := Rect2(origin + Vector2(91, 194) * k, Vector2(458, 29) * k)
	draw_rect(bar, bg)
	var fill := Color(0.4, 1.0, 0.7) if not done else Color(0.75, 1.0, 0.85)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * p, bar.size.y)), fill)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * p, bar.size.y * 0.3)), Color(1, 1, 1, 0.25))
	var text_rect := Rect2(origin + Vector2(110, 244) * k, Vector2(420, 30) * k)
	draw_rect(text_rect, bg)
	var label := "%d%%  -  %s" % [int(round(p * 100.0)), tr("jangan matikan sistem") if not done else tr("SISTEM DIPULIHKAN")]
	draw_string(get_theme_default_font(), Vector2(text_rect.position.x, text_rect.position.y + 32.0), label, HORIZONTAL_ALIGNMENT_CENTER, text_rect.size.x, 26, Color(0.5, 1.0, 0.8))
	if done:
		var since := local - 4.6
		var flash := clampf(1.0 - since / 0.8, 0.0, 1.0)
		draw_rect(Rect2(-20, -20, W + 40, H + 40), Color(0.8, 1.0, 0.9, 0.7 * flash))
		var pulse := 0.5 + 0.5 * sin(local * 6.0)
		draw_rect(Rect2(origin, Vector2(640, 360) * k).grow(8.0 + 6.0 * pulse), Color(0.4, 1.0, 0.7, 0.35), false, 4.0)
	draw_rect(Rect2(-20, -20, W + 40, H + 40), Color(0, 0, 0, 1.0 - _fade_edges(local, length)))


func _shot_awaken(local: float, length: float) -> void:
	var pan := -40.0 * (local / length)
	_set_base(Transform2D(0.0, Vector2(1.04, 1.04), 0.0, Vector2(pan - 25.0, -14.0)))
	draw_texture_rect(BG_SURFACE, Rect2(-20, -20, W + 40, H + 40), false)
	var reveal := lerpf(-300.0, W + 400.0, smoothstep(0.4, 5.2, local))
	var dark := Color(0.02, 0.01, 0.06, 0.82)
	draw_rect(Rect2(reveal, -20, W + 420 - reveal, H + 40), dark)
	var edge := PackedVector2Array([Vector2(reveal - 260, -20), Vector2(reveal, -20), Vector2(reveal, H + 20), Vector2(reveal - 260, H + 20)])
	draw_polygon(edge, PackedColorArray([Color(dark, 0.0), dark, dark, Color(dark, 0.0)]))
	draw_line(Vector2(reveal - 60, -20), Vector2(reveal - 60, H + 20), Color(1.0, 0.9, 0.6, 0.18), 60.0)
	for s in _sparkles:
		var sd: Dictionary = s
		var sx: float = sd["x"]
		if sx > reveal - 100.0:
			continue
		var u := fposmod(local * 0.25 + float(sd["ph"]), 1.0)
		var sy: float = float(sd["y"]) - u * float(sd["s"]) * 6.0
		draw_circle(Vector2(sx + sin(u * 6.0 + sx) * 10.0, sy), 2.5 * (1.0 - u) + 1.0, Color(1.0, 0.9, 0.55, 0.8 * (1.0 - u)))
	var lu := smoothstep(1.2, 4.2, local)
	var lpos := Vector2(lerpf(1150.0, 900.0, lu), lerpf(-120.0, 520.0, lu) + sin(local * 2.4) * 8.0)
	_sprite(LUSHTE_TEX, lpos, 300.0, true)
	var ku := smoothstep(2.0, 6.0, local)
	var kx := lerpf(1460.0, 1110.0, ku)
	var step := absf(sin(local * 6.0)) * 6.0 * (1.0 - ku)
	_sprite(KRUMS_TEX, Vector2(kx, GROUND + 4.0 - step), 330.0, true)
	for c in _chains:
		var cd: Dictionary = c
		var start := 1.8 if int(cd["who"]) == 0 else 3.4
		if local < start:
			continue
		var ct := local - start
		var anchor := lpos + Vector2(0, -160) if int(cd["who"]) == 0 else Vector2(kx, GROUND - 180.0)
		var cpos := anchor + Vector2(float(cd["x"]) + ct * float(cd["x"]) * 0.8, float(cd["vy"]) * ct + 420.0 * ct * ct)
		var alpha := clampf(1.0 - ct / 1.6, 0.0, 1.0)
		if alpha <= 0.0:
			continue
		var rot := float(cd["rot"]) + float(cd["spin"]) * ct
		draw_set_transform_matrix(_base * Transform2D(rot, cpos))
		draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 10, Color(0.6, 0.6, 0.68, alpha), 3.5)
		draw_circle(Vector2.ZERO, 14.0, Color(0.7, 0.3, 1.0, 0.25 * alpha))
		draw_set_transform_matrix(_base)
	draw_rect(Rect2(-40, -40, W + 80, H + 80), Color(0, 0, 0, 1.0 - _fade_edges(local, length)))


func _shot_together(local: float, length: float, xf: Transform2D) -> void:
	_set_base(xf)
	draw_texture_rect(BG_SURFACE, Rect2(0, 0, W, H), false)
	if _route == "hardcore":
		draw_rect(Rect2(0, 0, W, H), Color(0.35, 0.05, 0.08, 0.28))
		for i in 7:
			var wx := 90.0 + i * 180.0
			draw_colored_polygon(PackedVector2Array([Vector2(wx - 70, GROUND + 6), Vector2(wx - 30, GROUND - 40), Vector2(wx + 20, GROUND - 22), Vector2(wx + 60, GROUND + 6)]), Color(0.12, 0.09, 0.1, 0.9))
			draw_line(Vector2(wx - 20, GROUND - 30), Vector2(wx + 10, GROUND - 70), Color(0.2, 0.17, 0.2), 6.0)
	else:
		draw_rect(Rect2(0, 0, W, H), Color(1.0, 0.85, 0.5, 0.06))
	for r in _crowd:
		var rd: Dictionary = r
		var appear := smoothstep(float(rd["delay"]), float(rd["delay"]) + 1.0, local)
		if appear <= 0.0:
			continue
		var hop := 0.0
		if _route == "kind":
			hop = absf(sin(local * 4.0 + float(rd["ph"]))) * 14.0
		var tex: Texture2D = CHASER_TEX if int(rd["tex"]) == 0 else RANGED_TEX
		var shade := Color(0.55, 0.55, 0.65, appear) if _route != "hardcore" else Color(0.4, 0.3, 0.35, appear * 0.85)
		_sprite(tex, Vector2(float(rd["x"]), GROUND - 34.0 - hop), float(rd["h"]), bool(rd["flip"]), shade)
	var iu := smoothstep(0.0, 3.6, local)
	var ix := lerpf(-120.0, 560.0, iu)
	var walking := iu < 0.999
	var itex := _isme_frame("walk" if walking else "idle", local)
	_sprite(LUSHTE_TEX, Vector2(400.0, GROUND - 40.0 + sin(local * 2.2) * 8.0), 290.0, false)
	_sprite(KRUMS_TEX, Vector2(760.0, GROUND + 4.0), 320.0, true)
	if _route != "hardcore":
		var su := smoothstep(2.5, 6.5, local)
		var scott_mod := Color(0.85, 0.85, 0.95, su)
		_sprite(SCOTT_TEX, Vector2(lerpf(1300.0, 1000.0, su), GROUND + 4.0), 330.0, true, scott_mod)
	if _true_ending:
		var hu := smoothstep(7.0, 9.5, local)
		var face := 3 if int(local * 1.2) % 3 == 0 else 2
		_sprite(_hanch_faces[face], Vector2(lerpf(1380.0, 1170.0, hu), GROUND + 2.0 - absf(sin(local * 5.0)) * 4.0 * (1.0 - hu)), 175.0, false, Color(1, 1, 1, hu))
	_sprite(itex, Vector2(ix, GROUND + 8.0 - (absf(sin(local * 9.0)) * 3.0 if walking else 0.0)), 200.0, false)
	if xf == Transform2D.IDENTITY:
		draw_rect(Rect2(-40, -40, W + 80, H + 80), Color(0, 0, 0, 1.0 - clampf(local / 0.7, 0.0, 1.0)))


func _shot_photo(local: float, length: float) -> void:
	var settle := smoothstep(0.4, 1.8, local)
	var zoom := lerpf(1.0, 0.62, settle)
	var tilt := lerpf(0.0, -0.07, settle)
	var center := Vector2(W * 0.5, H * 0.46)
	_set_base(Transform2D.IDENTITY)
	draw_rect(Rect2(0, 0, W, H), Color(0.08, 0.06, 0.1))
	for i in 9:
		draw_rect(Rect2(0, i * 80.0, W, 40.0), Color(0.1, 0.075, 0.12))
	var frame_xf := Transform2D(tilt, Vector2(zoom, zoom), 0.0, center) * Transform2D(0.0, Vector2(-W * 0.5, -H * 0.5))
	if settle > 0.0:
		_set_base(frame_xf)
		var border := 36.0 / maxf(zoom, 0.01) * settle
		draw_rect(Rect2(-border, -border, W + border * 2.0, H + border * 2.0 + 140.0 * settle), Color(0.96, 0.94, 0.88))
	_shot_together(9.5, 9.5, frame_xf)
	_set_base(frame_xf)
	if settle > 0.6:
		var cap := tr("Planet Circuit  -  bersama lagi") if _route != "hardcore" else tr("Planet Circuit  -  yang tersisa")
		draw_string(get_theme_default_font(), Vector2(0, H + 92.0), cap, HORIZONTAL_ALIGNMENT_CENTER, W, 62, Color(0.25, 0.2, 0.3, clampf((settle - 0.6) / 0.4, 0.0, 1.0)))
	_set_base(Transform2D.IDENTITY)
	var flash := clampf(1.0 - local / 0.5, 0.0, 1.0)
	draw_rect(Rect2(0, 0, W, H), Color(1, 1, 1, flash))
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, clampf((local - (length - 0.7)) / 0.7, 0.0, 1.0)))


func _shot_finale(local: float) -> void:
	_set_base(Transform2D.IDENTITY)
	var top := Color(0.03, 0.03, 0.09)
	var bottom := Color(0.12, 0.05, 0.16) if not _true_ending else Color(0.18, 0.12, 0.04)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, H), Vector2(0, H)]), PackedColorArray([top, top, bottom, bottom]))
	for s in _stars:
		var sv: Vector3 = s
		var tw := 0.5 + 0.5 * sin(local * 2.0 + sv.x)
		draw_circle(Vector2(sv.x, sv.y), sv.z, Color(1, 1, 1, 0.3 + 0.5 * tw))
	var rise := smoothstep(0.0, 6.0, local)
	var sun := Vector2(W * 0.5, lerpf(H + 160.0, H - 60.0, rise))
	draw_circle(sun, 320.0, Color(1.0, 0.7, 0.3, 0.08))
	draw_circle(sun, 200.0, Color(1.0, 0.75, 0.35, 0.14))
	draw_circle(sun, 110.0, Color(1.0, 0.85, 0.5, 0.6))
	var a := smoothstep(0.6, 2.2, local)
	var head: Font = get_theme_font("font", "Button")
	var logo_y := 250.0 - 60.0 * smoothstep(5.0, 8.0, local)
	draw_string_outline(head, Vector2(0, logo_y), "H.A.R", HORIZONTAL_ALIGNMENT_CENTER, W, 150, 14, Color(0.035, 0.027, 0.07, a))
	draw_string(head, Vector2(0, logo_y), "H.A.R", HORIZONTAL_ALIGNMENT_CENTER, W, 150, Color(1.0, 0.725, 0.22, a))
	var sub := "TRUE ENDING" if _true_ending else tr("TAMAT")
	draw_string(head, Vector2(0, logo_y + 64.0), sub, HORIZONTAL_ALIGNMENT_CENTER, W, 34, Color(0.275, 0.851, 0.91, a))
	if local > 6.0:
		var scroll := (local - 6.0) * 46.0
		var y := H + 40.0 - scroll
		var font := get_theme_default_font()
		for line in CREDITS:
			var line_s: String = line
			var text: String = tr(line_s)
			var big: bool = line_s.begins_with("H.A.R") or line_s == "TEAM DAPHNE"
			var role: bool = line_s.begins_with("Game ")
			var fy := y
			if fy > 300.0 and fy < H + 40.0:
				var fade := clampf((fy - 300.0) / 80.0, 0.0, 1.0)
				var col := Color(1.0, 0.85, 0.5, fade) if big else (Color(0.6, 0.8, 0.9, fade) if role else Color(1, 1, 1, fade))
				draw_string(font, Vector2(0, fy), text, HORIZONTAL_ALIGNMENT_CENTER, W, 30 if big else (20 if role else 26), col)
			y += 40.0
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 1.0 - clampf(local / 0.8, 0.0, 1.0)))
