extends Node2D

## Jetpack flames for the chaser robot. A child of its Sprite2D, so everything is
## drawn in the sprite's own pixel space (1024x1024, origin at the centre) and
## follows its bobbing and tilt for free. Additive blending makes the flames glow.

const FX := preload("res://scripts/effects/laser_fx.gd")

## Nozzle base points of chaser_bot.png, relative to the sprite centre.
const NOZZLES := [Vector2(-340.0, 323.0), Vector2(-55.0, 403.0)]
const WIDTHS := [74.0, 62.0]

## 0 = barely idling, 1 = running, > 1 = overloaded (about to blow).
var intensity := 0.4
## Mirrors the flames when the sprite faces left (flip_h).
var flip := false

var _time := 0.0
var _smooth := 0.4
var _phase := [0.0, 0.0]


func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	_phase = [randf() * TAU, randf() * TAU]


func _process(delta: float) -> void:
	if not FX.on_screen(self, 500.0):
		return
	_time += delta
	_smooth = lerpf(_smooth, intensity, minf(1.0, 8.0 * delta))
	queue_redraw()


func _draw() -> void:
	for i in NOZZLES.size():
		var base: Vector2 = NOZZLES[i]
		if flip:
			base.x = -base.x
		var w: float = WIDTHS[i] * (0.8 + 0.3 * _smooth)
		var flicker := 0.5 + 0.5 * sin(_time * 31.0 + _phase[i]) * sin(_time * 17.0 + _phase[i] * 2.0)
		var length := 90.0 + 120.0 * _smooth + 55.0 * flicker
		_draw_flame(base, w, length, flicker)
		_draw_sparks(base, i)


func _draw_flame(base: Vector2, w: float, length: float, flicker: float) -> void:
	# Soft glow around the nozzle.
	draw_circle(base + Vector2(0, length * 0.28), length * 0.62, Color(1.0, 0.45, 0.1, 0.13 + 0.07 * flicker))
	# Outer red-orange, orange, yellow and white-hot core, each shorter and narrower.
	var layers := [
		[1.0, 1.0, Color(1.0, 0.25, 0.05, 0.85)],
		[0.78, 0.72, Color(1.0, 0.55, 0.1, 0.9)],
		[0.55, 0.46, Color(1.0, 0.88, 0.3, 0.95)],
		[0.32, 0.24, Color(1.0, 1.0, 0.9, 1.0)],
	]
	for layer in layers:
		var ll: float = length * layer[0]
		var ww: float = w * layer[1]
		var sway: float = sin(_time * 24.0 + ll * 0.05) * 6.0 * float(layer[0])
		draw_colored_polygon(PackedVector2Array([
			base + Vector2(-ww * 0.5, 0.0),
			base + Vector2(-ww * 0.42 + sway * 0.4, ll * 0.42),
			base + Vector2(sway, ll),
			base + Vector2(ww * 0.42 + sway * 0.4, ll * 0.42),
			base + Vector2(ww * 0.5, 0.0),
		]), layer[2])


func _draw_sparks(base: Vector2, index: int) -> void:
	for k in 5:
		var u := fposmod(_time * (1.3 + 0.5 * _smooth) + k * 0.2 + index * 0.37, 1.0)
		var drift := sin(k * 7.3 + index * 3.1) * 55.0 * u
		var pos := base + Vector2(drift, 60.0 + u * (150.0 + 130.0 * _smooth))
		var r := (11.0 - 8.0 * u) * (0.8 + 0.4 * _smooth)
		draw_circle(pos, r, Color(1.0, 0.7 - 0.4 * u, 0.15, 0.9 * (1.0 - u)))
