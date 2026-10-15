extends Node2D

const CENTER := Vector2(360.0, 540.0)
const WING_R := [Vector2(458, 38), Vector2(684, 426), Vector2(540, 300), Vector2(430, 235), Vector2(405, 160)]
const WING_L := [Vector2(203, 115), Vector2(122, 416), Vector2(200, 330), Vector2(255, 250), Vector2(285, 185)]
const PIVOT_R := Vector2(430, 200)
const PIVOT_L := Vector2(270, 200)
const EYE := Vector2(290, 92)
const FOOT_A := Vector2(300, 960)
const FOOT_B := Vector2(470, 1060)

var flip := false
var charge := 0.0
var boosting := false
var move_dir := Vector2.DOWN
var flash := 0.0
var muzzle := Vector2(333.0, -178.0)
var shot_charge := 0.0
var stunned := false

var _time := 0.0
var _boost := 0.0


func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	_time = randf() * TAU


func _process(delta: float) -> void:
	_time += delta
	_boost = lerpf(_boost, 1.0 if boosting else 0.0, minf(1.0, 10.0 * delta))
	flash = maxf(flash - delta * 5.0, 0.0)
	queue_redraw()


func _to_local_px(p: Vector2) -> Vector2:
	var rel := p - CENTER
	if flip:
		rel.x = -rel.x
	return rel


func _draw() -> void:
	var power := 0.35 if stunned else 1.0
	if stunned and int(_time * 14.0) % 2 == 0:
		power = 0.1
	_draw_wings(power)
	_draw_motes(power)
	_draw_eye(power)
	_draw_feet(power)
	if _boost > 0.05:
		_draw_streaks()
	if shot_charge > 0.0:
		_draw_shot_charge()
	if flash > 0.0:
		_draw_flash()


func _flap() -> float:
	return sin(_time * (8.0 + 6.0 * _boost + 5.0 * charge)) * (0.07 + 0.06 * _boost)


func _draw_wings(power: float) -> void:
	var glow := (0.14 + 0.1 * _boost + 0.25 * charge) * power
	var col := Color(0.55, 0.85, 1.0, glow)
	if charge > 0.0:
		col = col.lerp(Color(1.0, 0.55, 0.55, glow), charge)
	var flap := _flap()
	for side in 2:
		var pts: Array = WING_R if side == 0 else WING_L
		var pivot: Vector2 = PIVOT_R if side == 0 else PIVOT_L
		var ang := flap if side == 0 else -flap
		var poly := PackedVector2Array()
		for p in pts:
			poly.append(_to_local_px(pivot + (p - pivot).rotated(ang)))
		draw_colored_polygon(poly, col)
		for i in 7:
			var t0 := float(i) / 7.0
			var t1 := float(i + 1) / 7.0
			var a: Vector2 = poly[0].lerp(poly[1], t0)
			var b: Vector2 = poly[0].lerp(poly[1], t1)
			var pulse := maxf(0.0, sin(_time * 3.5 - i * 0.7 + side))
			draw_line(a, b, Color(0.8, 0.95, 1.0, (0.15 + 0.6 * pulse) * power), 6.0 + 4.0 * _boost)


func _draw_motes(power: float) -> void:
	for side in 2:
		var tip: Vector2 = WING_R[1] if side == 0 else WING_L[1]
		for k in 5:
			var u := fposmod(_time * 0.5 + k * 0.2 + side * 0.31, 1.0)
			var drift := Vector2(sin(k * 4.7 + side * 2.0) * 50.0, 30.0 + u * 150.0)
			var p := _to_local_px(tip) + drift
			draw_circle(p, 9.0 * (1.0 - u) + 2.0, Color(0.6, 0.9, 1.0, 0.75 * (1.0 - u) * power))


func _draw_eye(power: float) -> void:
	var e := _to_local_px(EYE)
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	var heat := clampf(charge + 0.6 * _boost, 0.0, 1.0)
	draw_circle(e, 60.0 + 70.0 * heat, Color(1.0, 0.1, 0.1, (0.14 + 0.1 * pulse + 0.3 * heat) * power))
	draw_circle(e, 24.0 + 24.0 * heat, Color(1.0, 0.45, 0.4, (0.35 + 0.25 * pulse + 0.4 * heat) * power))
	if charge > 0.0:
		draw_arc(e, 260.0 * (1.0 - charge) + 30.0, 0.0, TAU, 28, Color(1.0, 0.4, 0.4, 0.7 * charge), 5.0)


func _draw_feet(power: float) -> void:
	for foot in [FOOT_A, FOOT_B]:
		var f := _to_local_px(foot)
		var pulse := 0.5 + 0.5 * sin(_time * 7.0 + f.x * 0.01)
		draw_circle(f, 46.0 + 14.0 * pulse + 20.0 * _boost, Color(0.35, 0.8, 1.0, (0.16 + 0.12 * pulse) * power))
		draw_circle(f, 18.0, Color(0.8, 0.97, 1.0, 0.5 * power))
	var ground := _to_local_px(Vector2(390, 1075))
	for i in 3:
		var u := fposmod(_time * 0.7 + i / 3.0, 1.0)
		draw_arc(ground, 40.0 + u * 190.0, 0.0, TAU, 32, Color(0.5, 0.9, 1.0, 0.4 * (1.0 - u) * power), 5.0)


func _draw_streaks() -> void:
	var back := -move_dir.normalized()
	if back == Vector2.ZERO:
		return
	var side := Vector2(-back.y, back.x)
	for i in 6:
		var off := (float(i) - 2.5) * 70.0
		var start := side * off + back * 120.0
		var length := 220.0 + 80.0 * sin(_time * 20.0 + i * 1.7)
		draw_line(start, start + back * length, Color(0.7, 0.95, 1.0, 0.45 * _boost), 8.0)


func _draw_shot_charge() -> void:
	var wob := 1.0 + 0.1 * sin(_time * 38.0)
	draw_circle(muzzle, (20.0 + 60.0 * shot_charge) * wob, Color(0.4, 0.8, 1.0, 0.2 + 0.3 * shot_charge))
	draw_circle(muzzle, (10.0 + 26.0 * shot_charge) * wob, Color(0.9, 1.0, 1.0, 0.3 + 0.6 * shot_charge))


func _draw_flash() -> void:
	draw_circle(muzzle, 70.0 * flash + 20.0, Color(0.6, 0.9, 1.0, 0.5 * flash))
	for k in 6:
		var a := k * TAU / 6.0 + 0.3
		draw_line(muzzle, muzzle + Vector2.from_angle(a) * (50.0 + 110.0 * flash), Color(0.85, 0.97, 1.0, 0.8 * flash), 6.0)
