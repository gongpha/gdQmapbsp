shader_type spatial;
//render_mode unshaded;

uniform sampler2D skytex;

void fragment() {
	vec2 uv = (vec4(VIEW, 1.0) * VIEW_MATRIX).xz;
	uv = uv + (TIME * 0.08);
	vec3 t2 = texture(skytex, vec2(
		0.5 + mod(uv.x, 0.5),
		uv.y
	)).xyz;
	uv += (TIME * 0.08);
	vec3 t1 = texture(skytex, vec2(
		mod(uv.x, 0.5),
		uv.y
	)).xyz;
	
	vec3 tf = t1;
	if (t1.x + t1.y + t1.z < 0.2) {
		tf = t2;
	}
	ALBEDO = tf;
}
