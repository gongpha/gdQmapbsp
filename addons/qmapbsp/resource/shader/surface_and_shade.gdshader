shader_type spatial;

uniform int mode = 0;
uniform float lmboost = 4.0;
uniform bool regionhl = false;
uniform sampler2D[96] texs : source_color; // device dependent
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

float lightmap(in vec2 uv2) {
	float lighttotal = 0.0;
	float lcursor = 0.0;
	for (int l = 0; l < 4; l++) {
		if ((lstyles & (1 << l)) == 0) continue;
		lighttotal += texture(lmp, uv2 + vec2(lwidth * lcursor, 0.0)).x * lights[l];
		lcursor += 1.0;
	}
	return lighttotal;
}

void fragment() {
	vec3 color = texture(texs[texidx], UV).xyz;
	
	if (mode == 0) {
		ALBEDO = color * (lightmap(UV2) * lmboost);
	} else if (mode == 1) {
		ALBEDO = color;
	} else if (mode == 2) {
		ALBEDO = vec3(lightmap(UV2));
	}
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
	if (regionhl) {
		ALBEDO *= hsv2rgb(
			vec3(
				float(region.x + region.y + region.z) / 8.0,
				0.8, 1.0
			)
		);
	}
}