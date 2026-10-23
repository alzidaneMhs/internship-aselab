extends "res://scenes/enemies/boss_base.gd"

const PROJECTILE_SCENE := preload("res://scenes/enemies/projectile.tscn")
const SHOCKWAVE := preload("res://scenes/enemies/shockwave.gd")
const BEAM := preload("res://scenes/enemies/scott_beam.gd")
const PLASMA := preload("res://scenes/enemies/scott_plasma.gd")
const ROCKET := preload("res://scenes/enemies/scott_rocket.gd")
const MARKER := preload("res://scenes/enemies/target_marker.gd")
const SLAM_FX := preload("res://scenes/enemies/scott_slam_fx.gd")
const FINAL_UI := preload("res://scenes/ui/scott_final_ui.gd")
const SECRET_STAGE := "res://scenes/levels/stage_13.tscn"

const CENTER_PX := Vector2(469.0, 540.0)
const LOW_MUZZLE_PX := Vector2(125.0, 300.0)
const TOP_MUZZLE_PX := Vector2(140.0, 125.0)
const TURRET_PX := Vector2(500.0, 70.0)

const FINAL_RATIO := 0.2
const FINAL_DURATION := 10.0
const EXHAUST_TIME := 7.0
const INTRO_TIME := 2.6

enum State {
	WALK, BULLET_AIM, BULLET_FIRE, LASER, CHARGE_WIND,
	JUMP_WIND, JUMP_RISE, JUMP_HOVER, JUMP_FALL, JUMP_LAND,
	ROCKETS, RECOVER, FINAL_INTRO, FINAL_ASSAULT,
}
enum Attack { BULLETS, LASER, CHARGE, JUMP, ROCKETS }

@export var walk_speed: float = 120.0
@export var keep_min: float = 380.0
@export var keep_max: float = 720.0
@export var bullet_damage: float = 12.0
@export var laser_damage: float = 32.0
@export var plasma_damage: float = 45.0
@export var slam_damage: float = 45.0
@export var wave_damage: float = 28.0
@export var rocket_damage: float = 36.0
@export var jump_height: float = 540.0

@onready var low_muzzle: Marker2D = $LowMuzzle
@onready var top_muzzle: Marker2D = $TopMuzzle
@onready var turret: Marker2D = $Turret
@onready var fx = $Sprite2D/ScottFX

var _state := State.WALK
var _state_time := 0.0
var _bag: Array = []
var _last_attack := -1
var _shots_left := 0
var _shot_timer := 0.0
var _jump_start_y := 0.0
var _hit_landed := false
var _marker_made := false
var _rocket_idx := 0
var _rocket_count := 0
var _laser_total := 0.0
var _recoil := 0.0

var _final_pending := false
var _final_started := false
var _final_active := false
var _assault_running := false
var _final_done := false
var _final_time := 0.0
var _final_events: Array = []
var _rain_timer := 0.0
var _final_ui
var _final_tint := false

var _intro_offset := 0.0
var _intro_rage := 0.0
var _dying_fx := false

var _hurt_shape: CollisionShape2D
var _anim_time := 0.0
var _base_sprite_y := 0.0
var _base_scale := Vector2.ONE
var _ghost_timer := 0.0
var _step_timer := 0.0


func _ready() -> void:
	super._ready()
	_base_sprite_y = sprite.position.y
	_base_scale = sprite.scale
	_anim_time = randf() * TAU
	_state_time = -1.0
	_hurt_shape = hurtbox.get_node("CollisionShape2D") as CollisionShape2D
	var hurt_rect := RectangleShape2D.new()
	hurt_rect.size = Vector2(176.0, 256.0)
	_hurt_shape.shape = hurt_rect
	_hurt_shape.position = Vector2(0.0, -128.0)
	var body_rect := RectangleShape2D.new()
	body_rect.size = Vector2(130.0, 250.0)
	collision_shape.shape = body_rect
	collision_shape.position = Vector2(0.0, -125.0)


func _phase() -> int:
	var ratio := 1.0
	if health.max_health > 0.0:
		ratio = health.current_health / health.max_health
	if ratio > 0.6:
		return 0
	if ratio > 0.3:
		return 1
	return 2


func _pace() -> float:
	return [1.0, 1.2, 1.45][_phase()]


