extends Node2D

var width := 60.0
var max_height := 260.0
var strength := 0.42

var _hit := false
var _gap := 0.0
var _t := 0.0


func _ready() -> void:
	show_behind_parent = true
	z_as_relative = true


func _physics_process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = 0.03
	var owner_node := get_parent() as Node2D
	if owner_node == null:
		return
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.get_screen_center_position().distance_to(owner_node.global_position) > 1500.0:
		if _hit:
			_hit = false
			queue_redraw()
		return
	var from := owner_node.global_position + Vector2(0.0, -6.0)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0.0, max_height), 1)
	var res := get_world_2d().direct_space_state.intersect_ray(query)
	var was := _hit
	if res.is_empty():
		_hit = false
	else:
		_hit = true
		var p: Vector2 = res["position"]
		_gap = p.y - owner_node.global_position.y
		global_position = p
	if _hit or was:
		queue_redraw()


func _draw() -> void:
	if not _hit:
		return
	var k := clampf(1.0 - _gap / max_height, 0.0, 1.0)
	var w := width * (0.55 + 0.45 * k)
	var a := strength * k
	for i in 4:
		var f := 1.0 - i * 0.22
		draw_set_transform(Vector2(0.0, -1.0), 0.0, Vector2(1.0, 0.26))
		draw_circle(Vector2.ZERO, w * f, Color(0.0, 0.0, 0.02, a * 0.32))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
