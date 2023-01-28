extends QmapbspBaseLoader
class_name QmapbspBaseParser

var file : FileAccess
var error : StringName

# entities
var entity_curr_idx : int = -1
var entities_kv : Array[Dictionary]
var mapf : QmapbspMapFormat

func begin_file(f : FileAccess) :
	file = f

func _GatheringAllEntities() -> float :
	return 1.0

var kv : Dictionary
var brushes : Array
func _mapf_after_poll(pollr : int) :
	match pollr :
		QmapbspMapFormat.PollResult.ERR :
			__error = &'MAP_PARSE_ERROR'
		QmapbspMapFormat.PollResult.BEGIN_ENTITY :
			entity_curr_idx += 1
		QmapbspMapFormat.PollResult.END_ENTITY :
			load_index += 1
		QmapbspMapFormat.PollResult.FOUND_KEYVALUE :
			var k : String = mapf.out[0]
			var v : String = mapf.out[1]
			kv[k] = v
			if k == 'mapversion' and v == '220' :
				mapf.tell_valve_format = true
		QmapbspMapFormat.PollResult.FOUND_BRUSH :
			_brush_found()
			
func _brush_found() : pass
			
func _mapf_prog() -> float :
	return float(mapf.i) / mapf.src.length()

##################################################

func __sections__() -> Dictionary :
	return {
		&'GATHERING_ALL_ENTITIES' : _GatheringAllEntities
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
