## An extension that has Quake1-like features
extends QmapbspWorldImporterScene
class_name QmapbspWorldImporterQuake1Style

var surface_shader : QmapbspQuake1StyleShader
var surface_materials : Array[ShaderMaterial]

# volatiles
var global_textures : Array[Texture2D]
var grouped_textures_idx : Dictionary # <group_name : String, [[textures_diffuse : ImageTexture...], [textures_meta : ImageTexture...]>
var grouped_textures_idx_r : Array[Array] # [texture_index : int, group_name : String]...
	
var specials : Dictionary # <name : ShaderMaterial>
	
func _begin() -> void :
	
	# known issues : the global shader uniforms don't work
	#				 when added from the project settings
	RenderingServer.global_shader_parameter_add(
		&'lightstyle_tex',
		RenderingServer.GLOBAL_VAR_TYPE_SAMPLER2D,
		null
	)
	RenderingServer.global_shader_parameter_add(
		&'lightmap_tex',
		RenderingServer.GLOBAL_VAR_TYPE_SAMPLER2D,
		null
	)
	
	surface_shader = QmapbspQuake1StyleShader.new()
	surface_shader.rebuild_shader()

func _texture_get_mip_count(size : int) -> void :
	surface_materials.resize(size)
	
func _texture_your_bsp_texture(
	index : int, texture_name : String,
	texture : ImageTexture, texture_meta : ImageTexture
) -> Array :
	if texture_name.begins_with('sky') :
		var sky : ShaderMaterial = specials.get(texture_name)
		if !sky :
			sky = load("res://quake1_example/material/sky.tres")
			sky.set_shader_parameter(&'skytex', texture)
			if texture_name == 'sky4' :
				sky.set_shader_parameter(&'threshold', 0.4)
			specials[texture_name] = sky
			sky.set_meta(&'sky', true)
		return [sky, texture.get_size()]
	elif texture_name.begins_with('*') :
		var fluid : ShaderMaterial = specials.get(texture_name)
		if !fluid :
			fluid = ShaderMaterial.new()
			fluid.shader = preload("res://quake1_example/material/fluid.gdshader")
			fluid.set_shader_parameter(&'tex', texture)
			fluid.set_meta(&'fluid', true)
			specials[texture_name] = fluid
		return [fluid, texture.get_size()]
		
	########################################################
	
	var surfacemat : ShaderMaterial = ShaderMaterial.new()
	surface_materials[index] = surfacemat
	surfacemat.shader = surface_shader
	
	# distinguish texture groups
	if texture_name.unicode_at(0) == 43 : # +
		var groupi : String
		var framei : int
		
		var u := texture_name.unicode_at(1)
		if u >= 48 and u <= 57 :
			groupi = '0'
			framei = u - 48
		elif u >= 97 and u <= 106 :
			groupi = '1'
			framei = u - 97
			
		var groupn : String = groupi + texture_name.substr(2)
			
		if !groupn.is_empty() :
			var arr2 : Array
			var textures_diffuse : Array[Texture2D]
			var textures_meta : Array[Texture2D]
			if grouped_textures_idx.has(groupn) :
				arr2 = grouped_textures_idx[groupn]
				textures_diffuse = arr2[0]
				textures_meta = arr2[1]
			else :
				arr2.append(textures_diffuse)
				arr2.append(textures_meta)
				grouped_textures_idx[groupn] = arr2
				
			if framei >= textures_diffuse.size() :
				textures_diffuse.resize(framei + 1)
				textures_meta.resize(framei + 1)
			textures_diffuse[framei] = texture
			textures_meta[framei] = texture_meta
			
			grouped_textures_idx_r.append([index, groupn])
	#else :
	var textures_diffuse : Array[Texture2D]
	var textures_meta : Array[Texture2D]
	textures_diffuse.resize(10)
	textures_meta.resize(10)
	textures_diffuse[0] = texture
	textures_meta[0] = texture_meta
	surfacemat.set_shader_parameter(&'tex', textures_diffuse)
	surfacemat.set_shader_parameter(&'texf', textures_meta)
		
	if index + 1 == surface_materials.size() :
		# last
		for e in grouped_textures_idx_r :
			surfacemat = surface_materials[e[0]]
			var pair : Array = grouped_textures_idx[e[1]]
			
			var a : Array[Texture2D]
			var b : Array[Texture2D]
			for f in pair[0] :
				a.append(f)
			for f in pair[1] :
				b.append(f)
			
			surfacemat.set_shader_parameter(&'tex', a)
			surfacemat.set_shader_parameter(&'texf', b)
			surfacemat.set_shader_parameter(&'frame_count', a.size())
		
		grouped_textures_idx.clear()
		grouped_textures_idx_r.clear()
		surface_materials.clear()
	return [surfacemat, texture.get_size()]
	
func _texture_your_lightmap_texture(lmtex : ImageTexture) -> void :
	RenderingServer.global_shader_parameter_set(
		&'lightmap_tex',
		lmtex
	)
	
func _texture_read_lightmap_texture() -> bool : return true

const UUU := 0.0 # reserved
func _model_put_custom_data(
	# out
	customs : Array,
	
	# in
	texture_index : int,
	lightmap_position : float,
	lightmap_texel : float,
	lights : Color,
	lightstyle : int
) :
	customs[0] = Color(UUU, lightstyle, lightmap_position, lightmap_texel)
	customs[1] = Color(lights)
