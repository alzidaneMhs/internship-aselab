extends Control

const KIT := preload("res://scripts/ui/ui_kit.gd")
const ISME_FRAMES := preload("res://scenes/player/isme_frames.tres")
const ISME_TEX := preload("res://assets/sprites/player/isme.png")
const BG_SURFACE := preload("res://assets/sprites/backgrounds/hd/bg_permukaan.png")
const BG_PRISON := preload("res://assets/sprites/backgrounds/hd/bg_underground_prison.png")
const LUSHTE_TEX := preload("res://assets/sprites/enemies/winged/musuh_bersayap.png")
const KRUMS_TEX := preload("res://assets/sprites/enemies/shielded/musuh_bertameng.png")
const CHASER_TEX := preload("res://assets/sprites/enemies/regular/chaser_bot.png")
const RANGED_TEX := preload("res://assets/sprites/enemies/regular/ranged_bot.png")
const PLANET_SHADER := preload("res://shaders/planet.gdshader")
const STAR_SHADER := preload("res://shaders/starfield.gdshader")

const W := 1280.0
const H := 720.0
const BAR := 86.0
const GROUND := 600.0

const T_A1 := 0.0
const T_B := 9.0
const T_A2 := 17.0
const T_C := 26.0
const T_D := 33.0
const T_E := 40.0
const T_F := 47.5
const T_G := 60.0
const T_LOGO := 68.5
const T_END := 75.5

var _t := 0.0
var _prev_t := -0.01
var _speed := 1.0
var _done := false
var _base := Transform2D.IDENTITY
var _rng := RandomNumberGenerator.new()
var _events: Array = []
var _captions: Array = []
var _caption_idx := -1
var _shake := 0.0

var _space: Control
var _stars_rect: ColorRect
var _planet_rect: ColorRect
var _rings_back: Control
var _rings_front: Control
var _fleet: Control
var _overlay: Control
var _caption: Label
var _hint: Label
var _star_mat: ShaderMaterial
var _planet_mat: ShaderMaterial

var _planet_center := Vector2(790, 330)
var _planet_r := 200.0
var _ring_alpha := 1.0
var _ring_red := 0.0

var _ships: Array = []
var _junk: Array = []
var _dust: Array = []
var _crowd: Array = []
var _belt: Array = []
var _fallers: Array = []
var _sleepers: Array = []
var _soft: Texture2D
var _embers: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rng.seed = 9091
	_soft = _make_soft()
	_build_space()
	_build_overlay()
	_build_data()
	_build_events()
	_build_captions()


func _make_soft() -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 128
	tex.height = 128
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex


func _soft_blob(pos: Vector2, radius: float, col: Color) -> void:
	draw_texture_rect(_soft, Rect2(pos - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, col)


func _pile_y(x: float, peak_x: float, peak_y: float) -> float:
	var k := (x - peak_x) / 430.0
	return 720.0 - (720.0 - peak_y) * exp(-k * k)


func _build_space() -> void:
	_space = Control.new()
	_space.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_space)
	_stars_rect = ColorRect.new()
	_stars_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stars_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_star_mat = ShaderMaterial.new()
	_star_mat.shader = STAR_SHADER
	_stars_rect.material = _star_mat
	_space.add_child(_stars_rect)
	_rings_back = _layer(_space)
	_rings_back.draw.connect(_draw_rings.bind(_rings_back, false))
	_planet_rect = ColorRect.new()
	_planet_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_planet_mat = ShaderMaterial.new()
	_planet_mat.shader = PLANET_SHADER
	_planet_rect.material = _planet_mat
	_space.add_child(_planet_rect)
	_rings_front = _layer(_space)
	_rings_front.draw.connect(_draw_rings.bind(_rings_front, true))
	_fleet = _layer(_space)
	_fleet.draw.connect(_draw_fleet)


func _layer(parent: Node) -> Control:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	return c


func _build_overlay() -> void:
	_overlay = _layer(self)
	_overlay.draw.connect(_draw_overlay)
	_caption = Label.new()
	_caption.position = Vector2(140, H - BAR + 6.0)
	_caption.size = Vector2(1000, BAR - 12.0)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_font_size_override("font_size", 22)
	_caption.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88))
	_caption.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_caption.add_theme_constant_override("outline_size", 6)
	_caption.modulate.a = 0.0
	add_child(_caption)
	_hint = Label.new()
	_hint.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_hint.text = Settings.fill(tr("[Tahan {interact}] percepat     [{ui_cancel}] lewati"))
	_hint.position = Vector2(820, 14)
	_hint.size = Vector2(440, 26)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_size_override("font_size", 14)
	_hint.add_theme_color_override("font_color", Color(KIT.TEXT_DIM, 0.75))
	add_child(_hint)


func _build_data() -> void:
	var ship_slots := [
		Vector2(560, 230), Vector2(470, 400), Vector2(640, 470), Vector2(380, 290),
		Vector2(700, 150), Vector2(330, 470), Vector2(560, 320),
	]
	for i in ship_slots.size():
		_ships.append({
			"pos": ship_slots[i],
			"arrive": T_A2 + 0.9 + i * 0.22,
			"scale": 0.55 + 0.12 * (i % 3) + (0.5 if i == 6 else 0.0),
			"bob": _rng.randf() * TAU,
			"beam": i % 2 == 0 or i == 6,
		})
	for i in 64:
		var kind := _rng.randi_range(0, 4)
		_junk.append({
			"x": _rng.randf_range(-80.0, W + 80.0),
			"depth": pow(_rng.randf(), 1.4),
			"kind": kind,
			"size": _rng.randf_range(34.0, 105.0),
			"rot": _rng.randf_range(-1.2, 1.2),
			"shade": _rng.randf_range(0.14, 0.32),
		})
	_junk.sort_custom(func(a, b): return float(a["depth"]) < float(b["depth"]))
	for i in 46:
		_embers.append(Vector3(_rng.randf_range(0.0, W), _rng.randf(), _rng.randf_range(0.6, 2.2)))
	for i in 90:
		_dust.append(Vector3(_rng.randf(), _rng.randf(), _rng.randf_range(0.6, 2.4)))
	for i in 9:
		_crowd.append({
			"x": _rng.randf_range(80.0, 1200.0),
			"h": _rng.randf_range(70.0, 105.0),
			"tex": _rng.randi() % 2,
			"ph": _rng.randf() * TAU,
			"flip": _rng.randf() < 0.5,
		})
	for i in 7:
		_belt.append({"off": i * 190.0, "tex": i % 2, "h": _rng.randf_range(80.0, 100.0)})
	for i in 10:
		_fallers.append({"x": _rng.randf_range(200.0, 1080.0), "speed": _rng.randf_range(0.7, 1.3), "rot": _rng.randf_range(-3.0, 3.0), "size": _rng.randf_range(24.0, 70.0), "ph": _rng.randf()})
	for i in 6:
		_sleepers.append({"x": [190.0, 330.0, 900.0, 1040.0, 1150.0, 470.0][i], "y": [575.0, 610.0, 590.0, 620.0, 560.0, 640.0][i], "tex": i % 2, "wake": T_G + 3.6 + i * 0.55, "rot": _rng.randf_range(-0.5, 0.5)})


