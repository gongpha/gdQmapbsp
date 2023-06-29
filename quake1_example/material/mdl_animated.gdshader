shader_type spatial;
render_mode specular_disabled;

uniform sampler2D skin : source_color;

uniform sampler2D animation;
uniform vec3 scale;
uniform vec3 origin;
uniform float seek;

void vertex() {
	vec2 pixhalf = 1.0 / vec2(textureSize(animation, 0)) * 0.5f;
	vec3 v = vec3(
		255.0f * texture(animation, vec2(CUSTOM0.x, seek) + pixhalf).xyz
	) * scale + origin;
	VERTEX = vec3(-v.x, v.z, v.y);
}

void fragment() {
	ROUGHNESS = 1.0f;
	METALLIC = 0.0f;
	ALBEDO.rgb = texture(skin, UV).rgb;
}
