extends "res://scenes/enemies/boss_base.gd"

## KRUMS (Stage 5 boss): shield robot. HP 1000.
## Shield absorbs 200 damage, then breaks.
## Light attack: 25 damage. Heavy attack: charge, 45 damage.

enum State { WALK, LIGHT_WINDUP, LIGHT_STRIKE, HEAVY_WINDUP, HEAVY_CHARGE, RECOVER }

@export var shield_max: float = 200.0
@export var walk_speed: float = 95.0
@export var light_damage: float = 25.0
@export var heavy_damage: float = 45.0
@export var charge_speed: float = 720.0
@export var light_range: float = 170.0
@export var heavy_every: int = 3

@onready var strike_area: Area2D = $StrikeArea
@onready var charge_area: Area2D = $ChargeArea
@onready var shield_fx = $ShieldFX  # untyped: script defines `ratio`

var shield: float = 0.0
var _state := State.WALK
var _state_time := 0.0
var _charge_dir := 1.0
var _attack_count := 0
var _hit_landed := false


func _ready() -> void:
	super._ready()
	shield = shield_max
	shield_fx.ratio = 1.0
	shield_changed.emit(shield, shield_max)
	strike_area.area_entered.connect(_on_strike_area_entered)
	charge_area.area_entered.connect(_on_charge_area_entered)


## Called by the hurtbox before damage reaches Health.
func modify_incoming_damage(amount: float) -> float:
	if shield <= 0.0:
		return amount
	shield = maxf(shield - amount, 0.0)
	shield_fx.ratio = shield / shield_max
	shield_changed.emit(shield, shield_max)
	if shield <= 0.0:
		GameState.toast("Shield Krums hancur!")
		AudioManager.play_sfx("shield_break")
	return 0.0


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
			if absf(dx) > light_range:
				velocity.x = dir * walk_speed
			else:
				velocity.x = 0.0
			if _state_time > 1.6:
				_attack_count += 1
				if _attack_count % heavy_every == 0:
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
	var fx := get_node_or_null("ShieldFX") as Node2D
	if s != null:
		s.set_deferred("monitoring", false)
	if c != null:
		c.set_deferred("monitoring", false)
	if fx != null:
		fx.visible = false
