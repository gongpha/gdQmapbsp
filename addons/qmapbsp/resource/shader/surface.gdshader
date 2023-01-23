shader_type spatial;
render_mode unshaded;

uniform sampler2D tex;
uniform sampler2D lmp : repeat_disable;

// debugging purposes
instance uniform ivec3 region;

vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	ALBEDO = texture(lmp, UV2).xyz * texture(tex, UV).xyz;
//	ALBEDO *= hsv2rgb(
//		vec3(
//			float(region.x + region.y + region.z) / 8.0,
//			0.8, 1.0
//		)
//	);
}