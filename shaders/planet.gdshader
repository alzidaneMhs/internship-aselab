shader_type canvas_item;

uniform float rotation = 0.0;
uniform float corruption : hint_range(0.0, 1.0) = 0.0;
uniform vec3 light_dir = vec3(-0.75, -0.35, 0.55);
uniform float cloud_shift = 0.0;
uniform float glow_boost = 1.0;
uniform float planet_scale = 0.862;

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
		p = p * 2.07 + vec2(3.1, 1.7);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 p = (UV * 2.0 - 1.0) / planet_scale;
	float r = length(p);
	vec3 L = normalize(light_dir);
	vec4 outc = vec4(0.0);
	vec3 atmo_col = mix(vec3(0.45, 0.65, 1.0), vec3(1.0, 0.25, 0.2), corruption);
	if (r > 1.0) {
		float edge = 1.0 / planet_scale;
		float halo = exp(-(r - 1.0) * 7.0) * smoothstep(edge * 0.99, edge * 0.72, r);
		float lit = clamp(dot(normalize(vec3(p, 0.0)), L) * 0.6 + 0.55, 0.15, 1.0);
		outc = vec4(atmo_col * glow_boost, halo * 0.85 * lit);
	} else {
		float z = sqrt(1.0 - r * r);
		vec3 n = vec3(p.x, p.y, z);
		float ca = cos(rotation);
		float sa = sin(rotation);
		vec3 rn = vec3(n.x * ca + n.z * sa, n.y, -n.x * sa + n.z * ca);
		float lon = atan(rn.x, rn.z) / 6.2831853;
		float lat = asin(clamp(rn.y, -1.0, 1.0)) / 3.14159;
		vec2 uv = vec2(lon * 4.0, lat * 2.6);
		float h = fbm(uv * 1.6 + vec2(7.0, 2.0));
		float land = smoothstep(0.5, 0.54, h);
		vec3 ocean = mix(vec3(0.06, 0.1, 0.32), vec3(0.12, 0.28, 0.55), smoothstep(0.3, 0.5, h));
		vec3 ground = mix(vec3(0.18, 0.42, 0.42), vec3(0.42, 0.3, 0.6), smoothstep(0.55, 0.75, h));
		ground = mix(ground, vec3(0.75, 0.7, 0.55), smoothstep(0.72, 0.8, h) * 0.6);
		vec3 base = mix(ocean, ground, land);
		vec3 dead = mix(vec3(0.16, 0.05, 0.06), vec3(0.32, 0.12, 0.1), land);
		base = mix(base, dead, corruption * 0.85);
		float cl = fbm(uv * 2.4 + vec2(cloud_shift, 0.0) + 11.0);
		float clouds = smoothstep(0.52, 0.72, cl);
		float diff = clamp(dot(n, L), 0.0, 1.0);
		float term = smoothstep(-0.05, 0.25, dot(n, L));
		vec3 col = base * (0.08 + 1.05 * diff);
		vec3 cloud_col = mix(vec3(1.0), vec3(1.0, 0.55, 0.5), corruption);
		col = mix(col, cloud_col * (0.12 + 1.0 * diff), clouds * 0.85);
		vec2 cell = floor(uv * vec2(70.0, 50.0));
		float city = step(0.86, hash(cell)) * land * (1.0 - clouds);
		float grid = smoothstep(0.42, 0.5, abs(fract(uv.x * 70.0) - 0.5)) + smoothstep(0.42, 0.5, abs(fract(uv.y * 50.0) - 0.5));
		vec3 city_col = mix(vec3(0.35, 1.0, 0.95), vec3(1.0, 0.18, 0.1), corruption);
		col += city_col * (city + grid * 0.06 * land) * (1.0 - term) * 1.6 * glow_boost;
		float veins = smoothstep(0.47, 0.5, fbm(uv * 5.0 + 30.0)) * smoothstep(0.53, 0.5, fbm(uv * 5.0 + 30.0));
		col += vec3(1.0, 0.15, 0.08) * veins * corruption * 1.2;
		float rim = pow(1.0 - z, 3.0);
		col += atmo_col * rim * (0.35 + 0.9 * diff) * glow_boost;
		float edge_aa = smoothstep(1.0, 0.985, r);
		outc = vec4(col, edge_aa);
	}
	COLOR = outc;
}
