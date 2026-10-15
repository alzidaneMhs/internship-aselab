extends RefCounted

static var _glow_texture: GradientTexture2D


static func get_glow_texture() -> GradientTexture2D:
	if _glow_texture == null:
		var grad := Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 1.0])
		grad.colors = PackedColorArray([Color(1, 1, 1, 1), Color(0, 0, 0, 0)])
		_glow_texture = GradientTexture2D.new()
		_glow_texture.gradient = grad
		_glow_texture.fill = GradientTexture2D.FILL_RADIAL
		_glow_texture.fill_from = Vector2(0.5, 0.5)
		_glow_texture.fill_to = Vector2(0.85, 0.85)
		_glow_texture.width = 64
		_glow_texture.height = 64
	return _glow_texture


static func make_light(color: Color, energy: float, texture_scale: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.color = color
	light.energy = energy
	light.texture_scale = texture_scale
	light.texture = get_glow_texture()
	return light


static func circle_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := 12
	for i in range(steps + 1):
		var angle := i * TAU / steps
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


static func spawn_impact(parent: Node, pos: Vector2, scale_factor: float = 1.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var effect := Node2D.new()
	effect.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	parent.add_child(effect)
	effect.global_position = pos
	effect.scale = Vector2.ONE * scale_factor

	var line := Line2D.new()
	line.points = circle_points(12.0)
	line.width = 4.0
	line.default_color = Color(1.0, 0.0, 0.1, 0.9)
	effect.add_child(line)

	var inner := Line2D.new()
	inner.points = circle_points(7.0)
	inner.width = 2.0
	inner.default_color = Color(1.0, 0.9, 0.9, 1.0)
	effect.add_child(inner)

	var light := make_light(Color(1.0, 0.2, 0.3), 1.2, 1.0)
	effect.add_child(light)

	var particles := CPUParticles2D.new()
	particles.amount = 8
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.gravity = Vector2(0, 80)
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 120.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(1.0, 0.4, 0.2)
	effect.add_child(particles)
	particles.emitting = true

	var tween := effect.create_tween()
	tween.tween_property(line, "scale", Vector2(1.8, 1.8), 0.15)
	tween.parallel().tween_property(line, "default_color:a", 0.0, 0.15)
	tween.parallel().tween_property(inner, "scale", Vector2(2.2, 2.2), 0.15)
	tween.parallel().tween_property(inner, "default_color:a", 0.0, 0.15)
	tween.parallel().tween_property(light, "texture_scale", 3.0, 0.15).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(light, "energy", 0.0, 0.15)
	tween.tween_callback(effect.queue_free)


static func spawn_damage_number(parent: Node, pos: Vector2, text: String, color: Color, font_size: int = 26) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(160, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	label.add_theme_constant_override("outline_size", 8)
	label.z_index = 60
	label.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	label.process_mode = Node.PROCESS_MODE_ALWAYS
	label.pivot_offset = Vector2(80, 16)
	parent.add_child(label)
	label.global_position = pos + Vector2(randf_range(-18.0, 18.0) - 80.0, -24.0)
	label.scale = Vector2(1.5, 1.5)
	var tw := label.create_tween().set_parallel()
	tw.tween_property(label, "scale", Vector2.ONE, 0.12)
	tw.tween_property(label, "global_position:y", label.global_position.y - 62.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.5)
	tw.chain().tween_callback(label.queue_free)


static func spawn_death_burst(parent: Node, pos: Vector2, color: Color, scale_factor: float = 1.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	spawn_impact(parent, pos, 1.4 * scale_factor)
	var holder := Node2D.new()
	holder.z_index = 40
	holder.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	parent.add_child(holder)
	holder.global_position = pos

	var scrap := CPUParticles2D.new()
	scrap.amount = int(16 * scale_factor)
	scrap.one_shot = true
	scrap.explosiveness = 1.0
	scrap.lifetime = 0.9
	scrap.spread = 180.0
	scrap.gravity = Vector2(0, 700)
	scrap.initial_velocity_min = 140.0 * scale_factor
	scrap.initial_velocity_max = 380.0 * scale_factor
	scrap.angular_velocity_min = -500.0
	scrap.angular_velocity_max = 500.0
	scrap.scale_amount_min = 3.0
	scrap.scale_amount_max = 7.0 * scale_factor
	scrap.color = color
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)])
	scrap.color_ramp = fade
	holder.add_child(scrap)
	scrap.emitting = true

	var glow := make_light(color, 1.6, 2.0 * scale_factor)
	holder.add_child(glow)
	var tw := holder.create_tween()
	tw.tween_property(glow, "energy", 0.0, 0.35)
	tw.tween_interval(0.7)
	tw.tween_callback(holder.queue_free)


static func spawn_muzzle_flash(parent: Node, pos: Vector2, dir: float) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var flash := Node2D.new()
	flash.z_index = 30
	flash.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	parent.add_child(flash)
	flash.global_position = pos
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(0, -7), Vector2(26 * dir, 0), Vector2(0, 7), Vector2(-6 * dir, 0)])
	poly.color = Color(1.0, 0.55, 0.6, 0.95)
	flash.add_child(poly)
	var tw := flash.create_tween().set_parallel()
	tw.tween_property(flash, "scale", Vector2(1.7, 0.4), 0.1)
	tw.tween_property(poly, "modulate:a", 0.0, 0.1)
	tw.chain().tween_callback(flash.queue_free)


static func spawn_afterimage(sprite: Sprite2D, color: Color, life: float = 0.3) -> void:
	if sprite == null or not sprite.is_inside_tree() or sprite.texture == null:
		return
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.flip_h = sprite.flip_h
	ghost.scale = sprite.scale
	ghost.modulate = color
	ghost.z_index = -1
	ghost.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	sprite.get_tree().current_scene.add_child(ghost)
	ghost.global_position = sprite.global_position
	ghost.global_rotation = sprite.global_rotation
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, life)
	tw.tween_callback(ghost.queue_free)


static func spawn_dust(parent: Node, pos: Vector2, count: int = 8, color: Color = Color(0.7, 0.62, 0.55, 0.7), spread_x: float = 30.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := CPUParticles2D.new()
	p.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	p.z_index = 3
	p.one_shot = true
	p.emitting = false
	p.explosiveness = 0.95
	p.amount = count
	p.lifetime = 0.7
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(spread_x, 3.0)
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.gravity = Vector2(0, -20)
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 110.0
	p.scale_amount_min = 4.0
	p.scale_amount_max = 9.0
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([color, Color(color.r, color.g, color.b, 0.0)])
	p.color_ramp = grad
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.get_tree().create_timer(1.2).timeout.connect(p.queue_free)


static func spawn_screen_flash(tree: SceneTree, color: Color, duration: float = 0.35) -> void:
	if tree == null or tree.current_scene == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 85
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var rect := ColorRect.new()
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	tree.current_scene.add_child(layer)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tw := rect.create_tween()
	tw.tween_property(rect, "modulate:a", 0.0, duration)
	tw.tween_callback(layer.queue_free)


static func on_screen(item: CanvasItem, margin: float = 300.0) -> bool:
	if item == null or not item.is_inside_tree():
		return true
	var viewport := item.get_viewport()
	if viewport == null:
		return true
	var p := item.get_global_transform_with_canvas().origin
	var size := viewport.get_visible_rect().size
	return p.x > -margin and p.x < size.x + margin and p.y > -margin and p.y < size.y + margin
