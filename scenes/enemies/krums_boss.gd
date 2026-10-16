extends "res://scenes/enemies/boss_base.gd"

const PROJECTILE_SCENE := preload("res://scenes/enemies/projectile.tscn")
const SHOCKWAVE := preload("res://scenes/enemies/shockwave.gd")
const SLAM_FX := preload("res://scenes/enemies/scott_slam_fx.gd")
const MARKER := preload("res://scenes/enemies/target_marker.gd")

enum State { WALK, LIGHT_WINDUP, LIGHT_STRIKE, HEAVY_WINDUP, HEAVY_CHARGE, STOMP_WINDUP, STOMP, LEAP_WINDUP, LEAP_AIR, RECOVER }

@export var walk_speed: float = 95.0
@export var light_damage: float = 25.0
@export var heavy_damage: float = 45.0
@export var stomp_damage: float = 30.0
@export var cannon_damage: float = 18.0
@export var charge_speed: float = 720.0
@export var light_range: float = 170.0
@export var heavy_every: int = 3
@export var stomp_every: int = 4
@export var cannon_interval: float = 3.0
@export var leap_damage: float = 35.0
@export var leap_every: int = 5
@export var rage_ratio: float = 0.55

@onready var strike_area: Area2D = $StrikeArea
@onready var charge_area: Area2D = $ChargeArea
@onready var muzzle: Marker2D = $Muzzle
@onready var fx = $Sprite2D/KrumsFX

var _state := State.WALK
var _state_time := 0.0
var _charge_dir := 1.0
var _attack_count := 0
var _hit_landed := false
var _cannon_cd := 2.0
var _anim_time := 0.0
var _base_sprite_y := 0.0
var _base_scale := Vector2.ONE
var _ghost_timer := 0.0
var _dust_timer := 0.0
var _step_timer := 0.0
var _intro_offset := 0.0
var _intro_charge := 0.0
var _intro_walk := false
var _charges_left := 0
var _ambient_cannon := 5.0
var _leap_marker_made := false
var _leap_floor_y := 0.0


func _ready() -> void:
	super._ready()
	strike_area.area_entered.connect(_on_strike_area_entered)
	charge_area.area_entered.connect(_on_charge_area_entered)

	_base_sprite_y = sprite.position.y
	_base_scale = sprite.scale
	_anim_time = randf() * TAU


func _process(delta: float) -> void:
	super._process(delta)
	if _defeated:
		fx.visible = false
		return
	_anim_time += delta
	var stunned := stun_remaining > 0.0
	var face := 1.0 if sprite.flip_h else -1.0
	var moving := absf(velocity.x) > 10.0 or _intro_walk
	var target_pos := Vector2(0.0, _base_sprite_y)
	var target_rot := 0.0
	var target_scale := _base_scale
	var charge := 0.0
	var aura := Color(1.0, 0.45, 0.15)

	if stunned:
		target_pos.y += 14.0
		target_rot = sin(_anim_time * 3.0) * 0.07
		target_scale = _base_scale * Vector2(1.04, 0.95)
	else:
		match _state:
			State.WALK:
				var step := sin(_anim_time * 6.0)
				if moving:
					target_pos.y -= absf(step) * 5.0
					target_rot = step * 0.02
				var breath := sin(_anim_time * 2.0) * 0.012
				target_scale = _base_scale * Vector2(1.0 - breath * 0.5, 1.0 + breath)
			State.LIGHT_WINDUP:
				target_rot = -face * 0.12
				target_pos.x = -face * 10.0
			State.LIGHT_STRIKE:
				target_rot = face * 0.16
				target_pos.x = face * 20.0
			State.HEAVY_WINDUP:
				target_pos.y += 12.0
				target_pos.x = randf_range(-3.0, 3.0)
				target_scale = _base_scale * Vector2(1.06, 0.93)
				charge = clampf(_state_time / 0.9, 0.0, 1.0)
				aura = Color(1.0, 0.2, 0.15)
			State.HEAVY_CHARGE:
				target_rot = face * 0.2
				target_pos.x = face * 14.0
				charge = 0.6
				aura = Color(1.0, 0.3, 0.15)
			State.STOMP_WINDUP:
				var k := clampf(_state_time / 0.85, 0.0, 1.0)
				target_pos.y -= 26.0 * k
				target_scale = _base_scale * Vector2(0.97, 1.05)
				charge = k
				aura = Color(1.0, 0.7, 0.2)
			State.STOMP:
				target_pos.y += 6.0
				target_scale = _base_scale * Vector2(1.14, 0.88)
			State.RECOVER:
				target_scale = _base_scale * Vector2(1.0, 1.0 + sin(_anim_time * 9.0) * 0.015)
	target_pos.y += _intro_offset
	sprite.position = sprite.position.lerp(target_pos, minf(1.0, 14.0 * delta))
	sprite.rotation = lerp_angle(sprite.rotation, target_rot, minf(1.0, 10.0 * delta))
	sprite.scale = sprite.scale.lerp(target_scale, minf(1.0, 12.0 * delta))

	if not stunned and _state == State.WALK and moving and is_on_floor():
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = 0.52
			FX.spawn_dust(get_parent(), global_position + Vector2(-face * 30.0, 0.0), 5, Color(0.7, 0.62, 0.55, 0.6), 36.0)
			get_tree().call_group("main_camera", "shake", 1.6)
	if not stunned and _state == State.HEAVY_CHARGE:
		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			_ghost_timer = 0.045
			FX.spawn_afterimage(sprite, Color(1.0, 0.55, 0.3, 0.45), 0.3)
		_dust_timer -= delta
		if _dust_timer <= 0.0:
			_dust_timer = 0.07
			FX.spawn_dust(get_parent(), global_position + Vector2(-face * 70.0, 0.0), 5, Color(0.75, 0.65, 0.55, 0.7), 30.0)

	var hp_ratio := 1.0
	if health.max_health > 0.0:
		hp_ratio = health.current_health / health.max_health
	fx.flip = sprite.flip_h
	fx.stunned = stunned
	fx.charge = maxf(charge, _intro_charge)
	fx.aura_color = aura
	fx.speed = clampf(absf(velocity.x) / charge_speed, 0.0, 1.0)
	fx.rage = clampf(1.0 - hp_ratio, 0.0, 1.0)


