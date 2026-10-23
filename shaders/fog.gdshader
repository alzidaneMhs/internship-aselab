shader_type canvas_item;

uniform vec2 cam = vec2(0.0);
uniform vec4 fog_color : source_color = vec4(0.5, 0.3, 0.6, 1.0);
uniform float density = 0.2;
uniform float parallax = 0.00035;
uniform float low_bias = 0.7;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = SCREEN_UV * vec2(1.7778, 1.0);
	vec2 p = uv * 2.2 + cam * parallax + vec2(TIME * 0.03, TIME * 0.008);
	float f = fbm(p);
	float f2 = fbm(p * 0.5 - vec2(TIME * 0.015, 0.0) + 7.0);
	float shape = smoothstep(0.35, 0.85, f * 0.6 + f2 * 0.6);
	float vertical = mix(1.0 - low_bias, 1.0, smoothstep(0.15, 1.0, SCREEN_UV.y));
	COLOR = vec4(fog_color.rgb, clamp(shape * density * vertical, 0.0, 0.85));
}
