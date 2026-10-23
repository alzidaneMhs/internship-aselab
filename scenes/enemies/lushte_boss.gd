extends "res://scenes/enemies/boss_base.gd"

const PROJECTILE_SCENE := preload("res://scenes/enemies/projectile.tscn")

enum State { HOVER, ASCEND, TELEGRAPH, DIVE, RECOVER }

@export var fly_speed: float = 280.0
@export var hover_offset: Vector2 = Vector2(240.0, -150.0)
@export var light_damage: float = 15.0
@export var dive_damage: float = 25.0
@export var dive_speed: float = 950.0
@export var shoot_interval: float = 1.8
@export var heavy_interval: float = 6.5

@onready var shoot_timer: Timer = $ShootTimer
@onready var heavy_timer: Timer = $HeavyTimer
@onready var muzzle: Marker2D = $Muzzle
@onready var blade_area: Area2D = $BladeArea
@onready var fx = $Sprite2D/LushteFX

var _state := State.HOVER
var _state_time := 0.0
var _side := 1.0
var _dive_target := Vector2.ZERO
var _blade_hit := false
var _anim_time := 0.0
var _base_sprite_y := 0.0
var _base_scale := Vector2.ONE
var _ghost_timer := 0.0
var _intro_offset := 0.0
var _timers_rested := false
var _intro_boost := false
var _intro_charge := 0.0


func _ready() -> void:
	super._ready()
	_base_sprite_y = sprite.position.y
	_base_scale = sprite.scale
	_anim_time = randf() * TAU
	shoot_timer.wait_time = shoot_interval
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	shoot_timer.start()
	heavy_timer.wait_time = heavy_interval
	heavy_timer.timeout.connect(_on_heavy_timer_timeout)
	heavy_timer.start()
	blade_area.area_entered.connect(_on_blade_area_entered)


func _process(delta: float) -> void:
	super._process(delta)
	if _defeated:
		fx.visible = false
		return
	_anim_time += delta
	var stunned := stun_remaining > 0.0
	var boosting := not stunned and (_state == State.ASCEND or _state == State.DIVE)

	var bob := sin(_anim_time * 2.2) * 8.0 + sin(_anim_time * 4.7) * 2.0
	if stunned:
		bob = 14.0
	var target_x := 0.0
	if _state == State.TELEGRAPH and not stunned:
		target_x = randf_range(-3.0, 3.0)
	sprite.position = sprite.position.lerp(Vector2(target_x, _base_sprite_y + bob + _intro_offset), minf(1.0, 12.0 * delta))
	var lean := clampf(velocity.x / 700.0, -0.45, 0.45)
	var wobble := sin(_anim_time * 1.7) * 0.03
	if stunned:
		wobble = sin(_anim_time * 3.0) * 0.1
	sprite.rotation = lerp_angle(sprite.rotation, lean + wobble, minf(1.0, 10.0 * delta))
	var pulse := sin(_anim_time * (15.0 if boosting else 9.0)) * 0.02
	sprite.scale = _base_scale * Vector2(1.0 + pulse, 1.0 - pulse * 0.5)

	if boosting:
		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			_ghost_timer = 0.045
			FX.spawn_afterimage(sprite, Color(0.5, 0.85, 1.0, 0.5), 0.3)

	if Cutscene.active:
		if not _timers_rested:
			shoot_timer.stop()
			heavy_timer.stop()
			_timers_rested = true
	elif _timers_rested:
		shoot_timer.start()
		heavy_timer.start()
		_timers_rested = false
	var shot := 0.0
	if not Cutscene.active and not shoot_timer.is_stopped() and _state == State.HOVER and not stunned and _player_in_range() and shoot_timer.time_left < 0.4:
		shot = 1.0 - shoot_timer.time_left / 0.4
	fx.flip = sprite.flip_h
	fx.stunned = stunned
	fx.boosting = boosting or _intro_boost
	fx.move_dir = velocity
	fx.charge = maxf(clampf(_state_time / 0.55, 0.0, 1.0) if _state == State.TELEGRAPH and not stunned else 0.0, _intro_charge)
	fx.shot_charge = shot
	fx.muzzle = (muzzle.position - sprite.position) / _base_scale.x


