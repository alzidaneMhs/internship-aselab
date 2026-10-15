extends Node2D

const FX := preload("res://scripts/effects/laser_fx.gd")
const SHADER_CODE := """
shader_type canvas_item;
uniform vec2 center = vec2(0.5, 0.6);
uniform float radius = 0.62;
uniform float softness = 0.6;
uniform float strength = 0.9;
uniform float pulse = 0.0;
uniform vec4 tint : source_color = vec4(0.01, 0.02, 0.03, 1.0);
void fragment() {
	vec2 d = (UV - center) * vec2(1.7778, 1.0);
	float dist = length(d);
	float a = smoothstep(radius - pulse, radius + softness, dist) * strength;
	COLOR = vec4(tint.rgb, a);
}
"""

@export var darkness: float = 0.9
@export var radius: float = 0.62
@export var mist_amount: int = 22

var _overlay: ColorRect
var _material: ShaderMaterial
var _mist: CPUParticles2D
var _player: Node2D
var _time := 0.0
var _dip := 0.0
var _next_dip := 3.0


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = SHADER_CODE
	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("strength", darkness)
	_material.set_shader_parameter("radius", radius)
	_overlay.material = _material
	layer.add_child(_overlay)
	_build_mist()
	_next_dip = randf_range(2.0, 5.0)


func _build_mist() -> void:
	_mist = CPUParticles2D.new()
	_mist.texture = FX.get_glow_texture()
	_mist.amount = mist_amount
	_mist.lifetime = 11.0
	_mist.preprocess = 11.0
	_mist.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_mist.emission_rect_extents = Vector2(760.0, 420.0)
	_mist.direction = Vector2(1.0, -0.15)
	_mist.spread = 40.0
	_mist.gravity = Vector2.ZERO
	_mist.initial_velocity_min = 10.0
	_mist.initial_velocity_max = 26.0
	_mist.scale_amount_min = 7.0
	_mist.scale_amount_max = 13.0
	_mist.local_coords = false
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	ramp.colors = PackedColorArray([Color(0.55, 0.8, 0.72, 0.0), Color(0.55, 0.8, 0.72, 0.075), Color(0.5, 0.7, 0.7, 0.0)])
	_mist.color_ramp = ramp
	_mist.z_index = 4
	add_child(_mist)


func _process(delta: float) -> void:
	_time += delta
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		_mist.global_position = cam.get_screen_center_position()
	_next_dip -= delta
	if _next_dip <= 0.0:
		_dip = 0.14
		_next_dip = randf_range(2.5, 7.0)
	_dip = maxf(_dip - delta * 0.5, 0.0)
	var breathe := 0.015 * sin(_time * 1.3) + (_dip if fmod(_time, 0.2) < 0.1 else 0.0)
	_material.set_shader_parameter("pulse", breathe)
	if _player != null:
		var screen: Vector2 = get_viewport().get_canvas_transform() * (_player.global_position + Vector2(0.0, -48.0))
		var size := get_viewport().get_visible_rect().size
		_material.set_shader_parameter("center", Vector2(screen.x / size.x, screen.y / size.y))
