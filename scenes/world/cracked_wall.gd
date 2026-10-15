extends StaticBody2D

signal broken

const ROCK := preload("res://scenes/world/rock_style.gd")
const HURTBOX := preload("res://scenes/world/cracked_wall_hurtbox.gd")

@export var size: Vector2 = Vector2(40, 128)
@export var max_health: float = 25.0
@export var block_rect: Rect2 = Rect2()

var _health := 0.0
var _broken := false
var _time := 0.0
var _flash := 0.0
var _shape: CollisionShape2D
var _hurtbox: Area2D
var _hurt_shape: CollisionShape2D
var _cracks: Array = []
var _dust: CPUParticles2D
var alpha := 1.0:
	set(value):
		alpha = value
		queue_redraw()


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_health = max_health
	_build_cracks()

	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	_shape.position = size / 2.0
	add_child(_shape)

	_hurtbox = Area2D.new()
	_hurtbox.set_script(HURTBOX)
	_hurtbox.collision_layer = 16
	_hurtbox.collision_mask = 0
	_hurt_shape = CollisionShape2D.new()
	var hrect := RectangleShape2D.new()
	hrect.size = size + Vector2(140, 0)
	_hurt_shape.shape = hrect
	_hurt_shape.position = size / 2.0
	_hurtbox.add_child(_hurt_shape)
	add_child(_hurtbox)

	_dust = CPUParticles2D.new()
	_dust.position = Vector2(size.x / 2.0, 6.0)
	_dust.amount = 6
	_dust.lifetime = 2.6
	_dust.preprocess = 2.6
	_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust.emission_rect_extents = Vector2(size.x / 2.0, 2.0)
	_dust.direction = Vector2(0, 1)
	_dust.spread = 8.0
	_dust.gravity = Vector2(0, 40)
	_dust.initial_velocity_min = 4.0
	_dust.initial_velocity_max = 12.0
	_dust.scale_amount_min = 1.0
	_dust.scale_amount_max = 2.0
	_dust.color = Color(0.75, 0.68, 0.6, 0.55)
	add_child(_dust)


func open_instantly() -> void:
	_broken = true
	_shape.disabled = true
	_hurt_shape.disabled = true
	_hurtbox.monitorable = false
	_dust.emitting = false
	visible = false


func damage(amount: float, _attacker: Node = null) -> void:
	if _broken:
		return
	_health -= amount
	_flash = 1.0
	_spawn_chips(2 + int(minf(amount, 30.0) / 10.0))
	var cam := get_tree().get_first_node_in_group("main_camera")
	if cam != null and cam.has_method("shake"):
		cam.shake(2.0 if _health > 0.0 else 7.0)
	AudioManager.play_sfx("wall_hit")
	if _health <= 0.0:
		_break()
	queue_redraw()


func _break() -> void:
	_broken = true
	AudioManager.play_sfx("wall_break")
	_shape.set_deferred("disabled", true)
	_hurt_shape.set_deferred("disabled", true)
	_hurtbox.set_deferred("monitorable", false)
	_dust.emitting = false
	_spawn_chips(26)
	GameManager.hit_stop(0.08)
	broken.emit()
	var tw := create_tween()
	tw.tween_property(self, "alpha", 0.0, 0.25)
	tw.tween_callback(func(): visible = false)


func _process(delta: float) -> void:
	_time += delta
	if _flash > 0.0:
		_flash = maxf(_flash - delta * 5.0, 0.0)
	if not _broken:
		queue_redraw()


func _build_cracks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(global_position.x) * 7.0 + absf(global_position.y) * 13.0) + 1
	for k in 3:
		var pts := PackedVector2Array()
		var p := Vector2(rng.randf_range(size.x * 0.2, size.x * 0.8), size.y * (0.12 + 0.3 * k))
		pts.append(p)
		for step in 5:
			p += Vector2(rng.randf_range(-9.0, 9.0), rng.randf_range(10.0, 22.0))
			p.x = clampf(p.x, 4.0, size.x - 4.0)
			pts.append(p)
		_cracks.append(pts)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var block := block_rect
	if block.size == Vector2.ZERO:
		block = Rect2(position, size)
	var shifted := Rect2(rect.position + position, rect.size)
	var top_c := ROCK.shade_at(shifted.position.y, block)
	var bottom_c := ROCK.shade_at(shifted.end.y, block)
	top_c.a = alpha
	bottom_c.a = alpha
	draw_polygon(
		PackedVector2Array([rect.position, Vector2(rect.end.x, 0.0), rect.end, Vector2(0.0, rect.end.y)]),
		PackedColorArray([top_c, top_c, bottom_c, bottom_c]))

	var damage_ratio := 1.0 - clampf(_health / max_health, 0.0, 1.0)
	var shown := 1 + int(damage_ratio * 3.0)
	for i in mini(shown, _cracks.size()):
		var pts: PackedVector2Array = _cracks[i]
		var a := (0.38 if i == 0 and damage_ratio <= 0.0 else 0.7) * alpha
		draw_polyline(pts, Color(0.03, 0.0, 0.06, a), 2.0)
		draw_polyline(pts, Color(1.0, 0.85, 0.5, a * (0.18 + 0.14 * sin(_time * 2.2 + float(i)))), 1.0)
	draw_rect(Rect2(0.0, 0.0, 3.0, size.y), Color(0, 0, 0, 0.18 * alpha))
	draw_rect(Rect2(size.x - 3.0, 0.0, 3.0, size.y), Color(0, 0, 0, 0.18 * alpha))
	if _flash > 0.0:
		draw_rect(rect, Color(1.0, 0.95, 0.85, 0.5 * _flash * alpha))


func _spawn_chips(count: int) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var p := CPUParticles2D.new()
	p.position = position + size / 2.0
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = count
	p.lifetime = 0.9
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = size / 2.0
	p.direction = Vector2(0, -1)
	p.spread = 140.0
	p.gravity = Vector2(0, 900)
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 260.0
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 7.0
	p.color = Color(0.36, 0.3, 0.38)
	p.z_index = 6
	parent.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.4).timeout.connect(p.queue_free)
