shader_type spatial;
render_mode unshaded, shadows_disabled;

uniform sampler2D skytex : source_color;
uniform float threshold = 0.1;

void fragment()
{
	vec3 view = -(vec4(VIEW, 1.0) * VIEW_MATRIX).xyz;
	vec2 uv = ((view * (256.0 / view.y)).xz + (TIME * vec2(-8.0, 8.0))) / 512.0;
	vec3 t2 = texture(skytex, vec2(
		0.5 + mod(uv.x, 0.5),
		uv.y
	)).xyz;
	uv += (TIME * 0.05 * vec2(-1.0, 1.0));
	vec3 t1 = texture(skytex, vec2(
		mod(uv.x, 0.5),
		uv.y * 2.0
	)).xyz;
	
	vec3 tf = t1;
	if ((t1.x + t1.y + t1.z) < threshold) {
		tf = t2;
	}
	ALBEDO = tf;
}
