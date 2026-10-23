shader_type canvas_item;

uniform float speed = 0.2;
uniform float width = 60.0;
uniform float span = 700.0;
uniform float strength = 0.85;
uniform vec4 shine_color : source_color = vec4(1.0, 0.97, 0.85, 1.0);

varying vec2 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	vec4 c = COLOR;
	float t = fract(TIME * speed);
	float x = -300.0 + t * (span + 900.0);
	float d = abs(lp.x + lp.y * 0.45 - x);
	float band = 1.0 - smoothstep(0.0, width, d);
	float core = 1.0 - smoothstep(0.0, width * 0.25, d);
	float lum = max(c.r, max(c.g, c.b));
	float mask = smoothstep(0.35, 0.7, lum);
	c.rgb = mix(c.rgb, shine_color.rgb, (band * 0.6 + core * 0.4) * strength * mask);
	c.rgb *= 1.0 + 0.06 * sin(TIME * 2.2) * mask;
	COLOR = c;
}