func _build_events() -> void:
	_music(T_A1 + 0.05, "main_menu", 1.5)
	_sfx(0.4, "end_sweep", -12.0)
	_sfx(T_B - 1.5, "end_whoosh", -2.0)
	_sfx(T_B - 0.3, "end_sunrise", -6.0)
	_music(T_A2 - 0.4, "map_tower", 2.0)
	_sfx(T_A2 + 0.75, "intro_warp", 0.0)
	_sfx(T_A2 + 1.1, "intro_ship_hum", -4.0)
	_sfx(T_A2 + 4.3, "alarm", -7.0)
	_sfx(T_A2 + 4.5, "laser_fire", -3.0)
	_sfx(T_A2 + 5.4, "rumble", -3.0)
	_sfx(T_A2 + 6.8, "rumble", -3.0)
	_sfx(T_C + 0.1, "intro_ship_hum", -5.0)
	_sfx(T_C + 0.6, "alarm", -10.0)
	_sfx(T_C + 2.6, "end_chain_break", -5.0)
	_sfx(T_C + 3.3, "end_chain_break", -6.0)
	_sfx(T_C + 4.6, "explosion", -9.0)
	var stomp := T_D + 0.4
	while stomp < T_E:
		_sfx(stomp, "scott_step", -12.0)
		stomp += 1.2
	_sfx(T_D + 2.0, "glitch", -10.0)
	_sfx(T_D + 4.2, "glitch", -10.0)
	_sfx(T_E + 1.5, "intro_stamp", 0.0)
	_sfx(T_E + 3.0, "platform_break", -4.0)
	_sfx(T_E + 3.2, "end_whoosh", -5.0)
	_sfx(T_F - 0.9, "debris_crash", 0.0)
	_music(T_F - 0.6, "map_underground", 2.5)
	_sfx(T_F - 0.7, "rumble", -6.0)
	_sfx(T_F + 3.6, "intro_eye_on", -6.0)
	_sfx(T_F + 4.4, "intro_eye_on", -1.0)
	_sfx(T_F + 7.6, "stage_card", -5.0)
	_sfx(T_G + 0.6, "platform_crumble", -6.0)
	for i in _sleepers.size():
		_sfx(float(_sleepers[i]["wake"]), "heal_tick", -8.0)
	_sfx(T_LOGO - 0.25, "end_whoosh", -3.0)
	_sfx(T_LOGO, "end_logo", 0.0)
	_sfx(T_LOGO + 0.02, "krums_stomp", -10.0)


func _sfx(at: float, sfx_name: String, db: float) -> void:
	_events.append({"t": at, "sfx": sfx_name, "db": db})


func _music(at: float, track: String, fade: float) -> void:
	_events.append({"t": at, "music": track, "fade": fade})


func _build_captions() -> void:
	var pages: Array = Story.INTRO_PAGES
	_add_caption(1.0, T_B + 4.0 - 1.0, pages[0])
	_add_caption(T_A2 + 0.6, (T_C + 6.4) - (T_A2 + 0.6), pages[1])
	_add_caption(T_D + 0.5, (T_E + 6.6) - (T_D + 0.5), pages[2])
	_add_caption(T_F + 1.0, 5.4, pages[3])
	_add_caption(T_F + 7.0, 5.0, pages[4])
	_add_caption(T_G + 0.8, T_LOGO - T_G - 1.4, pages[5])


func _add_caption(at: float, dur: float, text: String) -> void:
	_captions.append({"at": at, "dur": dur, "text": text})


func _process(delta: float) -> void:
	if _done:
		return
	var hold: bool = Input.is_action_pressed("ui_accept") or Input.is_action_pressed("interact") or Input.is_action_pressed("jump")
	_speed = 3.0 if hold else 1.0
	_t += delta * _speed
	_fire_events(_prev_t, _t)
	_prev_t = _t
	_shake = maxf(_shake - delta * 18.0, 0.0)
	if _t >= T_END:
		_finish()
		return
	_update_space()
	_update_caption()
	queue_redraw()
	_overlay.queue_redraw()


func _input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	GameManager.goto_stage(GameState.DEFAULT_STAGE_PATH, false)


func _fire_events(from_t: float, to_t: float) -> void:
	for e in _events:
		var ev: Dictionary = e
		var at: float = ev["t"]
		if at > from_t and at <= to_t:
			if ev.has("music"):
				AudioManager.play_music(String(ev["music"]), float(ev["fade"]))
			else:
				AudioManager.play_sfx(String(ev["sfx"]), float(ev["db"]), 0.03)


func _update_caption() -> void:
	var active := -1
	for i in _captions.size():
		var c: Dictionary = _captions[i]
		if _t >= float(c["at"]) and _t < float(c["at"]) + float(c["dur"]):
			active = i
	if active != _caption_idx:
		_caption_idx = active
		if active >= 0:
			_caption.text = String(_captions[active]["text"])
			_caption.visible_characters = 0
	if _caption_idx >= 0:
		var c2: Dictionary = _captions[_caption_idx]
		var local := _t - float(c2["at"])
		var dur: float = c2["dur"]
		_caption.visible_characters = int(local * 40.0)
		_caption.modulate.a = clampf(local / 0.4, 0.0, 1.0) * clampf((dur - local) / 0.6, 0.0, 1.0)
	elif _t >= T_LOGO:
		_caption.modulate.a = 0.0
	else:
		_caption.modulate.a = move_toward(_caption.modulate.a, 0.0, 0.05)


func _ease(a: float, b: float, t: float) -> float:
	return smoothstep(a, b, t)


func _update_space() -> void:
	var in_a1 := _t < T_B
	var in_a2 := _t >= T_A2 and _t < T_C
	_space.visible = in_a1 or in_a2
	if not _space.visible:
		return
	var shake := Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * _shake
	if in_a1:
		var local := _t - T_A1
		var push := _ease(0.0, 7.4, local)
		var dive := clampf((local - 7.2) / 1.8, 0.0, 1.0)
		var r := lerpf(175.0, 245.0, push)
		r *= pow(14.0, dive * dive)
		_planet_center = Vector2(lerpf(800.0, 760.0, push), lerpf(335.0, 330.0, push)).lerp(Vector2(W * 0.5, H * 0.62), dive)
		_planet_r = r
		_ring_alpha = 1.0 - dive
		_ring_red = 0.0
		_star_mat.set_shader_parameter("offset", Vector2(local * 0.6, 0.0))
		_star_mat.set_shader_parameter("warp", dive * 2.0)
		_star_mat.set_shader_parameter("danger", 0.0)
		_planet_mat.set_shader_parameter("corruption", 0.0)
		_planet_mat.set_shader_parameter("rotation", local * 0.08)
		_planet_mat.set_shader_parameter("cloud_shift", local * 0.05)
	else:
		var local2 := _t - T_A2
		var corrupt := _ease(4.6, 8.4, local2)
		_planet_center = Vector2(820, 350) + Vector2(-12.0 * _ease(0.0, 9.0, local2), 0.0)
		_planet_r = 235.0 + 10.0 * _ease(0.0, 9.0, local2)
		_ring_alpha = 1.0 - _ease(5.0, 7.5, local2) * 0.8
		_ring_red = corrupt
		var warp := clampf(1.0 - absf(local2 - 0.85) / 0.5, 0.0, 1.0)
		if local2 > 0.75 and local2 < 0.8:
			_shake = 10.0
		if local2 > 4.5 and local2 < 4.55:
			_shake = 7.0
		_star_mat.set_shader_parameter("offset", Vector2(5.0 + local2 * 0.4, 0.0))
		_star_mat.set_shader_parameter("warp", warp * 1.6)
		_star_mat.set_shader_parameter("danger", corrupt)
		_planet_mat.set_shader_parameter("corruption", corrupt)
		_planet_mat.set_shader_parameter("rotation", 0.9 + local2 * 0.08)
		_planet_mat.set_shader_parameter("cloud_shift", 0.5 + local2 * 0.05)
	_space.position = shake
	var halo := _planet_r * 1.5
	_planet_rect.position = _planet_center - Vector2(halo, halo)
	_planet_rect.size = Vector2(halo, halo) * 2.0
	_planet_mat.set_shader_parameter("planet_scale", _planet_r / halo)
	_rings_back.queue_redraw()
	_rings_front.queue_redraw()
	_fleet.queue_redraw()


