shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float vignette = 0.35;
uniform float vignette_soft = 0.55;
uniform float aberration = 0.0;
uniform float grain = 0.0;
uniform vec3 tint = vec3(1.0);
uniform vec3 shadow_tint = vec3(0.0);
uniform float saturation = 1.0;
uniform float contrast = 1.0;
uniform float brightness = 1.0;
uniform float bloom_lift = 0.0;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 d = uv - 0.5;
	float r2 = dot(d, d);
	vec3 c;
	if (aberration > 0.0) {
		vec2 off = d * aberration * r2 * 4.0;
		c.r = texture(screen_tex, uv + off).r;
		c.g = texture(screen_tex, uv).g;
		c.b = texture(screen_tex, uv - off).b;
	} else {
		c = texture(screen_tex, uv).rgb;
	}
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	c = (c - 0.4) * contrast + 0.4;
	float shadow = 1.0 - clamp(l * 2.2, 0.0, 1.0);
	c = c * tint + shadow_tint * shadow;
	c += bloom_lift * smoothstep(0.6, 1.4, l) * c;
	c *= brightness;
	float dist = length(d * vec2(1.0, 0.82));
	float v = smoothstep(0.75, 0.75 - vignette_soft, dist);
	c *= mix(1.0 - vignette, 1.0, v);
	if (grain > 0.0) {
		float n = hash(floor(uv * vec2(960.0, 540.0)) + fract(TIME * 7.31) * 113.0);
		c += (n - 0.5) * grain;
	}
	COLOR = vec4(max(c, vec3(0.0)), 1.0);
}
