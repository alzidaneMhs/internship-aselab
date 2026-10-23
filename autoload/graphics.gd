extends Node

const POST_SHADER := preload("res://shaders/post_fx.gdshader")
const BACKDROP_SHADER := preload("res://shaders/backdrop.gdshader")
const FOG_SHADER := preload("res://shaders/fog.gdshader")
const PLATFORM_SHADER := preload("res://shaders/platform.gdshader")
const CONTACT_SHADOW := preload("res://scripts/effects/contact_shadow.gd")
const PLATFORM_CAP := preload("res://scripts/effects/platform_cap.gd")
const FOREGROUND := preload("res://scripts/effects/foreground_layer.gd")
const MENU_FX := preload("res://scripts/effects/menu_fx.gd")
const TITLE_SHADER := preload("res://shaders/title_shine.gdshader")
const HD_DIR := "res://assets/sprites/backgrounds/hd/"
const FOREGROUND_KINDS := {
	"underground": ["rocks", Color(0.05, 0.03, 0.08)],
	"violet": ["crystal", Color(0.07, 0.02, 0.1)],
	"surface": ["grass", Color(0.08, 0.06, 0.03)],
	"ice": ["ice", Color(0.05, 0.08, 0.14)],
	"tower": ["chains", Color(0.02, 0.05, 0.04)],
	"lair": ["cables", Color(0.04, 0.01, 0.03)],
	"vault": ["coins", Color(0.1, 0.06, 0.02)],
}
const PLATFORM_SCRIPT := "res://scenes/world/platform.gd"
const ENEMY_BASE := "res://scenes/enemies/enemy_base.gd"
const BOSS_BASE := "res://scenes/enemies/boss_base.gd"

const EMISSIVE := {
	"res://scenes/enemies/projectile.gd": 1.8,
	"res://scenes/player/laser_bullet.gd": 1.8,
	"res://scenes/player/laser_beam.gd": 1.6,
	"res://scenes/player/charge_fx.gd": 1.8,
	"res://scenes/enemies/scott_beam.gd": 1.5,
	"res://scenes/enemies/scott_plasma.gd": 1.7,
	"res://scenes/enemies/scott_rocket.gd": 1.3,
	"res://scenes/hazards/laser.gd": 1.05,
	"res://scenes/enemies/shockwave.gd": 1.5,
	"res://scenes/enemies/hanch_coin.gd": 1.0,
	"res://scenes/enemies/jet_fx.gd": 1.6,
	"res://scenes/enemies/ranged_fx.gd": 1.4,
	"res://scenes/enemies/lushte_fx.gd": 1.35,
	"res://scenes/enemies/krums_fx.gd": 1.3,
	"res://scenes/enemies/scott_fx.gd": 1.3,
	"res://scenes/enemies/stun_fx.gd": 1.5,
	"res://scenes/enemies/shield_fx.gd": 1.4,
	"res://scenes/enemies/target_marker.gd": 1.4,
	"res://scenes/world/crystal_props.gd": 1.35,
	"res://scenes/world/campfire.gd": 1.25,
}

const STAGE_THEMES := {
	"stage_0": "underground",
	"stage_1": "underground",
	"stage_2": "underground",
	"stage_3": "underground",
	"stage_4": "surface",
	"stage_5": "surface",
	"stage_6": "violet",
	"stage_7": "ice",
	"stage_8": "ice",
	"stage_9": "ice",
	"stage_10": "ice",
	"stage_11": "tower",
	"stage_12": "lair",
	"stage_13": "vault",
	"main_menu": "menu",
	"intro_cinematic": "cinematic",
	"ending_cinematic": "cinematic",
}

