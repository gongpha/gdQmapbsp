## A simple extension for loading textures from FileSystem
extends QmapbspImporterExtension
class_name QmapbspImporterExtensionCustomTextures

# VVV - override your own - VVV #

## Returns all supported file extensions for finding a texture
func _get_extensions() -> PackedStringArray :
	return PackedStringArray([
		'tres', 'material',
		'png', 'jpeg', 'jpg'
	])
	
## Returns the texture directory path that contains texture resources
func _get_texture_dir() -> String :
	return "res://textures/"
	
## Constructs new material from textures that were recognized as Texture2D
func _construct_new_material(texture : Texture2D) -> Material :
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = texture
	return mat
	
#################################################
var _created_textures : Dictionary # <name, Material>

func _get_texture(name : String, size : Vector2i) -> Material :
	var existed : Material = _created_textures.get(name, null)
	if existed : return existed
	
	var exts := _get_extensions()
	var texdir := _get_texture_dir()
	var rsc : Resource
	
	# finding the best resource file for this texture
	for e in exts :
		var path := texdir.path_join('%s.%s' % [name, e])
		if !ResourceLoader.exists(path) : continue
		rsc = load(path)
		if rsc is Texture2D :
			rsc = _construct_new_material(rsc)
			_created_textures[name] = rsc
			break
		elif rsc is Texture2D : break
		rsc = null
		continue
	if !rsc : return super(name, size)
	return rsc
