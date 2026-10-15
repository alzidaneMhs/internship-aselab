extends Control

const KIT := preload("res://scripts/ui/ui_kit.gd")
const CRYSTALS := [
	preload("res://assets/sprites/crystals/crystal_purple_a.png"),
	preload("res://assets/sprites/crystals/crystal_purple_b.png"),
]

@export var overlay: bool = false
@export var stage_pos: Vector2 = Vector2(1010.0, 640.0)

var _time := 0.0
var _glows: Array = []
var _rows: Array = []
var _header := "UNIT-01 : ISME"
var _has_data := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	if overlay:
		return
	_build_card()
	_build_crystals()


func _process(delta: float) -> void:
	_time += delta
	if overlay:
		return
	queue_redraw()
	for g in _glows:
		var pulse := 0.5 + 0.5 * sin(_time * float(g["speed"]) + float(g["phase"]))
		(g["node"] as Sprite2D).modulate = Color(0.8, 0.5, 1.0, 0.1 + 0.3 * pulse)


func _build_card() -> void:
	_has_data = GameState.has_save_file()
	_rows.clear()
	if not _has_data:
		_rows.append(["STATUS", "STANDBY", KIT.AMBER])
		_rows.append(["DATA", "TIDAK ADA", KIT.TEXT_DIM])
		_rows.append(["MISI", "BELUM DIMULAI", KIT.TEXT_DIM])
		return
	var info := Story.get_stage_info(GameState.current_stage_path)
	var stage_text := "PROLOG"
	if not info.is_empty():
		stage_text = "%s  -  %s" % [info["label"], info["title"]]
	_rows.append(["STATUS", "ONLINE", KIT.GREEN])
	_rows.append(["LOKASI", stage_text.to_upper(), KIT.TEXT])
	_rows.append(["VONIC", str(GameState.points), KIT.AMBER])
	_rows.append(["REPUTASI", "%d  %s" % [GameState.reputation, GameState.get_reputation_title().to_upper()], KIT.CYAN])
	_rows.append(["ACHIEVEMENT", "%d / %d" % [GameState.achievements.size(), GameState.get_achievement_total()], KIT.VIOLET])


func _build_crystals() -> void:
	var spots := [
		{"tex": 0, "pos": Vector2(1226.0, 724.0), "sc": 0.4, "flip": false},
		{"tex": 1, "pos": Vector2(690.0, 726.0), "sc": 0.3, "flip": true},
		{"tex": 0, "pos": Vector2(1128.0, 728.0), "sc": 0.22, "flip": true},
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for s in spots:
		var tex: Texture2D = CRYSTALS[int(s["tex"])]
		var holder := Node2D.new()
		holder.position = s["pos"]
		holder.scale = Vector2.ONE * float(s["sc"])
		add_child(holder)
		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.centered = false
		sprite.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
		sprite.flip_h = bool(s["flip"])
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		holder.add_child(sprite)
		var glow := Sprite2D.new()
		glow.texture = tex
		glow.centered = false
		glow.offset = sprite.offset
		glow.flip_h = sprite.flip_h
		glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow.material = mat
		holder.add_child(glow)
		_glows.append({"node": glow, "phase": rng.randf() * TAU, "speed": rng.randf_range(0.9, 1.5)})


func _draw() -> void:
	if overlay:
		_draw_overlay()
	else:
		_draw_under()


func _draw_under() -> void:
	var s := size
	var shade := Color(KIT.INK_950, 0.9)
	var clear := Color(KIT.INK_950, 0.0)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(800, 0), Vector2(800, s.y), Vector2(0, s.y)]),
		PackedColorArray([shade, clear, clear, shade]))
	var gx := 0.0
	while gx < 760.0:
		draw_line(Vector2(gx, 0), Vector2(gx, s.y), Color(KIT.STEEL, 0.06 * (1.0 - gx / 760.0)), 1.0)
		gx += 64.0
	var gy := 40.0
	while gy < s.y:
		draw_line(Vector2(0, gy), Vector2(760, gy), Color(KIT.STEEL, 0.05), 1.0)
		gy += 64.0
	draw_rect(Rect2(66.0, 66.0, 4.0, 224.0), KIT.AMBER)
	for k in 5:
		draw_rect(Rect2(66.0, 66.0 + k * 56.0, 14.0, 4.0), KIT.AMBER)
	var by := fposmod(_time * 80.0, s.y + 200.0) - 100.0
	draw_polygon(PackedVector2Array([Vector2(0, by - 60), Vector2(s.x, by - 60), Vector2(s.x, by), Vector2(0, by)]),
		PackedColorArray([Color(KIT.CYAN, 0.0), Color(KIT.CYAN, 0.0), Color(KIT.CYAN, 0.05), Color(KIT.CYAN, 0.05)]))
	_draw_stage()
	_draw_card()


