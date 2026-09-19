extends "res://scenes/enemies/enemy_base.gd"

@export var fly_speed: float = 4.0
@export var explosion_damage: float = 2.0
@export var explosion_range: float = 1.0

@onready var explosion_area: Area3D = $ExplosionArea


func _ready() -> void:
	super._ready()
	explosion_area.area_entered.connect(_on_explosion_area_entered)


func _update_ai(_delta: float) -> void:
	if _player_in_range():
		var dir := player_ref.global_position - global_position
		if absf(dir.x) > 0.05:
			velocity.x = sign(dir.x) * fly_speed
		else:
			velocity.x = 0.0
		velocity.y = clampf(dir.y, -fly_speed, fly_speed)
		sprite.flip_h = dir.x < 0.0
		if dir.length() < explosion_range:
			_explode()
	else:
		velocity.x = move_toward(velocity.x, 0.0, fly_speed)
		velocity.y = move_toward(velocity.y, 0.0, fly_speed)


func _explode() -> void:
	explosion_area.monitoring = true
	await get_tree().process_frame
	explosion_area.monitoring = false
	health.apply_damage(health.max_health)


func _on_explosion_area_entered(area: Area3D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(explosion_damage, self)