func _next_attack() -> int:
	if _bag.is_empty():
		_bag = [Attack.BULLETS, Attack.LASER, Attack.CHARGE, Attack.JUMP, Attack.ROCKETS]
		if _phase() >= 1:
			_bag.append_array([Attack.ROCKETS, Attack.JUMP])
		if _phase() >= 2:
			_bag.append_array([Attack.LASER, Attack.CHARGE])
		_bag.shuffle()
		if _bag.back() == _last_attack:
			_bag.reverse()
	_last_attack = _bag.pop_back()
	return _last_attack


func _is_airborne_state() -> bool:
	return _state == State.JUMP_RISE or _state == State.JUMP_HOVER or _state == State.JUMP_FALL


func _px_to_global(px: Vector2) -> Vector2:
	var rel := (px - CENTER_PX) * sprite.scale
	if sprite.flip_h:
		rel.x = -rel.x
	return sprite.global_position + rel.rotated(sprite.rotation)


func _face_dir() -> float:
	return 1.0 if sprite.flip_h else -1.0


func _player_hurtbox_in(center: Vector2, radius: float) -> Object:
	var shape := CircleShape2D.new()
	shape.radius = radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, center)
	query.collision_mask = 8
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for result in get_world_2d().direct_space_state.intersect_shape(query, 8):
		var hurtbox_hit: Object = result["collider"]
		if hurtbox_hit.has_method("take_damage"):
			return hurtbox_hit
	return null


func _ground_y_at(x: float) -> float:
	var from := Vector2(x, global_position.y - 900.0)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0.0, 1500.0), 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return global_position.y
	return hit["position"].y


func modify_incoming_damage(amount: float) -> float:
	if _final_active:
		return 0.0
	var result := super.modify_incoming_damage(amount)
	if result > 0.0 and not _final_started and not _defeated:
		var floor_hp: float = health.max_health * FINAL_RATIO
		if health.current_health - result <= floor_hp:
			result = maxf(health.current_health - floor_hp, 0.0)
			_final_pending = true
	return result


func _physics_process(delta: float) -> void:
	if Cutscene.active:
		velocity = Vector2.ZERO
		return
	if _final_pending and not _final_started and not _defeated and not _is_airborne_state():
		_begin_final()
	super._physics_process(delta)


func _update_ai(delta: float) -> void:
	if not _player_in_range():
		velocity.x = 0.0
		return
	_state_time += delta
	if _assault_running:
		_tick_final(delta)
	var pace := _pace()
	var dx := player_ref.global_position.x - global_position.x
	var dir := signf(dx) if dx != 0.0 else 1.0
	match _state:
		State.WALK:
			sprite.flip_h = dx > 0.0
			var dist := absf(dx)
			if dist > keep_max:
				velocity.x = dir * walk_speed
			elif dist < keep_min:
				velocity.x = -dir * walk_speed * 0.8
			else:
				velocity.x = 0.0
			if _state_time > 1.5 / pace:
				_start_attack(_next_attack())
		State.BULLET_AIM:
			velocity.x = 0.0
			sprite.flip_h = dx > 0.0
			if _state_time > 0.45 / pace:
				_enter(State.BULLET_FIRE)
		State.BULLET_FIRE:
			velocity.x = 0.0
			sprite.flip_h = dx > 0.0
			_shot_timer -= delta
			if _shot_timer <= 0.0 and _shots_left > 0:
				_fire_bullet()
				_shots_left -= 1
				_shot_timer = 0.12 / pace
			if _shots_left <= 0 and _shot_timer <= -0.2:
				_enter(State.RECOVER)
		State.LASER:
			velocity.x = 0.0
			if _state_time < 0.6:
				sprite.flip_h = dx > 0.0
			if _state_time > _laser_total:
				_enter(State.RECOVER)
		State.CHARGE_WIND:
			velocity.x = 0.0
			sprite.flip_h = dx > 0.0
			if _state_time > 1.25 / pace:
				_fire_plasma()
				_enter(State.RECOVER)
		State.JUMP_WIND:
			velocity.x = 0.0
			sprite.flip_h = dx > 0.0
			if _state_time > (0.45 if _assault_running else 0.7 / pace):
				_enter(State.JUMP_RISE)
		State.JUMP_RISE:
			velocity.y = -1700.0
			velocity.x = clampf(dx * 4.0, -520.0, 520.0)
			if global_position.y <= _jump_start_y - jump_height or _state_time > 0.55:
				_enter(State.JUMP_HOVER)
		State.JUMP_HOVER:
			velocity.y = 0.0
			sprite.flip_h = dx > 0.0
			var hover_total := 0.42 / pace
			if _state_time < hover_total - 0.2:
				velocity.x = clampf(dx * 8.0, -760.0, 760.0)
			else:
				velocity.x = 0.0
				if not _marker_made:
					_marker_made = true
					_spawn_marker()
			if _state_time > hover_total:
				_enter(State.JUMP_FALL)
		State.JUMP_FALL:
			velocity.x = 0.0
			velocity.y = 1900.0
			if not _hit_landed:
				var victim := _player_hurtbox_in(global_position + Vector2(0.0, -80.0), 125.0)
				if victim != null:
					_hit_landed = true
					victim.take_damage(slam_damage, self)
			if is_on_floor():
				_land()
		State.JUMP_LAND:
			velocity.x = 0.0
			if _state_time > 0.5:
				_enter(State.FINAL_ASSAULT if _assault_running else State.RECOVER)
		State.ROCKETS:
			velocity.x = 0.0
			sprite.flip_h = dx > 0.0
			while _rocket_idx < _rocket_count and _state_time >= 0.55 + _rocket_idx * 0.14:
				_spawn_rocket(_rocket_idx)
				_rocket_idx += 1
			if _state_time > 0.55 + _rocket_count * 0.14 + 0.5:
				_enter(State.RECOVER)
		State.RECOVER:
			velocity.x = 0.0
			if _state_time > 0.8 / pace:
				_enter(State.WALK)
		State.FINAL_INTRO:
			velocity.x = 0.0
			sprite.flip_h = dx > 0.0
			if _state_time > INTRO_TIME:
				_begin_assault()
		State.FINAL_ASSAULT:
			velocity.x = 0.0
			sprite.flip_h = dx > 0.0