func _raging() -> bool:
	return health.max_health > 0.0 and health.current_health / health.max_health <= rage_ratio


func _pace() -> float:
	return 1.35 if _raging() else 1.1


func _update_ai(delta: float) -> void:
	if not _player_in_range():
		velocity.x = 0.0
		return
	var pace := _pace()
	_state_time += delta * pace
	var dx := player_ref.global_position.x - global_position.x
	var dir := signf(dx) if dx != 0.0 else 1.0
	_ambient_cannon -= delta
	if _ambient_cannon <= 0.0 and (_state == State.WALK or _state == State.RECOVER):
		_ambient_cannon = 4.2 if _raging() else 6.0
		_fire_cannon()
	match _state:
		State.WALK:
			sprite.flip_h = dx > 0.0
			muzzle.position.x = absf(muzzle.position.x) * dir
			if absf(dx) > light_range:
				velocity.x = dir * walk_speed * pace
			else:
				velocity.x = 0.0
			_cannon_cd -= delta
			if _cannon_cd <= 0.0 and player_ref.global_position.y < global_position.y - 120.0:
				_cannon_cd = cannon_interval
				_fire_cannon()
			if _state_time > 1.5:
				_attack_count += 1
				if _attack_count % leap_every == 0:
					_enter_state(State.LEAP_WINDUP)
				elif _attack_count % stomp_every == 0:
					_enter_state(State.STOMP_WINDUP)
				elif _attack_count % heavy_every == 0:
					_charge_dir = dir
					_charges_left = 2 if _raging() else 1
					_enter_state(State.HEAVY_WINDUP)
				elif absf(dx) <= light_range * 1.3:
					_enter_state(State.LIGHT_WINDUP)
		State.LIGHT_WINDUP:
			velocity.x = 0.0
			if _state_time > 0.45:
				_enter_state(State.LIGHT_STRIKE)
		State.LIGHT_STRIKE:
			velocity.x = 0.0
			if _state_time > 0.18:
				_enter_state(State.RECOVER)
		State.HEAVY_WINDUP:
			velocity.x = 0.0
			if _state_time > 0.9:
				_enter_state(State.HEAVY_CHARGE)
		State.HEAVY_CHARGE:
			velocity.x = _charge_dir * charge_speed * (1.15 if _raging() else 1.0)
			if _state_time > 0.6 or (is_on_wall() and _state_time > 0.3):
				_charges_left -= 1
				get_tree().call_group("main_camera", "shake", 6.0)
				if _charges_left > 0:
					_charge_dir = -_charge_dir
					sprite.flip_h = _charge_dir > 0.0
					_hit_landed = false
					_state_time = 0.15
				else:
					_enter_state(State.RECOVER)
		State.STOMP_WINDUP:
			velocity.x = 0.0
			if _state_time > 0.85:
				_enter_state(State.STOMP)
		State.STOMP:
			velocity.x = 0.0
			if _state_time > 0.3:
				_enter_state(State.RECOVER)
		State.LEAP_WINDUP:
			velocity.x = 0.0
			sprite.flip_h = dx > 0.0
			if _state_time > 0.6:
				_leap_floor_y = global_position.y
				velocity.y = -1050.0
				velocity.x = clampf(dx * 1.6, -760.0, 760.0)
				_leap_marker_made = false
				_enter_state(State.LEAP_AIR)
		State.LEAP_AIR:
			if not _leap_marker_made and _state_time > 0.1:
				_leap_marker_made = true
				var m = Node2D.new()
				m.set_script(MARKER)
				m.radius = 170.0
				m.duration = 0.5
				get_tree().current_scene.add_child(m)
				m.global_position = Vector2(clampf(player_ref.global_position.x, arena_left, arena_right), _leap_floor_y)
			if _state_time > 0.25 and is_on_floor():
				_land_leap()
				_enter_state(State.RECOVER)
		State.RECOVER:
			velocity.x = 0.0
			if _state_time > 0.75:
				_enter_state(State.WALK)