func _draw_stage() -> void:
	var p := stage_pos
	var pulse := 0.5 + 0.5 * sin(_time * 2.0)
	draw_polygon(PackedVector2Array([p + Vector2(-30, -620), p + Vector2(30, -620), p + Vector2(230, 0), p + Vector2(-230, 0)]),
		PackedColorArray([Color(KIT.AMBER, 0.0), Color(KIT.AMBER, 0.0), Color(KIT.AMBER, 0.13), Color(KIT.AMBER, 0.13)]))
	var e := PackedVector2Array()
	var ring := PackedVector2Array()
	for i in 41:
		var a := i * TAU / 40.0
		e.append(p + Vector2(cos(a) * 210.0, sin(a) * 30.0))
		ring.append(p + Vector2(cos(a) * 170.0, sin(a) * 22.0))
	draw_colored_polygon(e, Color(KIT.INK_900, 0.9))
	draw_polyline(e, Color(KIT.STEEL, 0.9), 3.0)
	draw_polyline(ring, Color(KIT.AMBER, 0.4 + 0.5 * pulse), 3.0)
	for k in 8:
		var a := k * TAU / 8.0 + _time * 0.3
		draw_line(p + Vector2(cos(a) * 170.0, sin(a) * 22.0), p + Vector2(cos(a) * 205.0, sin(a) * 28.0), Color(KIT.AMBER, 0.6), 3.0)


func _draw_card() -> void:
	var rect := Rect2(824.0, 100.0, 376.0, 56.0 + _rows.size() * 38.0 + 22.0)
	KIT.draw_panel(self, rect, Color(KIT.INK_900, 0.92), KIT.STEEL, 12.0, KIT.AMBER)
	var font := get_theme_default_font()
	var head_font: Font = get_theme_font("font", "Button")
	draw_rect(Rect2(rect.position.x + 14.0, rect.position.y + 12.0, rect.size.x - 28.0, 30.0), Color(KIT.INK_700, 0.8))
	draw_rect(Rect2(rect.position.x + 14.0, rect.position.y + 12.0, 5.0, 30.0), KIT.AMBER)
	draw_string(head_font, rect.position + Vector2(30.0, 34.0), _header, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, KIT.AMBER)
	var blink := 0.5 + 0.5 * sin(_time * 5.0)
	draw_circle(rect.position + Vector2(rect.size.x - 32.0, 27.0), 5.0, Color(KIT.GREEN if _has_data else KIT.AMBER, 0.4 + 0.6 * blink))
	var y := rect.position.y + 72.0
	for row in _rows:
		draw_string(font, Vector2(rect.position.x + 22.0, y), String(row[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, KIT.TEXT_DIM)
		draw_string(head_font, Vector2(rect.position.x + 22.0, y + 22.0), String(row[1]), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 44.0, 20, Color(row[2]))
		y += 38.0


func _draw_overlay() -> void:
	var s := size
	var y := 0.0
	while y < s.y:
		draw_rect(Rect2(0, y, s.x, 1.0), Color(0, 0, 0, 0.12))
		y += 3.0
	var edge := Color(KIT.INK_950, 0.55)
	var clear := Color(KIT.INK_950, 0.0)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(s.x, 0), Vector2(s.x, 120), Vector2(0, 120)]), PackedColorArray([edge, edge, clear, clear]))
	draw_polygon(PackedVector2Array([Vector2(0, s.y - 160), Vector2(s.x, s.y - 160), Vector2(s.x, s.y), Vector2(0, s.y)]), PackedColorArray([clear, clear, edge, edge]))
	KIT.draw_hazard(self, Rect2(0, 0, s.x, 10.0), KIT.AMBER, Color(KIT.INK_950, 0.95), 0.0, 20.0)
	draw_rect(Rect2(0, s.y - 36.0, s.x, 36.0), Color(KIT.INK_950, 0.94))
	draw_rect(Rect2(0, s.y - 36.0, s.x, 2.0), KIT.STEEL_DIM)
	var font := get_theme_default_font()
	draw_string(font, Vector2(24.0, s.y - 12.0), "H.A.R   //   PLANET CIRCUIT   //   TEAM DAPHNE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, KIT.TEXT_DIM)
	draw_string(font, Vector2(s.x - 24.0 - 420.0, s.y - 12.0), "W / S  atau  panah :  pilih        Enter :  konfirmasi", HORIZONTAL_ALIGNMENT_RIGHT, 420.0, 16, KIT.TEXT_DIM)