func _draw_rings(target: Control, front: bool) -> void:
	if _ring_alpha <= 0.01:
		return
	var c := _planet_center
	var r := _planet_r
	for k in 3:
		var rx := r * (1.55 + k * 0.22)
		var ry := r * (0.26 + k * 0.05)
		var tilt := -0.32 + k * 0.08
		var segs := 90
		var phase := _t * (0.35 + k * 0.12)
		var prev := Vector2.ZERO
		var prev_ok := false
		for s in segs + 1:
			var a := TAU * float(s) / segs
			var is_front := sin(a) > 0.0
			var local := Vector2(cos(a) * rx, sin(a) * ry).rotated(tilt)
			var p := c + local
			var ok := is_front == front
			if _ring_red > 0.0 and fmod(a * 3.0 + _t * 2.0 + k, 2.0) < _ring_red * 1.3:
				ok = false
			if ok and prev_ok:
				var pulse := pow(maxf(0.0, sin(a * 2.0 - phase * 3.0)), 18.0)
				var col := Color(0.35, 0.95, 1.0).lerp(Color(1.0, 0.25, 0.2), _ring_red)
				target.draw_line(prev, p, Color(col, 0.16 * _ring_alpha), 7.0)
				target.draw_line(prev, p, Color(col.lightened(0.3), (0.55 + pulse) * _ring_alpha), 1.8)
				if pulse > 0.5:
					target.draw_circle(p, 3.0, Color(1, 1, 1, pulse * _ring_alpha))
			prev = p
			prev_ok = ok


func _draw_fleet() -> void:
	if _t < T_A2 or _t >= T_C:
		return
	var local := _t - T_A2
	for s in _ships:
		var sd: Dictionary = s
		var arrive: float = float(sd["arrive"]) - T_A2
		var target: Vector2 = sd["pos"]
		var sc: float = sd["scale"]
		if local < arrive - 0.35:
			continue
		var k := clampf((local - (arrive - 0.35)) / 0.9, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - k, 4.0)
		var pos := Vector2(lerpf(-500.0, target.x, e), target.y) + Vector2(0.0, sin(local * 1.3 + float(sd["bob"])) * 4.0)
		if k < 1.0:
			_fleet.draw_line(pos - Vector2(600.0 * (1.0 - e) + 80.0, 0.0), pos, Color(0.9, 0.95, 1.0, 0.7 * (1.0 - e)), 3.0 * sc)
		if bool(sd["beam"]) and local > 4.4:
			var beam_k := _ease(4.4, 5.0, local)
			var hit := _planet_center + (pos - _planet_center).normalized() * _planet_r * 0.92
			var wob := 0.6 + 0.4 * sin(local * 30.0 + sc * 9.0)
			_fleet.draw_line(pos + Vector2(60.0 * sc, 4.0), hit, Color(1.0, 0.15, 0.1, 0.25 * beam_k), 16.0 * sc * wob)
			_fleet.draw_line(pos + Vector2(60.0 * sc, 4.0), hit, Color(1.0, 0.8, 0.7, 0.9 * beam_k), 3.0 * sc)
			_fleet.draw_circle(hit, 12.0 * sc * wob, Color(1.0, 0.5, 0.3, 0.7 * beam_k))
		_draw_ship(_fleet, pos, sc, local)


func _draw_ship(target: CanvasItem, pos: Vector2, sc: float, local: float) -> void:
	var hull := PackedVector2Array([
		Vector2(-110, -14), Vector2(-72, -30), Vector2(40, -34), Vector2(118, -12), Vector2(152, 0),
		Vector2(118, 10), Vector2(40, 24), Vector2(-72, 26), Vector2(-110, 12),
	])
	var belly := PackedVector2Array([Vector2(-72, 6), Vector2(40, 6), Vector2(118, 10), Vector2(40, 24), Vector2(-72, 26), Vector2(-110, 12)])
	var tower := PackedVector2Array([Vector2(-46, -30), Vector2(-28, -54), Vector2(22, -54), Vector2(38, -32)])
	var fin := PackedVector2Array([Vector2(-96, -18), Vector2(-120, -44), Vector2(-80, -28)])
	var xf := Transform2D(0.0, Vector2(sc, sc), 0.0, pos)
	target.draw_set_transform_matrix(xf)
	for ey in [-12.0, 12.0]:
		var e: float = ey
		target.draw_circle(Vector2(-128, e), 26.0, Color(0.45, 0.7, 1.0, 0.22))
		target.draw_circle(Vector2(-126, e), 10.0, Color(0.85, 0.95, 1.0, 1.0))
		target.draw_rect(Rect2(-124, e - 7.0, 30, 14), Color(0.2, 0.2, 0.25))
	target.draw_colored_polygon(fin, Color(0.14, 0.14, 0.18))
	target.draw_colored_polygon(tower, Color(0.17, 0.17, 0.21))
	target.draw_colored_polygon(hull, Color(0.22, 0.22, 0.27))
	target.draw_colored_polygon(belly, Color(0.12, 0.12, 0.15))
	target.draw_polyline(PackedVector2Array([Vector2(-110, -14), Vector2(-72, -30), Vector2(40, -34), Vector2(118, -12), Vector2(152, 0)]), Color(0.62, 0.64, 0.75), 2.0)
	for k in 4:
		target.draw_line(Vector2(-60 + k * 40, -30), Vector2(-60 + k * 40, 22), Color(0.1, 0.1, 0.13), 1.5)
	target.draw_rect(Rect2(-20, -50, 30, 5), Color(1.0, 0.6, 0.35, 0.8))
	for i in 7:
		var blink := 0.5 + 0.5 * sin(local * 4.0 + i * 1.3)
		target.draw_circle(Vector2(-50 + i * 22, -6), 2.2, Color(1.0, 0.2, 0.15, 0.55 + 0.45 * blink))
	target.draw_circle(Vector2(150, 0), 3.0, Color(1.0, 0.3, 0.2, 0.6 + 0.4 * sin(local * 9.0)))
	target.draw_set_transform_matrix(Transform2D.IDENTITY)


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


func _cam(zoom: float, focus: Vector2, rot: float = 0.0) -> Transform2D:
	var shake := Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * _shake
	return Transform2D(rot, Vector2(zoom, zoom), 0.0, Vector2(W, H) * 0.5 + shake) * Transform2D(0.0, -focus)


func _fade(local: float, length: float, fin: float = 0.6, fout: float = 0.6) -> float:
	return clampf(local / fin, 0.0, 1.0) * clampf((length - local) / fout, 0.0, 1.0)


func _vgrad(rect: Rect2, top: Color, bottom: Color) -> void:
	draw_polygon(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]), PackedColorArray([top, top, bottom, bottom]))


func _rays(origin: Vector2, angle: float, spread: float, length: float, col: Color, count: int, t: float) -> void:
	for i in count:
		var f := float(i) / maxf(count - 1, 1)
		var a := angle - spread * 0.5 + spread * f + sin(t * 0.4 + i * 1.7) * 0.02
		var w := 0.018 + 0.02 * (0.5 + 0.5 * sin(i * 2.3))
		var p1 := origin + Vector2(cos(a - w), sin(a - w)) * length
		var p2 := origin + Vector2(cos(a + w), sin(a + w)) * length
		var flick := 0.6 + 0.4 * sin(t * 0.9 + i * 2.1)
		draw_polygon(PackedVector2Array([origin, p1, p2]), PackedColorArray([Color(col, col.a * flick), Color(col, 0.0), Color(col, 0.0)]))


