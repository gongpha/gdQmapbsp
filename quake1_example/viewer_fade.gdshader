shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
void fragment() {
	vec3 stex = texture(SCREEN_TEXTURE, SCREEN_UV).xyz;
	float g = dot(stex, vec3(0.5, 0.5, 0.5));
	COLOR.xyz = vec3(0.5, 0.33, 0.2) * g;
}
