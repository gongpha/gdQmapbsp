shader_type spatial;
render_mode unshaded;

uniform sampler2D[256] texs; // not an actual limit
uniform sampler2D lmp : repeat_disable;
uniform float[12] lightstyles;

// for debugging purposes
instance uniform ivec3 region;

vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

varying flat int texidx;
varying vec4 lights;

void vertex() {
	lights = vec4(
		(CUSTOM1.x < 12.0) ? lightstyles[int(CUSTOM1.x)] : 0.0,
		CUSTOM1.y,
		CUSTOM1.z,
		CUSTOM1.w
	);
	texidx = int(CUSTOM0.x);
}

void fragment() {
	float light = lights.x;// + lights.y + lights.z + lights.w;
	vec3 color = texture(texs[texidx], UV).xyz;
	float lightmap = texture(lmp, UV2).x;
	ALBEDO = color * lightmap * light;
//	ALBEDO *= hsv2rgb(
//		vec3(
//			float(region.x + region.y + region.z) / 8.0,
//			0.8, 1.0
//		)
//	);
}