const THEMES := {
	"underground": {
		"ambient": Color(0.93, 0.9, 0.98), "light": Color(1.0, 0.88, 0.72), "light_energy": 0.35, "light_scale": 4.2,
		"fog": Color(0.46, 0.28, 0.58), "fog_density": 0.16,
		"bg_fog": Color(0.3, 0.16, 0.38), "bg_fog_amount": 0.1, "bg_haze": 0.28, "rays": 0.3, "ray_color": Color(1.0, 0.74, 0.95), "ray_x": 0.62, "exposure": 0.95, "bg_sat": 0.95, "top_shade": 0.18, "top_color": Color(0.08, 0.03, 0.12),
		"tint": Vector3(1.02, 0.99, 1.04), "shadow_tint": Vector3(0.04, 0.015, 0.07), "saturation": 1.04, "contrast": 1.04, "vignette": 0.3,
		"particles": "dust", "accent": Color(0.35, 0.95, 1.0), "cap": "moss", "glow": 0.6,
	},
	"violet": {
		"ambient": Color(0.92, 0.88, 0.98), "light": Color(0.95, 0.82, 1.0), "light_energy": 0.35, "light_scale": 4.2,
		"fog": Color(0.58, 0.3, 0.78), "fog_density": 0.18,
		"bg_fog": Color(0.34, 0.14, 0.46), "bg_fog_amount": 0.12, "bg_haze": 0.3, "rays": 0.32, "ray_color": Color(0.95, 0.62, 1.0), "ray_x": 0.4, "exposure": 0.92, "bg_sat": 1.0, "top_shade": 0.2, "top_color": Color(0.1, 0.03, 0.16),
		"tint": Vector3(1.03, 0.98, 1.06), "shadow_tint": Vector3(0.05, 0.01, 0.08), "saturation": 1.06, "contrast": 1.04, "vignette": 0.32,
		"particles": "spores", "accent": Color(0.85, 0.45, 1.0), "cap": "crystal", "glow": 0.7,
	},
	"surface": {
		"ambient": Color(1.0, 0.97, 0.93), "light": Color(1.0, 0.9, 0.7), "light_energy": 0.2, "light_scale": 3.6,
		"fog": Color(1.0, 0.8, 0.55), "fog_density": 0.1,
		"bg_fog": Color(0.95, 0.74, 0.5), "bg_fog_amount": 0.04, "bg_haze": 0.22, "rays": 0.42, "ray_color": Color(1.0, 0.88, 0.58), "ray_x": 0.22, "exposure": 0.98, "bg_sat": 0.92, "top_shade": 0.0, "top_color": Color(0.0, 0.0, 0.0),
		"tint": Vector3(1.03, 1.0, 0.96), "shadow_tint": Vector3(0.05, 0.02, 0.08), "saturation": 1.02, "contrast": 1.03, "vignette": 0.26,
		"particles": "pollen", "accent": Color(1.0, 0.68, 0.28), "cap": "grass", "glow": 0.55,
	},
	"ice": {
		"ambient": Color(0.94, 0.97, 1.0), "light": Color(0.75, 0.9, 1.0), "light_energy": 0.35, "light_scale": 4.2,
		"fog": Color(0.8, 0.9, 1.0), "fog_density": 0.17,
		"bg_fog": Color(0.55, 0.7, 0.9), "bg_fog_amount": 0.16, "bg_haze": 0.3, "rays": 0.36, "ray_color": Color(0.8, 0.94, 1.0), "ray_x": 0.7, "exposure": 0.88, "bg_sat": 1.0, "top_shade": 0.18, "top_color": Color(0.06, 0.1, 0.2),
		"tint": Vector3(0.97, 1.0, 1.05), "shadow_tint": Vector3(0.0, 0.02, 0.06), "saturation": 1.03, "contrast": 1.05, "vignette": 0.3,
		"particles": "snow", "accent": Color(0.45, 0.9, 1.0), "cap": "snow", "glow": 0.6,
	},
	"tower": {
		"ambient": Color(0.86, 0.92, 0.9), "light": Color(0.85, 1.0, 0.88), "light_energy": 0.45, "light_scale": 4.6,
		"fog": Color(0.3, 0.55, 0.45), "fog_density": 0.2,
		"bg_fog": Color(0.16, 0.28, 0.24), "bg_fog_amount": 0.12, "bg_haze": 0.36, "rays": 0.38, "ray_color": Color(0.55, 1.0, 0.78), "ray_x": 0.5, "exposure": 1.15, "bg_sat": 1.0, "top_shade": 0.0, "top_color": Color(0.0, 0.0, 0.0),
		"tint": Vector3(0.97, 1.03, 0.99), "shadow_tint": Vector3(0.02, 0.06, 0.05), "saturation": 1.0, "contrast": 1.03, "vignette": 0.38,
		"particles": "wisps", "accent": Color(0.4, 1.0, 0.6), "cap": "web", "glow": 0.75,
	},
	"lair": {
		"ambient": Color(0.92, 0.9, 0.98), "light": Color(1.0, 0.6, 0.55), "light_energy": 0.3, "light_scale": 4.0,
		"fog": Color(0.55, 0.12, 0.18), "fog_density": 0.12,
		"bg_fog": Color(0.3, 0.08, 0.12), "bg_fog_amount": 0.08, "bg_haze": 0.26, "rays": 0.24, "ray_color": Color(1.0, 0.38, 0.32), "ray_x": 0.5, "exposure": 1.1, "bg_sat": 1.0, "top_shade": 0.0, "top_color": Color(0.0, 0.0, 0.0),
		"tint": Vector3(1.03, 0.98, 1.0), "shadow_tint": Vector3(0.05, 0.01, 0.04), "saturation": 1.05, "contrast": 1.04, "vignette": 0.36,
		"particles": "embers", "accent": Color(1.0, 0.25, 0.25), "cap": "neon", "glow": 0.75,
	},
	"vault": {
		"ambient": Color(0.98, 0.94, 0.86), "light": Color(1.0, 0.86, 0.55), "light_energy": 0.35, "light_scale": 4.2,
		"fog": Color(1.0, 0.76, 0.35), "fog_density": 0.12,
		"bg_fog": Color(0.45, 0.3, 0.12), "bg_fog_amount": 0.08, "bg_haze": 0.28, "rays": 0.42, "ray_color": Color(1.0, 0.82, 0.42), "ray_x": 0.5, "exposure": 1.12, "bg_sat": 1.0, "top_shade": 0.0, "top_color": Color(0.0, 0.0, 0.0),
		"tint": Vector3(1.04, 1.0, 0.93), "shadow_tint": Vector3(0.04, 0.02, 0.0), "saturation": 1.06, "contrast": 1.03, "vignette": 0.32,
		"particles": "glitter", "accent": Color(1.0, 0.8, 0.3), "cap": "coins", "glow": 0.75,
	},
	"cinematic": {
		"tint": Vector3(1.02, 1.0, 1.03), "shadow_tint": Vector3(0.02, 0.0, 0.05), "saturation": 1.08, "contrast": 1.05, "vignette": 0.38,
		"glow": 0.85,
	},
	"menu": {
		"tint": Vector3(1.03, 1.0, 1.04), "shadow_tint": Vector3(0.03, 0.0, 0.06), "saturation": 1.1, "contrast": 1.05, "vignette": 0.42,
		"particles": "embers_soft", "glow": 0.6,
	},
}

