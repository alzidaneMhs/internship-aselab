extends "res://scenes/enemies/boss_base.gd"

const COIN := preload("res://scenes/enemies/hanch_coin.gd")
const HAT := preload("res://scenes/enemies/hanch_hat.gd")
const GOLD_DROP := preload("res://scenes/enemies/hanch_gold_drop.gd")
const SHOCKWAVE := preload("res://scenes/enemies/shockwave.gd")
const FACE_IDLE := 0
const FACE_WAVE := 1
const FACE_HAPPY := 2
const FACE_COIN := 3
const FACE_CONFUSED := 4

enum State { WALK, SPRAY_WIND, HAT_WIND, HAT_WAIT, RAIN, DASH_WIND, DASH, VACUUM, SLAM_WIND, SLAM_AIR, RECOVER }
enum Attack { SPRAY, HAT, RAIN, DASH, VACUUM, SLAM }

@export var walk_speed: float = 130.0
@export var keep_min: float = 360.0
@export var keep_max: float = 720.0
@export var coin_damage: float = 14.0
@export var hat_damage: float = 22.0
@export var drop_damage: float = 26.0
@export var dash_damage: float = 35.0
@export var dash_speed: float = 1150.0
@export var wave_damage: float = 26.0
@export var steal_amount: int = 5
@export var vacuum_pull: float = 330.0
@export var vacuum_damage: float = 8.0

@onready var dash_area: Area2D = $DashArea
@onready var fx: Node2D = $HanchFX

var _state := State.WALK
var _state_time := 0.0
var _bag: Array = []
var _last_attack := -1
var _hats: Array = []
var _dash_dir := 1.0
var _dash_count := 0
var _hit_landed := false
var _face := FACE_IDLE
var _face_time := 0.0
var _drop_idx := 0
var _drop_count := 0
var _steal_cd := 0.0
var _trail_timer := 0.0
var _anim_time := 0.0
var _base_scale := Vector2.ONE
var _base_y := 0.0
var _rage := 0.0
var _facing := -1.0


func _ready() -> void:
	var spent := GameState.vonic_spent
	if spent <= 0:
		max_health = 1100.0
	else:
		max_health = clampf(1600.0 + spent * 6.0, 1600.0, 3200.0)
	super._ready()
	_base_scale = sprite.scale
	_base_y = sprite.position.y
	_anim_time = randf() * TAU
	dash_area.area_entered.connect(_on_dash_area_entered)
	fx.draw.connect(_draw_fx)


func _phase() -> int:
	if health.max_health <= 0.0:
		return 0
	return 0 if health.current_health / health.max_health > 0.5 else 1


func _pace() -> float:
	return 1.0 if _phase() == 0 else 1.3


func _next_attack() -> int:
	if _bag.is_empty():
		_bag = [Attack.SPRAY, Attack.HAT, Attack.RAIN, Attack.DASH, Attack.VACUUM]
		if _phase() >= 1:
			_bag.append_array([Attack.SLAM, Attack.RAIN, Attack.SPRAY, Attack.SLAM])
		_bag.shuffle()
		if _bag.back() == _last_attack:
			_bag.reverse()
	_last_attack = _bag.pop_back()
	return _last_attack


func _set_face(face: int, seconds: float) -> void:
	_face = face
	_face_time = seconds


