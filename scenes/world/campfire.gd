extends Area2D

const FX := preload("res://scripts/effects/laser_fx.gd")
const SHEET := preload("res://assets/sprites/props/campfire.png")
const KIT := preload("res://scripts/ui/ui_kit.gd")

@export var checkpoint_id: String = ""
@export var stage_scene_path: String = ""
@export var heal_amount: float = 1.0
@export var heal_interval: float = 1.0
@export var rest_delay: float = 0.5

var _sprite: Sprite2D
var _glow: Sprite2D
var _embers: CPUParticles2D
var _smoke: CPUParticles2D
var _hint: Label
var _player: Node2D
var _health: Node

var _time := 0.0
var _frame_t := 0.0
var _rest := 0.0
var _heal_t := 0.0
var _healing := false
var _pulse := 0.0
var _activated := false


func _ready() -> void:
	collision_layer = 128
	collision_mask = 2
	_build_visuals()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _build_visuals() -> void:
	var glow_mat := CanvasItemMaterial.new()
	glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	_glow = Sprite2D.new()
	_glow.texture = FX.get_glow_texture()
	_glow.position = Vector2(0.0, -62.0)
	_glow.scale = Vector2(7.0, 5.5)
	_glow.modulate = Color(1.0, 0.55, 0.2, 0.5)
	_glow.material = glow_mat
	_glow.z_index = -1
	add_child(_glow)

	_smoke = CPUParticles2D.new()
	_smoke.position = Vector2(0.0, -110.0)
	_smoke.amount = 8
	_smoke.lifetime = 3.6
	_smoke.preprocess = 3.6
	_smoke.direction = Vector2(0.15, -1.0)
	_smoke.spread = 12.0
	_smoke.gravity = Vector2.ZERO
	_smoke.initial_velocity_min = 14.0
	_smoke.initial_velocity_max = 26.0
	_smoke.scale_amount_min = 7.0
	_smoke.scale_amount_max = 13.0
	_smoke.local_coords = false
	var smoke_ramp := Gradient.new()
	smoke_ramp.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	smoke_ramp.colors = PackedColorArray([Color(0.7, 0.65, 0.75, 0.0), Color(0.7, 0.65, 0.75, 0.2), Color(0.5, 0.48, 0.6, 0.0)])
	_smoke.color_ramp = smoke_ramp
	_smoke.z_index = 2
	add_child(_smoke)

	_sprite = Sprite2D.new()
	_sprite.texture = SHEET
	_sprite.hframes = 4
	_sprite.offset = Vector2(0.0, -26.0)
	_sprite.scale = Vector2(3.0, 3.0)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)

	_embers = CPUParticles2D.new()
	_embers.position = Vector2(0.0, -60.0)
	_embers.amount = 24
	_embers.lifetime = 2.2
	_embers.preprocess = 2.2
	_embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_embers.emission_rect_extents = Vector2(26.0, 6.0)
	_embers.direction = Vector2(0.0, -1.0)
	_embers.spread = 28.0
	_embers.gravity = Vector2(0.0, -14.0)
	_embers.initial_velocity_min = 26.0
	_embers.initial_velocity_max = 78.0
	_embers.scale_amount_min = 2.0
	_embers.scale_amount_max = 4.5
	_embers.local_coords = false
	var ember_ramp := Gradient.new()
	ember_ramp.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	ember_ramp.colors = PackedColorArray([Color(1.0, 0.9, 0.5, 0.0), Color(1.0, 0.6, 0.2, 0.95), Color(1.0, 0.3, 0.1, 0.0)])
	_embers.color_ramp = ember_ramp
	_embers.material = glow_mat
	_embers.z_index = 2
	add_child(_embers)

	_hint = Label.new()
	_hint.text = "Diam di dekat api untuk memulihkan HP"
	_hint.add_theme_font_size_override("font_size", 16)
	_hint.add_theme_color_override("font_color", KIT.TEXT)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.position = Vector2(-180.0, -220.0)
	_hint.size = Vector2(360.0, 28.0)
	_hint.z_index = 20
	_hint.visible = false
	add_child(_hint)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player = body
	_health = body.get_node_or_null("Health")
	if not _activated and checkpoint_id != "":
		_activated = true
		GameState.set_checkpoint(stage_scene_path, checkpoint_id, global_position + Vector2(-50.0, -4.0))
		GameState.save_game()
		GameState.toast("Checkpoint tersimpan di api unggun")
		AudioManager.play_sfx("checkpoint")
		_pulse = 1.0
		_flare_sparks()


func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null
		_health = null
		_healing = false
		_rest = 0.0
		_heal_t = 0.0
		_hint.visible = false


func _physics_process(delta: float) -> void:
	_tick_healing(delta)


