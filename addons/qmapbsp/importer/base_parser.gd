extends QmapbspBaseLoader
class_name QmapbspBaseParser

var file : FileAccess
var error : StringName

# in
var wim : QmapbspWorldImporter
var unit_scale : float = 1.0 / 32

signal tell_entity_props(id : int, props : Dictionary)

# entities
var mapf : QmapbspMapFormat

func begin_file(f : FileAccess) -> StringName :
	file = f
	return StringName()

func _GatheringAllEntities() -> float :
	var err : int = mapf.poll(__ret)
	var end := _mapf_after_poll(err)
	
	if end :
		entity_dict = {}
		return 1.0
	return minf(_mapf_prog(), 0.99)
	
func _ImportingData() -> float :
	return 1.0
	
func _ConstructingData() -> float :
	return 1.0
	
func _BuildingData() -> float :
	return 1.0
	
func _BuildingDataCustom() -> float :
	return 1.0
	
const WORLDSPAWN_BRUSH_ENTITIES := [
	# Trenchbroom
	&"func_group",
	# ericw-tools
	&"func_detail",
	&"func_detail_illusionary",
	&"func_detail_wall",
	&"func_detail_fence",
]

var entity_idx := 0
var entity_dict : Dictionary

var entity_first_brush : bool = false
var entity_is_illusionary : bool = false

# !!! a bsp entity count can probably not be the same as a map entity !!!
var worldspawn_entity_count : int = 0

var brushes : Array
func _mapf_after_poll(pollr : int) -> bool :
	match pollr :
		QmapbspMapFormat.PollResult.ERR :
			__error = &'MAP_PARSE_ERROR'
		QmapbspMapFormat.PollResult.BEGIN_ENTITY :
			entity_dict = {}
			entity_first_brush = true
		QmapbspMapFormat.PollResult.END_ENTITY :
			if entity_dict.get('classname') in WORLDSPAWN_BRUSH_ENTITIES :
				# ignore these entities
				_end_entity(0) # treat as Worldspawn
				worldspawn_entity_count += 1
			else :
				_end_entity(
					entity_idx - worldspawn_entity_count
				)
			entity_idx += 1
			
		QmapbspMapFormat.PollResult.FOUND_KEYVALUE :
			var k : StringName = mapf.out[0]
			var v : StringName = mapf.out[1]
			entity_dict[k] = v
			if k == &'mapversion' and v == &'220' :
				mapf.tell_valve_format = true
		QmapbspMapFormat.PollResult.FOUND_BRUSH :
			entity_dict['__qmapbsp_has_brush'] = true
			if entity_first_brush :
				entity_is_illusionary = entity_dict.get('classname') == &'func_detail_illusionary'
				entity_first_brush = false
				
			_brush_found()
		QmapbspMapFormat.PollResult.END :
			return true
	return false
			
func _brush_found() -> void : return
func _end_entity(idx : int) -> void : return
			
func _mapf_prog() -> float :
	return float(mapf.i) / mapf.src.length()

##################################################

func __sections__() -> Dictionary :
	return {
		&'GATHERING_ALL_ENTITIES' : _GatheringAllEntities,
		&'IMPORTING_DATA' : _ImportingData,
		&'CONSTRUCTING_DATA' : _ConstructingData,
		&'BUILDING_DATA' : _BuildingData,
		&'BUILDING_DATA_CUSTOM' : _BuildingDataCustom,
	}

static func _qnor_to_vec3(q : Vector3) -> Vector3 :
	return Vector3(-q.y, q.z, -q.x)
	
static func _read_vec3(f : FileAccess) -> Vector3 :
	return Vector3(
		f.get_float(),
		f.get_float(),
		f.get_float()
	)
	
static func _read_vec3_16(f : FileAccess) -> Vector3 :
	return Vector3(
		f.get_16(),
		f.get_16(),
		f.get_16()
	)
	
func _qpos_to_vec3(q : Vector3) -> Vector3 :
	return _qnor_to_vec3(q) * unit_scale

static func _qnor_to_vec3_read(f : FileAccess) -> Vector3 :
	return _qnor_to_vec3(_read_vec3(f))
	
func _qpos_to_vec3_read(f : FileAccess) -> Vector3 :
	return _qnor_to_vec3(_read_vec3(f)) * unit_scale
	
static func _qnor_to_vec3_read_16(f : FileAccess) -> Vector3 :
	return _qnor_to_vec3(_read_vec3_16(f))
	
func _qpos_to_vec3_read_16(f : FileAccess) -> Vector3 :
	return _qnor_to_vec3(_read_vec3_16(f)) * unit_scale
	
const _1s15 = 1 << 15
const _1s16 = 1 << 16
static func u16to16(u : int) -> int :
	return (u + _1s15) % _1s16 - _1s15
	
static func _read_qvec3_16(f : FileAccess) -> Vector3i :
	return Vector3i(
		u16to16(f.get_16()),
		u16to16(f.get_16()),
		u16to16(f.get_16())
	)

func _read_bbshort(f : FileAccess) -> AABB :
	var min := _read_qvec3_16(f) * unit_scale
	var max := _read_qvec3_16(f) * unit_scale
	max -= min
	#return AABB(min, max)
	min.x += max.x
	return AABB(
		_qnor_to_vec3(min),
		Vector3(max.x, max.z, max.y)
	)

func _read_bbfloat(f : FileAccess) -> AABB :
	var min := _read_vec3(f) * unit_scale
	var max := _read_vec3(f) * unit_scale
	max -= min
	#return AABB(min, max)
	min.x += max.x
	return AABB(
		_qnor_to_vec3(min),
		Vector3(max.x, max.z, max.y)
	)

func _get16as32(f : FileAccess) -> int :
	return u16to16(f.get_16())
