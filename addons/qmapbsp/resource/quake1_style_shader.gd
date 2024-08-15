extends Shader
class_name QmapbspQuake1StyleShader

# After modifying these variables,
# "rebuild_shader" must be called after it
# VVV - VVV
var texture_filter := BaseMaterial3D.TextureFilter.TEXTURE_FILTER_LINEAR

enum TextureMode { NORMAL, UNSHADED, LIGHTMAP, NORMALMAP }
var texture_mode := TextureMode.NORMAL

## use "true" if you don't desire to have any lights on your scene.
## It's surely faster than the "false" option
## but it will have literally NO lights except the lightmaps.
## That means you can't have gunfire flash effects like
## the Quake's original has.
## (This project used "true" because
##it's intended to be a demonstration of lightmap rendering)
var fully_no_lights := true

# ^^^ - ^^^

func rebuild_shader() -> void :
	var albedo : String
	var texture_albedo_hint : String
	
	match texture_filter :
		BaseMaterial3D.TextureFilter.TEXTURE_FILTER_NEAREST :
			texture_albedo_hint = ", filter_nearest"
	
	albedo = get_albedo()
		
	######################################################
	
	code = get_base_code().format({
		'render_mode' : make_render_mode(),
		'texture_albedo_hint' : texture_albedo_hint,
		'albedo' : albedo,
	})
func make_render_mode() -> String :
	if fully_no_lights :
		return "render_mode unshaded, specular_disabled;"
	return "render_mode specular_disabled;"
	
func get_albedo() -> String :
	match texture_mode :
		TextureMode.NORMAL :
			if fully_no_lights :
				return """
	ALBEDO = color * mix(
		lightmap(UV2),
		4.0f,
		texture(texf[frame], UV).r
	) * lmboost;
"""
			return """
	ALBEDO = color;
	AO = mix(
		lightmap(UV2),
		4.0f,
		texture(texf[frame], UV).r
	) * lmboost;
"""
		TextureMode.UNSHADED :
			return "ALBEDO = color;"
			
		TextureMode.LIGHTMAP :
			return "ALBEDO = vec3(lightmap(UV2));"
			
			
		TextureMode.NORMALMAP :
			return "ALBEDO = NORMAL;"
	return ""

func get_base_code() -> String : return """
shader_type spatial;
{render_mode}

uniform sampler2D tex[20] : source_color{texture_albedo_hint};
uniform sampler2D texf[20];
uniform int frame_count = 1;
uniform int frame_count2 = 1;

global uniform sampler2D lightstyle_tex : filter_nearest, source_color; // 64x1
global uniform float lmboost = 1.0f;
global uniform sampler2D lightmap_tex;

instance uniform bool use_alternate = false; // use +a +b +c ... instead of +0 +1 +2 ...

varying flat int lstyles;
varying float lwidth;
varying float lights[4];
varying float lx2pix;
varying flat int frame;
varying flat int frame_plus;

void vertex() {
	lights = {
		texture(lightstyle_tex, vec2(CUSTOM1.x, 0.0f)).r,
		texture(lightstyle_tex, vec2(CUSTOM1.y, 0.0f)).r,
		texture(lightstyle_tex, vec2(CUSTOM1.z, 0.0f)).r,
		texture(lightstyle_tex, vec2(CUSTOM1.w, 0.0f)).r
	};
	lstyles = int(CUSTOM0.y);
	lwidth = CUSTOM0.z;
	lx2pix = CUSTOM0.w;
	frame = int(TIME * 5.0f) % (use_alternate ? frame_count2 : frame_count);
	frame_plus = use_alternate ? frame_count : 0;
}

float lightmap(in vec2 uv2) {
	float lighttotal = 0.0;
	float lcursor = 0.0;
	for (int l = 0; l < 4; l++) {
		if ((lstyles & (1 << l)) == 0) continue;
		lighttotal += texture(lightmap_tex, uv2 + vec2(lcursor, 0.0)).x * lights[l];
		lcursor += lwidth + lx2pix;
	}
	return lighttotal;
}

void fragment() {
	vec3 color = texture(tex[frame + frame_plus], UV).xyz;
	ROUGHNESS = 1.0f;
	METALLIC = 0.0f;
	
	{albedo}
}

"""
