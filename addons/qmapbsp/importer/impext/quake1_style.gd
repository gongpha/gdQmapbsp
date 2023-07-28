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
	texture : Image, texture_meta : Image
) -> Array :
	if texture_name.begins_with('sky') :
		var sky_fg : Image = Image.create(
			texture.get_width() / 2,
			texture.get_height(), false, texture.get_format()
		)
		
		sky_fg.blit_rect(texture, Rect2i(Vector2(), sky_fg.get_size()), Vector2i())
		
		sky_fg.convert(Image.FORMAT_RGBA8)
		var alpha0 := Color(0.0, 0.0, 0.0, 0.0)
		var calpha := Color(0.0, 0.0, 0.0, 1.0)
		for x in sky_fg.get_width() :
			for y in sky_fg.get_width() :
				if sky_fg.get_pixel(x, y).is_equal_approx(calpha) :
					sky_fg.set_pixel(x, y, alpha0)
		
		var sky_bg : Image = Image.create(
			texture.get_width() / 2,
			texture.get_height(), false, texture.get_format()
		)
		
		sky_bg.blit_rect(texture, Rect2i(Vector2(texture.get_width() / 2, 0), sky_fg.get_size()), Vector2i())
		
		sky_bg.generate_mipmaps()
		sky_fg.generate_mipmaps()
		sky_fg.fix_alpha_edges()
		
		var tex_fg := ImageTexture.create_from_image(sky_fg)
		var tex_bg := ImageTexture.create_from_image(sky_bg)
		
		var sky : ShaderMaterial = specials.get(texture_name)
		if !sky :
			sky = load("res://quake1_example/material/sky.tres")
			sky.set_shader_parameter(&'skytex_fg', tex_fg)
			sky.set_shader_parameter(&'skytex_bg', tex_bg)
			
			specials[texture_name] = sky
			sky.set_meta(&'sky', true)
		return [sky, tex_fg.get_size()]
	elif texture_name.begins_with('*') :
		var itexture := ImageTexture.create_from_image(texture)
		var fluid : ShaderMaterial = specials.get(texture_name)
		if !fluid :
			fluid = ShaderMaterial.new()
			fluid.shader = preload("res://quake1_example/material/fluid.gdshader")
			fluid.set_shader_parameter(&'tex', itexture)
			fluid.set_meta(&'fluid', true)
			specials[texture_name] = fluid
		return [fluid, itexture.get_size()]
		
	########################################################
	
	var surfacemat : ShaderMaterial = ShaderMaterial.new()
	surface_materials[index] = surfacemat
	surfacemat.shader = surface_shader
	
	var itexture := ImageTexture.create_from_image(texture)
	var itexture_meta := ImageTexture.create_from_image(texture_meta)
	
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
			textures_diffuse[framei] = itexture
			textures_meta[framei] = itexture_meta
			
			grouped_textures_idx_r.append([index, groupn])
	#else :
	var textures_diffuse : Array[Texture2D]
	var textures_meta : Array[Texture2D]
	textures_diffuse.resize(10)
	textures_meta.resize(10)
	textures_diffuse[0] = itexture
	textures_meta[0] = itexture_meta
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

func _entity_your_mesh(
	ent_id : int,
	brush_id : int,
	mesh : ArrayMesh, origin : Vector3,
	region
) -> void :
	super(ent_id, brush_id, mesh, origin, region)
	
	# z-fighting fix
	if ent_id == 0 : return
	var invf := 1.0 / _get_unit_scale_f() * 0.01
	last_added_meshin.translate(Vector3(invf, invf, invf))
