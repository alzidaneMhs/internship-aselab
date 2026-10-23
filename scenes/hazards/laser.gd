extends Area2D

const FX := preload("res://scripts/effects/laser_fx.gd")

enum State { OFF, WARNING, ON, FADE }

@export var size: Vector2 = Vector2(16, 170):
	set(value):
		size = value
		if is_node_ready():
			_rebuild()
@export var damage: float = 15.0
@export var tick_interval: float = 0.3
@export var on_duration: float = 1.5
@export var off_duration: float = 1.5
@export var warning_duration: float = 0.7
@export var start_delay: float = 0.6
@export var mount_height: float = 800.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var tick_timer: Timer = $TickTimer

var beam_power: float = 0.0
var charge: float = 0.0
var flash: float = 0.0

var _state := State.OFF
var _state_time := 0.0
var _time := 0.0
var _light: PointLight2D
var _sparks_bottom: CPUParticles2D
var _sparks_top: CPUParticles2D


func _ready() -> void:
	_rebuild()
	_build_effects()
	tick_timer.wait_time = tick_interval
	tick_timer.timeout.connect(_on_tick)
	tick_timer.start()
	monitoring = false
	_state_time = -start_delay


func _rebuild() -> void:
	var rect := RectangleShape2D.new()
	rect.size = size
	collision_shape.shape = rect
	collision_shape.position = size / 2.0
	if _light != null:
		_light.position = Vector2(size.x / 2.0, size.y / 2.0)
		_sparks_bottom.position = Vector2(size.x / 2.0, size.y)
		_sparks_top.position = Vector2(size.x / 2.0, 0.0)
	queue_redraw()


func _build_effects() -> void:
	var cx := size.x / 2.0
	_light = FX.make_light(Color(1.0, 0.15, 0.25), 0.0, 4.0)
	_light.position = Vector2(cx, size.y / 2.0)
	add_child(_light)
	_sparks_bottom = _make_sparks(Vector2(cx, size.y), Vector2(0, -1), 75.0, 20)
	_sparks_top = _make_sparks(Vector2(cx, 0.0), Vector2(0, 1), 50.0, 8)


func _make_sparks(pos: Vector2, dir: Vector2, spread_deg: float, count: int) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = count
	p.lifetime = 0.45
	p.direction = dir
	p.spread = spread_deg
	p.gravity = Vector2(0, 700)
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 280.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 3.5
	p.color = Color(1.0, 0.55, 0.3)
	p.emitting = false
	add_child(p)
	return p


func _process(delta: float) -> void:
	_time += delta
	_state_time += delta
	match _state:
		State.OFF:
			if _state_time >= off_duration:
				_enter(State.WARNING)
		State.WARNING:
			charge = clampf(_state_time / warning_duration, 0.0, 1.0)
			if _state_time >= warning_duration:
				_enter(State.ON)
		State.ON:
			if _state_time >= on_duration:
				_enter(State.FADE)
		State.FADE:
			if _state_time >= 0.25:
				_enter(State.OFF)
	_light.energy = beam_power * (0.9 + 0.15 * sin(_time * 50.0))
	_light.visible = beam_power > 0.02
	if FX.on_screen(self, 500.0):
		queue_redraw()


func _enter(new_state: State) -> void:
	_state = new_state
	_state_time = 0.0
	match new_state:
		State.WARNING:
			charge = 0.0
			AudioManager.play_sfx_at("laser_warning", global_position, -6.0, 0.03, 1300.0)
		State.ON:
			monitoring = true
			_sparks_bottom.emitting = true
			_sparks_top.emitting = true
			flash = 1.0
			create_tween().tween_property(self, "beam_power", 1.0, 0.08)
			create_tween().tween_property(self, "flash", 0.0, 0.3)
			AudioManager.play_sfx_at("laser_fire", global_position, -3.0, 0.04, 1300.0)
		State.FADE:
			monitoring = false
			_sparks_bottom.emitting = false
			_sparks_top.emitting = false
			create_tween().tween_property(self, "beam_power", 0.0, 0.25)
		State.OFF:
			charge = 0.0
			beam_power = 0.0


func _draw() -> void:
	var cx := size.x / 2.0
	_draw_mount(cx)
	_draw_beam(cx)
	_draw_emitters(cx)


