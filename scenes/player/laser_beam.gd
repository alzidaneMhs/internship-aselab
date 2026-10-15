extends Node2D

const FX := preload("res://scripts/effects/laser_fx.gd")
const MAX_LENGTH := 1300.0
const HIT_THICKNESS := 70.0
const ENEMY_HURTBOX_MASK := 16
const WORLD_MASK := 1

var _length := 0.0
var thickness: float = 0.0:
	set(value):
		thickness = value
		queue_redraw()


func fire(from: Vector2, dir: Vector2, damage: float, source: Node) -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	global_position = from
	rotation = dir.angle()
	var space := get_world_2d().direct_space_state

	var ray := PhysicsRayQueryParameters2D.create(from, from + dir * MAX_LENGTH, WORLD_MASK)
	var wall := space.intersect_ray(ray)
	var end_point: Vector2 = from + dir * MAX_LENGTH
	if not wall.is_empty():
		end_point = wall["position"]
	_length = from.distance_to(end_point)

	var shape := RectangleShape2D.new()
	shape.size = Vector2(_length, HIT_THICKNESS)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(rotation, from + dir * _length / 2.0)
	query.collision_mask = ENEMY_HURTBOX_MASK
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var already_hit := {}
	for result in space.intersect_shape(query, 32):
		var hurtbox: Object = result["collider"]
		if already_hit.has(hurtbox):
			continue
		already_hit[hurtbox] = true
		if hurtbox.has_method("take_damage"):
			hurtbox.take_damage(damage, source)
			GameManager.hit_stop(0.07)
			FX.spawn_impact(get_parent(), (hurtbox as Node2D).global_position + Vector2(0, -50), 0.9)

	FX.spawn_impact(get_parent(), end_point, 1.4)
	var light := FX.make_light(Color(1.0, 0.15, 0.25), 1.0, 4.0)
	light.position = Vector2(60, 0)
	add_child(light)

	var tw := create_tween()
	tw.tween_property(self, "thickness", 1.0, 0.05)
	tw.tween_interval(0.14)
	tw.tween_property(self, "thickness", 0.0, 0.22)
	tw.tween_callback(queue_free)


func _draw() -> void:
	if thickness <= 0.0 or _length <= 0.0:
		return
	var h := 58.0 * thickness
	draw_rect(Rect2(0, -h / 2.0, _length, h), Color(1.0, 0.1, 0.25, 0.30))
	draw_rect(Rect2(0, -h * 0.30, _length, h * 0.60), Color(1.0, 0.25, 0.35, 0.75))
	draw_rect(Rect2(0, -h * 0.10, _length, h * 0.20), Color(1.0, 1.0, 1.0, 1.0))
	draw_circle(Vector2.ZERO, h * 0.65, Color(1.0, 0.6, 0.7, 0.85))
	draw_circle(Vector2(_length, 0), h * 0.45, Color(1.0, 0.5, 0.6, 0.7))