func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color.BLACK)
	var t := _t
	if t < T_B:
		return
	if t < T_A2:
		_shot_peace(t - T_B, T_A2 - T_B)
	elif t < T_C:
		return
	elif t < T_D:
		_shot_invasion(t - T_C, T_D - T_C)
	elif t < T_E:
		_shot_factory(t - T_D, T_E - T_D)
	elif t < T_F:
		_shot_discard(t - T_E, T_F - T_E)
	elif t < T_G:
		_shot_wake(t - T_F, T_G - T_F)
	elif t < T_LOGO:
		_shot_resolve(t - T_G, T_LOGO - T_G)
	_set_base(Transform2D.IDENTITY)


func _shot_peace(local: float, length: float) -> void:
	var zoom := lerpf(1.12, 1.0, _ease(0.0, length, local))
	_set_base(_cam(zoom, Vector2(lerpf(580.0, 700.0, local / length), 350.0)))
	draw_texture_rect(BG_SURFACE, Rect2(-40, -30, W + 80, H + 60), false)
	draw_rect(Rect2(-40, -30, W + 80, H + 60), Color(1.0, 0.82, 0.45, 0.08))
	_rays(Vector2(180, -120), 1.05, 0.9, 1300.0, Color(1.0, 0.9, 0.6, 0.16), 9, local)
	for r in _crowd:
		var rd: Dictionary = r
		var hop := absf(sin(local * 3.4 + float(rd["ph"]))) * 16.0
		var tex: Texture2D = CHASER_TEX if int(rd["tex"]) == 0 else RANGED_TEX
		var x: float = float(rd["x"]) + sin(local * 0.6 + float(rd["ph"])) * 30.0
		_soft_blob(Vector2(x, 548.0), 40.0, Color(0, 0, 0, 0.25))
		_sprite(tex, Vector2(x, 552.0 - hop), float(rd["h"]), bool(rd["flip"]), Color(0.95, 0.92, 0.88))
	var lp := Vector2(lerpf(-100.0, 1380.0, local / length), 330.0 + sin(local * 1.6) * 35.0)
	_sprite(LUSHTE_TEX, lp, 200.0, false, Color(1, 1, 1), sin(local * 1.6) * 0.08)
	_soft_blob(Vector2(lerpf(1040.0, 900.0, local / length), 548.0), 80.0, Color(0, 0, 0, 0.3))
	_sprite(KRUMS_TEX, Vector2(lerpf(1040.0, 900.0, local / length), 552.0 - absf(sin(local * 4.0)) * 4.0), 240.0, true)
	for d in _dust:
		var dv: Vector3 = d
		var u := fposmod(dv.y - local * 0.04 * dv.z, 1.0)
		var p := Vector2(dv.x * (W + 80.0) - 40.0 + sin(local + dv.x * 9.0) * 14.0, u * H)
		draw_circle(p, dv.z * 1.3, Color(1.0, 0.92, 0.6, 0.55 * sin(u * PI)))
	_set_base(Transform2D.IDENTITY)
	var flash := clampf(1.0 - local / 0.9, 0.0, 1.0)
	draw_rect(Rect2(0, 0, W, H), Color(1, 1, 1, flash))
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, clampf((local - (length - 0.8)) / 0.8, 0.0, 1.0)))


func _shot_invasion(local: float, length: float) -> void:
	_set_base(_cam(lerpf(1.08, 1.0, local / length), Vector2(640, 360)))
	draw_texture_rect(BG_SURFACE, Rect2(-40, -30, W + 80, H + 60), false, Color(0.55, 0.32, 0.36))
	_vgrad(Rect2(-40, -30, W + 80, 420), Color(0.35, 0.02, 0.04, 0.85), Color(0.5, 0.06, 0.05, 0.15))
	for i in 5:
		var fx := 120.0 + i * 260.0
		var fh := 90.0 + 30.0 * sin(local * 3.0 + i)
		_soft_blob(Vector2(fx, GROUND - 20.0), fh, Color(1.0, 0.45, 0.12, 0.35))
		for j in 9:
			var u := fposmod(local * 0.18 + j / 9.0 + i * 0.13, 1.0)
			var sp := Vector2(fx + sin(u * 4.0 + i) * 40.0 + u * 70.0, GROUND - 30.0 - u * 420.0)
			_soft_blob(sp, 40.0 + u * 110.0, Color(0.06, 0.04, 0.05, 0.42 * sin(u * PI)))
	var mx := lerpf(520.0, 720.0, local / length)
	var beam_on := _ease(1.6, 2.4, local)
	if beam_on > 0.0:
		var top := Vector2(mx, 250.0)
		var wob := 1.0 + 0.04 * sin(local * 20.0)
		draw_polygon(PackedVector2Array([top + Vector2(-50, 0), top + Vector2(50, 0), Vector2(mx + 210.0 * wob, GROUND + 40.0), Vector2(mx - 210.0 * wob, GROUND + 40.0)]),
			PackedColorArray([Color(1.0, 0.3, 0.2, 0.4 * beam_on), Color(1.0, 0.3, 0.2, 0.4 * beam_on), Color(1.0, 0.25, 0.15, 0.08 * beam_on), Color(1.0, 0.25, 0.15, 0.08 * beam_on)]))
		for i in 4:
			var ly := fposmod(local * 160.0 + i * 120.0, 460.0)
			draw_line(Vector2(mx - 120.0, GROUND - ly), Vector2(mx + 120.0, GROUND - ly), Color(1.0, 0.6, 0.5, 0.18 * beam_on), 2.0)
	for i in 6:
		var rise := clampf((local - 1.8 - i * 0.45) / 3.0, 0.0, 1.0)
		if rise <= 0.0:
			continue
		var rx := mx + (i - 2.5) * 55.0 + sin(local * 2.0 + i) * 20.0
		var ry := lerpf(GROUND - 20.0, 300.0, rise * rise)
		var tex: Texture2D = CHASER_TEX if i % 2 == 0 else RANGED_TEX
		_sprite(tex, Vector2(rx, ry), 80.0, i % 2 == 0, Color(1.0, 0.55, 0.5, 1.0 - rise * 0.6), sin(local * 3.0 + i) * 0.6 * rise)
	var lk := _ease(2.4, 6.0, local)
	var lpos := Vector2(mx + 40.0, lerpf(GROUND - 60.0, 330.0, lk))
	_sprite(LUSHTE_TEX, lpos, 230.0, true, Color(1.0, 0.5, 0.45), sin(local * 4.0) * 0.12)
	if local > 2.6:
		for i in 10:
			var a := TAU * i / 10.0 + local * 1.5
			var cp := lpos + Vector2(cos(a) * 70.0, -115.0 + sin(a) * 30.0)
			draw_arc(cp, 8.0, 0.0, TAU, 10, Color(0.85, 0.2, 0.18, 0.9), 3.0)
	var kx := 1050.0
	_sprite(KRUMS_TEX, Vector2(kx, GROUND - 40.0), 250.0, true, Color(0.9, 0.45, 0.42))
	if local > 3.2:
		var ck := _ease(3.2, 4.0, local)
		draw_line(Vector2(kx - 70.0, 0.0), Vector2(kx - 20.0, GROUND - 160.0) * ck + Vector2(kx - 70.0, 0.0) * (1.0 - ck), Color(0.85, 0.2, 0.18, 0.9), 5.0)
		draw_line(Vector2(kx + 90.0, 0.0), Vector2(kx + 30.0, GROUND - 150.0) * ck + Vector2(kx + 90.0, 0.0) * (1.0 - ck), Color(0.85, 0.2, 0.18, 0.9), 5.0)
	for i in 2:
		var sa := 1.57 + sin(local * 0.9 + i * 2.5) * 0.55
		var so := Vector2(300.0 + i * 700.0, 120.0)
		var tip_l := so + Vector2(cos(sa - 0.12), sin(sa - 0.12)) * 700.0
		var tip_r := so + Vector2(cos(sa + 0.12), sin(sa + 0.12)) * 700.0
		draw_polygon(PackedVector2Array([so, tip_l, tip_r]), PackedColorArray([Color(1.0, 0.95, 0.85, 0.32), Color(1.0, 0.95, 0.85, 0.0), Color(1.0, 0.95, 0.85, 0.0)]))
	_draw_mothership(Vector2(mx, 165.0), local)
	_set_base(Transform2D.IDENTITY)
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 1.0 - _fade(local, length, 0.5, 0.6)))