var _scene: Node
var _theme_name := ""
var _theme: Dictionary = {}
var _bg_mat: ShaderMaterial
var _fog_mat: ShaderMaterial
var _post_mat: ShaderMaterial
var _light_tex: Texture2D
var _soft_tex: Texture2D
var _fps_layer: CanvasLayer
var _fps_label: Label
var _fps_time := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_light_tex = _radial_texture(256, [0.0, 0.25, 0.6, 1.0], [1.0, 0.55, 0.16, 0.0])
	_soft_tex = _radial_texture(64, [0.0, 0.4, 1.0], [1.0, 0.45, 0.0])
	_build_fps_overlay()
	Settings.graphics_changed.connect(_on_graphics_changed)
	get_tree().node_added.connect(_on_node_added)
	_apply_engine()


func _radial_texture(size: int, offsets: Array, alphas: Array) -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offsets)
	var cols := PackedColorArray()
	for a in alphas:
		cols.append(Color(1, 1, 1, float(a)))
	g.colors = cols
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = size
	tex.height = size
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex


func gfx(key: String):
	return Settings.gfx.get(key)


func _apply_engine() -> void:
	var vp := get_viewport()
	vp.use_hdr_2d = false
	var msaa := int(gfx("msaa"))
	vp.msaa_2d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][clampi(msaa, 0, 2)]
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(gfx("vsync")) else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = int(gfx("fps_limit"))
	_fps_layer.visible = bool(gfx("show_fps"))


