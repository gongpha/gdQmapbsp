extends QmapbspBaseLoader
class_name QmapbspWorldImporter

## An abstract extension.
## Provides only fundamental properties.
## For loading the map into the nodes, see [QmapbspWorldImporterScene].
	
# for loading textures from the wad/bsp file
func _get_bsp_palette() -> PackedColorArray : return PackedColorArray()
func _get_unit_scale_f() -> float : return 32.0

func _texture_get_missing_texture() -> Array :
	return [load("res://addons/qmapbsp/texture/missing.tres"), Vector2i(64, 64)]
	
func _texture_get_mip_count(size : int) -> void :
	return
	
# [material, preferred texture size (or just return the argument "texture_size")]
# returns an empty array if want the mip texture
func _texture_get_material(
	index : int, texture_name : String, texture_size : Vector2i
) -> Array :
	return []
	
# returns like the above method
func _texture_your_bsp_texture(
	index : int, texture_name : String,
	texture : Image, texture_meta : Image
) -> Array :
	return []
	
func _texture_read_lightmap_texture() -> bool : return true
	
func _texture_your_lightmap_texture(lmtex : ImageTexture) -> void :
	return

###########################################

func _model_get_region(
	model_id : int,
	face_index : int, facemat : Material
) :
	return null
	
# the "customs" array has allocated 4 slots for putting either null or colors
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
	return

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
	metadata : Dictionary
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
	return 0.75
	
func _entity_prefers_bsp_geometry(model_id : int) -> bool :
	return true
	
# 0 : best (boxshape > convex)
# 1 : convex hull (default)
# 2 : convex hull (simple)
# 3 : trimesh (concave)
# 4 : disabled
func _entity_get_collision_shape_method(ent_id : int) -> int :
	return 0
	
func _entity_prefers_occluder(ent_id : int) -> bool :
	return false
	
# -1 : disabled
func _entity_auto_smooth_degree() -> float :
	return 30
	
func _entity_region_size(ent_id : int) -> float :
	return 12.0 if _entity_prefers_occluder(ent_id) else 32.0

func _entity_prefers_region_partition(model_id : int) -> bool :
	return false
	
func _entity_your_properties(id : int, entity : Dictionary) -> void :
	_entity_your_cooked_properties(id, entity)
	
## Offers essential properties on each entity
func _entity_your_cooked_properties(id : int, entity : Dictionary) -> void :
	var classname : String = entity.get('classname', '')
	if id == 0 : # worldspawn
		entity['spawnflags'] = QmapbspMapFormat.expect_int(entity.get('spawnflags', ''))
		entity['sounds'] = QmapbspMapFormat.expect_int(entity.get('sounds', ''))
		entity['worldtype'] = QmapbspMapFormat.expect_int(entity.get('worldtype', ''))
		entity['light'] = QmapbspMapFormat.expect_int(entity.get('light', ''))
	else:
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
		
	

func _load_clip_nodes() -> bool :
	return false
		
func _load_bsp_nodes() -> bool :
	return false
	
# certainly 0, 1, 2, and 3 are allowed
func _traverse_nodes(model_id : int, hull_id : int) -> bool :
	return true
	
# return true, if want the parser creates a collision shape
# and returns it via _entity_your_shape
func _leaf_your_bsp_planes(
	model_id : int, leaf_type : int,
	planes_const : Array[Plane] # do not modify !
) -> bool :
	return false
	
func _leaf_your_clip_planes(
	model_id : int,
	planes_const : Array[Plane] # do not modify !
) -> bool :
	return false
	
#########################################

func _custom_work_bsp(bsp : RefCounted) -> void :
	return

#########################################

func __sections__() -> Dictionary : return {
	'BEGIN' : [_Begin, 0.5],
	'GATHERING_ALL_ENTITIES' : [_GatheringAllEntities, 0.5],
	'IMPORTING_DATA' : _ImportingData,
	'CONSTRUCTING_DATA' : _ConstructingData,
	'BUILDING_DATA' : _BuildingData,
	'BUILDING_DATA_CUSTOM' : [_BuildingDataCustom, 0.1],
	'FINALLY' : [_Finally, 0.1],
}

func _Begin() -> float :
	_begin()
	return 1.0
func _GatheringAllEntities() -> float : return _race(0)
func _ImportingData() -> float :
	if mapp :
		bspp.known_map_textures = mapp.known_textures
	return _race(1)
func _ConstructingData() -> float : return _race(2)
func _BuildingData() -> float : return _race(3)
func _BuildingDataCustom() -> float : return _race(4)
func _Finally() -> float :
	_finally()
	return 1.0
	
func _begin() -> void : return
func _finally() -> void : return
	
var mapp : QmapbspMAPParser
var bspp : QmapbspBSPParser

#############################################
# public methods

# ! MAP file is optional

func begin_load(mapbsp_name : String, basedir : String, ret := []) -> StringName :
	return begin_load_absolute(
		basedir.path_join(mapbsp_name + '.bsp') if !mapbsp_name.is_empty() else
		'',
		basedir.path_join(mapbsp_name + '.map') if !mapbsp_name.is_empty() else
		'',
		ret
	)

func begin_load_absolute(bsp_path : String, map_path : String = "", ret := []) -> StringName :
	var M : FileAccess
	var B : FileAccess
	
	if !bsp_path.is_empty() :
		B = FileAccess.open(bsp_path, FileAccess.READ)
		if !B :
			ret.append(FileAccess.get_open_error())
			return &'CANNOT_OPEN_BSP_FILE'
	
	if !map_path.is_empty() :
		M = FileAccess.open(map_path, FileAccess.READ)
		if !M :
			ret.append(FileAccess.get_open_error())
			return &'CANNOT_OPEN_MAP_FILE'
		
	return begin_load_files(B, M, ret)
	
func begin_load_files(bspf : FileAccess, mapf : FileAccess = null, ret := []) -> StringName :
	var err : StringName
	if bspf :
		bspp = QmapbspBSPParser.new()
		err = bspp.begin_file(bspf)
		if err != StringName() : return err
		
		bspp.known_palette = _get_bsp_palette()
			
	if mapf :
		mapp = QmapbspMAPParser.new()
		err = mapp.begin_file(mapf)
		if err != StringName() : return err
		mapp.tell_collision_shapes.connect(_entity_your_shape)
		
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

var missing_texture : Array
func get_missing_texture() -> Array :
	if missing_texture.is_empty() :
		missing_texture = _texture_get_missing_texture()
	return missing_texture