func _update_ai(delta: float) -> void:
	if not _player_in_range():
		velocity.x = 0.0
		return
	_state_time += delta
	_steal_cd = maxf(_steal_cd - delta, 0.0)
	var pace := _pace()
	var dx := player_ref.global_position.x - global_position.x
	var dir := signf(dx) if dx != 0.0 else 1.0
	match _state:
		State.WALK:
			_facing = 1.0 if dx > 0.0 else -1.0
			var dist := absf(dx)
			if dist > keep_max:
				velocity.x = dir * walk_speed * pace
			elif dist < keep_min:
				velocity.x = -dir * walk_speed * 0.8
			else:
				velocity.x = 0.0
			if _state_time > 1.3 / pace:
				_start_attack(_next_attack())
		State.SPRAY_WIND:
			velocity.x = 0.0
			_facing = 1.0 if dx > 0.0 else -1.0
			if _state_time > 0.55 / pace:
				_spray_coins()
				_enter(State.RECOVER)
		State.HAT_WIND:
			velocity.x = 0.0
			_facing = 1.0 if dx > 0.0 else -1.0
			if _state_time > 0.45 / pace:
				_throw_hats(dir)
				_enter(State.HAT_WAIT)
		State.HAT_WAIT:
			velocity.x = 0.0
			_hats = _hats.filter(func(h): return is_instance_valid(h))
			if _hats.is_empty() or _state_time > 3.4:
				_enter(State.RECOVER)
		State.RAIN:
			velocity.x = 0.0
			while _drop_idx < _drop_count and _state_time >= 0.35 + _drop_idx * 0.16:
				_spawn_drop(_drop_idx)
				_drop_idx += 1
			if _state_time > 0.35 + _drop_count * 0.16 + 0.7:
				_enter(State.RECOVER)
		State.DASH_WIND:
			velocity.x = 0.0
			_facing = 1.0 if dx > 0.0 else -1.0
			if _state_time > 0.8 / pace:
				_dash_dir = dir
				_enter(State.DASH)
		State.DASH:
			velocity.x = _dash_dir * dash_speed
			_trail_timer -= delta
			if _trail_timer <= 0.0:
				_trail_timer = 0.05
				FX.spawn_afterimage(sprite, Color(1.0, 0.8, 0.3, 0.45), 0.3)
			var at_edge := (global_position.x <= arena_left + 20.0 and _dash_dir < 0.0) or (global_position.x >= arena_right - 20.0 and _dash_dir > 0.0)
			if _state_time > 1.1 or is_on_wall() or at_edge:
				get_tree().call_group("main_camera", "shake", 9.0)
				if _phase() >= 1 and _dash_count == 0:
					_dash_count = 1
					_dash_dir = -_dash_dir
					_hit_landed = false
					_state_time = 0.0
				else:
					_enter(State.RECOVER)
		State.VACUUM:
			velocity.x = 0.0
			_facing = 1.0 if dx > 0.0 else -1.0
			_pull_player(delta)
			if _state_time > 2.4:
				_enter(State.RECOVER)
		State.SLAM_WIND:
			velocity.x = 0.0
			_facing = 1.0 if dx > 0.0 else -1.0
			if _state_time > 0.5 / pace:
				velocity.y = -980.0
				velocity.x = clampf(dx * 1.2, -520.0, 520.0)
				_enter(State.SLAM_AIR)
		State.SLAM_AIR:
			if _state_time > 0.15 and is_on_floor():
				_land_slam()
				_enter(State.RECOVER)
		State.RECOVER:
			velocity.x = 0.0
			if _state_time > 0.8 / pace:
				_enter(State.WALK)


func _start_attack(attack: int) -> void:
	match attack:
		Attack.SPRAY:
			_enter(State.SPRAY_WIND)
		Attack.HAT:
			_enter(State.HAT_WIND)
		Attack.RAIN:
			_enter(State.RAIN)
		Attack.DASH:
			_enter(State.DASH_WIND)
		Attack.VACUUM:
			_enter(State.VACUUM)
		Attack.SLAM:
			_enter(State.SLAM_WIND)


func _enter(new_state: State) -> void:
	_state = new_state
	_state_time = 0.0
	dash_area.set_deferred("monitoring", new_state == State.DASH)
	match new_state:
		State.SPRAY_WIND, State.RAIN:
			_set_face(FACE_COIN, 1.4)
		State.HAT_WIND:
			_set_face(FACE_WAVE, 0.8)
		State.DASH_WIND:
			_set_face(FACE_COIN, 1.6)
			_hit_landed = false
			_dash_count = 0
			var tw := create_tween()
			tw.tween_property(sprite, "self_modulate", Color(2.4, 1.8, 0.6), 0.35)
			tw.tween_property(sprite, "self_modulate", Color.WHITE, 0.35)
		State.VACUUM:
			_set_face(FACE_COIN, 2.4)
			AudioManager.play_sfx("hanch_vacuum")
		State.SLAM_WIND:
			_set_face(FACE_HAPPY, 1.0)
	if new_state == State.RAIN:
		_drop_idx = 0
		_drop_count = 5 + 2 * _phase()


func _spray_coins() -> void:
	var count := 5 if _phase() == 0 else 8
	var from := global_position + Vector2(_facing * 60.0, -230.0)
	var target := player_ref.global_position
	var dist := clampf(absf(target.x - from.x), 120.0, 900.0)
	var dir := signf(target.x - from.x)
	if dir == 0.0:
		dir = 1.0
	for i in count:
		var coin = Area2D.new()
		coin.set_script(COIN)
		coin.damage = coin_damage
		coin.source = self
		var spread := lerpf(0.55, 1.35, float(i) / maxf(count - 1, 1))
		var flight := 0.9
		coin.velocity = Vector2(dir * dist * spread / flight, -560.0 + randf_range(-60.0, 60.0))
		get_parent().add_child(coin)
		coin.global_position = from
	AudioManager.play_sfx("hanch_coins")
	get_tree().call_group("main_camera", "shake", 3.0)