func _on_graphics_changed() -> void:
	_apply_engine()
	if is_instance_valid(_scene):
		_teardown()
		_setup(_scene)


func _process(delta: float) -> void:
	var cur := get_tree().current_scene
	if cur != _scene:
		_scene = cur
		_theme_name = ""
		if cur != null:
			_setup.call_deferred(cur)
	if _fps_layer.visible:
		_fps_time -= delta
		if _fps_time <= 0.0:
			_fps_time = 0.25
			_fps_label.text = "FPS %d" % Engine.get_frames_per_second()
	_update_dynamic()


func _update_dynamic() -> void:
	if _theme_name == "" or not is_instance_valid(_scene):
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var c := cam.get_screen_center_position()
	if _fog_mat != null:
		_fog_mat.set_shader_parameter("cam", c)
	if _bg_mat != null:
		var dx := clampf(c.x * 0.0000018, -0.011, 0.011)
		var dy := clampf(c.y * 0.0000014, -0.009, 0.009)
		_bg_mat.set_shader_parameter("drift", Vector2(dx, dy))


func _theme_for(scene: Node) -> String:
	var key := scene.scene_file_path.get_file().get_basename()
	return String(STAGE_THEMES.get(key, ""))


func _setup(scene: Node) -> void:
	if not is_instance_valid(scene) or scene != get_tree().current_scene:
		return
	_theme_name = _theme_for(scene)
	if _theme_name == "":
		return
	_theme = THEMES[_theme_name]
	_build_environment(scene)
	if _theme_name == "cinematic":
		_build_post(scene)
		return
	if _theme_name == "menu":
		_build_menu_fx(scene)
		_build_post(scene)
		_build_menu_particles(scene)
		return
	_build_lighting(scene)
	_build_backdrop(scene)
	_build_fog(scene)
	_build_particles(scene)
	_decorate_platforms(scene)
	_decorate_existing(scene)
	_build_foreground(scene)
	_build_post(scene)


func _teardown() -> void:
	for n in get_tree().get_nodes_in_group("gfx_decorated"):
		if is_instance_valid(n):
			n.remove_meta("_gfx")
			n.remove_from_group("gfx_decorated")
	for n in get_tree().get_nodes_in_group("gfx_deco"):
		if is_instance_valid(n):
			n.queue_free()
	for n in get_tree().get_nodes_in_group("gfx_emissive"):
		if is_instance_valid(n) and n is CanvasItem:
			(n as CanvasItem).self_modulate = Color.WHITE
	for n in get_tree().get_nodes_in_group("gfx_platform"):
		if is_instance_valid(n) and n is CanvasItem:
			(n as CanvasItem).material = null
			n.remove_from_group("gfx_platform")
	if is_instance_valid(_scene):
		var back := _scene.get_node_or_null("Backdrop")
		if back != null:
			for child in back.get_children():
				if child is CanvasItem:
					(child as CanvasItem).material = null
				if child is TextureRect:
					_restore_texture(child as TextureRect)
		var menu_bg := _scene.get_node_or_null("Background") as TextureRect
		if menu_bg != null:
			menu_bg.material = null
			_restore_texture(menu_bg)
		var title := _scene.get_node_or_null("TitleBox/TitleLabel") as CanvasItem
		if title != null:
			title.material = null
	_bg_mat = null
	_fog_mat = null
	_post_mat = null
	_theme_name = ""


func _deco(node: Node) -> Node:
	node.add_to_group("gfx_deco")
	return node


func _build_environment(scene: Node) -> void:
	if not bool(gfx("glow")):
		return
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.background_canvas_max_layer = 0
	env.glow_enabled = true
	env.glow_normalized = false
	env.glow_intensity = float(_theme.get("glow", 0.8)) * 0.75
	env.glow_strength = 1.0
	env.glow_bloom = 0.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.glow_hdr_threshold = 0.94
	env.glow_hdr_scale = 1.6
	env.glow_hdr_luminance_cap = 8.0
	var ultra := int(gfx("preset")) == 3
	var levels := [0.0, 0.9, 0.75, 0.35 if ultra else 0.2, 0.0, 0.0, 0.0]
	for i in levels.size():
		env.set_glow_level(i, levels[i])
	var we := WorldEnvironment.new()
	we.environment = env
	scene.add_child(_deco(we))