func _start_attack(attack: int) -> void:
	match attack:
		Attack.BULLETS:
			_enter(State.BULLET_AIM)
		Attack.LASER:
			_enter(State.LASER)
		Attack.CHARGE:
			_enter(State.CHARGE_WIND)
		Attack.JUMP:
			_enter(State.JUMP_WIND)
		Attack.ROCKETS:
			_enter(State.ROCKETS)


func _enter(new_state: State) -> void:
	_state = new_state
	_state_time = 0.0
	match new_state:
		State.BULLET_FIRE:
			_shots_left = 5 + _phase() * 2
			_shot_timer = 0.0
		State.LASER:
			AudioManager.play_sfx("scott_laser_charge", -2.0, 0.0)
			_spawn_beams(0.95 / _pace(), _phase() >= 1)
			_laser_total = 0.95 / _pace() + 0.5 + 0.35
		State.JUMP_WIND:
			_jump_start_y = global_position.y
			AudioManager.play_sfx("scott_windup", -3.0, 0.04)
			FX.spawn_dust(get_parent(), global_position, 10, Color(0.7, 0.62, 0.55, 0.6), 70.0)
		State.JUMP_RISE:
			_hit_landed = false
			FX.spawn_dust(get_parent(), global_position, 18, Color(0.75, 0.68, 0.6, 0.8), 80.0)
			get_tree().call_group("main_camera", "shake", 8.0)
			AudioManager.play_sfx("scott_jump")
		State.JUMP_HOVER:
			_marker_made = false
		State.ROCKETS:
			_rocket_idx = 0
			_rocket_count = 4 + 2 * _phase()
			get_tree().call_group("scott_lair", "set_alert", 3.0)
			AudioManager.play_sfx("scott_rockets")


func _fire_bullet() -> void:
	var from := low_muzzle.global_position
	var dir := (player_ref.global_position + PLAYER_CENTER) - from
	if dir.length() < 1.0:
		return
	dir = dir.normalized().rotated(randf_range(-0.07, 0.07))
	var proj := PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = from
	proj.launch(dir, 600.0, bullet_damage)
	fx.flash = 1.0
	fx.flash_barrel = 0
	_recoil = 1.0
	AudioManager.play_sfx("scott_shoot")


