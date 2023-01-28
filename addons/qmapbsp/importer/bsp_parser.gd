extends QmapbspBaseParser
class_name QmapbspBSPParser

# CURRENTLY SUPPORT QUAKE 1 MAP ONLY

var curr_entry : Vector2i

func begin_file(f : FileAccess) :
	super(f)
	_read_dentry()
	
func _GatheringAllEntities() -> float :
	if !mapf :
		curr_entry = entries['entities']
		file.seek(curr_entry.x)
		var b := file.get_buffer(curr_entry.y).get_string_from_ascii()
		mapf = QmapbspMapFormat.begin_from_text(b)
		#mapf.tell_skip_entity_brushes = true
		
	var ret : Dictionary
	
	var err := mapf.poll(__ret)
	
	var prog := _mapf_prog()
	if prog >= 1.0 :
		entities_kv.clear()
		#mapf = null
		kv = {}
		return 1.0
	return prog
	
func _brush_found() :
	# impossible to reach here
	breakpoint
	
##############################################

var entries : Dictionary # <name : Vector2i (dentry)>

func _read_dentry() :
	for n in ENTRY_LIST :
		entries[n] = Vector2i(file.get_32(), file.get_32())
	
const VEC3_SIZE := 4 * 3 # sizeof(float) * 3
const ENTRY_LIST := [
	'entities', 'planes', 'miptex', 'vertices', 'visilist',
	'nodes', 'texinfo', 'faces', 'lightmaps', 'clipnodes',
	'leaves', 'lface', 'edges', 'ledges', 'models',
]
