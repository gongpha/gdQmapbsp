shader_type spatial;
render_mode unshaded;

uniform int mode = 0;
uniform float lmboost = 4.0;
uniform bool regionhl = false;
uniform sampler2D[96] texs : source_color; // device dependent
uniform sampler2D[96] texfs : source_color; // device dependent
uniform sampler2D lmp : repeat_disable;
uniform float[64] lightstyles;

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
varying float lx2pix;
varying float lights[4];

void vertex() {
	lights = {
		lightstyles[int(CUSTOM1.x)],
		lightstyles[int(CUSTOM1.y)],
		lightstyles[int(CUSTOM1.z)],
		lightstyles[int(CUSTOM1.w)]
	};
	texidx = int(CUSTOM0.x);
	lstyles = int(CUSTOM0.y);
	lwidth = CUSTOM0.z;
	lx2pix = CUSTOM0.w;
}

float lightmap(in vec2 uv2) {
	float lighttotal = 0.0;
	float lcursor = 0.0;
	for (int l = 0; l < 4; l++) {
		if ((lstyles & (1 << l)) == 0) continue;
		lighttotal += texture(lmp, uv2 + vec2(lcursor, 0.0)).x * lights[l];
		lcursor += lwidth + lx2pix;
	}
	return lighttotal;
}

void fragment() {
	vec3 color = texture(texs[texidx], UV).xyz;
	
	if (mode == 0) {
		ALBEDO = clamp(color, vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0)) * (mix(
			lightmap(UV2),
			1.0f,
			texture(texfs[texidx], UV).r
		) * lmboost);
	} else if (mode == 1) {
		ALBEDO = color;
	} else if (mode == 2) {
		ALBEDO = vec3(lightmap(UV2));
	} else if (mode == 3) {
		ALBEDO = NORMAL;
	}
	
	if (regionhl) {
		ALBEDO *= hsv2rgb(
			vec3(
				float(region.x + region.y + region.z) / 8.0,
				0.8, 1.0
			)
		);
	}
}