extends Shader
class_name QmapbspQuake1StyleShader

@export var texture_filter := BaseMaterial3D.TextureFilter.TEXTURE_FILTER_LINEAR :
	set(v) :
		if texture_filter == v :
			return
		texture_filter = v
		rebuild_shader()

enum TextureMode { NORMAL, UNSHADED, LIGHTMAP, NORMALMAP }
@export var texture_mode := TextureMode.NORMAL :
	set(v) :
		if texture_mode == v :
			return
		texture_mode = v
		rebuild_shader()

## set to "true" to support rendering any Godot lights on lightmaps.
## it is recommended to keep it false if you don't have Godot lights
## in the scene at all for better performance
@export var dynamic_lights := false :
	set(v) :
		if dynamic_lights == v :
			return
		dynamic_lights = v
		rebuild_shader()
		
func _init() -> void :
	rebuild_shader()

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
		'albedo' : albedo
	})
	
func make_render_mode() -> String :
	if dynamic_lights and texture_mode == TextureMode.NORMAL :
		return "render_mode specular_disabled;"
	return "render_mode unshaded, specular_disabled;"
	
func get_albedo() -> String :
	match texture_mode :
		TextureMode.NORMAL :
			if dynamic_lights :
				return """
	ALBEDO = color;
	EMISSION = ALBEDO * mix(
		lightmap(UV2),
		4.0f,
		texture(texf[frame], UV).r
	) * lmboost;
"""
			else :
				return """
	ALBEDO = color * mix(
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

func get_base_code() -> String : 
	return """
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
