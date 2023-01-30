## A simple extension for loading map into the nodes.
extends QmapbspWorldImporter
class_name QmapbspWorldImporterBasic

var root : Node3D
var entity_props : Dictionary # <id : Dict>
var entity_nodes : Dictionary # <id : Node>
var entity_is_brush : PackedByteArray # tells if the entitiy has brushes
	
func _entity_your_cooked_properties(id : int, entity : Dictionary) -> void :
	if entity_props.has(id) : return
	super(id, entity)
	entity_props[id] = entity
	_get_entity_node(id)
	
func _entity_your_mesh(
	ent_id : int,
	brush_id : int,
	mesh : ArrayMesh, origin : Vector3
) -> void :
	var node := _get_entity_node(ent_id)
	
	if !(
		node._is_brush_visible() if 
		node.has_method(&'_is_brush_visible') else true
	) : return
	
	var meshin := MeshInstance3D.new()
	meshin.mesh = mesh
	meshin.name = 'meshin%04d' % brush_id
	if ent_id == 0 :
		meshin.position = origin
	else :
		_recenter(node, origin)
	node.add_child(meshin)

func _entity_your_shape(
	ent_id : int,
	brush_id : int,
	shape : Shape3D, origin : Vector3
) -> void :
	var node := _get_entity_node(ent_id)
	
	var col := CollisionShape3D.new()
	col.shape = shape
	col.name = 'col%04d' % brush_id
	if ent_id == 0 :
		col.position = origin
	else :
		_recenter(node, origin)
	node.add_child(col)
	
	if entity_is_brush.size() < ent_id + 1 :
		# extend
		entity_is_brush.resize(ent_id + 1)
		entity_is_brush[ent_id] = 1
	
##############

func _recenter(n : Node3D, new_center_pos : Vector3) -> void :
	var add := n.position - new_center_pos
	n.position = new_center_pos
	for i in n.get_child_count() :
		var c : Node = n.get_child(i)
		if c is Node3D :
			c.position += add

func _entity_node_directory_path() -> String :
	return "res://addons/qmapbsp/class/"

func _new_entity_node(classname : String) -> Node :
	var dir := _entity_node_directory_path()
	var rscpath := dir.path_join("%s.tscn") % classname
	if ResourceLoader.exists(rscpath) :
		return load(rscpath).instantiate()
	rscpath = dir.path_join("%s.scn") % classname
	if ResourceLoader.exists(rscpath) :
		return load(rscpath).instantiate()
	rscpath = dir.path_join("%s.gd") % classname
	if !ResourceLoader.exists(rscpath) :
		return null
	var scr : Script = load(rscpath)
	if !scr :
		return null
	return scr.new()

func _get_entity_node(id : int) -> Node :
	var node : Node = entity_nodes.get(id, null)
	if node : return node
	
	# new node
	var dict : Dictionary = entity_props.get(id, {})
	var classname : String = dict.get('classname', '')
	node = _new_entity_node(classname)
	if !node :
		node = QmapbspUnknownClassname.new()
		node.props = dict
	elif node.has_method(&'_get_properties') :
		node._get_properties(dict)
		
	if dict.has("model") :
		dict['__qmapbsp_has_brush'] = true
		
	if node is Node3D and id != 0 :
		var origin : Vector3 = dict.get('origin', Vector3())
		node.position = origin
		
		if !dict.get('__qmapbsp_has_brush', false) : # it isn't a brush entity
			var angle : int = dict.get('angle', 0)
			node.rotation_degrees.y = 90.0 + angle
	if node.has_method(&'_ent_props') :
		node._ent_props(dict)
	root.add_child(node)
	node.name = '%s%04d' % [classname, id]
	entity_nodes[id] = node
	return node

func _entity_prefers_region_partition(model_id : int) -> bool :
	return model_id == 0 # worldspawn only