func _draw_mothership(c: Vector2, local: float) -> void:
	_soft_blob(c + Vector2(0, 40), 700.0, Color(0.0, 0.0, 0.0, 0.35))
	var body := PackedVector2Array([
		c + Vector2(-820, -120), c + Vector2(820, -120), c + Vector2(700, 10), c + Vector2(420, 60), c + Vector2(180, 90),
		c + Vector2(-180, 90), c + Vector2(-420, 60), c + Vector2(-700, 10),
	])
	draw_colored_polygon(body, Color(0.08, 0.07, 0.09))
	var keel := PackedVector2Array([c + Vector2(-260, 70), c + Vector2(260, 70), c + Vector2(140, 112), c + Vector2(-140, 112)])
	draw_colored_polygon(keel, Color(0.11, 0.1, 0.12))
	draw_polyline(PackedVector2Array([c + Vector2(-700, 10), c + Vector2(-420, 60), c + Vector2(-180, 90), c + Vector2(180, 90), c + Vector2(420, 60), c + Vector2(700, 10)]), Color(0.5, 0.22, 0.24), 3.0)
	for k in 9:
		var px := -640.0 + k * 160.0
		draw_line(c + Vector2(px, -110), c + Vector2(px + 30.0, 40.0 + (1.0 - absf(px) / 700.0) * 40.0), Color(0.05, 0.05, 0.06), 3.0)
	for i in 30:
		var lx := -660.0 + i * 46.0
		var ly := 14.0 + (1.0 - absf(lx) / 700.0) * 66.0
		var blink := 0.5 + 0.5 * sin(local * 5.0 + i * 0.7)
		draw_circle(c + Vector2(lx, ly), 3.2, Color(1.0, 0.25, 0.2, 0.5 + 0.5 * blink))
	for side in [-1.0, 1.0]:
		var sd: float = side
		_soft_blob(c + Vector2(sd * 520.0, 40.0), 60.0, Color(0.5, 0.75, 1.0, 0.5))
		draw_circle(c + Vector2(sd * 520.0, 40.0), 10.0, Color(0.9, 0.97, 1.0))
	_soft_blob(c + Vector2(0, 112), 90.0, Color(1.0, 0.35, 0.25, 0.55))
	draw_circle(c + Vector2(0, 112), 26.0, Color(1.0, 0.85, 0.75, 0.95))


func _shot_factory(local: float, length: float) -> void:
	_set_base(_cam(lerpf(1.0, 1.1, local / length), Vector2(lerpf(560.0, 700.0, local / length), 360.0)))
	_vgrad(Rect2(-60, -40, W + 120, H + 80), Color(0.05, 0.03, 0.05), Color(0.12, 0.05, 0.06))
	for i in 8:
		var px := -40.0 + i * 190.0
		draw_rect(Rect2(px, -40, 46, H + 80), Color(0.09, 0.07, 0.1))
		draw_rect(Rect2(px + 4, -40, 6, H + 80), Color(0.16, 0.12, 0.16))
	for i in 3:
		var sx := 140.0 + i * 420.0
		var scr := Rect2(sx, 120, 260, 150)
		var flick := 0.75 + 0.25 * sin(local * 23.0 + i * 3.0)
		draw_rect(scr.grow(6.0), Color(0.15, 0.1, 0.12))
		draw_rect(scr, Color(0.25, 0.02, 0.03, flick))
		var ec := scr.get_center()
		draw_circle(ec, 52.0, Color(0.9, 0.12, 0.1, 0.9 * flick))
		draw_circle(ec, 22.0, Color(0.1, 0.0, 0.0))
		draw_circle(ec + Vector2(6, -6), 6.0, Color(1.0, 0.7, 0.6, flick))
		for l in 10:
			draw_line(Vector2(scr.position.x, scr.position.y + l * 15.0), Vector2(scr.end.x, scr.position.y + l * 15.0), Color(0, 0, 0, 0.25), 1.0)
	for i in 4:
		var bx := 80.0 + i * 360.0
		var rot := local * 4.0 + i
		draw_circle(Vector2(bx, 60), 14.0, Color(0.6, 0.05, 0.05))
		var beam_a := Vector2(cos(rot), sin(rot) * 0.4)
		draw_polygon(PackedVector2Array([Vector2(bx, 60), Vector2(bx, 60) + beam_a.rotated(0.25) * 520.0, Vector2(bx, 60) + beam_a.rotated(-0.25) * 520.0]),
			PackedColorArray([Color(1.0, 0.15, 0.1, 0.35), Color(1.0, 0.15, 0.1, 0.0), Color(1.0, 0.15, 0.1, 0.0)]))
	_sprite(KRUMS_TEX, Vector2(1180.0, 470.0), 230.0, true, Color(0.55, 0.25, 0.25))
	draw_circle(Vector2(1160.0, 300.0), 26.0, Color(1.0, 0.1, 0.05, 0.25 + 0.15 * sin(local * 6.0)))
	_sprite(LUSHTE_TEX, Vector2(110.0, 450.0 + sin(local * 1.5) * 8.0), 220.0, false, Color(0.55, 0.25, 0.28))
	draw_circle(Vector2(118.0, 290.0), 26.0, Color(1.0, 0.1, 0.05, 0.25 + 0.15 * sin(local * 6.0 + 1.0)))
	var belt_y := 520.0
	draw_rect(Rect2(-60, belt_y, W + 120, 34), Color(0.13, 0.11, 0.13))
	var seg := fposmod(local * 120.0, 60.0)
	var x := -60.0 + seg
	while x < W + 60.0:
		draw_line(Vector2(x, belt_y + 4), Vector2(x, belt_y + 30), Color(0.05, 0.04, 0.05), 3.0)
		x += 60.0
	for i in 12:
		draw_circle(Vector2(-40.0 + i * 120.0, belt_y + 17.0), 13.0, Color(0.2, 0.18, 0.22))
	draw_rect(Rect2(-60, belt_y + 34, W + 120, H), Color(0.06, 0.04, 0.05))
	var station := 640.0
	var arm_y := 330.0 + 70.0 * maxf(0.0, sin(local * TAU / 1.2))
	draw_rect(Rect2(station - 12.0, 0.0, 24.0, arm_y), Color(0.2, 0.17, 0.2))
	draw_colored_polygon(PackedVector2Array([Vector2(station - 40, arm_y), Vector2(station + 40, arm_y), Vector2(station + 18, arm_y + 40), Vector2(station - 18, arm_y + 40)]), Color(0.28, 0.24, 0.28))
	if sin(local * TAU / 1.2) > 0.92:
		draw_circle(Vector2(station, arm_y + 44.0), 30.0, Color(1.0, 0.4, 0.3, 0.5))
		draw_circle(Vector2(station, arm_y + 44.0), 10.0, Color(1.0, 0.95, 0.85, 1.0))
	for b in _belt:
		var bd: Dictionary = b
		var bx2 := fposmod(float(bd["off"]) + local * 120.0, 1330.0) - 50.0
		var tex: Texture2D = CHASER_TEX if int(bd["tex"]) == 0 else RANGED_TEX
		var infected := bx2 > station
		var mod := Color(0.7, 0.62, 0.66) if not infected else Color(0.85, 0.45, 0.45)
		var h: float = bd["h"]
		_sprite(tex, Vector2(bx2, belt_y + 2.0), h, false, mod)
		if infected:
			var glow := 0.6 + 0.4 * sin(local * 8.0 + bx2)
			draw_circle(Vector2(bx2 + 6.0, belt_y - h * 0.62), 14.0, Color(1.0, 0.1, 0.05, 0.35 * glow))
			draw_circle(Vector2(bx2 + 6.0, belt_y - h * 0.62), 5.0, Color(1.0, 0.4, 0.3, glow))
	_set_base(Transform2D.IDENTITY)
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 1.0 - _fade(local, length, 0.5, 0.4)))