func _spawn_beams(aim: float, volley: bool) -> void:
	var offsets: Array = [0.0]
	if volley:
		offsets = [0.0, -0.3, 0.3]
	for off in offsets:
		var beam = Node2D.new()
		beam.set_script(BEAM)
		beam.owner_boss = self
		beam.target = player_ref
		beam.damage = laser_damage
		beam.aim_time = aim
		beam.angle_offset = off
		beam.muzzle_node = top_muzzle
		get_tree().current_scene.add_child(beam)
		beam.global_position = top_muzzle.global_position


func _fire_plasma() -> void:
	var from := low_muzzle.global_position
	var dir := (player_ref.global_position + PLAYER_CENTER) - from
	if dir.length() < 1.0:
		dir = Vector2.LEFT
	var angles: Array = [0.0]
	if _phase() >= 2:
		angles = [-0.22, 0.0, 0.22]
	for a in angles:
		var orb = Area2D.new()
		orb.set_script(PLASMA)
		orb.damage = plasma_damage
		orb.source = self
		get_tree().current_scene.add_child(orb)
		orb.global_position = from
		orb.launch(dir.rotated(a), 520.0)
	fx.flash = 1.0
	fx.flash_barrel = 0
	_recoil = 1.6
	get_tree().call_group("main_camera", "shake", 7.0)
	AudioManager.play_sfx("scott_plasma")


func _spawn_marker() -> void:
	var m = Node2D.new()
	m.set_script(MARKER)
	m.radius = 190.0
	m.duration = 0.26
	get_tree().current_scene.add_child(m)
	m.global_position = Vector2(global_position.x, _ground_y_at(global_position.x))


func _land() -> void:
	_enter(State.JUMP_LAND)
	var power := 1.0 + 0.2 * _phase()
	var spectacle = Node2D.new()
	spectacle.set_script(SLAM_FX)
	spectacle.power = power
	get_parent().add_child(spectacle)
	spectacle.global_position = global_position
	FX.spawn_screen_flash(get_tree(), Color(1.0, 0.85, 0.7, 0.6), 0.45)
	FX.spawn_dust(get_parent(), global_position + Vector2(-70.0, 0.0), 16, Color(0.75, 0.68, 0.6, 0.85), 60.0)
	FX.spawn_dust(get_parent(), global_position + Vector2(70.0, 0.0), 16, Color(0.75, 0.68, 0.6, 0.85), 60.0)
	get_tree().call_group("main_camera", "shake", 26.0)
	GameManager.hit_stop(0.16, 0.04)
	AudioManager.play_sfx("scott_slam")
	if not _hit_landed:
		var victim := _player_hurtbox_in(global_position + Vector2(0.0, -60.0), 170.0)
		if victim != null:
			_hit_landed = true
			victim.take_damage(slam_damage, self)
	_spawn_waves(1.6, 560.0 + 80.0 * _phase(), wave_damage)
	_aftershock(power)


func _aftershock(power: float) -> void:
	await get_tree().create_timer(0.45).timeout
	if not is_inside_tree() or _defeated:
		return
	get_tree().call_group("main_camera", "shake", 14.0)
	AudioManager.play_sfx("scott_slam", -6.0, 0.1)
	var again = Node2D.new()
	again.set_script(SLAM_FX)
	again.power = power * 0.6
	get_parent().add_child(again)
	again.global_position = global_position
	_spawn_waves(1.25, 470.0, wave_damage * 0.8)


func _spawn_waves(power: float, speed: float, dmg: float) -> void:
	for wave_dir in [-1.0, 1.0]:
		var wave = Area2D.new()
		wave.set_script(SHOCKWAVE)
		wave.direction = wave_dir
		wave.damage = dmg
		wave.speed = speed
		wave.power = power
		wave.tint = Color(1.0, 0.35, 0.2)
		wave.source = self
		wave.min_x = arena_left - 40.0
		wave.max_x = arena_right + 40.0
		get_parent().add_child(wave)
		wave.global_position = global_position + Vector2(wave_dir * 80.0, 0.0)


func _spawn_rocket(index: int) -> void:
	var px := player_ref.global_position.x
	var tx := px
	if index == 0:
		tx = px + player_ref.velocity.x * 0.45
	else:
		var side := 1.0 if index % 2 == 1 else -1.0
		tx = px + side * (150.0 * ceilf(index / 2.0) + randf_range(-30.0, 60.0))
	_rocket_at(tx, 1.25 - 0.1 * _phase())


