## A simple extension for loading textures from FileSystem
extends QmapbspWorldImporterScene
class_name QmapbspWorldImporterCustomTextures

# VVV - override your own - VVV #

## Returns all supported file extensions for finding a texture
func _get_extensions() -> PackedStringArray :
	return PackedStringArray([
		'tres', 'material',
		'png', 'jpeg', 'jpg'
	])
	
## Returns the texture directory path that contains texture resources
func _texture_get_dir() -> String :
	return "res://textures/"
	
## Constructs new material from textures that were recognized as Texture2D
func _construct_new_material(texture : Texture2D) -> Material :
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = texture
	return mat
	
#################################################
var _created_textures : Dictionary # <name, [Material, size : Vector2i]>

func _texture_include_bsp_textures() -> bool : return true

func _rename_texture(name : String) -> String : return name

func _build_paths(
	name : String
) -> PackedStringArray :
	var exts := _get_extensions()
	var texdir := _texture_get_dir()
	var paths : PackedStringArray
	for e in exts :
		paths.append(texdir.path_join('%s.%s' % [_rename_texture(name), e]))
	return paths

func _texture_get_material(
	index : int, texture_name : String, texture_size : Vector2i
) -> Array :
	var existed : Array = _created_textures.get(texture_name, [])
	if !existed.is_empty() : return existed
	
	var paths := _build_paths(texture_name)
	var rsc : Array
	
	# finding the best resource file for this texture
	for p in paths :
		if !ResourceLoader.exists(p) : continue
		var mat_or_tex2d = load(p)
		if mat_or_tex2d is Texture2D :
			rsc = [_construct_new_material(mat_or_tex2d), mat_or_tex2d.get_size()]
			_created_textures[texture_name] = rsc
			return rsc
		elif mat_or_tex2d is StandardMaterial3D :
			if mat_or_tex2d.albedo_texture :
				rsc = [mat_or_tex2d, mat_or_tex2d.albedo_texture.get_size()]
				_created_textures[texture_name] = [rsc]
				return rsc
	return super(index, texture_name, texture_size)
