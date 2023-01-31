shader_type spatial;
render_mode unshaded, shadows_disabled, depth_prepass_alpha;

uniform sampler2D tex;
uniform float alpha = 0.6;

const float AMP = 0.1;

float map(float value, float from, float to) {
	return (value - from) / (to - from);
}

const float WAVES = 5.0;
const float SPEED = 3.0;

void fragment() {
	vec2 uv = UV;
	uv.x -= map(sin(uv.y * WAVES - (TIME * SPEED)), -WAVES, WAVES) - 0.5;
	uv.y += map(sin(uv.x * WAVES - (TIME * SPEED)), -WAVES, WAVES) - 0.5;
	ALBEDO = texture(tex, uv).rgb;
	ALPHA = alpha; // ?
}