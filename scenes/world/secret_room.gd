extends Area2D

const LORE_VIEWER := preload("res://scenes/ui/lore_viewer.tscn")
const ROCK := preload("res://scenes/world/rock_style.gd")
const CRACKED_WALL := preload("res://scenes/world/cracked_wall.gd")

const WALL_THICKNESS := 40.0
const DOOR_HEIGHT := 128.0

enum Entrance { LEFT, RIGHT }

@export var secret_id: String = ""
@export var room_size: Vector2 = Vector2(420, 220)
@export var entrance: Entrance = Entrance.LEFT

var cover_alpha: float = 1.0:
	set(value):
		cover_alpha = value
		queue_redraw()
var cover_dark: float = 0.0:
	set(value):
		cover_dark = value
		queue_redraw()

var _triggered := false
var _time := 0.0
var _decor: Node2D
var _wall
var _wall_style := StyleBoxFlat.new()
var _stone_style := StyleBoxFlat.new()


func _ready() -> void:
	z_index = 5
	_wall_style.bg_color = Color(0.1, 0.06, 0.17)
	_wall_style.border_color = Color(0.55, 0.38, 0.85)
	_wall_style.set_border_width_all(3)
	_wall_style.set_corner_radius_all(14)
	_stone_style.bg_color = Color(0.27, 0.22, 0.34)
	_stone_style.border_color = Color(0.12, 0.09, 0.18)
	_stone_style.set_border_width_all(2)
	_stone_style.set_corner_radius_all(4)
	_decor = Node2D.new()
	_decor.z_as_relative = false
	_decor.z_index = -1
	add_child(_decor)
	_decor.draw.connect(_draw_chamber)
	_build_sparkles()
	_build_trigger()
	_build_shell()

	var found := GameState.is_secret_found(secret_id)
	if found:
		cover_alpha = 0.0
		_triggered = true
		_wall.open_instantly()
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_decor.queue_redraw()


func _block_rect() -> Rect2:
	var t := WALL_THICKNESS
	return Rect2(-t, -t, room_size.x + t * 2.0, room_size.y + t * 2.0)


func _front_x() -> float:
	return -WALL_THICKNESS if entrance == Entrance.LEFT else room_size.x


func _back_x() -> float:
	return room_size.x if entrance == Entrance.LEFT else -WALL_THICKNESS


func _solid_rects() -> Array[Rect2]:
	var t := WALL_THICKNESS
	var w := room_size.x
	var h := room_size.y
	var out: Array[Rect2] = []
	out.append(Rect2(-t, -t, w + t * 2.0, t))
	out.append(Rect2(-t, h, w + t * 2.0, t))
	out.append(Rect2(_back_x(), 0.0, t, h))
	out.append(Rect2(_front_x(), 0.0, t, h - DOOR_HEIGHT))
	return out


func _build_trigger() -> void:
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = room_size
	cs.shape = rect
	cs.position = room_size / 2.0
	add_child(cs)


func _build_shell() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	for r in _solid_rects():
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		cs.shape = shape
		cs.position = r.position + r.size / 2.0
		body.add_child(cs)
	add_child(body)

	_wall = StaticBody2D.new()
	_wall.set_script(CRACKED_WALL)
	_wall.position = Vector2(_front_x(), room_size.y - DOOR_HEIGHT)
	_wall.size = Vector2(WALL_THICKNESS, DOOR_HEIGHT)
	_wall.block_rect = _block_rect()
	add_child(_wall)
	_wall.broken.connect(_on_wall_broken)


func _build_sparkles() -> void:
	var p := CPUParticles2D.new()
	p.z_as_relative = false
	p.z_index = -1
	p.position = room_size / 2.0
	p.amount = 20
	p.lifetime = 4.0
	p.preprocess = 4.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = room_size / 2.0 - Vector2(30, 30)
	p.direction = Vector2(0, -1)
	p.spread = 60.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 18.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	grad.colors = PackedColorArray([Color(1, 0.9, 0.5, 0.0), Color(1, 0.9, 0.5, 0.9), Color(1, 0.9, 0.5, 0.0)])
	p.color_ramp = grad
	add_child(p)


func _draw() -> void:
	var block := _block_rect()
	for r in _solid_rects():
		ROCK.draw_rock(self, r, block)
	ROCK.draw_top_strip(self, block)
	if cover_alpha > 0.0:
		var interior := Rect2(Vector2.ZERO, room_size)
		ROCK.draw_rock(self, interior, block, cover_alpha)
		if cover_dark > 0.0:
			draw_rect(interior, Color(0.03, 0.02, 0.06, 0.96 * cover_dark * cover_alpha))