func _build_lighting(scene: Node) -> void:
	if not bool(gfx("lighting")):
		return
	var cm := CanvasModulate.new()
	cm.color = _theme["ambient"]
	scene.add_child(_deco(cm))
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		var light := PointLight2D.new()
		light.texture = _light_tex
		light.texture_scale = float(_theme["light_scale"])
		light.energy = float(_theme["light_energy"])
		light.color = _theme["light"]
		light.position = Vector2(0.0, -60.0)
		light.blend_mode = Light2D.BLEND_MODE_ADD
		light.range_item_cull_mask = 1
		player.add_child(_deco(light))
		var spr := player.get_node_or_null("AnimatedSprite2D") as CanvasItem
		if spr != null:
			spr.light_mask = 2


func _build_backdrop(scene: Node) -> void:
	if not bool(gfx("bg_fx")):
		return
	var back := scene.get_node_or_null("Backdrop")
	if back == null:
		return
	var target: CanvasItem = null
	for child in back.get_children():
		if child is TextureRect or child is ColorRect:
			target = child
			break
	if target == null:
		return
	_bg_mat = ShaderMaterial.new()
	_bg_mat.shader = BACKDROP_SHADER
	_bg_mat.set_shader_parameter("use_texture", target is TextureRect)
	_bg_mat.set_shader_parameter("blur", 0.0)
	_bg_mat.set_shader_parameter("zoom", 0.975)
	_bg_mat.set_shader_parameter("fog_color", _theme["bg_fog"])
	_bg_mat.set_shader_parameter("fog", float(_theme["bg_fog_amount"]))
	_bg_mat.set_shader_parameter("haze", float(_theme["bg_haze"]))
	_bg_mat.set_shader_parameter("rays", float(_theme["rays"]))
	_bg_mat.set_shader_parameter("ray_color", _theme["ray_color"])
	_bg_mat.set_shader_parameter("ray_x", float(_theme["ray_x"]))
	_bg_mat.set_shader_parameter("exposure", float(_theme["exposure"]))
	_bg_mat.set_shader_parameter("saturation", float(_theme["bg_sat"]))
	_bg_mat.set_shader_parameter("top_color", _theme["top_color"])
	_bg_mat.set_shader_parameter("top_shade", float(_theme["top_shade"]))
	if target is TextureRect:
		_use_hd_texture(target as TextureRect)
	target.material = _bg_mat


func _use_hd_texture(rect: TextureRect) -> void:
	if rect.texture == null:
		return
	var path := rect.texture.resource_path
	if path.begins_with(HD_DIR):
		return
	var hd := HD_DIR + path.get_file()
	if not ResourceLoader.exists(hd):
		return
	rect.set_meta("_gfx_orig_tex", rect.texture)
	rect.texture = load(hd) as Texture2D
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


func _restore_texture(rect: TextureRect) -> void:
	if rect.has_meta("_gfx_orig_tex"):
		rect.texture = rect.get_meta("_gfx_orig_tex")
		rect.remove_meta("_gfx_orig_tex")
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_PARENT_NODE


func _build_fog(scene: Node) -> void:
	if not bool(gfx("bg_fx")):
		return
	var layer := CanvasLayer.new()
	layer.layer = -5
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fog_mat = ShaderMaterial.new()
	_fog_mat.shader = FOG_SHADER
	_fog_mat.set_shader_parameter("fog_color", _theme["fog"])
	_fog_mat.set_shader_parameter("density", float(_theme["fog_density"]))
	rect.material = _fog_mat
	layer.add_child(rect)
	scene.add_child(_deco(layer))