func _rocket_at(tx: float, warn: float) -> void:
	tx = clampf(tx, arena_left + 40.0, arena_right - 40.0)
	var rocket = Node2D.new()
	rocket.set_script(ROCKET)
	rocket.launch_from = turret.global_position
	rocket.warn_time = warn
	rocket.damage = rocket_damage
	rocket.source = self
	get_tree().current_scene.add_child(rocket)
	rocket.global_position = Vector2(tx, _ground_y_at(tx))
	AudioManager.play_sfx("rocket_launch")


func _begin_final() -> void:
	_final_started = true
	_final_active = true
	_final_pending = false
	if stun_remaining > 0.0:
		stun_remaining = 0.0
		_end_stun()
	shield = 0.0
	shield_changed.emit(shield, shield_max)
	if _shield_fx != null:
		_shield_fx.ratio = 0.0
	_enter(State.FINAL_INTRO)
	velocity = Vector2(0.0, maxf(velocity.y, 0.0))
	var layer := CanvasLayer.new()
	layer.layer = 80
	_final_ui = Control.new()
	_final_ui.set_script(FINAL_UI)
	layer.add_child(_final_ui)
	get_tree().current_scene.add_child(layer)
	_final_ui.show_warning(INTRO_TIME)
	FX.spawn_screen_flash(get_tree(), Color(1.0, 0.1, 0.05, 0.5), 0.7)
	get_tree().call_group("main_camera", "shake", 16.0)
	get_tree().call_group("scott_lair", "set_alert", INTRO_TIME + FINAL_DURATION + 1.0)
	GameManager.hit_stop(0.25, 0.06)
	AudioManager.play_sfx("scott_final")


func _begin_assault() -> void:
	_assault_running = true
	_final_time = 0.0
	_rain_timer = 0.2
	_final_events = [
		{"t": 0.6, "k": "laser", "done": false},
		{"t": 2.5, "k": "slam", "done": false},
		{"t": 4.4, "k": "burst", "done": false},
		{"t": 5.0, "k": "plasma", "done": false},
		{"t": 5.9, "k": "laser", "done": false},
		{"t": 7.3, "k": "burst", "done": false},
		{"t": 7.8, "k": "slam", "done": false},
	]
	_enter(State.FINAL_ASSAULT)
	_final_ui.start_timer(FINAL_DURATION)
	AudioManager.play_sfx("alarm", -4.0, 0.0)
	_final_ui.show_banner("HINDARI!", Color(1.0, 0.3, 0.2), 1.0)


func _tick_final(delta: float) -> void:
	_final_time += delta
	_final_ui.set_time_left(FINAL_DURATION - _final_time)
	_rain_timer -= delta
	if _rain_timer <= 0.0 and _final_time < FINAL_DURATION - 1.0:
		_rain_timer = 0.6
		var px := player_ref.global_position.x
		_rocket_at(px + player_ref.velocity.x * 0.4, 1.0)
		_rocket_at(px + randf_range(-420.0, 420.0), 1.0)
	for ev in _final_events:
		if ev["done"] or _final_time < float(ev["t"]):
			continue
		var kind: String = ev["k"]
		if (kind == "laser" or kind == "slam") and _state != State.FINAL_ASSAULT:
			continue
		ev["done"] = true
		match kind:
			"laser":
				_spawn_beams(0.75, true)
			"slam":
				_enter(State.JUMP_WIND)
			"burst":
				_final_burst(8)
			"plasma":
				_fire_plasma()
	if _final_time >= FINAL_DURATION and _state == State.FINAL_ASSAULT:
		_end_assault()


func _final_burst(count: int) -> void:
	for i in count:
		if not _final_active or _defeated:
			return
		_fire_bullet()
		await get_tree().create_timer(0.09).timeout


func _end_assault() -> void:
	_assault_running = false
	_final_active = false
	_final_done = true
	_final_ui.stop_timer()
	_final_ui.fade_alarm()
	_final_ui.show_banner("BERTAHAN!", Color(0.4, 1.0, 0.5), 1.3)
	GameState.toast("Scott kelebihan panas! Serang sekarang, damage 2x!")
	stun_duration = EXHAUST_TIME
	stun_remaining = EXHAUST_TIME
	stun_damage_multiplier = 2.0
	shield_regen_after_stun = false
	_stun_fx.active = true
	_was_stunned = true
	get_tree().call_group("main_camera", "shake", 14.0)
	AudioManager.play_sfx("scott_overheat")
	FX.spawn_screen_flash(get_tree(), Color(1.0, 1.0, 1.0, 0.45), 0.5)
	_on_stun_start()
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(_final_ui) and not _defeated:
		_final_ui.show_banner("SERANG SEKARANG!", Color(1.0, 0.9, 0.3), 1.8)


