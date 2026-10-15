extends Node2D

const KIT := preload("res://scripts/ui/ui_kit.gd")
const CRYSTALS := [
	preload("res://assets/sprites/crystals/crystal_blue_a.png"),
	preload("res://assets/sprites/crystals/crystal_blue_b.png"),
]

@export_file("*.tscn") var next_stage_path: String = ""
@export var tower_height: float = 2600.0

var _time := 0.0
var _used := false
var _glows: Array = []


func _ready() -> void:
	z_index = -2
	var trigger := Area2D.new()
	trigger.collision_layer = 128
	trigger.collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(150.0, 170.0)
	shape.shape = rect
	shape.position = Vector2(0.0, -85.0)
	trigger.add_child(shape)
	add_child(trigger)
	trigger.body_entered.connect(_on_body_entered)
	_add_crystal(CRYSTALS[0], Vector2(-390.0, 6.0), 0.4, false)
	_add_crystal(CRYSTALS[1], Vector2(400.0, 6.0), 0.36, true)
	_add_crystal(CRYSTALS[1], Vector2(-300.0, 6.0), 0.22, true)


func _add_crystal(tex: Texture2D, pos: Vector2, sc: float, flip: bool) -> void:
	var holder := Node2D.new()
	holder.position = pos
	holder.scale = Vector2.ONE * sc
	add_child(holder)
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
	sprite.flip_h = flip
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	holder.add_child(sprite)
	var glow := Sprite2D.new()
	glow.texture = tex
	glow.centered = false
	glow.offset = sprite.offset
	glow.flip_h = flip
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	holder.add_child(glow)
	_glows.append({"node": glow, "phase": randf() * TAU})


func _process(delta: float) -> void:
	_time += delta
	for g in _glows:
		var pulse := 0.5 + 0.5 * sin(_time * 1.2 + float(g["phase"]))
		(g["node"] as Sprite2D).modulate = Color(0.55, 0.75, 1.0, 0.1 + 0.3 * pulse)
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if _used or not body.is_in_group("player") or next_stage_path.is_empty():
		return
	_used = true
	await Cutscene.begin()
	Cutscene.focus(global_position + Vector2(0.0, -230.0), 2.4, 1.1)
	await Cutscene.walk_player_to(global_position.x, 8.0, 3.0)
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		create_tween().tween_property(player, "modulate:a", 0.0, 0.6)
	await Cutscene.wait(0.5)
	await Cutscene.fade(Color.BLACK, 1.0, 0.8)
	GameState.set_checkpoint(next_stage_path, "", Vector2.ZERO)
	GameState.save_game()
	GameManager.goto_stage(next_stage_path, false)


func _draw() -> void:
	var tiers := 9
	var tier_h := tower_height / tiers
	var rng := RandomNumberGenerator.new()
	rng.seed = 424
	# Glow at the foot of the tower.
	draw_polygon(PackedVector2Array([Vector2(-420, 0), Vector2(420, 0), Vector2(300, -380), Vector2(-300, -380)]),
		PackedColorArray([Color(0.4, 0.75, 1.0, 0.18), Color(0.4, 0.75, 1.0, 0.18), Color(0.4, 0.75, 1.0, 0.0), Color(0.4, 0.75, 1.0, 0.0)]))
	for i in tiers:
		var t0 := float(i) / tiers
		var t1 := float(i + 1) / tiers
		var w0 := lerpf(560.0, 300.0, t0)
		var w1 := lerpf(560.0, 300.0, t1)
		var y0 := -i * tier_h
		var y1 := -(i + 1) * tier_h
		var body := Color(0.13, 0.16, 0.3).lerp(Color(0.2, 0.26, 0.46), t0)
		draw_colored_polygon(PackedVector2Array([Vector2(-w0 / 2.0, y0), Vector2(w0 / 2.0, y0), Vector2(w1 / 2.0, y1), Vector2(-w1 / 2.0, y1)]), body)
		draw_colored_polygon(PackedVector2Array([Vector2(w0 * 0.18, y0), Vector2(w0 / 2.0, y0), Vector2(w1 / 2.0, y1), Vector2(w1 * 0.18, y1)]), Color(0.06, 0.08, 0.18, 0.55))
		draw_colored_polygon(PackedVector2Array([Vector2(-w0 / 2.0, y0), Vector2(-w0 * 0.34, y0), Vector2(-w1 * 0.34, y1), Vector2(-w1 / 2.0, y1)]), Color(0.5, 0.62, 0.9, 0.12))
		# Band between tiers.
		draw_rect(Rect2(-w0 / 2.0 - 10.0, y0 - 14.0, w0 + 20.0, 16.0), Color(0.07, 0.09, 0.2))
		draw_rect(Rect2(-w0 / 2.0 - 10.0, y0 - 14.0, w0 + 20.0, 3.0), Color(0.45, 0.55, 0.85, 0.7))
		# Lit arched windows.
		var cols := 3
		for c in cols:
			var wx := lerpf(-w0 * 0.3, w0 * 0.3, float(c) / (cols - 1))
			var wy := y0 - tier_h * 0.5
			var lit := 0.7 + 0.3 * sin(_time * 1.3 + i * 1.7 + c * 2.3)
			if rng.randf() < 0.18:
				lit *= 0.15
			draw_rect(Rect2(wx - 22.0, wy - 14.0, 44.0, 70.0), Color(0.04, 0.05, 0.12))
			draw_circle(Vector2(wx, wy - 14.0), 22.0, Color(0.04, 0.05, 0.12))
			draw_rect(Rect2(wx - 16.0, wy - 12.0, 32.0, 62.0), Color(0.45, 0.82, 1.0, 0.55 * lit))
			draw_circle(Vector2(wx, wy - 12.0), 16.0, Color(0.45, 0.82, 1.0, 0.55 * lit))
			draw_rect(Rect2(wx - 2.0, wy - 28.0, 4.0, 80.0), Color(0.04, 0.05, 0.12, 0.8))
	# Door: arch, glowing interior and steps.
	var door := Rect2(-70.0, -180.0, 140.0, 180.0)
	draw_rect(Rect2(-92.0, -190.0, 184.0, 190.0), Color(0.06, 0.08, 0.18))
	draw_circle(Vector2(0.0, -190.0), 92.0, Color(0.06, 0.08, 0.18))
	draw_rect(door, Color(0.03, 0.04, 0.1))
	draw_circle(Vector2(0.0, -180.0), 70.0, Color(0.03, 0.04, 0.1))
	var pulse := 0.5 + 0.5 * sin(_time * 2.0)
	draw_polygon(PackedVector2Array([Vector2(-62, 0), Vector2(62, 0), Vector2(30, -170), Vector2(-30, -170)]),
		PackedColorArray([Color(0.5, 0.85, 1.0, 0.5 + 0.2 * pulse), Color(0.5, 0.85, 1.0, 0.5 + 0.2 * pulse), Color(0.5, 0.85, 1.0, 0.1), Color(0.5, 0.85, 1.0, 0.1)]))
	draw_arc(Vector2(0.0, -180.0), 70.0, PI, TAU, 24, Color(0.7, 0.92, 1.0, 0.8), 4.0)
	for k in 3:
		draw_rect(Rect2(-100.0 - k * 14.0, -k * 8.0 - 8.0, 200.0 + k * 28.0, 8.0), Color(0.16 + 0.04 * k, 0.2 + 0.04 * k, 0.36 + 0.04 * k))