func _shot_discard(local: float, length: float) -> void:
	var fall := _ease(3.0, 6.6, local)
	var cam_y := lerpf(380.0, 1700.0, fall * fall)
	var zoom := lerpf(1.3, 1.0, _ease(2.6, 4.0, local))
	if local > 1.5 and local < 1.55:
		_shake = 14.0
	_set_base(_cam(zoom, Vector2(640, cam_y)))
	_vgrad(Rect2(-80, -80, W + 160, 2700), Color(0.1, 0.05, 0.06), Color(0.0, 0.0, 0.0))
	for i in 6:
		var px := 60.0 + i * 230.0
		draw_rect(Rect2(px, -80, 40, 600), Color(0.13, 0.09, 0.11))
	var beacon := local * 5.0
	for bx in [300.0, 980.0]:
		var bxx: float = bx
		var dir := Vector2(cos(beacon + bxx), sin(beacon + bxx) * 0.35)
		draw_polygon(PackedVector2Array([Vector2(bxx, 170), Vector2(bxx, 170) + dir.rotated(0.3) * 600.0, Vector2(bxx, 170) + dir.rotated(-0.3) * 600.0]),
			PackedColorArray([Color(1.0, 0.12, 0.08, 0.4), Color(1.0, 0.12, 0.08, 0.0), Color(1.0, 0.12, 0.08, 0.0)]))
		_soft_blob(Vector2(bxx, 170), 50.0, Color(1.0, 0.15, 0.1, 0.8))
		draw_circle(Vector2(bxx, 170), 12.0, Color(1.0, 0.5, 0.4))
	draw_rect(Rect2(-80, 480, W + 160, 30), Color(0.16, 0.13, 0.15))
	var door_open := _ease(3.0, 3.25, local)
	draw_rect(Rect2(520, 480, 240 * (1.0 - door_open), 30), Color(0.2, 0.13, 0.13))
	draw_rect(Rect2(520, 510, 240, 2200), Color(0.03, 0.02, 0.03))
	for i in 44:
		var wy := 520.0 + i * 50.0
		draw_line(Vector2(520, wy), Vector2(500, wy + 25.0), Color(0.14, 0.1, 0.12), 3.0)
		draw_line(Vector2(760, wy), Vector2(780, wy + 25.0), Color(0.14, 0.1, 0.12), 3.0)
		if i % 4 == 0:
			var on := 0.5 + 0.5 * sin(local * 6.0 + i)
			_soft_blob(Vector2(510, wy), 26.0, Color(1.0, 0.15, 0.1, 0.35 * on))
			_soft_blob(Vector2(770, wy), 26.0, Color(1.0, 0.15, 0.1, 0.35 * on))
	var press_k := 0.0
	if local < 1.5:
		press_k = _ease(0.6, 1.5, local)
	else:
		press_k = 1.0 - _ease(1.9, 2.6, local)
	var press_y := lerpf(150.0, 340.0, press_k * press_k)
	draw_rect(Rect2(626, -400, 28, press_y + 400.0), Color(0.24, 0.21, 0.24))
	draw_rect(Rect2(560, press_y, 160, 70), Color(0.32, 0.12, 0.12))
	draw_rect(Rect2(560, press_y + 58, 160, 12), Color(0.8, 0.12, 0.1))
	var robot_y := 480.0
	var spin := 0.0
	if local > 3.05:
		var ft := local - 3.05
		robot_y = 480.0 + 300.0 * ft * ft + 60.0 * ft
		spin = ft * 2.2
	var jitter := sin(local * 7.0) * 2.0 if local < 3.0 else 0.0
	_sprite(CHASER_TEX, Vector2(640.0 + jitter, robot_y), 120.0, false, Color(0.42, 0.4, 0.44), spin)
	if local < 3.0:
		var smoke := fposmod(local * 0.8, 1.0)
		_soft_blob(Vector2(660.0, 380.0 - smoke * 90.0), 20.0 + smoke * 30.0, Color(0.3, 0.3, 0.32, 0.5 * (1.0 - smoke)))
		draw_line(Vector2(610, 410), Vector2(632, 440), Color(0.1, 0.1, 0.1), 3.0)
		draw_line(Vector2(632, 440), Vector2(620, 462), Color(0.1, 0.1, 0.1), 3.0)
	if local > 1.5 and local < 2.2:
		var sk := 1.0 - (local - 1.5) / 0.7
		for i in 14:
			var a := -PI * float(i) / 13.0
			var d := (1.0 - sk) * 160.0 + 10.0
			var sp := Vector2(640, 412) + Vector2(cos(a), sin(a) * 0.6) * d
			draw_line(sp, sp + Vector2(cos(a), sin(a) * 0.6) * 18.0, Color(1.0, 0.8, 0.4, sk), 2.5)
	for f in _fallers:
		var fd: Dictionary = f
		var start := 3.4 + float(fd["ph"]) * 2.5
		if local < start:
			continue
		var ft2 := local - start
		var fy := 520.0 + 260.0 * ft2 * ft2 * float(fd["speed"])
		var fx: float = fd["x"]
		fx = clampf(fx, 540.0, 740.0)
		draw_set_transform_matrix(_base * Transform2D(float(fd["rot"]) * ft2, Vector2(fx, fy)))
		var sz: float = fd["size"]
		draw_rect(Rect2(-sz * 0.5, -sz * 0.2, sz, sz * 0.4), Color(0.22, 0.19, 0.22))
		draw_set_transform_matrix(_base)
	for i in 30:
		var sy := fposmod(cam_y - 360.0 + i * 37.0 - local * 900.0 * fall, 760.0) + cam_y - 380.0
		if fall > 0.05:
			draw_line(Vector2(530.0 + (i * 53) % 220, sy), Vector2(530.0 + (i * 53) % 220, sy + 40.0 * fall), Color(0.6, 0.55, 0.6, 0.3 * fall), 1.5)
	_set_base(Transform2D.IDENTITY)
	if local > 1.5:
		var sk2 := _ease(1.5, 1.7, local) * (1.0 - _ease(2.8, 3.3, local))
		if sk2 > 0.0:
			var head: Font = get_theme_font("font", "Button")
			var pop := 1.0 + (1.0 - _ease(1.5, 1.7, local)) * 0.6
			draw_set_transform_matrix(Transform2D(-0.12, Vector2(pop, pop), 0.0, Vector2(640, 250)))
			var txt := tr("PRODUK GAGAL")
			var tw := head.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 74).x
			draw_rect(Rect2(-tw * 0.5 - 26.0, -70.0, tw + 52.0, 96.0), Color(0.85, 0.1, 0.08, 0.9 * sk2), false, 8.0)
			draw_string(head, Vector2(-tw * 0.5, 0.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 74, Color(0.95, 0.12, 0.1, sk2))
			draw_set_transform_matrix(Transform2D.IDENTITY)
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, clampf((local - (length - 1.1)) / 0.4, 0.0, 1.0)))
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 1.0 - clampf(local / 0.4, 0.0, 1.0)))