func _on_stun_start() -> void:
	velocity = Vector2(0.0, maxf(velocity.y, 0.0))
	_enter(State.RECOVER)


func _on_stun_end() -> void:
	_enter(State.WALK)


func _on_defeated_state() -> void:
	velocity = Vector2.ZERO
	_final_active = false
	_assault_running = false


func _on_died() -> void:
	if _defeated:
		return
	GameState.scott_beaten = true
	GameState.add_points(drop_vonic)
	GameState.toast(tr("%s dikalahkan! +%d Vonic") % [boss_name, drop_vonic])
	_enter_defeated()
	if is_instance_valid(_final_ui):
		_final_ui.stop_timer()
		_final_ui.fade_alarm()
	GameManager.hit_stop(0.5, 0.08)
	await Cutscene.scott_defeat(self)
	if GameState.has_all_achievements():
		await Cutscene.hanch_reveal()
		GameState.set_checkpoint(SECRET_STAGE, "", Vector2.ZERO)
		GameState.save_game()
		GameManager.goto_stage(SECRET_STAGE, false)
		return
	GameState.ending_kind = "normal"
	GameState.set_checkpoint(GameState.DEFAULT_STAGE_PATH, "", Vector2.ZERO)
	GameState.save_game()
	GameManager.goto_ending()


func _offer_item_choice() -> void:
	pass