func _tick_healing(delta: float) -> void:
	if _player == null or _health == null or Cutscene.active:
		_healing = false
		return
	var hurt: bool = _health.current_health < _health.max_health
	var still: bool = _player.is_on_floor() and absf(_player.velocity.x) < 12.0 and not _player.controls_locked
	_hint.visible = hurt and not _healing
	if hurt and still:
		_rest += delta
		if _rest >= rest_delay:
			_healing = true
			_heal_t += delta
			if _heal_t >= heal_interval:
				_heal_t = 0.0
				_health.heal(heal_amount)
				_pulse = 1.0
				FX.spawn_damage_number(get_parent(), _player.global_position + Vector2(0.0, -135.0), "+%d" % int(heal_amount), Color(0.5, 1.0, 0.65), 28)
				_heal_sparkles()
				AudioManager.play_sfx("heal_tick")
	else:
		_rest = 0.0
		_healing = false
		_heal_t = 0.0


func _process(delta: float) -> void:
	_time += delta
	_pulse = maxf(_pulse - delta * 1.6, 0.0)
	_frame_t += delta
	if _frame_t >= 0.12:
		_frame_t = 0.0
		_sprite.frame = (_sprite.frame + 1 + randi() % 2) % 4
	var flicker := 0.78 + 0.22 * sin(_time * 11.0) * sin(_time * 5.3)
	_glow.modulate = Color(1.0, 0.55, 0.2, (0.38 + 0.1 * float(_healing)) * flicker + 0.25 * _pulse)
	_glow.scale = Vector2(7.0, 5.5) * (0.95 + 0.07 * flicker + 0.18 * _pulse)
	if FX.on_screen(self, 700.0):
		queue_redraw()


func _draw() -> void:
	# A faint warm ring on the ground marks the resting spot.
	var ring := PackedVector2Array()
	var near := 1.0 if _player != null else 0.0
	for i in 41:
		var a := i * TAU / 40.0
		ring.append(Vector2(cos(a) * 118.0, -2.0 + sin(a) * 15.0))
	draw_polyline(ring, Color(1.0, 0.65, 0.25, 0.16 + 0.14 * near + 0.3 * _pulse), 3.0)
	for k in 6:
		var a := k * TAU / 6.0 + _time * 0.4
		var p := Vector2(cos(a) * 118.0, -2.0 + sin(a) * 15.0)
		draw_circle(p, 3.0, Color(1.0, 0.8, 0.4, 0.3 + 0.3 * near))
	if _player != null and _healing:
		var local := to_local(_player.global_position) + Vector2(0.0, -52.0)
		var breathe := 0.5 + 0.5 * sin(_time * 3.2)
		draw_circle(local, 66.0 + 6.0 * breathe, Color(0.4, 1.0, 0.6, 0.1 + 0.07 * breathe))
		draw_arc(local, 56.0 + 22.0 * _pulse, 0.0, TAU, 28, Color(0.55, 1.0, 0.7, 0.3 + 0.5 * _pulse), 3.0)
		for k in 5:
			var a := _time * 1.6 + k * TAU / 5.0
			var rise := fposmod(_time * 0.7 + k * 0.2, 1.0)
			var p := local + Vector2(cos(a) * 40.0, 40.0 - rise * 90.0)
			draw_circle(p, 3.0 * (1.0 - rise) + 1.0, Color(0.6, 1.0, 0.75, 0.8 * (1.0 - rise)))


func _heal_sparkles() -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false
	p.explosiveness = 0.9
	p.amount = 12
	p.lifetime = 0.9
	p.direction = Vector2(0.0, -1.0)
	p.spread = 70.0
	p.gravity = Vector2(0.0, -30.0)
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 100.0
	p.scale_amount_min = 2.5
	p.scale_amount_max = 5.0
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(0.6, 1.0, 0.75, 0.95), Color(0.4, 1.0, 0.6, 0.0)])
	p.color_ramp = ramp
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	p.z_index = 5
	get_parent().add_child(p)
	p.global_position = _player.global_position + Vector2(0.0, -50.0)
	p.emitting = true
	get_tree().create_timer(1.4).timeout.connect(p.queue_free)


func _flare_sparks() -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false
	p.explosiveness = 0.95
	p.amount = 30
	p.lifetime = 1.2
	p.direction = Vector2(0.0, -1.0)
	p.spread = 80.0
	p.gravity = Vector2(0.0, 60.0)
	p.initial_velocity_min = 100.0
	p.initial_velocity_max = 280.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.5
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(1.0, 0.9, 0.5, 1.0), Color(1.0, 0.35, 0.1, 0.0)])
	p.color_ramp = ramp
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	p.z_index = 5
	add_child(p)
	p.position = Vector2(0.0, -60.0)
	p.emitting = true
	get_tree().create_timer(1.6).timeout.connect(p.queue_free)