func _update_ai(delta: float) -> void:
	if not _player_in_range() and _state == State.HOVER:
		velocity = Vector2.ZERO
		return
	_state_time += delta
	var player_pos := player_ref.global_position
	match _state:
		State.HOVER:
			var side_now := signf(global_position.x - player_pos.x)
			if side_now != 0.0:
				_side = side_now
			var target := player_pos + Vector2(_side * absf(hover_offset.x), hover_offset.y)
			velocity = (target - global_position).limit_length(fly_speed * 1.2) * 3.0
			velocity = velocity.limit_length(fly_speed)
			_face(player_pos.x)
		State.ASCEND:
			var target := Vector2(player_pos.x, player_pos.y - 420.0)
			velocity = (target - global_position).limit_length(fly_speed * 2.0) * 4.0
			velocity = velocity.limit_length(fly_speed * 2.0)
			if _state_time > 0.9 or global_position.distance_to(target) < 40.0:
				_enter_state(State.TELEGRAPH)
		State.TELEGRAPH:
			velocity = Vector2.ZERO
			_face(player_pos.x)
			_dive_target = player_pos + Vector2(0, -40)
			if _state_time > 0.55:
				_enter_state(State.DIVE)
		State.DIVE:
			var to_target := _dive_target - global_position
			velocity = to_target.normalized() * dive_speed
			if to_target.length() < 40.0 or is_on_floor() or _state_time > 1.0:
				_enter_state(State.RECOVER)
		State.RECOVER:
			velocity.x = 0.0
			if _state_time > 1.2:
				_enter_state(State.HOVER)


func _enter_state(new_state: State) -> void:
	_state = new_state
	_state_time = 0.0
	match new_state:
		State.TELEGRAPH:
			AudioManager.play_sfx("lushte_telegraph", -2.0, 0.05)
			var tw := create_tween()
			tw.tween_property(sprite, "self_modulate", Color(3.0, 0.6, 0.6), 0.25)
			tw.tween_property(sprite, "self_modulate", Color.WHITE, 0.25)
		State.DIVE:
			AudioManager.play_sfx("lushte_dive", 0.0, 0.05)
			_blade_hit = false
			blade_area.monitoring = true
		State.RECOVER:
			blade_area.set_deferred("monitoring", false)
			velocity = Vector2.ZERO
			if is_on_floor():
				FX.spawn_dust(get_parent(), global_position, 12, Color(0.75, 0.82, 0.9, 0.7), 50.0)
				get_tree().call_group("main_camera", "shake", 5.0)
				AudioManager.play_sfx("lushte_impact", -2.0, 0.08)
		State.HOVER:
			blade_area.set_deferred("monitoring", false)


func _face(player_x: float) -> void:
	var player_is_right := player_x > global_position.x
	sprite.flip_h = player_is_right
	muzzle.position.x = absf(muzzle.position.x) * (1.0 if player_is_right else -1.0)


func _on_shoot_timer_timeout() -> void:
	if Cutscene.active or _defeated or stun_remaining > 0.0 or _state != State.HOVER or not _player_in_range():
		return
	var dir := (player_ref.global_position + PLAYER_CENTER) - muzzle.global_position
	if dir.length() < 1.0:
		return
	var proj := PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = muzzle.global_position
	proj.launch(dir, 460.0, light_damage)
	fx.flash = 1.0
	AudioManager.play_sfx("lushte_shoot")


func _on_heavy_timer_timeout() -> void:
	if Cutscene.active or _defeated or stun_remaining > 0.0 or _state != State.HOVER or not _player_in_range():
		return
	AudioManager.play_sfx("lushte_ascend", -2.0, 0.05)
	_enter_state(State.ASCEND)


func _on_stun_start() -> void:
	_state = State.HOVER
	_state_time = 0.0
	blade_area.set_deferred("monitoring", false)
	velocity = Vector2.ZERO


func _on_stun_end() -> void:
	_state = State.HOVER
	_state_time = 0.0


func _on_blade_area_entered(area: Area2D) -> void:
	if _blade_hit or not area.has_method("take_damage"):
		return
	_blade_hit = true
	area.take_damage(dive_damage, self)


func _on_defeated_state() -> void:
	var st := get_node_or_null("ShootTimer") as Timer
	var ht := get_node_or_null("HeavyTimer") as Timer
	if st != null:
		st.stop()
	if ht != null:
		ht.stop()
	var blade := get_node_or_null("BladeArea") as Area2D
	if blade != null:
		blade.set_deferred("monitoring", false)


func play_intro() -> void:
	_intro_offset = 90.0
	_intro_boost = true
	sprite.modulate.a = 0.0
	reveal()
	FX.spawn_screen_flash(get_tree(), Color(0.6, 0.9, 1.0, 0.3), 0.6)
	get_tree().call_group("main_camera", "shake", 4.0)
	AudioManager.play_sfx("lushte_ascend")
	var rise := create_tween().set_parallel()
	rise.tween_property(self, "_intro_offset", 0.0, 1.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	rise.tween_property(sprite, "modulate:a", 1.0, 0.9)
	await Cutscene.wait(1.1)
	var flare := create_tween()
	flare.tween_property(self, "_intro_charge", 1.0, 0.6)
	await flare.finished
	FX.spawn_screen_flash(get_tree(), Color(0.7, 0.95, 1.0, 0.5), 0.5)
	get_tree().call_group("main_camera", "shake", 9.0)
	AudioManager.play_sfx("lushte_roar")
	await Cutscene.wait(0.5)
	_intro_boost = false
	create_tween().tween_property(self, "_intro_charge", 0.0, 0.4)