func _process(delta: float) -> void:
	super._process(delta)
	_place_markers()
	if _defeated:
		fx.visible = _dying_fx
		if _dying_fx:
			fx.stunned = true
			fx.flip = sprite.flip_h
		return
	_anim_time += delta
	_recoil = maxf(_recoil - delta * 5.0, 0.0)
	var stunned := stun_remaining > 0.0
	var face := _face_dir()
	var moving := absf(velocity.x) > 10.0 and _state == State.WALK
	var k := clampf(_state_time, 0.0, 10.0)
	var target_pos := Vector2(0.0, _base_sprite_y)
	var target_rot := 0.0
	var target_scale := _base_scale
	var charge := 0.0
	var windup := 0.0
	var hatch := 0.0
	var barrel := 0
	var charge_color := Color(0.4, 0.85, 1.0)
	var rage := 0.35 if _final_done and not stunned else 0.0
	var trail := 0.0

	_hurt_shape.position.x = 7.0 * face
	if _shield_fx != null:
		_shield_fx.position.x = 7.0 * face

	if stunned:
		target_pos.y += 16.0
		target_rot = sin(_anim_time * 3.0) * 0.07
		target_scale = _base_scale * Vector2(1.05, 0.94)
	else:
		match _state:
			State.WALK:
				var step := sin(_anim_time * 5.5)
				if moving:
					target_pos.y -= absf(step) * 5.0
					target_rot = step * 0.02
				var breath := sin(_anim_time * 2.0) * 0.012
				target_scale = _base_scale * Vector2(1.0 - breath * 0.5, 1.0 + breath)
			State.BULLET_AIM:
				target_rot = -face * 0.04
				target_pos.x = -face * 5.0
			State.BULLET_FIRE:
				target_pos.x = -face * (6.0 + _recoil * 10.0)
			State.LASER:
				var aim := 0.95 / _pace()
				if k < aim:
					charge = clampf(k / aim, 0.0, 1.0)
					barrel = 1
					charge_color = Color(1.0, 0.35, 0.3)
					target_rot = -face * 0.07
					target_pos.x = -face * 8.0
				else:
					target_pos.x = -face * 16.0
					target_rot = -face * 0.03
			State.CHARGE_WIND:
				charge = clampf(k / (1.25 / _pace()), 0.0, 1.0)
				target_pos.x = randf_range(-2.5, 2.5) * charge
				target_pos.y += 4.0 * charge
				target_rot = -face * 0.06
				target_scale = _base_scale * Vector2(1.03, 0.97)
			State.JUMP_WIND:
				var wk := clampf(k / (0.45 if _assault_running else 0.7 / _pace()), 0.0, 1.0)
				windup = wk
				target_pos.y += 22.0 * wk
				target_scale = _base_scale * Vector2(1.0 + 0.17 * wk, 1.0 - 0.19 * wk)
				target_pos.x = randf_range(-2.5, 2.5) * wk
			State.JUMP_RISE:
				target_scale = _base_scale * Vector2(0.9, 1.15)
				windup = 0.6
			State.JUMP_HOVER:
				target_scale = _base_scale * Vector2(1.0, 1.0)
				windup = 0.4
				target_pos.x = randf_range(-1.5, 1.5)
			State.JUMP_FALL:
				target_scale = _base_scale * Vector2(0.84, 1.26)
				windup = 0.8
				trail = 1.0
			State.JUMP_LAND:
				var squash := clampf(1.0 - k / 0.4, 0.0, 1.0)
				target_scale = _base_scale * Vector2(1.0 + 0.3 * squash, 1.0 - 0.26 * squash)
				target_pos.y += 14.0 * squash
			State.ROCKETS:
				hatch = clampf(k / 0.3, 0.0, 1.0)
				target_rot = -face * 0.09
				target_pos.y -= 4.0
			State.RECOVER:
				target_scale = _base_scale * Vector2(1.0, 1.0 + sin(_anim_time * 9.0) * 0.015)
			State.FINAL_INTRO:
				var ik := clampf(k / INTRO_TIME, 0.0, 1.0)
				rage = ik
				target_pos.x = randf_range(-5.0, 5.0) * ik
				target_pos.y += randf_range(-3.0, 3.0) * ik - 6.0 * ik
				target_scale = _base_scale * Vector2(1.0 + 0.1 * ik, 1.0 + 0.04 * ik)
				if int(k * 10.0) != int((k - delta) * 10.0):
					get_tree().call_group("main_camera", "shake", 3.0 + 6.0 * ik)
			State.FINAL_ASSAULT:
				rage = 1.0
				target_pos.x = -face * _recoil * 12.0 + randf_range(-1.5, 1.5)
				target_rot = -face * 0.03
				hatch = 0.6
				var pulse := sin(_anim_time * 12.0) * 0.015
				target_scale = _base_scale * Vector2(1.0 + pulse, 1.0 - pulse)
	target_pos.y += _intro_offset
	rage = maxf(rage, _intro_rage)
	sprite.position = sprite.position.lerp(target_pos, minf(1.0, 14.0 * delta))
	sprite.rotation = lerp_angle(sprite.rotation, target_rot, minf(1.0, 10.0 * delta))
	sprite.scale = sprite.scale.lerp(target_scale, minf(1.0, 12.0 * delta))

	if _final_active and not stunned:
		var heat := 0.5 + 0.5 * sin(_anim_time * 10.0)
		sprite.self_modulate = Color(1.15 + 0.35 * heat, 0.7, 0.7)
		_final_tint = true
	elif _final_tint and not stunned:
		sprite.self_modulate = Color.WHITE
		_final_tint = false

	if moving and is_on_floor():
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = 0.5
			FX.spawn_dust(get_parent(), global_position + Vector2(-face * 30.0, 0.0), 5, Color(0.7, 0.62, 0.55, 0.6), 36.0)
			get_tree().call_group("main_camera", "shake", 1.4)
			AudioManager.play_sfx("scott_step", -6.0, 0.08)
	if not stunned and (_state == State.JUMP_RISE or _state == State.JUMP_HOVER or _state == State.JUMP_FALL):
		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			_ghost_timer = 0.04
			var ghost_col := Color(1.0, 0.5, 0.3, 0.5) if _state == State.JUMP_FALL else Color(0.55, 0.85, 1.0, 0.45)
			FX.spawn_afterimage(sprite, ghost_col, 0.3)

	fx.flip = sprite.flip_h
	fx.stunned = stunned
	fx.charge = charge
	fx.charge_barrel = barrel
	fx.charge_color = charge_color
	fx.windup = windup
	fx.hatch = hatch
	fx.rage = rage
	fx.fall_trail = trail
	fx.phase_heat = float(_phase())


func _place_markers() -> void:
	low_muzzle.global_position = _px_to_global(LOW_MUZZLE_PX)
	top_muzzle.global_position = _px_to_global(TOP_MUZZLE_PX)
	turret.global_position = _px_to_global(TURRET_PX)


