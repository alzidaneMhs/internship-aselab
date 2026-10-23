shader_type canvas_item;

uniform bool use_texture = true;
uniform float blur = 1.2;
uniform float zoom = 0.94;
uniform vec2 drift = vec2(0.0);
uniform vec4 fog_color : source_color = vec4(0.25, 0.12, 0.32, 1.0);
uniform float fog = 0.15;
uniform float haze = 0.3;
uniform vec4 ray_color : source_color = vec4(1.0, 0.85, 0.7, 1.0);
uniform float rays = 0.3;
uniform float ray_x = 0.35;
uniform float exposure = 1.0;
uniform float saturation = 1.0;
uniform vec4 top_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float top_shade = 0.0;

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

void fragment() {
	vec2 suv = UV;
	vec3 c;
	if (use_texture) {
		vec2 uv = (UV - 0.5) * zoom + 0.5 + drift;
		vec2 px = TEXTURE_PIXEL_SIZE * blur;
		vec3 acc = texture(TEXTURE, uv).rgb * 0.16;
		float wsum = 0.16;
		int taps = blur > 0.01 ? 8 : 0;
		for (int i = 0; i < taps; i++) {
			float a = float(i) * 0.785398 + 0.39;
			vec2 o = vec2(cos(a), sin(a));
			acc += texture(TEXTURE, uv + o * px).rgb * 0.07;
			acc += texture(TEXTURE, uv + o * px * 2.1).rgb * 0.035;
			wsum += 0.105;
		}
		acc /= wsum;
		c = acc * COLOR.rgb;
	} else {
		c = COLOR.rgb;
	}
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	c *= exposure;
	c = mix(c, top_color.rgb, top_shade * (1.0 - smoothstep(0.0, 0.55, suv.y)));
	float mist = noise(suv * vec2(3.0, 6.0) + vec2(TIME * 0.025, TIME * 0.01) + drift * 4.0) * 0.6 + noise(suv * vec2(7.0, 12.0) - vec2(TIME * 0.04, 0.0)) * 0.4;
	float fog_amt = clamp(fog + haze * smoothstep(0.45, 1.0, suv.y) * (0.6 + 0.6 * mist), 0.0, 0.92);
	c = mix(c, fog_color.rgb, fog_amt);
	vec2 o = vec2(ray_x, -0.25);
	vec2 dir = suv - o;
	float ang = atan(dir.x, dir.y);
	float b1 = 0.5 + 0.5 * sin(ang * 23.0 + TIME * 0.35);
	float b2 = 0.5 + 0.5 * sin(ang * 37.0 - TIME * 0.22 + 1.3);
	float beams = pow(b1 * b2, 2.5);
	float fall = smoothstep(1.35, 0.1, length(dir)) * smoothstep(-0.05, 0.25, suv.y);
	c += ray_color.rgb * beams * fall * rays;
	COLOR = vec4(c, 1.0);
}
