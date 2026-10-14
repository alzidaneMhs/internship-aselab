extends "res://scenes/enemies/enemy_base.gd"

const PROJECTILE_SCENE := preload("res://scenes/enemies/projectile.tscn")

@export var fire_interval: float = 2.0
@export var projectile_speed: float = 420.0
@export var projectile_damage: float = 1.0
## It backs away when the player gets closer than this (it prefers to snipe).
@export var keep_distance: float = 300.0
@export var retreat_speed: float = 170.0
## How long before a shot the charge-up and aiming line show.
@export var charge_warning: float = 0.55

@onready var attack_timer: Timer = $AttackTimer
@onready var muzzle: Marker2D = $Muzzle
@onready var fx = $Sprite2D/RangedFX  # untyped: ranged_fx.gd defines its own properties

var _anim_time := 0.0
var _base_sprite_y := 0.0
var _recoil := 0.0


func _ready() -> void:
	super._ready()
	attack_timer.wait_time = fire_interval
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()
	_base_sprite_y = sprite.position.y
	_anim_time = randf() * TAU


func _update_ai(_delta: float) -> void:
	# Sniper: faces the player, shoots, and backs away when someone gets close.
	velocity.x = 0.0
	if not _player_in_range():
		return
	var dx := player_ref.global_position.x - global_position.x
	var player_is_right := dx > 0.0
	# ranged_bot.png looks to the right by default.
	sprite.flip_h = not player_is_right
	muzzle.position.x = absf(muzzle.position.x) * (1.0 if player_is_right else -1.0)
	if absf(dx) < keep_distance and is_on_floor():
		var away := -1.0 if player_is_right else 1.0
		if _has_ground_ahead(away):
			velocity.x = away * retreat_speed


func _has_ground_ahead(dir: float) -> bool:
	var from := global_position + Vector2(dir * 50.0, -10.0)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0.0, 40.0), 1)
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


# Hovering drone feel: bobbing, leaning, recoil, and the effects node.
func _process(delta: float) -> void:
	if _dead:
		fx.visible = false
		return
	_anim_time += delta
	var moving := absf(velocity.x) > 20.0
	var bob := sin(_anim_time * 2.6) * 4.0 + sin(_anim_time * 5.3) * 1.2
	sprite.position.y = lerpf(sprite.position.y, _base_sprite_y - 9.0 + bob, minf(1.0, 12.0 * delta))
	# Leans away from the player while backing off, with a gentle wobble.
	var lean := signf(velocity.x) * 0.1 if moving else 0.0
	sprite.rotation = lerp_angle(sprite.rotation, lean + sin(_anim_time * 1.9) * 0.025, minf(1.0, 10.0 * delta))
	_recoil = maxf(_recoil - delta * 6.0, 0.0)
	sprite.position.x = -signf(muzzle.position.x) * _recoil * 7.0

	var in_range := _player_in_range()
	var charge := 0.0
	attack_timer.paused = Cutscene.active
	if in_range and not Cutscene.active and not attack_timer.is_stopped() and attack_timer.time_left < charge_warning:
		charge = 1.0 - attack_timer.time_left / charge_warning
	fx.flip = sprite.flip_h
	fx.thrust = 1.1 if moving else 0.4
	fx.charge = charge
	fx.muzzle = (muzzle.position - sprite.position) / sprite.scale.x
	if in_range:
		var dir := (player_ref.global_position + PLAYER_CENTER) - muzzle.global_position
		fx.aim_dir = dir.normalized().rotated(-sprite.rotation)
	if FX.on_screen(self, 400.0):
		queue_redraw()


# Soft shadow on the ground that shrinks as the drone rises.
func _draw() -> void:
	if _dead:
		return
	var rise := clampf((-(sprite.position.y - _base_sprite_y) - 5.0) / 12.0, -0.5, 1.0)
	var rx := 40.0 - 6.0 * rise
	var pts := PackedVector2Array()
	for i in 21:
		var a := i * TAU / 20.0
		pts.append(Vector2(cos(a) * rx, -2.0 + sin(a) * 7.0))
	draw_colored_polygon(pts, Color(0, 0, 0, 0.28 - 0.06 * rise))


func _on_attack_timer_timeout() -> void:
	if Cutscene.active or _dead or not _player_in_range():
		return
	var dir := (player_ref.global_position + PLAYER_CENTER) - muzzle.global_position
	if dir.length() < 1.0:
		return
	var proj := PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = muzzle.global_position
	proj.launch(dir, projectile_speed, projectile_damage)
	fx.flash = 1.0
	_recoil = 1.0
	AudioManager.play_sfx("enemy_shoot")
