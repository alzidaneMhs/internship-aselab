extends "res://scenes/enemies/enemy_base.gd"

## "Creeper"-style robot: runs at the player, flashes its fuse, then explodes.
## Design doc stats: HP 40, ATK 15.

@export var run_speed: float = 190.0
@export var explosion_damage: float = 15.0
@export var fuse_distance: float = 95.0
@export var fuse_time: float = 0.7

@onready var explosion_area: Area2D = $ExplosionArea
@onready var jet_fx = $Sprite2D/JetFX  # untyped: jet_fx.gd defines flip and intensity

var _fuse := -1.0
var _anim_time := 0.0
var _base_sprite_y := 0.0


func _ready() -> void:
	super._ready()
	explosion_area.area_entered.connect(_on_explosion_area_entered)
	_base_sprite_y = sprite.position.y
	_anim_time = randf() * TAU


# Jetpack robot: hovers a little, leans into its run, and the flames flare up.
func _process(delta: float) -> void:
	if _dead:
		jet_fx.visible = false
		return
	_anim_time += delta
	var running := absf(velocity.x) > 20.0
	var fusing := _fuse >= 0.0
	var bob := sin(_anim_time * (10.0 if running else 4.0)) * (2.0 if running else 3.0)
	sprite.position.y = lerpf(sprite.position.y, _base_sprite_y - 5.0 + bob, minf(1.0, 14.0 * delta))
	var lean := 0.0
	if running:
		lean = signf(velocity.x) * 0.1
	sprite.rotation = lerp_angle(sprite.rotation, lean, minf(1.0, 10.0 * delta))
	# Shaking before the blast.
	sprite.position.x = randf_range(-2.5, 2.5) if fusing else 0.0
	jet_fx.flip = sprite.flip_h
	jet_fx.intensity = 1.7 if fusing else (1.0 if running else 0.4)


func _update_ai(delta: float) -> void:
	if _fuse >= 0.0:
		velocity.x = 0.0
		_fuse -= delta
		sprite.self_modulate = Color(2.5, 2.5, 2.5) if int(_fuse * 12.0) % 2 == 0 else Color.WHITE
		if _fuse < 0.0:
			_explode()
		return

	if not _player_in_range():
		velocity.x = 0.0
		return
	var dx := player_ref.global_position.x - global_position.x
	sprite.flip_h = dx < 0.0
	if absf(dx) < fuse_distance and absf(player_ref.global_position.y - global_position.y) < 120.0:
		_fuse = fuse_time
		velocity.x = 0.0
	elif is_on_floor() and not _has_ground_ahead(signf(dx)):
		# Edge of the platform: stop instead of chasing the player off the map.
		velocity.x = 0.0
	else:
		velocity.x = signf(dx) * run_speed


func _has_ground_ahead(dir: float) -> bool:
	var from := global_position + Vector2(dir * 50.0, -10.0)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0.0, 40.0), 1)
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _explode() -> void:
	_suicide = true
	explosion_area.monitoring = true
	await get_tree().create_timer(0.1).timeout
	if is_inside_tree():
		health.apply_damage(health.max_health)


func _on_explosion_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(explosion_damage, self)
