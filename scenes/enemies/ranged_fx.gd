extends Node2D

const FX := preload("res://scripts/effects/laser_fx.gd")

const EYES := [Vector2(23.0, -12.0), Vector2(168.0, -17.0)]
const THRUSTER := Vector2(78.0, 440.0)

var flip := false
var thrust := 0.4
var charge := 0.0
var flash := 0.0
var muzzle := Vector2(400.0, 40.0)
var aim_dir := Vector2.RIGHT

var _time := 0.0
var _smooth := 0.4


func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	_time = randf() * TAU


func _process(delta: float) -> void:
	if not FX.on_screen(self, 500.0):
		return
	_time += delta
	_smooth = lerpf(_smooth, thrust, minf(1.0, 8.0 * delta))
	flash = maxf(flash - delta * 5.0, 0.0)
	queue_redraw()


func _draw() -> void:
	var mx := -1.0 if flip else 1.0
	_draw_eyes(mx)
	_draw_thruster(mx)
	if charge > 0.0:
		_draw_aim()
	if flash > 0.0:
		_draw_flash()


func _draw_eyes(mx: float) -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 3.0)
	for e in EYES:
		var pos := Vector2(e.x * mx, e.y)
		draw_circle(pos, 78.0, Color(0.2, 1.0, 0.3, 0.07 + 0.07 * pulse + 0.2 * charge))
		draw_circle(pos, 40.0, Color(0.4, 1.0, 0.5, 0.2 + 0.18 * pulse + 0.3 * charge))


func _draw_thruster(mx: float) -> void:
	var base := Vector2(THRUSTER.x * mx, THRUSTER.y)
	var flicker := 0.5 + 0.5 * sin(_time * 33.0) * sin(_time * 19.0)
	var length := 60.0 + 100.0 * _smooth + 40.0 * flicker
	draw_circle(base + Vector2(0.0, length * 0.3), length * 0.75, Color(0.3, 0.75, 1.0, 0.1 + 0.06 * flicker))
	var layers := [
		[1.0, 80.0, Color(0.15, 0.5, 1.0, 0.75)],
		[0.7, 54.0, Color(0.4, 0.85, 1.0, 0.9)],
		[0.42, 30.0, Color(0.9, 1.0, 1.0, 1.0)],
	]
	for layer in layers:
		var ll: float = length * float(layer[0])
		var ww: float = float(layer[1]) * (0.85 + 0.25 * _smooth)
		var sway: float = sin(_time * 26.0 + ll * 0.05) * 5.0
		draw_colored_polygon(PackedVector2Array([
			base + Vector2(-ww * 0.5, 0.0),
			base + Vector2(-ww * 0.4 + sway * 0.4, ll * 0.45),
			base + Vector2(sway, ll),
			base + Vector2(ww * 0.4 + sway * 0.4, ll * 0.45),
			base + Vector2(ww * 0.5, 0.0),
		]), layer[2])
	for k in 4:
		var u := fposmod(_time * 1.5 + k * 0.25, 1.0)
		var p := base + Vector2(sin(k * 5.1) * 40.0 * u, 50.0 + u * (130.0 + 90.0 * _smooth))
		draw_circle(p, 8.0 - 6.0 * u, Color(0.6, 0.9, 1.0, 0.8 * (1.0 - u)))


func _draw_aim() -> void:
	var end := muzzle + aim_dir * 2600.0
	draw_line(muzzle, end, Color(1.0, 0.15, 0.1, 0.22 * charge), 10.0 * (0.4 + charge))
	draw_line(muzzle, end, Color(1.0, 0.7, 0.6, 0.5 * charge), 3.0)
	var wob := 1.0 + 0.12 * sin(_time * 40.0)
	draw_circle(muzzle, (26.0 + 80.0 * charge) * wob, Color(1.0, 0.45, 0.15, 0.2 + 0.3 * charge))
	draw_circle(muzzle, (12.0 + 34.0 * charge) * wob, Color(1.0, 0.9, 0.6, 0.35 + 0.55 * charge))
	draw_arc(muzzle, 40.0 + 60.0 * (1.0 - charge), 0.0, TAU, 20, Color(1.0, 0.7, 0.4, 0.5 * charge), 4.0)


func _draw_flash() -> void:
	draw_circle(muzzle, 90.0 * flash + 20.0, Color(1.0, 0.6, 0.25, 0.5 * flash))
	for k in 6:
		var a := k * TAU / 6.0 + 0.4
		draw_line(muzzle, muzzle + Vector2.from_angle(a) * (60.0 + 120.0 * flash), Color(1.0, 0.85, 0.5, 0.8 * flash), 6.0)