func _draw_junk(j: Dictionary, p: Vector2, shade_mul: float) -> void:
	var s: float = j["size"]
	var sh: float = float(j["shade"]) * shade_mul
	var col := Color(sh, sh * 0.95, sh * 1.1)
	draw_set_transform_matrix(_base * Transform2D(float(j["rot"]), p))
	match int(j["kind"]):
		0:
			draw_circle(Vector2.ZERO, s * 0.45, col)
			for k in 8:
				var a := TAU * k / 8.0
				draw_rect(Rect2(Vector2(cos(a), sin(a)) * s * 0.45 - Vector2(6, 6), Vector2(12, 12)), col)
			draw_circle(Vector2.ZERO, s * 0.15, Color(col.darkened(0.5)))
		1:
			draw_rect(Rect2(-s * 0.7, -s * 0.12, s * 1.4, s * 0.24), col)
			draw_rect(Rect2(-s * 0.7, -s * 0.12, s * 1.4, s * 0.05), col.lightened(0.15))
		2:
			draw_colored_polygon(PackedVector2Array([Vector2(-s * 0.5, 0), Vector2(-s * 0.2, -s * 0.5), Vector2(s * 0.45, -s * 0.3), Vector2(s * 0.5, s * 0.1)]), col)
		_:
			draw_set_transform_matrix(_base)
			var tex: Texture2D = CHASER_TEX if int(j["kind"]) == 3 else RANGED_TEX
			_sprite(tex, p + Vector2(0, s * 0.3), s * 1.05, int(j["kind"]) == 4, Color(sh * 1.6, sh * 1.55, sh * 1.7), float(j["rot"]))
	draw_set_transform_matrix(_base)


func _draw_pile(peak_x: float, peak_y: float, front: bool, shade_mul: float) -> void:
	if not front:
		var pts := PackedVector2Array()
		pts.append(Vector2(-120, H + 80))
		var x := -120.0
		while x <= W + 120.0:
			pts.append(Vector2(x, _pile_y(x, peak_x, peak_y) + 18.0))
			x += 40.0
		pts.append(Vector2(W + 120, H + 80))
		draw_colored_polygon(pts, Color(0.06, 0.055, 0.08))
	for j in _junk:
		var jd: Dictionary = j
		var depth: float = jd["depth"]
		if (depth >= 0.55) != front:
			continue
		var x2: float = jd["x"]
		var y2 := _pile_y(x2, peak_x, peak_y) + 6.0 + depth * 150.0
		_draw_junk(jd, Vector2(x2, y2), shade_mul * (1.0 + depth * 0.4))


func _isme_rect(center_x: float, feet_y: float, height: float) -> Rect2:
	return Rect2(center_x - height * 0.5, feet_y - height, height, height)


func _shot_wake(local: float, length: float) -> void:
	var close := _ease(2.4, 3.4, local) * (1.0 - _ease(6.3, 7.4, local))
	var zoom := lerpf(1.0, 2.6, close)
	var focus := Vector2(640, 430).lerp(Vector2(690, 455), close)
	if local > 0.0 and local < 0.05:
		_shake = 9.0
	_set_base(_cam(zoom, focus))
	draw_texture_rect(BG_PRISON, Rect2(-60, -40, W + 120, H + 80), false, Color(0.22, 0.2, 0.3))
	_vgrad(Rect2(-60, -40, W + 120, H + 80), Color(0.02, 0.02, 0.06, 0.4), Color(0.0, 0.0, 0.02, 0.7))
	_rays(Vector2(520, -80), 1.45, 0.32, 900.0, Color(0.65, 0.75, 1.0, 0.16), 7, local)
	_draw_pile(700.0, 470.0, false, 1.0)
	var wake := _ease(3.6, 3.75, local) * 0.5 + _ease(4.4, 4.7, local) * 0.5
	if local > 3.6 and local < 4.4:
		wake *= 0.5 + 0.5 * signf(sin(local * 40.0))
	var rise := _ease(7.4, 11.0, local)
	var irect := _isme_rect(690.0, 600.0 - 40.0 * rise, 300.0)
	var lit := lerpf(0.18, 0.62, wake)
	draw_texture_rect(ISME_TEX, irect, false, Color(lit, lit * 1.02, lit * 1.12))
	for lens in [Vector2(0.558, 0.346), Vector2(0.759, 0.346)]:
		var lv: Vector2 = lens
		var lp := irect.position + lv * irect.size
		if wake > 0.01:
			draw_circle(lp, irect.size.x * 0.11, Color(0.4, 0.95, 1.0, 0.25 * wake))
			draw_circle(lp, irect.size.x * 0.05, Color(0.75, 1.0, 1.0, 0.9 * wake))
			draw_circle(lp, irect.size.x * 0.022, Color(1, 1, 1, wake))
	_draw_pile(700.0, 470.0, true, 1.0)
	for d in _dust:
		var dv: Vector3 = d
		var u := fposmod(dv.y + local * 0.02 * dv.z, 1.0)
		var p := Vector2(380.0 + dv.x * 360.0 + sin(local * 0.5 + dv.x * 20.0) * 20.0, u * H)
		var in_beam := clampf(1.0 - absf(p.x - (520.0 + (p.y + 80.0) * 0.12)) / 160.0, 0.0, 1.0)
		draw_circle(p, dv.z * 0.9, Color(0.8, 0.85, 1.0, 0.5 * in_beam))
	_set_base(Transform2D.IDENTITY)
	if local > 7.5:
		var k := _ease(7.5, 8.1, local) * (1.0 - _ease(11.4, 12.1, local))
		var head: Font = get_theme_font("font", "Button")
		var jitter := Vector2(_rng.randf_range(-3.0, 3.0), 0.0) if fmod(local, 1.3) < 0.08 else Vector2.ZERO
		var base := Vector2(110, 300) + jitter
		draw_rect(Rect2(base.x - 20.0, base.y - 100.0, 6.0, 150.0 * k), Color(KIT.AMBER, k))
		draw_string_outline(get_theme_font("font", "Button"), base, "ISME", HORIZONTAL_ALIGNMENT_LEFT, -1, 110, 10, Color(0.03, 0.02, 0.05, k))
		draw_string(head, base, "ISME", HORIZONTAL_ALIGNMENT_LEFT, -1, 110, Color(1.0, 0.75, 0.25, k))
		var sub := "UNIT-01   //   " + tr("PRODUK GAGAL")
		draw_string(head, base + Vector2(4, 48), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.6, 0.9, 1.0, k))
		var strike := _ease(9.0, 9.6, local)
		if strike > 0.0:
			var sw := head.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
			var sx0 := base.x + 4.0 + head.get_string_size("UNIT-01   //   ", HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
			draw_line(Vector2(sx0, base.y + 39.0), Vector2(sx0 + (base.x + 4.0 + sw - sx0) * strike, base.y + 39.0), Color(1.0, 0.3, 0.25, k), 4.0)
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 1.0 - _fade(local, length, 1.4, 0.5)))


