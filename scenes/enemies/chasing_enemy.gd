extends "res://scenes/enemies/enemy_base.gd"

## "Creeper"-style robot: runs at the player, flashes its fuse, then explodes.
## Design doc stats: HP 40, ATK 15.

@export var run_speed: float = 190.0
@export var explosion_damage: float = 15.0
@export var fuse_distance: float = 95.0
@export var fuse_time: float = 0.7

@onready var explosion_area: Area2D = $ExplosionArea

var _fuse := -1.0


func _ready() -> void:
	super._ready()
	explosion_area.area_entered.connect(_on_explosion_area_entered)


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
	else:
		velocity.x = signf(dx) * run_speed


func _explode() -> void:
	_suicide = true
	explosion_area.monitoring = true
	await get_tree().create_timer(0.1).timeout
	if is_inside_tree():
		health.apply_damage(health.max_health)


func _on_explosion_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(explosion_damage, self)
