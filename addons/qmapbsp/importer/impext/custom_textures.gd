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
var _created_textures : Dictionary # <name, Material>

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

func _texture_get(name : String, size : Vector2i) :
	var existed : Material = _created_textures.get(name, null)
	if existed : return existed
	
	var paths := _build_paths(name)
	var rsc : Resource
	
	# finding the best resource file for this texture
	for p in paths :
		if !ResourceLoader.exists(p) : continue
		rsc = load(p)
		if rsc is Texture2D :
			rsc = _construct_new_material(rsc)
			_created_textures[name] = rsc
			break
		elif rsc is Material :
			break
		rsc = null
		continue
	if !rsc : return super(name, size)
	return rsc