func play_intro() -> void:
	var ground_y := global_position.y
	global_position.y = ground_y - 900.0
	sprite.flip_h = false
	get_tree().call_group("scott_lair", "power_on")
	AudioManager.play_sfx("scott_power_on")
	get_tree().call_group("scott_lair", "set_alert", 2.4)
	await Cutscene.wait(0.8)
	reveal()
	var fall := create_tween()
	fall.tween_property(self, "global_position:y", ground_y, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await fall.finished
	var spectacle = Node2D.new()
	spectacle.set_script(SLAM_FX)
	spectacle.power = 1.5
	get_parent().add_child(spectacle)
	spectacle.global_position = global_position
	FX.spawn_screen_flash(get_tree(), Color(1.0, 0.85, 0.7, 0.7), 0.5)
	FX.spawn_dust(get_parent(), global_position + Vector2(-80.0, 0.0), 16, Color(0.75, 0.68, 0.6, 0.85), 60.0)
	FX.spawn_dust(get_parent(), global_position + Vector2(80.0, 0.0), 16, Color(0.75, 0.68, 0.6, 0.85), 60.0)
	get_tree().call_group("main_camera", "shake", 30.0)
	AudioManager.play_sfx("scott_slam")
	_intro_offset = 26.0
	_intro_rage = 1.0
	create_tween().tween_property(self, "_intro_offset", 0.0, 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	create_tween().tween_property(self, "_intro_rage", 0.0, 1.6)
	await Cutscene.wait(1.5)


func play_death_throes() -> void:
	_dying_fx = true
	var face := _face_dir()
	var sink := create_tween().set_parallel()
	sink.tween_property(sprite, "rotation", -face * 0.14, 1.8).set_trans(Tween.TRANS_SINE)
	sink.tween_property(sprite, "position:y", _base_sprite_y + 18.0, 1.8)
	sink.tween_property(sprite, "scale", _base_scale * Vector2(1.08, 0.9), 1.8)
	for i in 16:
		if Cutscene.skipped and i > 3:
			break
		var offset := Vector2(randf_range(-110.0, 110.0), -randf_range(20.0, 250.0))
		FX.spawn_death_burst(get_parent(), global_position + offset, Color(0.6, 0.85, 1.0) if i % 2 == 0 else Color(1.0, 0.55, 0.25), 2.0)
		get_tree().call_group("main_camera", "shake", 5.0 + i * 0.7)
		AudioManager.play_sfx("explosion", -5.0, 0.15)
		if i % 4 == 3:
			FX.spawn_screen_flash(get_tree(), Color(1.0, 0.4, 0.2, 0.25), 0.25)
			FX.spawn_dust(get_parent(), global_position + Vector2(randf_range(-60.0, 60.0), 0.0), 8, Color(0.5, 0.5, 0.55, 0.6), 50.0)
		await Cutscene.wait(0.2)
	AudioManager.play_sfx("boss_defeat")


func play_shutdown() -> void:
	AudioManager.play_sfx("end_power_down")
	var dark := create_tween().set_parallel()
	dark.tween_property(fx, "modulate:a", 0.0, 1.6)
	dark.tween_property(sprite, "modulate", Color(0.22, 0.22, 0.28), 1.6)
	await Cutscene.wait(1.7)


func ensure_revealed() -> void:
	if _revealed:
		return
	var ground_y := global_position.y
	global_position.y = ground_y - 800.0
	velocity = Vector2.ZERO
	reveal()
	var waited := 0.0
	while not is_on_floor() and waited < 2.5:
		await get_tree().physics_frame
		waited += get_physics_process_delta_time()
	var spectacle = Node2D.new()
	spectacle.set_script(SLAM_FX)
	spectacle.power = 1.2
	get_parent().add_child(spectacle)
	spectacle.global_position = global_position
	FX.spawn_screen_flash(get_tree(), Color(1.0, 0.85, 0.7, 0.5), 0.4)
	FX.spawn_dust(get_parent(), global_position + Vector2(-80.0, 0.0), 14, Color(0.75, 0.68, 0.6, 0.85), 60.0)
	FX.spawn_dust(get_parent(), global_position + Vector2(80.0, 0.0), 14, Color(0.75, 0.68, 0.6, 0.85), 60.0)
	get_tree().call_group("main_camera", "shake", 22.0)
	AudioManager.play_sfx("scott_slam")
	_intro_offset = 22.0
	create_tween().tween_property(self, "_intro_offset", 0.0, 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.5).timeout
