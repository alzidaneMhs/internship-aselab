extends Node2D

## Big pixel-art crystal clusters growing out of the ground, placed along the
## sibling "Platforms". They sit behind the platforms (so their bases look planted),
## and each one has a soft glow that pulses. Same seed, same layout every run.
## Place right after Platforms.

const FX := preload("res://scripts/effects/laser_fx.gd")
const PURPLE := [
	preload("res://assets/sprites/crystals/crystal_purple_a.png"),
	preload("res://assets/sprites/crystals/crystal_purple_b.png"),
]
const BLUE := [
	preload("res://assets/sprites/crystals/crystal_blue_a.png"),
	preload("res://assets/sprites/crystals/crystal_blue_b.png"),
]

@export_enum("Purple", "Blue") var palette: int = 0
@export var seed_value: int = 1
@export var platforms_path: NodePath = NodePath("../Platforms")
## Average clusters per 1000 px of ground.
@export var density: float = 2.4
@export var min_scale: float = 0.17
@export var max_scale: float = 0.36
## Ground shorter than this (ledges, steps) gets no crystals.
@export var min_platform_width: float = 220.0

var _glows: Array = []
var _time := 0.0


func _ready() -> void:
	z_index = -1
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 4421 + 3
	var textures: Array = PURPLE if palette == 0 else BLUE
	var glow_color := Color(0.8, 0.5, 1.0) if palette == 0 else Color(0.55, 0.75, 1.0)
	var platforms := get_node_or_null(platforms_path)
	if platforms == null:
		return
	for p in platforms.get_children():
		var sz: Variant = p.get("size")
		if typeof(sz) != TYPE_VECTOR2:
			continue
		var size: Vector2 = sz
		var style_value: Variant = p.get("style")
		if (style_value != null and int(style_value) == 1) or size.x < min_platform_width or size.y < 100.0:
			continue
		var count := int(round(size.x / 1000.0 * density + rng.randf_range(-0.4, 0.9)))
		for i in maxi(count, 1 if size.x > 520.0 else 0):
			var tex: Texture2D = textures[rng.randi() % textures.size()]
			var sc := rng.randf_range(min_scale, max_scale)
			var half_w := tex.get_width() * sc * 0.5
			if size.x < half_w * 2.0 + 40.0:
				continue
			var x := rng.randf_range(p.position.x + half_w + 20.0, p.position.x + size.x - half_w - 20.0)
			_add_crystal(tex, Vector2(x, p.position.y + 8.0), sc, glow_color, rng)


func _add_crystal(tex: Texture2D, base: Vector2, sc: float, glow_color: Color, rng: RandomNumberGenerator) -> void:
	var holder := Node2D.new()
	holder.position = base
	holder.scale = Vector2(sc, sc)
	add_child(holder)

	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if rng.randf() < 0.5:
		sprite.flip_h = true
	holder.add_child(sprite)

	# Additive copy of the same sprite, pulsing, as a glow.
	var glow := Sprite2D.new()
	glow.texture = tex
	glow.centered = false
	glow.offset = sprite.offset
	glow.flip_h = sprite.flip_h
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	glow.modulate = Color(glow_color, 0.0)
	holder.add_child(glow)
	_glows.append({"node": glow, "phase": rng.randf() * TAU, "speed": rng.randf_range(0.8, 1.6), "color": glow_color})


func _process(delta: float) -> void:
	_time += delta
	for g in _glows:
		# Skip the glow of crystals that are far off screen.
		if not FX.on_screen(g["node"], 700.0):
			continue
		var pulse := 0.5 + 0.5 * sin(_time * float(g["speed"]) + float(g["phase"]))
		var c: Color = g["color"]
		(g["node"] as Sprite2D).modulate = Color(c, 0.08 + 0.3 * pulse)
