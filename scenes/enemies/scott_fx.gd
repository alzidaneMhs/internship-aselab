extends Node2D

const CENTER := Vector2(469.0, 540.0)
const LOW_MUZZLE := Vector2(125, 300)
const TOP_MUZZLE := Vector2(140, 125)
const TURRET := Vector2(500, 70)
const LEDS := [Vector2(690, 160), Vector2(740, 255)]
const KNEES := [Vector2(305, 610), Vector2(580, 650)]
const FEET := [Vector2(300, 930), Vector2(650, 1010)]

var flip := false
var charge := 0.0
var charge_barrel := 0
var charge_color := Color(0.4, 0.85, 1.0)
var flash := 0.0
var flash_barrel := 0
var windup := 0.0
var hatch := 0.0
var phase_heat := 0.0
var rage := 0.0
var fall_trail := 0.0
var stunned := false

var _time := 0.0


func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	_time = randf() * TAU


func _process(delta: float) -> void:
	_time += delta
	flash = maxf(flash - delta * 5.0, 0.0)
	queue_redraw()


func _px(p: Vector2) -> Vector2:
	var rel := p - CENTER
	if flip:
		rel.x = -rel.x
	return rel


func _barrel(which: int) -> Vector2:
	return _px(TOP_MUZZLE if which == 1 else LOW_MUZZLE)


func _draw() -> void:
	var power := 0.25 if stunned else 1.0
	if stunned and int(_time * 12.0) % 2 == 0:
		power = 0.05
	_draw_scan(power)
	_draw_leds(power)
	_draw_knees(power)
	if rage > 0.0:
		_draw_rage()
	if fall_trail > 0.0:
		_draw_fall_trail()
	if windup > 0.0:
		_draw_windup()
	if hatch > 0.0:
		_draw_turret()
	if charge > 0.0:
		_draw_charge()
	if flash > 0.0:
		_draw_flash()


func _draw_scan(power: float) -> void:
	var u := fposmod(_time * 0.3, 1.0)
	var y := lerpf(-440.0, 80.0, u)
	var a := sin(u * PI) * 0.22 * power
	draw_line(Vector2(-300.0, y), Vector2(300.0, y), Color(0.5, 0.9, 1.0, a), 6.0)


func _draw_leds(power: float) -> void:
	var rate := 3.0 + 4.0 * phase_heat
	var col := Color(0.35, 0.85, 1.0).lerp(Color(1.0, 0.2, 0.15), clampf(phase_heat * 0.6, 0.0, 1.0))
	for i in LEDS.size():
		var pulse := 0.5 + 0.5 * sin(_time * rate + i * 1.7)
		var p := _px(LEDS[i])
		draw_circle(p, 34.0 + 12.0 * pulse, Color(col, (0.15 + 0.15 * pulse) * power))
		draw_circle(p, 12.0, Color(col, (0.55 + 0.4 * pulse) * power))


func _draw_knees(power: float) -> void:
	for k in KNEES:
		var p := _px(k)
		var pulse := 0.5 + 0.5 * sin(_time * 4.0 + p.x * 0.01)
		draw_circle(p, 44.0, Color(0.4, 0.85, 1.0, (0.08 + 0.08 * pulse) * power))
		draw_arc(p, 30.0, 0.0, TAU, 20, Color(0.7, 0.95, 1.0, (0.2 + 0.25 * pulse) * power), 4.0)


func _draw_windup() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 30.0)
	for side in [-1.0, 1.0]:
		for i in 6:
			var u := fposmod(_time * 2.6 + i * 0.17, 1.0)
			var x: float = float(side) * (420.0 * (1.0 - u) + 50.0)
			draw_line(Vector2(x, 500.0), Vector2(x - side * 70.0, 500.0), Color(1.0, 0.6, 0.2, 0.7 * windup * u), 8.0)
	for k in KNEES:
		draw_circle(_px(k), (50.0 + 30.0 * windup) * (0.9 + 0.2 * pulse), Color(1.0, 0.5, 0.15, 0.35 * windup))
	for f in FEET:
		var p := _px(f)
		draw_circle(p, (60.0 + 50.0 * windup), Color(1.0, 0.45, 0.1, 0.3 * windup))
		draw_circle(p, 24.0, Color(1.0, 0.9, 0.6, 0.6 * windup))


