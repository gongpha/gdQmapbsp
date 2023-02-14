shader_type spatial;

uniform int mode = 0;
uniform float lmboost = 4.0;
uniform bool regionhl = false;
uniform sampler2D[256] texs : source_color; // not an actual limit
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

void vertex() {
	texidx = int(CUSTOM0.x);
}

void fragment() {
	vec3 color = texture(texs[texidx], UV).xyz;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
	ALBEDO = color;
	
	if (regionhl) {
		ALBEDO *= hsv2rgb(
			vec3(
				float(region.x + region.y + region.z) / 8.0,
				0.8, 1.0
			)
		);
	}
}