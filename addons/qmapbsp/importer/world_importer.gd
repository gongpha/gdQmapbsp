extends QmapbspBaseLoader
class_name QmapbspWorldImporter

## An abstract extension.
## Provides only fundamental properties.
## For loading the map into the nodes, see [QmapbspWorldImporterScene].

func _start() : pass
	
# for loading textures from the wad/bsp file
func _get_bsp_palette() -> PackedColorArray : return PackedColorArray()
func _get_unit_scale_f() -> float : return 32.0
func _get_custom_bsp_textures_shader() -> Shader :
	return preload(
		"../resource/shader/surface.gdshader"
	)
	
# Returning [code]false[/code] will ignore all BSP textures and loading slightly faster
func _texture_include_bsp_textures() -> bool :
	return false

func _texture_get_no_texture() -> Material :
	var t := StandardMaterial3D.new()
	t.albedo_color = Color.RED
	return t

## Returns [Material] or [Texture2D] (for lightmaps)
func _texture_get(name : String, size : Vector2i) :
	return null
	
## Calls when using a texture from the BSP file or textures from [code]_texture_get[/code]
## that return [Texture2D]
func _texture_get_material_for_integrated(
	name : String, tex : Texture2D
) -> Material :
	return null
	
func _texture_get_global_surface_material() -> ShaderMaterial :
	return ShaderMaterial.new()

###########################################

func _model_get_region(
	model_id : int,
	face_index : int, facemat : Material
) :
	return null

###########################################
# entities (models & worldspawn)
	

func _entity_your_mesh(
	ent_id : int,
	brush_id : int,
	mesh : ArrayMesh, origin : Vector3,
	region
) -> void : pass
# The brush_id of [code]_entity_your_mesh[/code] and [code]_entity_your_shape[/code] are different !
# Do not reference these ids are the same object 
func _entity_your_shape(
	ent_id : int,
	brush_id : int,
	shape : Shape3D, origin : Vector3,
	
	known_texture_names : PackedStringArray
) -> void :
	pass
	
func _entity_your_occluder(
	ent_id : int,
	occluder : ArrayOccluder3D,
) -> void :
	pass
	
func _entity_occluder_includes_region(
	ent_id : int,
	occluder : ArrayOccluder3D,
	region
) -> bool :
	return true
	
func _entity_occluder_shrink_amount(
	ent_id : int
) -> float :
	return 1.0
	
func _entity_prefers_bsp_geometry(model_id : int) -> bool :
	return true
	
func _entity_prefers_occluder(model_id : int) -> bool :
	return false
	
func _entity_region_size(model_id : int) -> float :
	return 12.0 if _entity_prefers_occluder(model_id) else 32.0

func _entity_prefers_region_partition(model_id : int) -> bool :
	return false
	
func _entity_your_properties(id : int, entity : Dictionary) -> void :
	_entity_your_cooked_properties(id, entity)
	
## Offers essential properties on each entity
func _entity_your_cooked_properties(id : int, entity : Dictionary) -> void :
	var classname : String = entity.get('classname', '')
	if id != 0 :
		entity['origin'] = (
			QmapbspBaseParser._qnor_to_vec3(
				QmapbspMapFormat.expect_vec3(entity.get('origin', ''))
				/ _get_unit_scale_f()
			)
		)
		var angle : int = QmapbspMapFormat.expect_int(entity.get('angle', ''))
		if angle >= 0 : angle += 90
		entity['angle'] = angle
		entity['spawnflags'] = QmapbspMapFormat.expect_int(entity.get('spawnflags', ''))
	
#########################################

func _custom_work_bsp(bsp : RefCounted) -> void :
	return

#########################################

func __sections__() -> Dictionary : return {
	&'GATHERING_ALL_ENTITIES' : [_GatheringAllEntities, 0.5],
	&'IMPORTING_DATA' : _ImportingData,
	&'CONSTRUCTING_DATA' : _ConstructingData,
	&'BUILDING_DATA' : _BuildingData,
	&'BUILDING_DATA_CUSTOM' : [_BuildingDataCustom, 0.1],
}

func _GatheringAllEntities() -> float : return _race(0)
func _ImportingData() -> float :
	bspp.known_map_textures = mapp.known_textures
	return _race(1)
func _ConstructingData() -> float : return _race(2)
func _BuildingData() -> float : return _race(3)
func _BuildingDataCustom() -> float : return _race(4)
	
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
	var err : StringName
	if mapf :
		mapp = QmapbspMAPParser.new()
		err = mapp.begin_file(mapf)
		if err != StringName() : return err
		mapp.tell_collision_shapes.connect(_entity_your_shape)
	if bspf :
		bspp = QmapbspBSPParser.new()
		err = bspp.begin_file(bspf)
		if err != StringName() : return err
		
		bspp.read_miptextures = _texture_include_bsp_textures()
		if bspp.read_miptextures :
			bspp.bsp_shader = _get_custom_bsp_textures_shader()
			bspp.known_palette = _get_bsp_palette()
		
	for e in [mapp, bspp] :
		if !e : continue
		e.wim = self
		e.unit_scale = 1.0 / _get_unit_scale_f()
		e.tell_entity_props.connect(_entity_your_properties)
		
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
		if e[1][0] != sec :
			valid += 1
			localp += 1.0
			continue
		var l : QmapbspBaseParser = e[0]
		if !l :
			continue
		var err : StringName = l.poll()
		if err != &'END' and err != StringName() :
			__ret.append_array(l.__ret)
			__error = err
			return 0.0
		valid += 1
		e[1][0] = l.load_section
		localp += 1.0 if l.load_section != sec else (
			l.get_local_progress()
		)
		
	var prog := (localp / valid) if valid != 0 else 0.0
	if prog >= 1.0 :
		return 1.0
	return prog
	
func _end() :
	# idk if this was a cyclic ref or somehow
	bspp = null
	mapp = null

#############################################
# DO NOT TOUCH

var no_texture : Material
func get_no_texture() -> Material :
	if !no_texture : no_texture = _texture_get_no_texture()
	return no_texture