func _build_post(scene: Node) -> void:
	var post := bool(gfx("post_fx"))
	var bright := float(gfx("brightness"))
	if not post and absf(bright - 1.0) < 0.01:
		return
	var film := bool(gfx("film_fx")) and post
	_post_mat = ShaderMaterial.new()
	_post_mat.shader = POST_SHADER
	_post_mat.set_shader_parameter("brightness", bright)
	if post:
		_post_mat.set_shader_parameter("tint", _theme.get("tint", Vector3.ONE))
		_post_mat.set_shader_parameter("shadow_tint", _theme.get("shadow_tint", Vector3.ZERO))
		_post_mat.set_shader_parameter("saturation", float(_theme.get("saturation", 1.0)))
		_post_mat.set_shader_parameter("contrast", float(_theme.get("contrast", 1.0)))
		_post_mat.set_shader_parameter("vignette", float(_theme.get("vignette", 0.35)))
		_post_mat.set_shader_parameter("aberration", 0.0)
		_post_mat.set_shader_parameter("grain", 0.018 if film else 0.0)
	else:
		_post_mat.set_shader_parameter("vignette", 0.0)
	var layer := CanvasLayer.new()
	layer.layer = 0
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = _post_mat
	layer.add_child(rect)
	scene.add_child(_deco(layer))


func _particle_material(kind: String, front: bool, extents: Vector2) -> ParticleProcessMaterial:
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(extents.x, extents.y, 1.0)
	m.particle_flag_disable_z = true
	m.direction = Vector3(0, -1, 0)
	m.spread = 180.0
	m.gravity = Vector3.ZERO
	m.initial_velocity_min = 4.0
	m.initial_velocity_max = 16.0
	m.scale_min = 0.12
	m.scale_max = 0.4
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 1.2
	m.turbulence_noise_scale = 6.0
	m.turbulence_influence_min = 0.04
	m.turbulence_influence_max = 0.12
	var col := Color(1, 1, 1, 0.4)
	match kind:
		"dust":
			col = Color(1.0, 0.85, 1.0, 0.35)
			m.gravity = Vector3(0, -3, 0)
		"spores":
			col = Color(1.5, 0.8, 2.2, 0.55)
			m.gravity = Vector3(0, -9, 0)
			m.scale_max = 0.3
		"pollen":
			col = Color(2.0, 1.6, 0.7, 0.7)
			m.gravity = Vector3(4, -2, 0)
			m.scale_min = 0.08
			m.scale_max = 0.24
		"snow":
			col = Color(1.0, 1.05, 1.15, 0.85)
			m.gravity = Vector3(22, 55, 0)
			m.initial_velocity_min = 10.0
			m.initial_velocity_max = 30.0
			m.direction = Vector3(0.3, 1, 0)
			m.spread = 25.0
			m.scale_min = 0.1
			m.scale_max = 0.32
		"wisps":
			col = Color(0.6, 1.6, 1.0, 0.3)
			m.gravity = Vector3(0, -12, 0)
			m.scale_min = 0.25
			m.scale_max = 0.7
		"embers", "embers_soft":
			col = Color(2.4, 0.8, 0.35, 0.85)
			m.gravity = Vector3(3, -28, 0)
			m.initial_velocity_min = 10.0
			m.initial_velocity_max = 40.0
			m.scale_min = 0.06
			m.scale_max = 0.18
		"glitter":
			col = Color(2.3, 1.8, 0.6, 0.9)
			m.gravity = Vector3(0, 14, 0)
			m.scale_min = 0.05
			m.scale_max = 0.16
	if front:
		m.scale_min *= 2.4
		m.scale_max *= 2.8
		col.a *= 0.22
		m.initial_velocity_min *= 1.6
		m.initial_velocity_max *= 1.6
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.75, 1.0])
	ramp.colors = PackedColorArray([Color(col, 0.0), col, col, Color(col, 0.0)])
	var rt := GradientTexture1D.new()
	rt.gradient = ramp
	m.color_ramp = rt
	return m


func _make_particles(kind: String, front: bool, amount: int, extents: Vector2) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.amount = maxi(amount, 1)
	p.lifetime = 9.0 if kind == "snow" else 7.0
	p.preprocess = p.lifetime
	p.local_coords = false
	p.texture = _soft_tex
	p.process_material = _particle_material(kind, front, extents)
	p.visibility_rect = Rect2(-extents * 2.0, extents * 4.0)
	p.z_index = 40 if front else -3
	p.z_as_relative = false
	return p