func _throw_hats(dir: float) -> void:
	_hats.clear()
	var heights: Array = [70.0]
	if _phase() >= 1:
		heights = [70.0, 230.0]
	var delay := 0.0
	for h in heights:
		if delay > 0.0:
			await get_tree().create_timer(delay).timeout
			if not is_inside_tree() or _defeated or stun_remaining > 0.0:
				return
		var hat = Area2D.new()
		hat.set_script(HAT)
		hat.direction = dir
		hat.damage = hat_damage
		hat.source = self
		hat.min_x = arena_left - 40.0
		hat.max_x = arena_right + 40.0
		hat.distance = 1100.0
		get_parent().add_child(hat)
		hat.global_position = Vector2(global_position.x + dir * 80.0, global_position.y - float(h))
		_hats.append(hat)
		delay = 0.65
	AudioManager.play_sfx("hanch_hat")


func _spawn_drop(index: int) -> void:
	var px := player_ref.global_position.x
	var tx: float = px + player_ref.velocity.x * 0.35
	if index > 0:
		var side := 1.0 if index % 2 == 1 else -1.0
		tx = px + side * (170.0 * ceilf(index / 2.0) + randf_range(-30.0, 40.0))
	tx = clampf(tx, arena_left + 40.0, arena_right - 40.0)
	var drop = Node2D.new()
	drop.set_script(GOLD_DROP)
	drop.damage = drop_damage
	drop.source = self
	drop.warn_time = 0.95 - 0.12 * _phase()
	get_parent().add_child(drop)
	drop.global_position = Vector2(tx, global_position.y)


func _pull_player(delta: float) -> void:
	if player_ref == null:
		return
	var to_me := global_position.x - player_ref.global_position.x
	var dist := absf(to_me)
	if dist > 60.0 and player_ref is CharacterBody2D:
		var strength := vacuum_pull * clampf(1.2 - dist / 1600.0, 0.35, 1.0)
		(player_ref as CharacterBody2D).move_and_collide(Vector2(signf(to_me) * strength * delta, 0.0))
	if dist < 150.0 and _steal_cd <= 0.0:
		_steal_cd = 0.9
		var hurt := player_ref.get_node_or_null("HurtBox")
		if hurt != null and hurt.has_method("take_damage"):
			hurt.take_damage(vacuum_damage, self)
		var stolen := mini(GameState.points, steal_amount)
		if stolen > 0:
			GameState.add_points(-stolen)
			FX.spawn_damage_number(get_parent(), player_ref.global_position + Vector2(0.0, -140.0), "-%d Vonic" % stolen, Color(1.0, 0.8, 0.3), 26)
		health.heal(40.0)
		_set_face(FACE_HAPPY, 1.2)
		AudioManager.play_sfx("hanch_steal")


func _land_slam() -> void:
	get_tree().call_group("main_camera", "shake", 16.0)
	FX.spawn_dust(get_parent(), global_position + Vector2(-80.0, 0.0), 14, Color(1.0, 0.85, 0.45, 0.8), 60.0)
	FX.spawn_dust(get_parent(), global_position + Vector2(80.0, 0.0), 14, Color(1.0, 0.85, 0.45, 0.8), 60.0)
	for wave_dir in [-1.0, 1.0]:
		var wave = Area2D.new()
		wave.set_script(SHOCKWAVE)
		wave.direction = wave_dir
		wave.damage = wave_damage
		wave.speed = 600.0
		wave.power = 1.3
		wave.tint = Color(1.0, 0.78, 0.25)
		wave.source = self
		wave.min_x = arena_left - 40.0
		wave.max_x = arena_right + 40.0
		get_parent().add_child(wave)
		wave.global_position = global_position + Vector2(wave_dir * 90.0, 0.0)
	AudioManager.play_sfx("hanch_slam")


func _on_dash_area_entered(area: Area2D) -> void:
	if _hit_landed or not area.has_method("take_damage"):
		return
	_hit_landed = true
	area.take_damage(dash_damage, self)
	_set_face(FACE_HAPPY, 1.0)


func _on_stun_start() -> void:
	_enter(State.RECOVER)
	velocity = Vector2(0.0, maxf(velocity.y, 0.0))


func _on_stun_end() -> void:
	_enter(State.WALK)


func _on_defeated_state() -> void:
	var d := get_node_or_null("DashArea") as Area2D
	if d != null:
		d.set_deferred("monitoring", false)