func _draw_mount(cx: float) -> void:
	if mount_height <= 0.0:
		return
	var step := 32.0
	var steps := int(ceil(mount_height / step))
	for i in steps:
		var y_bottom := -20.0 - i * step
		var y_top := y_bottom - step
		var fade := clampf(1.0 - float(i) / steps, 0.0, 1.0)
		var a := minf(1.0, fade * 2.2)
		draw_rect(Rect2(cx - 8.0, y_top, 16.0, step + 1.0), Color(0.17, 0.17, 0.23, a))
		draw_rect(Rect2(cx - 8.0, y_top, 3.0, step + 1.0), Color(0.40, 0.40, 0.5, a))
		draw_rect(Rect2(cx + 5.0, y_top, 3.0, step + 1.0), Color(0.08, 0.08, 0.12, a))
		if i % 2 == 0:
			draw_rect(Rect2(cx - 12.0, y_bottom - 10.0, 24.0, 8.0), Color(0.27, 0.27, 0.35, a))
			draw_rect(Rect2(cx - 12.0, y_bottom - 10.0, 24.0, 2.0), Color(0.5, 0.5, 0.6, a))
			draw_circle(Vector2(cx - 8.0, y_bottom - 6.0), 1.6, Color(0.7, 0.7, 0.8, a))
			draw_circle(Vector2(cx + 8.0, y_bottom - 6.0), 1.6, Color(0.7, 0.7, 0.8, a))
		var sway := sin(_time * 1.6 + i * 0.7) * 1.5
		draw_line(Vector2(cx + 12.0 + sway, y_bottom), Vector2(cx + 12.0 - sway, y_top), Color(0.05, 0.05, 0.08, a), 2.0)
	draw_rect(Rect2(cx - 14.0, -26.0, 28.0, 8.0), Color(0.27, 0.27, 0.35))
	draw_rect(Rect2(cx - 14.0, -26.0, 28.0, 2.0), Color(0.5, 0.5, 0.6))


func _draw_beam(cx: float) -> void:
	if _state == State.WARNING:
		var blink := 0.25 + 0.55 * absf(sin(_time * 16.0))
		var y := 0.0
		while y < size.y:
			draw_line(Vector2(cx, y), Vector2(cx, minf(y + 8.0, size.y)), Color(1.0, 0.55, 0.3, blink * charge), 2.0)
			y += 14.0
	if beam_power <= 0.01:
		return
	var w := size.x * beam_power * (1.0 + 0.12 * sin(_time * 60.0))
	draw_rect(Rect2(cx - w * 1.9, 0.0, w * 3.8, size.y), Color(1.0, 0.1, 0.2, 0.18 * beam_power))
	draw_rect(Rect2(cx - w * 1.1, 0.0, w * 2.2, size.y), Color(1.0, 0.2, 0.3, 0.45 * beam_power))
	draw_rect(Rect2(cx - w * 0.5, 0.0, w, size.y), Color(1.0, 0.8, 0.85, 0.95 * beam_power))
	draw_rect(Rect2(cx - w * 0.18, 0.0, w * 0.36, size.y), Color(1.0, 1.0, 1.0, beam_power))
	for i in 5:
		var py := fposmod(_time * 520.0 + i * size.y / 5.0, size.y)
		draw_rect(Rect2(cx - w * 0.9, py - 8.0, w * 1.8, 16.0), Color(1.0, 1.0, 1.0, 0.35 * beam_power))
	draw_circle(Vector2(cx, 0.0), w * 2.2, Color(1.0, 0.3, 0.4, 0.35 * beam_power))
	draw_circle(Vector2(cx, size.y), w * 2.6, Color(1.0, 0.3, 0.4, 0.4 * beam_power))
	if flash > 0.0:
		draw_rect(Rect2(cx - size.x * 3.0, 0.0, size.x * 6.0, size.y), Color(1.0, 1.0, 1.0, 0.55 * flash))


func _draw_emitters(cx: float) -> void:
	var metal := Color(0.2, 0.2, 0.27)
	var metal_light := Color(0.42, 0.42, 0.52)
	var led := Color(0.4, 0.1, 0.12)
	match _state:
		State.WARNING:
			led = Color(1.0, 0.6, 0.2).lerp(Color(1.0, 0.2, 0.1), 0.5 + 0.5 * sin(_time * 18.0))
		State.ON, State.FADE:
			led = Color(1.0, 0.85, 0.9)
	var glow := 0.0
	if _state == State.WARNING:
		glow = 8.0 + 16.0 * charge
	elif beam_power > 0.01:
		glow = 14.0 * beam_power + 8.0

	draw_rect(Rect2(cx - 22.0, -20.0, 44.0, 20.0), metal)
	draw_rect(Rect2(cx - 22.0, -20.0, 44.0, 4.0), metal_light)
	draw_rect(Rect2(cx - 22.0, -20.0, 44.0, 20.0), Color(0.08, 0.08, 0.12), false, 2.0)
	draw_rect(Rect2(cx - 8.0, -4.0, 16.0, 6.0), led)
	draw_rect(Rect2(cx - 22.0, size.y - 2.0, 44.0, 12.0), metal)
	draw_rect(Rect2(cx - 22.0, size.y - 2.0, 44.0, 3.0), metal_light)
	draw_rect(Rect2(cx - 22.0, size.y - 2.0, 44.0, 12.0), Color(0.08, 0.08, 0.12), false, 2.0)
	draw_rect(Rect2(cx - 8.0, size.y - 4.0, 16.0, 5.0), led)
	if glow > 0.0:
		draw_circle(Vector2(cx, 0.0), glow, Color(led, 0.35))
		draw_circle(Vector2(cx, size.y), glow, Color(led, 0.35))


func _on_tick() -> void:
	if _state != State.ON:
		return
	for area in get_overlapping_areas():
		if area.has_method("take_damage"):
			area.take_damage(damage * GameState.get_trap_multiplier())