func _build_particles(_target: Node) -> void:
	var level := int(gfx("particles"))
	if level <= 0:
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var kind := String(_theme["particles"])
	var size := get_viewport().get_visible_rect().size / cam.zoom
	var extents := size * 0.68
	var back_amount: int = [0, 45, 95, 170][clampi(level, 0, 3)]
	var front_amount: int = [0, 0, 12, 26][clampi(level, 0, 3)]
	cam.add_child(_deco(_make_particles(kind, false, back_amount, extents)))
	if front_amount > 0:
		cam.add_child(_deco(_make_particles(kind, true, front_amount, extents)))


func _build_menu_fx(scene: Node) -> void:
	var bg := scene.get_node_or_null("Background") as TextureRect
	var mat: ShaderMaterial = null
	if bg != null and bool(gfx("bg_fx")):
		_use_hd_texture(bg)
		mat = ShaderMaterial.new()
		mat.shader = BACKDROP_SHADER
		mat.set_shader_parameter("use_texture", true)
		mat.set_shader_parameter("blur", 0.0)
		mat.set_shader_parameter("zoom", 0.94)
		mat.set_shader_parameter("fog_color", Color(0.22, 0.1, 0.32))
		mat.set_shader_parameter("fog", 0.04)
		mat.set_shader_parameter("haze", 0.3)
		mat.set_shader_parameter("rays", 0.75)
		mat.set_shader_parameter("ray_color", Color(1.0, 0.78, 0.95))
		mat.set_shader_parameter("ray_x", 0.86)
		mat.set_shader_parameter("exposure", 1.0)
		mat.set_shader_parameter("saturation", 1.05)
		bg.material = mat
	if bool(gfx("detail")) or bool(gfx("bg_fx")):
		var fx := Control.new()
		fx.set_script(MENU_FX)
		fx.set("background_mat", mat)
		var isme := scene.get_node_or_null("Isme") as Node2D
		if isme != null:
			fx.set("stage_pos", isme.position + Vector2(0.0, 4.0))
		scene.add_child(_deco(fx))
		var tint := scene.get_node_or_null("Tint")
		scene.move_child(fx, tint.get_index() + 1 if tint != null else 1)
	var title := scene.get_node_or_null("TitleBox/TitleLabel") as CanvasItem
	if title != null and bool(gfx("post_fx")):
		var tm := ShaderMaterial.new()
		tm.shader = TITLE_SHADER
		title.material = tm


func _build_menu_particles(scene: Node) -> void:
	var level := int(gfx("particles"))
	if level <= 0:
		return
	var size := get_viewport().get_visible_rect().size
	var p := _make_particles("embers_soft", true, [0, 40, 80, 140][clampi(level, 0, 3)], size * 0.55)
	p.local_coords = true
	p.position = size * 0.5
	p.z_index = 0
	p.z_as_relative = true
	scene.add_child(_deco(p))
	scene.move_child(p, 0)


func _build_foreground(scene: Node) -> void:
	if not bool(gfx("detail")) or not FOREGROUND_KINDS.has(_theme_name):
		return
	var info: Array = FOREGROUND_KINDS[_theme_name]
	var layer := CanvasLayer.new()
	layer.layer = 0
	var fg := Node2D.new()
	fg.set_script(FOREGROUND)
	fg.set("kind", info[0])
	fg.set("tint", info[1])
	layer.add_child(fg)
	scene.add_child(_deco(layer))


func _decorate_platforms(scene: Node) -> void:
	if not bool(gfx("detail")) and not bool(gfx("bg_fx")):
		return
	var list: Array = []
	_collect_platforms(scene, list)
	var cap_kind := String(_theme.get("cap", ""))
	for p in list:
		var plat := p as Node2D
		var size_v = plat.get("size")
		if not (size_v is Vector2):
			continue
		var sz: Vector2 = size_v
		var mat := ShaderMaterial.new()
		mat.shader = PLATFORM_SHADER
		mat.set_shader_parameter("size", sz)
		var acc: Color = _theme["accent"]
		if int(plat.get("style")) == 1:
			acc = plat.get("accent")
		mat.set_shader_parameter("accent", acc)
		var textured: bool = plat.get("ground_texture") != null
		mat.set_shader_parameter("circuit", 0.55 if textured else 1.0)
		mat.set_shader_parameter("depth_shade", 0.22 if textured else 0.3)
		plat.material = mat
		plat.add_to_group("gfx_platform")
		if bool(gfx("detail")) and cap_kind != "" and sz.x >= 60.0:
			var cap := Node2D.new()
			cap.set_script(PLATFORM_CAP)
			cap.set("kind", cap_kind)
			cap.set("width", sz.x)
			cap.set("height", sz.y)
			cap.set("accent", acc)
			cap.use_parent_material = false
			plat.add_child(_deco(cap))


