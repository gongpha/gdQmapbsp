shader_type spatial;
render_mode unshaded, shadows_disabled;

uniform sampler2D skytex_fg : source_color;
uniform sampler2D skytex_bg : source_color; // has alpha

void fragment()
{
	vec3 view = -(vec4(VIEW, 1.0f) * VIEW_MATRIX).xyz;
	vec2 uv = ((view * (256.0f / view.y)).xz + (TIME * vec2(-8.0f, 8.0f))) / 512.0f;
	vec3 t2 = texture(skytex_bg, uv * 2.0f).xyz;
	uv += (TIME * 0.05f * vec2(-1.0f, 1.0f));
	vec4 t1 = texture(skytex_fg, uv * 2.0f);
	ALBEDO = mix(t2, t1.xyz, t1.a);
}
