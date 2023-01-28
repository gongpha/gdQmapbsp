extends QmapbspBaseLoader
class_name QmapbspWorldImporter

## An abstract extension.
## Provides only fundamental properties.
## For loading the map into the nodes, see [QmapbspWorldImporterBasic].

func _start() : pass
	
# for loading textures from the wad/bsp file
func _get_bsp_palette() -> PackedColorArray : return PackedColorArray()
func _get_region_size() -> float : return 0.5
func _get_unit_scale_f() -> float : return 32.0
func _get_custom_bsp_textures_shader() -> Shader :
	return preload(
		"../resource/shader/surface.gdshader"
	)

func _texture_get_no_texture() -> Material :
	var t := StandardMaterial3D.new()
	t.albedo_color = Color.RED
	return t

func _texture_get(name : String, size : Vector2i) -> Material :
	return null
	
func _texture_get_material_for_integrated(
	name : String, itex : ImageTexture
) -> Material :
	return null

###########################################
# entities (models & worldspawn)
func _entity_your_mesh(
	ent_id : int,
	mesh : ArrayMesh, xform : Transform3D
) -> void : pass

func _entity_your_shape(
	ent_id : int,
	shape : Shape3D, origin : Vector3
) -> void :
	pass

func _entity_prefers_region_partition(model_id : int) -> bool :
	return false
	
func _entity_node_directory_path() -> String :
	return "res://addons/qmapbsp/class/"

func _entity_your_properties(entity : Dictionary) -> void :
	_entity_your_cooked_properties(entity)
	
func _entity_your_cooked_properties(entity : Dictionary) -> void :
	var classname : String = entity.get('classname')
	entity['origin'] = QmapbspMapFormat.expect_vec3(entity.get('origin', ''))
	entity['angle'] = QmapbspMapFormat.expect_int(entity.get('angle', ''))
	entity['model'] = QmapbspMapFormat.expect_int(entity.get('model', '*-1').substr(1))
	
#########################################

func __sections__() -> Dictionary : return {
	&'GATHERING_ALL_ENTITIES' : _GatheringAllEntities
}
	
var mapp : QmapbspMAPParser
var bspp : QmapbspBSPParser

#############################################
# public methods

func begin_load(mapbsp_name : String, basedir : String, ret := []) -> StringName :
	return begin_load_absolute(
		basedir.path_join(mapbsp_name + '.map') if !mapbsp_name.is_empty() else
		'',
		basedir.path_join(mapbsp_name + '.bsp') if !mapbsp_name.is_empty() else
		'',
		ret
	)

func begin_load_absolute(map_path : String, bsp_path : String, ret := []) -> StringName :
	var M : FileAccess
	var B : FileAccess
	
	if !map_path.is_empty() :
		M = FileAccess.open(map_path, FileAccess.READ)
		if !M :
			ret.append(FileAccess.get_open_error())
			return &'CANNOT_OPEN_MAP_FILE'
			
	if !bsp_path.is_empty() :
		B = FileAccess.open(bsp_path, FileAccess.READ)
		if !B :
			ret.append(FileAccess.get_open_error())
			return &'CANNOT_OPEN_BSP_FILE'
		
	return begin_load_files(M, B, ret)
	
func begin_load_files(mapf : FileAccess, bspf : FileAccess, ret := []) -> StringName :
	if mapf :
		mapp = QmapbspMAPParser.new()
		mapp.begin_file(mapf)
		mapp.tell_collision_shapes.connect(_entity_your_shape)
	if bspf :
		bspp = QmapbspBSPParser.new()
		bspp.begin_file(bspf)
	__ret = ret
		
	return StringName()
	
func entity_current_region() -> Vector3i :
	return Vector3i()

#############################################
var mapp_s := [0]
var bspp_s := [0]
	
func _race(sec : int) -> float :
	#var err : StringName
	var localp : float = 0.0
	var valid : int = 0
	for e in [
		[mapp, mapp_s],
		[bspp, bspp_s],
	] :
		if e[1][0] != sec : continue
		var l : QmapbspBaseParser = e[0]
		if !l : continue
		var err : StringName = l.poll()
		if err != &'END' and err != StringName() :
			__ret.append_array(l.__ret)
			__error = err
			return 0.0
		valid += 1
		localp += l.get_local_progress()
		e[1][0] = l.load_section
		
	var prog := (localp / valid) if valid != 0 else 0.0
	if prog >= 1.0 :
		return 1.0
		
	print(prog)
	return prog
	
func _GatheringAllEntities() -> float : return _race(0)

#############################################
# DO NOT TOUCH

var no_texture : Material
func get_no_texture() -> Material :
	if !no_texture : no_texture = _texture_get_no_texture()
	return no_texture