func _enter_state(new_state: State) -> void:
	_state = new_state
	_state_time = 0.0
	_hit_landed = false
	strike_area.set_deferred("monitoring", new_state == State.LIGHT_STRIKE)
	charge_area.set_deferred("monitoring", new_state == State.HEAVY_CHARGE)
	match new_state:
		State.LIGHT_WINDUP:
			var tw := create_tween()
			tw.tween_property(sprite, "self_modulate", Color(2.0, 1.6, 0.6), 0.2)
			tw.tween_property(sprite, "self_modulate", Color.WHITE, 0.2)
		State.HEAVY_WINDUP:
			var tw2 := create_tween()
			tw2.tween_property(sprite, "self_modulate", Color(3.0, 0.5, 0.5), 0.45)
			tw2.tween_property(sprite, "self_modulate", Color.WHITE, 0.45)
		State.STOMP_WINDUP:
			var tw3 := create_tween()
			tw3.tween_property(sprite, "self_modulate", Color(3.0, 1.4, 0.4), 0.4)
			tw3.tween_property(sprite, "self_modulate", Color(1.5, 0.8, 0.4), 0.2)
			tw3.tween_property(sprite, "self_modulate", Color.WHITE, 0.2)
		State.STOMP:
			_do_stomp()


func _land_leap() -> void:
	get_tree().call_group("main_camera", "shake", 14.0)
	var spectacle = Node2D.new()
	spectacle.set_script(SLAM_FX)
	spectacle.power = 0.8
	get_parent().add_child(spectacle)
	spectacle.global_position = global_position
	FX.spawn_dust(get_parent(), global_position + Vector2(-80.0, 0.0), 12, Color(0.75, 0.65, 0.55, 0.8), 50.0)
	FX.spawn_dust(get_parent(), global_position + Vector2(80.0, 0.0), 12, Color(0.75, 0.65, 0.55, 0.8), 50.0)
	if player_ref != null and absf(player_ref.global_position.x - global_position.x) < 180.0 and absf(player_ref.global_position.y - global_position.y) < 160.0:
		var hurt := player_ref.get_node_or_null("HurtBox")
		if hurt != null and hurt.has_method("take_damage"):
			hurt.take_damage(leap_damage, self)
	_spawn_waves(stomp_damage * 0.8, 1.0)
	AudioManager.play_sfx("krums_stomp")


func _spawn_waves(dmg: float, power: float) -> void:
	for wave_dir in [-1.0, 1.0]:
		var wave = Area2D.new()
		wave.set_script(SHOCKWAVE)
		wave.direction = wave_dir
		wave.damage = dmg
		wave.speed = 600.0 if _raging() else 540.0
		wave.power = power
		wave.source = self
		wave.min_x = arena_left - 40.0
		wave.max_x = arena_right + 40.0
		get_parent().add_child(wave)
		wave.global_position = global_position + Vector2(wave_dir * 70.0, 0.0)