func _collect_platforms(node: Node, out: Array) -> void:
	for child in node.get_children():
		var s: Script = child.get_script()
		if s != null and s.resource_path == PLATFORM_SCRIPT:
			out.append(child)
		elif child.get_child_count() > 0 and not (child is CanvasLayer):
			_collect_platforms(child, out)


func _decorate_existing(scene: Node) -> void:
	var stack: Array = [scene]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		_decorate_node(n)
		for c in n.get_children():
			stack.append(c)


func _on_node_added(node: Node) -> void:
	if _theme_name == "" or _theme_name == "menu" or _theme_name == "cinematic":
		return
	_decorate_node.call_deferred(node)


func _script_chain_has(s: Script, path: String) -> bool:
	while s != null:
		if s.resource_path == path:
			return true
		s = s.get_base_script()
	return false


func _decorate_node(obj: Variant) -> void:
	if not is_instance_valid(obj) or not (obj is Node):
		return
	var node: Node = obj
	if node.has_meta("_gfx") or _theme_name == "" or _theme_name == "menu" or _theme_name == "cinematic":
		return
	var s: Script = node.get_script()
	if s == null and not node.is_in_group("player"):
		return
	if s != null and EMISSIVE.has(s.resource_path) and bool(gfx("glow")) and node is CanvasItem:
		_mark(node)
		var k: float = EMISSIVE[s.resource_path]
		(node as CanvasItem).self_modulate = Color(k, k, k, 1.0)
		node.add_to_group("gfx_emissive")
		return
	if not (node is CharacterBody2D):
		return
	var is_player := node.is_in_group("player")
	var is_enemy := s != null and _script_chain_has(s, ENEMY_BASE)
	if not is_player and not is_enemy:
		return
	_mark(node)
	var is_boss := s != null and _script_chain_has(s, BOSS_BASE)
	if bool(gfx("shadows")):
		var sh := Node2D.new()
		sh.set_script(CONTACT_SHADOW)
		sh.set("width", 150.0 if is_boss else (62.0 if is_player else 56.0))
		sh.set("max_height", 420.0 if is_boss else 260.0)
		(node as Node2D).add_child(_deco(sh))
	if is_enemy and bool(gfx("lighting")) and int(gfx("preset")) == 3:
		var col = node.get("burst_color")
		var light := PointLight2D.new()
		light.texture = _light_tex
		light.texture_scale = 3.0 if is_boss else 1.5
		light.energy = 0.6 if is_boss else 0.45
		light.color = col if col is Color else Color(1, 0.8, 1)
		light.position = Vector2(0.0, -120.0 if is_boss else -50.0)
		(node as Node2D).add_child(_deco(light))


func _mark(node: Node) -> void:
	node.set_meta("_gfx", true)
	node.add_to_group("gfx_decorated")


func _build_fps_overlay() -> void:
	_fps_layer = CanvasLayer.new()
	_fps_layer.layer = 99
	_fps_label = Label.new()
	_fps_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_fps_label.add_theme_font_size_override("font_size", 18)
	_fps_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.7))
	_fps_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_fps_label.add_theme_constant_override("outline_size", 4)
	_fps_label.anchor_left = 1.0
	_fps_label.anchor_right = 1.0
	_fps_label.offset_left = -130.0
	_fps_label.offset_top = 8.0
	_fps_label.offset_right = -12.0
	_fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fps_layer.add_child(_fps_label)
	add_child(_fps_layer)
	_fps_layer.visible = false