func _on_died() -> void:
	if _defeated:
		return
	GameState.add_points(drop_vonic)
	GameState.toast(tr("%s dikalahkan! +%d Vonic") % [boss_name, drop_vonic])
	_play_defeat_explosions()
	GameManager.hit_stop(0.5, 0.1)
	get_tree().call_group("main_camera", "shake", 18.0)
	_enter_defeated()
	_set_face(FACE_CONFUSED, 99.0)
	await get_tree().create_timer(1.6).timeout
	await Story.play(Story.SCRIPTS["hanch_defeated"])
	GameState.ending_kind = "true"
	GameState.set_checkpoint(GameState.DEFAULT_STAGE_PATH, "", Vector2.ZERO)
	GameState.save_game()
	GameManager.goto_ending()


func _offer_item_choice() -> void:
	pass


func play_intro() -> void:
	reveal(0.6)
	_set_face(FACE_HAPPY, 2.0)
	await Cutscene.wait(0.7)
	var up := create_tween()
	up.tween_property(self, "_rage", 1.0, 0.6)
	get_tree().call_group("main_camera", "shake", 10.0)
	FX.spawn_screen_flash(get_tree(), Color(1.0, 0.8, 0.3, 0.4), 0.5)
	await Cutscene.wait(1.0)
	_set_face(FACE_COIN, 1.5)
	await Cutscene.wait(0.8)


func _process(delta: float) -> void:
	super._process(delta)
	_anim_time += delta
	_face_time = maxf(_face_time - delta, 0.0)
	var stunned := stun_remaining > 0.0
	var frame := FACE_IDLE
	if _defeated or stunned:
		frame = FACE_CONFUSED
	elif _face_time > 0.0:
		frame = _face
	elif _state == State.VACUUM:
		frame = FACE_COIN
	sprite.frame = frame
	if _defeated:
		fx.queue_redraw()
		return
	var bob := sin(_anim_time * (5.0 if absf(velocity.x) > 20.0 else 2.0)) * 5.0
	var squash := 0.0
	if _state == State.DASH_WIND or _state == State.SLAM_WIND:
		squash = 0.08
		bob = 10.0
	sprite.position.y = lerpf(sprite.position.y, _base_y + bob, minf(1.0, 12.0 * delta))
	sprite.scale = sprite.scale.lerp(_base_scale * Vector2(1.0 + squash, 1.0 - squash), minf(1.0, 12.0 * delta))
	var lean := clampf(velocity.x / 1600.0, -0.25, 0.25)
	sprite.rotation = lerp_angle(sprite.rotation, lean, minf(1.0, 10.0 * delta))
	if _phase() >= 1:
		_rage = minf(_rage + delta, 1.0)
	fx.queue_redraw()


func _draw_fx() -> void:
	var t := _anim_time
	var pulse := 0.5 + 0.5 * sin(t * 3.0)
	var center := Vector2(0.0, _base_y)
	fx.draw_circle(center, 210.0 + 14.0 * pulse, Color(1.0, 0.75, 0.25, 0.05 + 0.03 * _rage))
	fx.draw_circle(center, 150.0, Color(1.0, 0.8, 0.3, 0.05))
	for i in 10:
		var a := t * 0.8 + i * TAU / 10.0
		var r := 175.0 + 18.0 * sin(t * 2.0 + i)
		var p := center + Vector2(cos(a) * r, sin(a) * r * 0.55)
		fx.draw_circle(p, 5.0, Color(1.0, 0.85, 0.35, 0.55))
		fx.draw_circle(p, 2.0, Color(1, 1, 0.9, 0.9))
	if _defeated:
		return
	if _state == State.VACUUM and player_ref != null:
		var mouth := Vector2(_facing * 50.0, -170.0)
		var target := to_local(player_ref.global_position + Vector2(0.0, -48.0))
		for i in 6:
			var u := fposmod(t * 1.6 + i / 6.0, 1.0)
			var p2 := target.lerp(mouth, u) + Vector2(0.0, sin(u * 9.0 + i) * 30.0 * (1.0 - u))
			fx.draw_circle(p2, 6.0 * (1.0 - u) + 2.0, Color(1.0, 0.85, 0.35, 0.8 * (1.0 - u * 0.5)))
		fx.draw_line(mouth, target, Color(1.0, 0.8, 0.3, 0.12), 26.0)
	if _state == State.DASH_WIND:
		var k2 := clampf(_state_time / 0.8, 0.0, 1.0)
		var d := _facing
		fx.draw_line(Vector2(0, -60), Vector2(d * 900.0, -60), Color(1.0, 0.75, 0.2, 0.1 + 0.3 * k2), 6.0 + 18.0 * k2)
