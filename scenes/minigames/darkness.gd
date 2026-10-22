extends ColorRect

# Shader ini membuat penutup hitam dengan lubang sorotan.
const FLASHLIGHT_SHADER: String = """
shader_type canvas_item;
render_mode unshaded;

uniform vec2 rect_size = vec2(1.0, 1.0);
uniform vec2 mouse_position = vec2(-1000.0, -1000.0);

uniform float radius = 90.0;
uniform float softness = 24.0;
uniform bool light_on = false;

void fragment() {
    // Ubah posisi UV menjadi koordinat lokal papan.
    vec2 pixel_position = UV * rect_size;

    float distance_to_mouse = distance(
        pixel_position,
        mouse_position
    );

    // Bagian tengah jelas, kemudian memudar menuju tepi.
    float inner_radius = max(radius - softness, 0.0);

    float darkness_alpha = smoothstep(
        inner_radius,
        radius,
        distance_to_mouse
    );

    // Senter padam berarti seluruh area hitam penuh.
    if (!light_on) {
        darkness_alpha = 1.0;
    }

    COLOR = vec4(0.0, 0.0, 0.0, darkness_alpha);
}
"""


@export_range(40.0, 180.0, 1.0)
var light_radius: float = 90.0

@export_range(4.0, 60.0, 1.0)
var edge_softness: float = 24.0

var flashlight_enabled: bool = true

var _mask_material: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var flashlight_shader: Shader = Shader.new()
	flashlight_shader.code = FLASHLIGHT_SHADER

	_mask_material = ShaderMaterial.new()
	_mask_material.shader = flashlight_shader

	material = _mask_material

	_update_flashlight()


func _process(_delta: float) -> void:
	_update_flashlight()


func _update_flashlight() -> void:
	if _mask_material == null:
		return

	var local_mouse: Vector2 = get_local_mouse_position()

	var inside_board: bool = Rect2(
		Vector2.ZERO,
		size
	).has_point(local_mouse)

	var window_focused: bool = get_window().has_focus()

	var light_on: bool = (
		flashlight_enabled
		and inside_board
		and window_focused
	)

	_mask_material.set_shader_parameter(
		"rect_size",
		size
	)

	_mask_material.set_shader_parameter(
		"mouse_position",
		local_mouse
	)

	_mask_material.set_shader_parameter(
		"radius",
		light_radius
	)

	_mask_material.set_shader_parameter(
		"softness",
		edge_softness
	)

	_mask_material.set_shader_parameter(
		"light_on",
		light_on
	)


func set_flashlight_enabled(enabled: bool) -> void:
	flashlight_enabled = enabled
	_update_flashlight()