func _draw_rage() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 9.0)
	draw_circle(Vector2(0.0, -20.0), 520.0 + 30.0 * pulse, Color(1.0, 0.1, 0.05, 0.1 * rage))
	draw_circle(Vector2(0.0, -20.0), 340.0, Color(1.0, 0.25, 0.1, 0.1 * rage))
	for k in 14:
		var x := lerpf(-300.0, 300.0, k / 13.0) + sin(_time * 3.0 + k) * 20.0
		var base := Vector2(x, 360.0 - absf(x) * 0.35)
		var tip := base + Vector2(sin(_time * 4.0 + k * 2.0) * 40.0, -(250.0 + 130.0 * sin(_time * 5.0 + k * 1.3)))
		var w := 52.0 + 18.0 * sin(_time * 7.0 + k)
		draw_colored_polygon(PackedVector2Array([base + Vector2(-w, 0.0), tip, base + Vector2(w, 0.0)]), Color(1.0, 0.2, 0.08, 0.28 * rage))
		draw_colored_polygon(PackedVector2Array([base + Vector2(-w * 0.45, 0.0), base.lerp(tip, 0.75), base + Vector2(w * 0.45, 0.0)]), Color(1.0, 0.65, 0.2, 0.3 * rage))


func _draw_fall_trail() -> void:
	draw_circle(Vector2(0.0, 380.0), 220.0, Color(1.0, 0.45, 0.15, 0.3 * fall_trail))
	draw_circle(Vector2(0.0, 380.0), 110.0, Color(1.0, 0.9, 0.7, 0.4 * fall_trail))
	for k in 9:
		var x := lerpf(-260.0, 260.0, k / 8.0)
		var length := 380.0 + 260.0 * sin(_time * 22.0 + k * 1.9)
		draw_line(Vector2(x, -260.0), Vector2(x, -260.0 - length), Color(1.0, 0.7, 0.35, 0.5 * fall_trail), 14.0)
		draw_line(Vector2(x, -260.0), Vector2(x, -260.0 - length * 0.6), Color(1.0, 1.0, 0.9, 0.7 * fall_trail), 4.0)


func _draw_turret() -> void:
	var p := _px(TURRET)
	var pulse := 0.5 + 0.5 * sin(_time * 18.0)
	draw_circle(p, (60.0 + 30.0 * pulse) * hatch, Color(1.0, 0.5, 0.15, 0.35 * hatch))
	draw_circle(p, 26.0 * hatch, Color(1.0, 0.9, 0.6, 0.8 * hatch))
	for k in 5:
		var u := fposmod(_time * 1.8 + k * 0.2, 1.0)
		draw_circle(p + Vector2(sin(k * 4.1) * 40.0 * u, -u * 220.0), 10.0 * (1.0 - u) + 2.0, Color(1.0, 0.7, 0.3, 0.7 * hatch * (1.0 - u)))


func _draw_charge() -> void:
	var p := _barrel(charge_barrel)
	var wob := 1.0 + 0.1 * sin(_time * 40.0)
	draw_circle(p, (24.0 + 100.0 * charge) * wob, Color(charge_color, 0.14 + 0.28 * charge))
	draw_circle(p, (12.0 + 46.0 * charge) * wob, Color(charge_color.lightened(0.3), 0.3 + 0.5 * charge))
	draw_circle(p, 8.0 + 18.0 * charge, Color(1, 1, 1, 0.4 + 0.5 * charge))
	for k in 8:
		var a := k * TAU / 8.0 + _time * 3.0
		var u := fposmod(_time * 2.2 + k * 0.13, 1.0)
		var from := p + Vector2.from_angle(a) * (200.0 * (1.0 - u) + 30.0)
		draw_line(from, from.lerp(p, 0.3), Color(charge_color.lightened(0.4), 0.7 * charge * u), 4.0)


func _draw_flash() -> void:
	var p := _barrel(flash_barrel)
	draw_circle(p, 90.0 * flash + 24.0, Color(1.0, 0.8, 0.5, 0.55 * flash))
	for k in 7:
		var a := k * TAU / 7.0 + 0.2
		draw_line(p, p + Vector2.from_angle(a) * (70.0 + 130.0 * flash), Color(1.0, 0.9, 0.65, 0.85 * flash), 7.0)
