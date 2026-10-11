extends "res://scenes/enemies/boss_base.gd"

## KRUMS (Stage 5 boss): shield robot. HP 1000, shield 200 (regenerates after a stun).
## Light attack: 25. Heavy charge: 45. Stomp shockwaves: 30. Shoulder cannon (18)
## punishes hiding on the floating platforms.

const PROJECTILE_SCENE := preload("res://scenes/enemies/projectile.tscn")
const SHOCKWAVE := preload("res://scenes/enemies/shockwave.gd")

enum State { WALK, LIGHT_WINDUP, LIGHT_STRIKE, HEAVY_WINDUP, HEAVY_CHARGE, STOMP_WINDUP, STOMP, RECOVER }

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

@onready var strike_area: Area2D = $StrikeArea
@onready var charge_area: Area2D = $ChargeArea
@onready var muzzle: Marker2D = $Muzzle

var _state := State.WALK
var _state_time := 0.0
var _charge_dir := 1.0
var _attack_count := 0
var _hit_landed := false
var _cannon_cd := 2.0


func _ready() -> void:
	super._ready()
	strike_area.area_entered.connect(_on_strike_area_entered)
	charge_area.area_entered.connect(_on_charge_area_entered)


func _update_ai(delta: float) -> void:
	if not _player_in_range():
		velocity.x = 0.0
		return
	_state_time += delta
	var dx := player_ref.global_position.x - global_position.x
	var dir := signf(dx) if dx != 0.0 else 1.0
	match _state:
		State.WALK:
			sprite.flip_h = dx > 0.0
			muzzle.position.x = absf(muzzle.position.x) * dir
			if absf(dx) > light_range:
				velocity.x = dir * walk_speed
			else:
				velocity.x = 0.0
			_cannon_cd -= delta
			if _cannon_cd <= 0.0 and player_ref.global_position.y < global_position.y - 120.0:
				_cannon_cd = cannon_interval
				_fire_cannon()
			if _state_time > 1.6:
				_attack_count += 1
				if _attack_count % stomp_every == 0:
					_enter_state(State.STOMP_WINDUP)
				elif _attack_count % heavy_every == 0:
					_charge_dir = dir
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
			velocity.x = _charge_dir * charge_speed
			if _state_time > 0.55 or is_on_wall():
				_enter_state(State.RECOVER)
		State.STOMP_WINDUP:
			velocity.x = 0.0
			if _state_time > 0.85:
				_enter_state(State.STOMP)
		State.STOMP:
			velocity.x = 0.0
			if _state_time > 0.3:
				_enter_state(State.RECOVER)
		State.RECOVER:
			velocity.x = 0.0
			if _state_time > 0.9:
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


func _do_stomp() -> void:
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
	AudioManager.play_sfx("krums_stomp")


func _fire_cannon() -> void:
	for i in 3:
		if _defeated or stun_remaining > 0.0 or not is_inside_tree():
			return
		var dir := (player_ref.global_position + PLAYER_CENTER) - muzzle.global_position
		if dir.length() > 1.0:
			var proj := PROJECTILE_SCENE.instantiate()
			get_tree().current_scene.add_child(proj)
			proj.global_position = muzzle.global_position
			proj.launch(dir, 520.0, cannon_damage)
			AudioManager.play_sfx("krums_cannon")
		await get_tree().create_timer(0.22).timeout


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
