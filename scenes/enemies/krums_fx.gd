extends Node2D

## Effects for Krums, a child of his Sprite2D (drawn in the sprite's 1080x1620
## pixel space, origin at the centre, additive blending): glowing eye and chest
## vent, spinning boot wheels, steam, and the aura that builds before his big attacks.

const CENTER := Vector2(540.0, 810.0)
## Landmarks in sprite pixels (the sprite faces left by default).
const EYE := Vector2(487, 130)
const VENT := Vector2(500, 520)
const WHEEL_A := Vector2(500, 1410)
const WHEEL_B := Vector2(895, 1470)
const GUN_TIP := Vector2(915, 1100)
const SHOULDERS := [Vector2(370, 330), Vector2(740, 230)]

## Mirrors everything when the sprite faces right (flip_h).
var flip := false
## 0..1 build-up before a heavy attack or stomp.
var charge := 0.0
## Colour of the build-up aura.
var aura_color := Color(1.0, 0.45, 0.15)
## 0..1 how fast he is moving (wheels, dust glow).
var speed := 0.0
## 0 = healthy, 1 = badly damaged: brighter eye, venting steam.
var rage := 0.0
## 1 = strike/stomp impact just happened, fades out.
var impact := 0.0
## Dim and flicker while stunned.
var stunned := false

var _time := 0.0
var _wheel_angle := 0.0


func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	_time = randf() * TAU


func _process(delta: float) -> void:
	_time += delta
	_wheel_angle += delta * (3.0 + 28.0 * speed + 10.0 * charge)
	impact = maxf(impact - delta * 4.0, 0.0)
	queue_redraw()


func _px(p: Vector2) -> Vector2:
	var rel := p - CENTER
	if flip:
		rel.x = -rel.x
	return rel


func _draw() -> void:
	var power := 0.3 if stunned else 1.0
	if stunned and int(_time * 12.0) % 2 == 0:
		power = 0.08
	_draw_aura()
	_draw_vent(power)
	_draw_eye(power)
	_draw_wheels(power)
	_draw_steam(power)
	if impact > 0.0:
		_draw_impact()


func _draw_aura() -> void:
	if charge <= 0.0:
		return
	# Rings contract toward his body; a pulsing glow swells behind him.
	var center := Vector2(0.0, -40.0)
	draw_circle(center, 420.0 + 40.0 * sin(_time * 14.0), Color(aura_color, 0.07 + 0.16 * charge))
	for i in 3:
		var u := fposmod(_time * 1.6 + i / 3.0, 1.0)
		draw_arc(center, 160.0 + (1.0 - u) * 520.0, 0.0, TAU, 40, Color(aura_color, 0.55 * charge * u), 8.0)


func _draw_vent(power: float) -> void:
	var v := _px(VENT)
	var pulse := 0.5 + 0.5 * sin(_time * (2.5 + 5.0 * rage + 8.0 * charge))
	var heat := clampf(0.25 + 0.35 * rage + 0.5 * charge, 0.0, 1.0)
	draw_circle(v, 120.0 + 40.0 * pulse, Color(1.0, 0.35, 0.1, (0.07 + 0.12 * heat * pulse) * power))
	for k in 4:
		var y := v.y - 60.0 + k * 38.0
		draw_line(Vector2(v.x - 90.0, y), Vector2(v.x + 90.0, y), Color(1.0, 0.5, 0.15, (0.1 + 0.4 * heat * pulse) * power), 8.0)


func _draw_eye(power: float) -> void:
	var e := _px(EYE)
	var pulse := 0.5 + 0.5 * sin(_time * (3.0 + 4.0 * rage))
	var heat := clampf(0.2 * rage + charge, 0.0, 1.0)
	draw_circle(e, 70.0 + 50.0 * heat, Color(1.0, 0.1, 0.1, (0.16 + 0.12 * pulse + 0.3 * heat) * power))
	draw_circle(e, 26.0 + 18.0 * heat, Color(1.0, 0.5, 0.45, (0.4 + 0.3 * pulse + 0.3 * heat) * power))
	# Scanning beam sweeping from the eye now and then.
	var sweep := fposmod(_time * 0.35, 1.0)
	if sweep < 0.25 and not stunned:
		var a := PI + 0.25 - sweep / 0.25 * 0.5
		var dir := Vector2.from_angle(a)
		if flip:
			dir.x = -dir.x
		draw_line(e, e + dir * 520.0, Color(1.0, 0.2, 0.2, 0.22 * sin(sweep / 0.25 * PI)), 14.0)


func _draw_wheels(power: float) -> void:
	for wheel in [WHEEL_A, WHEEL_B]:
		var w := _px(wheel)
		var glow := 0.12 + 0.35 * speed + 0.3 * charge
		draw_circle(w, 80.0 + 30.0 * speed, Color(aura_color, glow * 0.45 * power))
		for k in 3:
			var a := _wheel_angle + k * TAU / 3.0
			draw_line(w, w + Vector2.from_angle(a) * 62.0, Color(1.0, 0.85, 0.6, (0.25 + 0.5 * glow) * power), 8.0)
		draw_arc(w, 62.0, 0.0, TAU, 24, Color(1.0, 0.8, 0.5, (0.2 + 0.5 * glow) * power), 5.0)


func _draw_steam(power: float) -> void:
	# Steam leaking from the shoulders; much more when damaged or winding up.
	var amount := 0.25 + 0.6 * rage + 0.9 * charge
	for s in SHOULDERS:
		var base := _px(s)
		for k in 4:
			var u := fposmod(_time * (0.35 + 0.4 * amount) + k * 0.25, 1.0)
			var p := base + Vector2(sin(k * 3.3 + base.x) * 30.0 * u, -u * 260.0)
			draw_circle(p, 22.0 + 50.0 * u, Color(1.0, 0.85, 0.7, 0.16 * amount * (1.0 - u) * power))


func _draw_impact() -> void:
	var floor_y := 790.0
	draw_arc(Vector2(0.0, floor_y), 150.0 + 520.0 * (1.0 - impact), PI, TAU, 36, Color(1.0, 0.8, 0.5, 0.7 * impact), 18.0 * impact + 4.0)