func _draw_chamber() -> void:
	var w := room_size.x
	var h := room_size.y
	var pulse := 0.5 + 0.5 * sin(_time * 2.0)
	var gold := Color(1.0, 0.82, 0.35)

	_decor.draw_style_box(_wall_style, Rect2(Vector2.ZERO, room_size))
	var row := 0
	var y := 18.0
	while y < h:
		_decor.draw_line(Vector2(6, y), Vector2(w - 6, y), Color(1, 1, 1, 0.05), 2.0)
		var bx := 22.0 + (28.0 if row % 2 == 0 else 0.0)
		while bx < w - 10.0:
			_decor.draw_line(Vector2(bx, y), Vector2(bx, minf(y + 20.0, h - 6.0)), Color(1, 1, 1, 0.04), 2.0)
			bx += 56.0
		y += 20.0
		row += 1

	var cx := w / 2.0
	_decor.draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 26, 4), Vector2(cx + 26, 4), Vector2(cx + 90, h - 12), Vector2(cx - 90, h - 12),
	]), Color(1.0, 0.9, 0.6, 0.06 + 0.04 * pulse))

	var rc := Vector2(cx, h * 0.42)
	for k in 8:
		var a := _time * 0.35 + k * TAU / 8.0
		_decor.draw_line(rc + Vector2.from_angle(a) * 52.0, rc + Vector2.from_angle(a) * 66.0, Color(0.75, 0.55, 1.0, 0.7), 3.0)
		_decor.draw_arc(rc, 78.0, a, a + 0.42, 8, Color(0.75, 0.55, 1.0, 0.35), 3.0)
	_decor.draw_arc(rc, 46.0, 0.0, TAU, 40, Color(0.75, 0.55, 1.0, 0.25 + 0.2 * pulse), 2.0)

	var floor_y := h - 10.0
	_decor.draw_style_box(_stone_style, Rect2(cx - 40, floor_y - 18, 80, 18))
	_decor.draw_style_box(_stone_style, Rect2(cx - 28, floor_y - 42, 56, 26))
	_decor.draw_rect(Rect2(cx - 28, floor_y - 42, 56, 3), Color(1, 1, 1, 0.25))
	var orb := Vector2(cx, floor_y - 78.0 + sin(_time * 2.0) * 6.0)
	_decor.draw_circle(orb, 36.0 + 6.0 * pulse, Color(gold, 0.1))
	_decor.draw_circle(orb, 22.0, Color(gold, 0.22))
	_decor.draw_circle(orb, 12.0, gold)
	_decor.draw_circle(orb + Vector2(-3, -3), 4.0, Color(1, 1, 1, 0.9))
	var spin := _time * 1.5
	for k in 4:
		var a2 := spin + k * TAU / 4.0
		_decor.draw_colored_polygon(PackedVector2Array([
			orb + Vector2.from_angle(a2) * 26.0,
			orb + Vector2.from_angle(a2 + 0.12) * 18.0,
			orb + Vector2.from_angle(a2 - 0.12) * 18.0,
		]), Color(gold, 0.8))

	for lx in [34.0, w - 34.0]:
		var sway := sin(_time * 1.4 + lx) * 3.0
		_decor.draw_line(Vector2(lx, 4), Vector2(lx + sway, 44), Color(0.55, 0.5, 0.6), 2.0)
		var lamp := Vector2(lx + sway, 56)
		var flicker := 0.85 + 0.15 * sin(_time * 17.0 + lx)
		_decor.draw_circle(lamp, 26.0, Color(1.0, 0.7, 0.3, 0.12 * flicker))
		_decor.draw_rect(Rect2(lamp + Vector2(-8, -10), Vector2(16, 22)), Color(0.28, 0.22, 0.2))
		_decor.draw_rect(Rect2(lamp + Vector2(-5, -6), Vector2(10, 14)), Color(1.0, 0.8, 0.4, flicker))

	for corner in [Vector2(10, 10), Vector2(w - 10, 10)]:
		var sx := 1.0 if corner.x < w / 2.0 else -1.0
		_decor.draw_polyline(PackedVector2Array([corner + Vector2(0, 22), corner, corner + Vector2(22 * sx, 0)]), Color(0.75, 0.55, 1.0, 0.6), 3.0)


func _on_wall_broken() -> void:
	create_tween().tween_property(self, "cover_dark", 1.0, 0.6)


func _on_body_entered(body: Node) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	AudioManager.play_sfx("secret_found")
	var tw := create_tween()
	tw.tween_property(self, "cover_alpha", 0.0, 0.6)
	GameState.discover_secret(secret_id)
	GameState.save_game()
	await get_tree().create_timer(1.1).timeout
	_open_lore()


func _open_lore() -> void:
	var info := GameState.get_secret_info(secret_id)
	var tex: Texture2D = null
	if info.has("image"):
		tex = load(info["image"]) as Texture2D
	var ui: Control = LORE_VIEWER.instantiate()
	ui.call("setup", info.get("title", "Secret Room"), info.get("lore", ""), tex)
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(ui)
	get_tree().current_scene.add_child(layer)
	ui.connect("closed", _on_lore_closed.bind(layer))
	get_tree().paused = true


func _on_lore_closed(layer: CanvasLayer) -> void:
	get_tree().paused = false
	layer.queue_free()
