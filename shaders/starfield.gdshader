shader_type canvas_item;

uniform vec2 offset = vec2(0.0);
uniform float warp = 0.0;
uniform vec4 nebula_a : source_color = vec4(0.45, 0.15, 0.6, 1.0);
uniform vec4 nebula_b : source_color = vec4(0.1, 0.45, 0.6, 1.0);
uniform float danger = 0.0;

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
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p = p * 2.1 + vec2(1.3, 7.7);
		a *= 0.5;
	}
	return v;
}

float stars(vec2 uv, float density, float size) {
	vec2 g = floor(uv * density);
	vec2 f = fract(uv * density) - 0.5;
	float h = hash(g);
	if (h < 0.86) {
		return 0.0;
	}
	vec2 jitter = vec2(hash(g + 3.1), hash(g + 7.3)) - 0.5;
	float d = length(f - jitter * 0.6);
	float tw = 0.6 + 0.4 * sin(TIME * (1.5 + h * 4.0) + h * 40.0);
	return smoothstep(size, 0.0, d) * tw * (h - 0.86) * 7.0;
}

void fragment() {
	vec2 uv = SCREEN_UV * vec2(1.7778, 1.0);
	vec3 col = vec3(0.01, 0.008, 0.03);
	vec2 q = uv * 1.4 + offset * 0.05;
	float n1 = fbm(q + vec2(TIME * 0.004, 0.0));
	float n2 = fbm(q * 1.7 - vec2(0.0, TIME * 0.006) + 5.0);
	vec3 neb = nebula_a.rgb * smoothstep(0.45, 0.85, n1) * 0.55 + nebula_b.rgb * smoothstep(0.5, 0.9, n2) * 0.45;
	neb = mix(neb, vec3(0.6, 0.06, 0.05) * smoothstep(0.4, 0.9, n1), danger * 0.7);
	col += neb;
	vec2 s1 = uv + offset * 0.02;
	vec2 s2 = uv + offset * 0.05;
	vec2 s3 = uv + offset * 0.1;
	if (warp > 0.0) {
		vec2 c = vec2(0.889, 0.5);
		s3 = c + (s3 - c) / (1.0 + warp * 0.6);
	}
	col += vec3(0.8, 0.85, 1.0) * stars(s1, 90.0, 0.08);
	col += vec3(1.0, 0.95, 0.85) * stars(s2, 45.0, 0.1) * 1.3;
	col += vec3(0.9, 0.95, 1.0) * stars(s3, 22.0, 0.12) * 1.8;
	if (warp > 0.0) {
		vec2 c2 = vec2(0.889, 0.5);
		vec2 d = uv - c2;
		float ang = atan(d.y, d.x);
		float streak = step(0.93, hash(vec2(floor(ang * 60.0), 3.0)));
		float rad = length(d);
		col += vec3(0.8, 0.9, 1.0) * streak * smoothstep(0.1, 0.9, rad) * warp * 0.9;
	}
	COLOR = vec4(col, 1.0);
}
