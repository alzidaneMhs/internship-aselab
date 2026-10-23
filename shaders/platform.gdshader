shader_type canvas_item;

uniform vec2 size = vec2(400.0, 200.0);
uniform vec4 accent : source_color = vec4(0.35, 0.95, 1.0, 1.0);
uniform float circuit = 1.0;
uniform float glow = 2.2;
uniform float grain = 0.05;
uniform vec4 rim : source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform float rim_strength = 0.35;
uniform float depth_shade = 0.45;

varying vec2 lp;

void vertex() {
	lp = VERTEX;
}

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec4 c = COLOR;
	float n = hash(floor(lp / 3.0));
	float n2 = hash(floor(lp / 11.0) + 3.1);
	c.rgb *= 1.0 + (n - 0.5) * grain * 2.0 + (n2 - 0.5) * grain;
	float depth = clamp(lp.y / max(size.y, 1.0), 0.0, 1.0);
	c.rgb *= mix(1.0, 1.0 - depth_shade, smoothstep(0.08, 1.0, depth));
	float side = min(lp.x, size.x - lp.x);
	c.rgb *= mix(0.78, 1.0, smoothstep(0.0, 22.0, side));
	float top = 1.0 - smoothstep(0.0, 5.0, lp.y);
	c.rgb += rim.rgb * top * rim_strength;
	float under = smoothstep(4.0, 9.0, lp.y) * (1.0 - smoothstep(9.0, 30.0, lp.y));
	c.rgb *= 1.0 - under * 0.25;
	if (circuit > 0.0 && size.y > 56.0 && size.x > 90.0) {
		float ly = 44.0;
		float line = 1.0 - smoothstep(0.6, 2.2, abs(lp.y - ly));
		float pulse = pow(max(0.0, sin(lp.x * 0.011 - TIME * 2.1)), 22.0);
		float inside = step(10.0, lp.x) * step(lp.x, size.x - 10.0);
		c.rgb += accent.rgb * line * inside * (0.5 + pulse * glow) * circuit;
		float seg = floor(lp.x / 128.0);
		float has = step(0.45, hash(vec2(seg, 7.0)));
		float lx = mod(lp.x, 128.0) - 64.0 + (hash(vec2(seg, 2.0)) - 0.5) * 50.0;
		float len = 30.0 + hash(vec2(seg, 3.0)) * min(size.y - 70.0, 90.0);
		float vline = (1.0 - smoothstep(0.6, 2.0, abs(lx))) * step(ly, lp.y) * step(lp.y, ly + len);
		float vp = pow(max(0.0, sin(lp.y * 0.06 - TIME * 3.0 + seg * 1.7)), 14.0);
		c.rgb += accent.rgb * vline * has * inside * (0.38 + vp * glow) * circuit;
		float node = 1.0 - smoothstep(2.0, 4.5, length(vec2(lx, lp.y - ly - len)));
		c.rgb += accent.rgb * node * has * inside * (0.6 + 0.8 * vp) * circuit;
	}
	COLOR = c;
}
