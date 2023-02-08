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
	return min(_mapf_prog(), 0.99)
	
func _ImportingData() -> float :
	return 1.0
	
func _ConstructingData() -> float :
	return 1.0
	
func _BuildingData() -> float :
	return 1.0
	
func _BuildingDataCustom() -> float :
	return 1.0

var entity_idx := 0
var entity_dict : Dictionary
var brushes : Array
func _mapf_after_poll(pollr : int) -> bool :
	match pollr :
		QmapbspMapFormat.PollResult.ERR :
			__error = &'MAP_PARSE_ERROR'
		QmapbspMapFormat.PollResult.BEGIN_ENTITY :
			entity_dict = {}
		QmapbspMapFormat.PollResult.END_ENTITY :
			if entity_dict.get('classname') == 'func_group' :
				# ignore func_group entity
				_end_entity(0) # treat as Worldspawn
			else :
				_end_entity(entity_idx)
			entity_idx += 1
			
		QmapbspMapFormat.PollResult.FOUND_KEYVALUE :
			var k : String = mapf.out[0]
			var v : String = mapf.out[1]
			entity_dict[k] = v
			if k == 'mapversion' and v == '220' :
				mapf.tell_valve_format = true
		QmapbspMapFormat.PollResult.FOUND_BRUSH :
			entity_dict['__qmapbsp_has_brush'] = true
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
	return Vector3(-q.x, q.z, q.y)
	
static func _read_vec3(f : FileAccess) -> Vector3 :
	return Vector3(
		f.get_float(),
		f.get_float(),
		f.get_float()
	)
	
static func _qnor_to_vec3_read(f : FileAccess) -> Vector3 :
	return _qnor_to_vec3(_read_vec3(f))
	
func _qpos_to_vec3_read(f : FileAccess) -> Vector3 :
	return _qnor_to_vec3(_read_vec3(f)) * unit_scale
	
func _qpos_to_vec3(q : Vector3) -> Vector3 :
	return _qnor_to_vec3(q) * unit_scale
