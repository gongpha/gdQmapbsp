shader_type spatial;
render_mode unshaded;

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
varying flat int lstyles;
varying float lwidth;
varying float lights[4];

void vertex() {
	lights = {
		(CUSTOM1.x < 12.0) ? lightstyles[int(CUSTOM1.x)] : 1.0,
		(CUSTOM1.y < 12.0) ? lightstyles[int(CUSTOM1.y)] : 1.0,
		(CUSTOM1.z < 12.0) ? lightstyles[int(CUSTOM1.z)] : 1.0,
		(CUSTOM1.w < 12.0) ? lightstyles[int(CUSTOM1.w)] : 1.0
	};
	texidx = int(CUSTOM0.x);
	lstyles = int(CUSTOM0.y);
	lwidth = CUSTOM0.z;
}

void fragment() {
	vec3 color = texture(texs[texidx], UV).xyz;
	
	float lighttotal = 0.0;
	float lcursor = 0.0;
	for (int l = 0; l < 4; l++) {
		if ((lstyles & (1 << l)) == 0) continue;
		lighttotal += texture(lmp, UV2 + vec2(lwidth * lcursor, 0.0)).x * lights[l];
		lcursor += 1.0;
	}
	ALBEDO = color * (lighttotal * 4.0);
	
//	ALBEDO *= hsv2rgb(
//		vec3(
//			float(region.x + region.y + region.z) / 8.0,
//			0.8, 1.0
//		)
//	);
}