func _stomp_aftershock() -> void:
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree() or _defeated or stun_remaining > 0.0:
		return
	get_tree().call_group("main_camera", "shake", 8.0)
	_spawn_waves(stomp_damage * 0.8, 0.9)


func _do_stomp() -> void:
	if _raging():
		_stomp_aftershock()
	for wave_dir in [-1.0, 1.0]:
		var wave = Area2D.new()
		wave.set_script(SHOCKWAVE)
		wave.direction = wave_dir
		wave.damage = stomp_damage
		wave.source = self
		wave.min_x = arena_left - 40.0
		wave.max_x = arena_right + 40.0
		get_parent().add_child(wave)
		wave.global_position = global_position + Vector2(wave_dir * 70.0, 0.0)
	get_tree().call_group("main_camera", "shake", 12.0)
	fx.impact = 1.0
	FX.spawn_dust(get_parent(), global_position + Vector2(-90.0, 0.0), 14, Color(0.75, 0.65, 0.55, 0.8), 50.0)
	FX.spawn_dust(get_parent(), global_position + Vector2(90.0, 0.0), 14, Color(0.75, 0.65, 0.55, 0.8), 50.0)
	AudioManager.play_sfx("krums_stomp")


func _fire_cannon() -> void:
	var shots := 5 if _raging() else 3
	for i in shots:
		if _defeated or stun_remaining > 0.0 or not is_inside_tree() or Cutscene.active:
			return
		var dir := (player_ref.global_position + PLAYER_CENTER) - muzzle.global_position
		if dir.length() > 1.0:
			var proj := PROJECTILE_SCENE.instantiate()
			get_tree().current_scene.add_child(proj)
			proj.global_position = muzzle.global_position
			proj.launch(dir.rotated(randf_range(-0.06, 0.06)), 560.0, cannon_damage)
			AudioManager.play_sfx("krums_cannon")
		await get_tree().create_timer(0.18).timeout


func _on_strike_area_entered(area: Area2D) -> void:
	if _hit_landed or not area.has_method("take_damage"):
		return
	_hit_landed = true
	area.take_damage(light_damage, self)


func _on_charge_area_entered(area: Area2D) -> void:
	if _hit_landed or not area.has_method("take_damage"):
		return
	_hit_landed = true
	area.take_damage(heavy_damage, self)


func _on_defeated_state() -> void:
	var s := get_node_or_null("StrikeArea") as Area2D
	var c := get_node_or_null("ChargeArea") as Area2D
	if s != null:
		s.set_deferred("monitoring", false)
	if c != null:
		c.set_deferred("monitoring", false)


func _on_stun_start() -> void:
	_enter_state(State.RECOVER)


func _on_stun_end() -> void:
	_enter_state(State.WALK)


func play_intro() -> void:
	var target_x := global_position.x
	global_position.x = arena_right + 380.0
	sprite.flip_h = false
	reveal()
	_intro_walk = true
	var march := create_tween()
	march.tween_property(self, "global_position:x", target_x, 2.4)
	await march.finished
	_intro_walk = false
	sprite.flip_h = false
	await Cutscene.wait(0.3)
	var up := create_tween()
	up.tween_property(self, "_intro_offset", -52.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await up.finished
	var down := create_tween()
	down.tween_property(self, "_intro_offset", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await down.finished
	var spectacle = Node2D.new()
	spectacle.set_script(SLAM_FX)
	spectacle.power = 1.0
	get_parent().add_child(spectacle)
	spectacle.global_position = global_position
	FX.spawn_dust(get_parent(), global_position + Vector2(-70.0, 0.0), 14, Color(0.75, 0.65, 0.55, 0.8), 50.0)
	FX.spawn_dust(get_parent(), global_position + Vector2(70.0, 0.0), 14, Color(0.75, 0.65, 0.55, 0.8), 50.0)
	get_tree().call_group("main_camera", "shake", 18.0)
	FX.spawn_screen_flash(get_tree(), Color(1.0, 0.8, 0.5, 0.3), 0.35)
	await Cutscene.wait(0.45)
	var roar := create_tween()
	roar.tween_property(self, "_intro_charge", 1.0, 0.5)
	await roar.finished
	FX.spawn_screen_flash(get_tree(), Color(1.0, 0.6, 0.3, 0.45), 0.5)
	get_tree().call_group("main_camera", "shake", 10.0)
	await Cutscene.wait(0.6)
	create_tween().tween_property(self, "_intro_charge", 0.0, 0.5)
