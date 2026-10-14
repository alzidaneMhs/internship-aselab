extends Node2D

## Scott's laser: a thin red aiming line that follows the player, locks in for the
## last moment (so there is time to dodge), then fires a thick beam that stops at
## walls. Cancels itself if the owner is stunned or defeated.
##
## Set the fields, add to the scene, then call start(). Origin is the muzzle.

const FX := preload("res://scripts/effects/laser_fx.gd")
const MAX_LENGTH := 2600.0
const BEAM_WIDTH := 46.0

enum Phase { AIM, FIRE, FADE }

var owner_boss: Node
var target: Node2D
var damage: float = 32.0
var aim_time: float = 0.95
var lock_time: float = 0.3
var fire_time: float = 0.5
## Extra rotation (radians) added to the aim, for multi-beam volleys.
var angle_offset: float = 0.0
## Where the muzzle is, as a function of the boss (set by the owner each frame).
var muzzle_node: Node2D

var _phase := Phase.AIM
var _t := 0.0
var _dir := Vector2.LEFT
var _length := MAX_LENGTH
var _hit := false
var _locked := false


func _ready() -> void:
	z_index = 5
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat


func _physics_process(delta: float) -> void:
	if owner_boss != null and is_instance_valid(owner_boss):
		if owner_boss.get("stun_remaining") > 0.0 or owner_boss.get("_defeated"):
			queue_free()
			return
	if muzzle_node != null and is_instance_valid(muzzle_node):
		global_position = muzzle_node.global_position
	_t += delta
	match _phase:
		Phase.AIM:
			if not _locked:
				_update_aim()
				if _t >= aim_time - lock_time:
					_locked = true
			_length = _ray_length()
			if _t >= aim_time:
				_phase = Phase.FIRE
				_t = 0.0
				get_tree().call_group("main_camera", "shake", 8.0)
				AudioManager.play_sfx("scott_laser")
		Phase.FIRE:
			_length = _ray_length()
			if not _hit:
				_check_hit()
			if _t >= fire_time:
				_phase = Phase.FADE
				_t = 0.0
		Phase.FADE:
			if _t >= 0.25:
				queue_free()
	queue_redraw()


func _update_aim() -> void:
	if target == null or not is_instance_valid(target):
		return
	var to_target := (target.global_position + Vector2(0.0, -48.0)) - global_position
	if to_target.length() > 1.0:
		_dir = to_target.normalized().rotated(angle_offset)


func _ray_length() -> float:
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + _dir * MAX_LENGTH, 1)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return MAX_LENGTH
	return global_position.distance_to(hit["position"])


func _check_hit() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(_length, BEAM_WIDTH)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(_dir.angle(), global_position + _dir * _length * 0.5)
	query.collision_mask = 8   # player hurtbox
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for result in get_world_2d().direct_space_state.intersect_shape(query, 8):
		var hurtbox: Object = result["collider"]
		if hurtbox.has_method("take_damage"):
			hurtbox.take_damage(damage, owner_boss)
			_hit = true
			FX.spawn_impact(get_parent(), (hurtbox as Node2D).global_position + Vector2(0, -48), 1.3)
			break


func _draw() -> void:
	var end := _dir * _length
	match _phase:
		Phase.AIM:
			var k := clampf(_t / aim_time, 0.0, 1.0)
			var locked_flash := 0.5 + 0.5 * sin(_t * 50.0) if _locked else 0.0
			draw_line(Vector2.ZERO, end, Color(1.0, 0.15, 0.1, 0.14 + 0.3 * k), 6.0 + 10.0 * k)
			draw_line(Vector2.ZERO, end, Color(1.0, 0.65, 0.55, 0.35 + 0.35 * k + 0.3 * locked_flash), 2.0)
			draw_circle(Vector2.ZERO, 14.0 + 40.0 * k, Color(1.0, 0.3, 0.2, 0.2 + 0.4 * k))
			draw_circle(end, 18.0, Color(1.0, 0.4, 0.3, 0.3 + 0.4 * k))
		Phase.FIRE:
			var grow := clampf(_t / 0.06, 0.0, 1.0)
			var w := BEAM_WIDTH * grow
			draw_line(Vector2.ZERO, end, Color(1.0, 0.1, 0.1, 0.28), w * 1.6)
			draw_line(Vector2.ZERO, end, Color(1.0, 0.35, 0.3, 0.7), w)
			draw_line(Vector2.ZERO, end, Color(1.0, 1.0, 0.95, 1.0), w * 0.38)
			draw_circle(Vector2.ZERO, w * 1.1, Color(1.0, 0.6, 0.5, 0.8))
			draw_circle(end, w * 0.8, Color(1.0, 0.6, 0.5, 0.7))
		Phase.FADE:
			var f := 1.0 - clampf(_t / 0.25, 0.0, 1.0)
			draw_line(Vector2.ZERO, end, Color(1.0, 0.3, 0.25, 0.6 * f), BEAM_WIDTH * f)
			draw_line(Vector2.ZERO, end, Color(1.0, 1.0, 0.9, f), BEAM_WIDTH * 0.3 * f)