func _shot_resolve(local: float, length: float) -> void:
	var crane := _ease(0.0, length, local)
	_set_base(_cam(lerpf(1.25, 1.05, crane), Vector2(lerpf(660.0, 700.0, crane), lerpf(470.0, 330.0, crane))))
	draw_texture_rect(BG_PRISON, Rect2(-120, -200, W + 240, H + 260), false, Color(0.25, 0.23, 0.33))
	var crack := Vector2(930, 60)
	draw_circle(crack, 120.0, Color(0.9, 0.95, 1.0, 0.35))
	draw_circle(crack, 50.0, Color(1.0, 1.0, 1.0, 0.95))
	_rays(crack, 2.05, 0.75, 1200.0, Color(0.85, 0.92, 1.0, 0.2), 9, local)
	_draw_pile(640.0, 440.0, false, 0.9)
	for s in _sleepers:
		var sd: Dictionary = s
		var tex: Texture2D = CHASER_TEX if int(sd["tex"]) == 0 else RANGED_TEX
		var p := Vector2(float(sd["x"]), float(sd["y"]))
		_sprite(tex, p, 85.0, int(sd["tex"]) == 1, Color(0.3, 0.3, 0.36), float(sd["rot"]))
		var wk := _ease(float(sd["wake"]) - T_G, float(sd["wake"]) - T_G + 0.3, local)
		if wk > 0.0:
			var ep := p + Vector2(8.0, -55.0).rotated(float(sd["rot"]))
			draw_circle(ep, 16.0 * wk, Color(0.4, 1.0, 0.9, 0.25 * wk))
			draw_circle(ep, 5.0, Color(0.75, 1.0, 0.95, wk))
	var stand := _ease(0.3, 1.4, local)
	var itex := _isme_frame("idle", local)
	_sprite(itex, Vector2(640.0, 440.0 - 10.0 * stand), 230.0, false, Color(0.75, 0.75, 0.85).lerp(Color.WHITE, _ease(2.0, 5.0, local)))
	_draw_pile(640.0, 440.0, true, 0.9)
	if local < 1.6:
		for i in 10:
			var u := clampf((local - i * 0.08) / 0.9, 0.0, 1.0)
			draw_circle(Vector2(600.0 + i * 9.0, 300.0 + u * 140.0), 3.0, Color(0.5, 0.48, 0.52, 1.0 - u))
	for d in _dust:
		var dv: Vector3 = d
		var u2 := fposmod(dv.y - local * 0.03 * dv.z, 1.0)
		draw_circle(Vector2(dv.x * W, u2 * H - 100.0), dv.z * 0.8, Color(0.85, 0.9, 1.0, 0.35 * sin(u2 * PI)))
	_set_base(Transform2D.IDENTITY)
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 1.0 - clampf(local / 1.0, 0.0, 1.0)))


func _draw_overlay() -> void:
	var t := _t
	if t >= T_LOGO:
		_overlay.draw_set_transform_matrix(Transform2D.IDENTITY)
		_draw_logo_on(_overlay, t - T_LOGO)
	var flash := clampf(1.0 - absf(t - T_B) / 0.5, 0.0, 1.0)
	if flash > 0.0:
		_overlay.draw_rect(Rect2(0, 0, W, H), Color(1, 1, 1, flash))
	var warp := clampf(1.0 - absf(t - (T_A2 + 0.8)) / 0.25, 0.0, 1.0)
	if warp > 0.0:
		_overlay.draw_rect(Rect2(0, 0, W, H), Color(0.85, 0.9, 1.0, warp * 0.7))
	var fade_in := clampf(1.0 - t / 1.2, 0.0, 1.0)
	if fade_in > 0.0:
		_overlay.draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, fade_in))
	var a2_fade := clampf(1.0 - absf(t - T_A2) / 0.5, 0.0, 1.0)
	if a2_fade > 0.0 and t < T_A2 + 0.5:
		_overlay.draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, a2_fade))
	var a2_out := clampf((t - (T_C - 0.6)) / 0.6, 0.0, 1.0) if t < T_C and t >= T_A2 else 0.0
	if a2_out > 0.0:
		_overlay.draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, a2_out))
	if t > T_END - 1.6:
		_overlay.draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, clampf((t - (T_END - 1.6)) / 1.4, 0.0, 1.0)))
	var bar := BAR
	if t >= T_LOGO:
		bar = maxf(BAR - (t - T_LOGO) * 200.0, 0.0)
	_overlay.draw_rect(Rect2(0, 0, W, bar), Color.BLACK)
	_overlay.draw_rect(Rect2(0, H - bar, W, bar), Color.BLACK)
	if _speed > 1.5:
		_overlay.draw_string(get_theme_default_font(), Vector2(30, 34), ">> x3", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(KIT.AMBER, 0.8))


func _draw_logo_on(target: CanvasItem, local: float) -> void:
	target.draw_rect(Rect2(0, 0, W, H), Color(0.01, 0.008, 0.03))
	var head: Font = get_theme_font("font", "Button")
	var slam := clampf(local / 0.18, 0.0, 1.0)
	var sc := lerpf(1.6, 1.0, 1.0 - pow(1.0 - slam, 3.0))
	var glow := clampf(1.0 - local / 1.2, 0.0, 1.0)
	var c := Vector2(W * 0.5, 290)
	for i in 4:
		target.draw_texture_rect(_soft, Rect2(c - Vector2(1, 1) * (260.0 + i * 120.0), Vector2(2, 2) * (260.0 + i * 120.0)), false, Color(1.0, 0.55, 0.18, maxf(0.16 - i * 0.035, 0.02) * (0.7 + glow)))
	for e in _embers:
		var ev: Vector3 = e
		var u := fposmod(ev.y + local * 0.08 * ev.z, 1.0)
		var p := Vector2(ev.x + sin(local + ev.x) * 12.0, H - u * H)
		target.draw_circle(p, ev.z, Color(1.0, 0.65, 0.3, 0.7 * sin(u * PI)))
	for i in 40:
		var a := TAU * i / 40.0 + local * 0.05
		var r0 := 230.0 + 20.0 * sin(i * 3.1)
		var r1 := r0 + 120.0 + 80.0 * sin(i * 1.7 + local)
		target.draw_line(c + Vector2(cos(a), sin(a) * 0.55) * r0, c + Vector2(cos(a), sin(a) * 0.55) * r1, Color(1.0, 0.8, 0.45, 0.07), 2.0)
	target.draw_set_transform_matrix(Transform2D(0.0, Vector2(sc, sc), 0.0, Vector2(W * 0.5, 330)))
	target.draw_string_outline(head, Vector2(-W * 0.5, 0), "H.A.R", HORIZONTAL_ALIGNMENT_CENTER, W, 170, 16, Color(0.035, 0.027, 0.07, slam))
	target.draw_string(head, Vector2(-W * 0.5, 0), "H.A.R", HORIZONTAL_ALIGNMENT_CENTER, W, 170, Color(1.0, 0.725, 0.22, slam))
	target.draw_set_transform_matrix(Transform2D.IDENTITY)
	var sweep := fposmod(local * 0.45, 1.5)
	if sweep < 1.0:
		var fx := lerpf(250.0, W - 250.0, sweep)
		var fa := sin(sweep * PI)
		target.draw_texture_rect(_soft, Rect2(Vector2(fx - 520.0, 268.0), Vector2(1040.0, 28.0)), false, Color(1.0, 0.85, 0.6, 0.35 * fa))
		target.draw_rect(Rect2(fx - 300.0, 281.0, 600.0, 2.0), Color(1.0, 0.95, 0.85, 0.55 * fa))
		target.draw_texture_rect(_soft, Rect2(Vector2(fx - 40.0, 242.0), Vector2(80.0, 80.0)), false, Color(1.0, 0.95, 0.85, 0.8 * fa))
	var sub_a := _ease(0.6, 1.4, local)
	target.draw_string(head, Vector2(0, 405), "PLANET   SOLENOID", HORIZONTAL_ALIGNMENT_CENTER, W, 40, Color(0.275, 0.851, 0.91, sub_a))
	var line_w := 540.0 * _ease(0.8, 1.8, local)
	target.draw_rect(Rect2(W * 0.5 - line_w * 0.5, 428, line_w, 3), Color(1.0, 0.725, 0.22, 0.8))
	target.draw_rect(Rect2(0, 0, W, H), Color(1, 1, 1, glow * 0.85))


