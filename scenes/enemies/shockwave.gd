extends Area2D

## Ground shockwave from Krums' stomp. Travels along the floor; jump over it
## or stand on a floating platform. Origin is at floor level.

var direction: float = 1.0
var speed: float = 520.0
var damage: float = 30.0
var min_x: float = -1.0e9
var max_x: float = 1.0e9
var source: Node
## Bigger waves (Scott's slam) are taller and wider; `tint` recolours the fire.
var power: float = 1.0
var tint: Color = Color(1.0, 0.5, 0.15)

var _time := 0.0
var _hit := false


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	collision_layer = 64
	collision_mask = 8
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(44.0, 52.0) * power
	shape.shape = rect
	shape.position = Vector2(0.0, -26.0 * power)
	add_child(shape)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	_time += delta
	position.x += direction * speed * delta
	queue_redraw()
	if position.x < min_x or position.x > max_x:
		queue_free()


func _draw() -> void:
	var flicker := 0.85 + 0.15 * sin(_time * 40.0)
	var d := direction
	var p := power
	var hot := Color(tint, 0.9)
	var core := Color(1.0, 0.95, 0.75, 0.95)
	# Spiky crest leaning in the direction of travel.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18.0 * d, 0.0) * p, Vector2(-6.0 * d, -34.0 * flicker) * p, Vector2(4.0 * d, -14.0) * p,
		Vector2(14.0 * d, -52.0 * flicker) * p, Vector2(22.0 * d, -10.0) * p, Vector2(30.0 * d, 0.0) * p,
	]), hot)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8.0 * d, 0.0) * p, Vector2(0.0, -22.0) * p, Vector2(8.0 * d, 0.0) * p,
	]), core)
	draw_rect(Rect2(-30.0 * p, -3.0, 60.0 * p, 5.0), Color(tint.lightened(0.2), 0.5))
	if p > 1.0:
		# Extra spikes, a glowing front and a smoky tail for the big waves.
		for k in 4:
			var bx := (-34.0 - k * 22.0) * d * p
			var h := (30.0 - k * 6.0) * (0.6 + 0.4 * sin(_time * 30.0 + k)) * p
			draw_colored_polygon(PackedVector2Array([Vector2(bx - 9.0, 0.0), Vector2(bx, -h), Vector2(bx + 9.0, 0.0)]), Color(tint, 0.55 - k * 0.1))
		draw_circle(Vector2(32.0 * d * p, -18.0 * p), 22.0 * p, Color(tint.lightened(0.3), 0.3))
		draw_circle(Vector2(-60.0 * d * p, -10.0), 26.0 * p, Color(0.5, 0.45, 0.45, 0.25))


func _on_area_entered(area: Area2D) -> void:
	if _hit or not area.has_method("take_damage"):
		return
	_hit = true
	area.take_damage(damage, source)
