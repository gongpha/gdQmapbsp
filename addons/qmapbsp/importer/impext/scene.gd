## A simple extension for loading map into the nodes.
extends QmapbspWorldImporter
class_name QmapbspWorldImporterScene

# Inputs (can be assigned outside of the class)
var root : Node3D
var owner : Node

var entity_props : Dictionary # <id : Dict>
var entity_nodes : Dictionary # <id : Node>
var entity_is_brush : PackedByteArray # tells if the entitiy has brushes
	
func _entity_your_cooked_properties(id : int, entity : Dictionary) -> void :
	if entity_props.has(id) : return
	super(id, entity)
	entity_props[id] = entity
	_get_entity_node(id)
	
# return the texel size if unwrapping is preferred. Otherwise return a negative value.
func _entity_unwrap_uv2(
	id : int, brush_id : int, mesh : ArrayMesh
) -> float :
	return -1.0
	
var last_added_meshin : MeshInstance3D
func _entity_your_mesh(
	ent_id : int,
	brush_id : int,
	mesh : ArrayMesh, origin : Vector3,
	region
) -> void :
	var node := _get_entity_node(ent_id)
	if !node : return
	
	if !(
		node._qmapbsp_is_brush_visible() if 
		node.has_method(&'_qmapbsp_is_brush_visible') else true
	) : return
	
	last_added_meshin = MeshInstance3D.new()
	last_added_meshin.mesh = mesh
	last_added_meshin.name = 'm%d' % brush_id
	last_added_meshin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	last_added_meshin.set_meta(&'_qmapbsp_region', region)
	
	if ent_id == 0 :
		last_added_meshin.position = origin
	else :
		last_added_meshin.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
		_recenter(node, origin)
	node.add_child(last_added_meshin)
	
	var dict : Dictionary = entity_props.get(ent_id, {})
	if dict.has('__qmapbsp_aabb') :
		var aabb : AABB = dict['__qmapbsp_aabb']
		var aabbb := mesh.get_aabb()
		aabbb.position += origin

		dict['__qmapbsp_aabb'] = aabb.merge(aabbb)
		
	var texel := _entity_unwrap_uv2(ent_id, brush_id, mesh)
		
	if dict.get("classname", "") == "func_blocklight" :
		# only casts shadow
		last_added_meshin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		for i in mesh.get_surface_count() :
			mesh.surface_set_material(i, null)
		texel = -1.0
		mesh.lightmap_size_hint = Vector2i(1, 1)
		last_added_meshin.gi_mode = GeometryInstance3D.GI_MODE_STATIC
	
	if owner : last_added_meshin.owner = owner
	if texel >= 0.0 :
		mesh.lightmap_unwrap(Transform3D(), texel)
		
var last_added_occin : OccluderInstance3D
func _entity_your_occluder(
	ent_id : int,
	occluder : ArrayOccluder3D,
) -> void :
	var node := _get_entity_node(ent_id)
	if !node : return
	
	last_added_occin = OccluderInstance3D.new()
	last_added_occin.occluder = occluder
	last_added_occin.name = 'occin'
	node.add_child(last_added_occin)
	if owner : last_added_occin.owner = owner

var last_added_col : CollisionShape3D
func _entity_your_shape(
	ent_id : int,
	brush_id : int,
	shape : Shape3D, origin : Vector3,
	
	known_texture_names : PackedStringArray
) -> void :
	var node := _get_entity_node(ent_id)
	if !node : return
	
	if !(
		node._qmapbsp_is_brush_solid() if 
		node.has_method(&'_qmapbsp_is_brush_solid') else true
	) : return
	
	last_added_col = CollisionShape3D.new()
	last_added_col.shape = shape
	last_added_col.name = 'c%d' % brush_id
	if ent_id == 0 :
		last_added_col.position = origin
	else :
		_recenter(node, origin)
	node.add_child(last_added_col)
	if owner : last_added_col.owner = owner
	
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

func _entity_node_directory_paths() -> PackedStringArray :
	return [
		"res://addons/qmapbsp/class/"
	]

func _new_entity_node(classname : String) -> Node :
	if classname == "func_occluder" :
		# build occluder
		var occluder
	
	var dirs := _entity_node_directory_paths()
	for d in dirs :
		var rscpath := d.path_join("%s.tscn") % classname
		if ResourceLoader.exists(rscpath) :
			return load(rscpath).instantiate()
		rscpath = d.path_join("%s.scn") % classname
		if ResourceLoader.exists(rscpath) :
			return load(rscpath).instantiate()
		rscpath = d.path_join("%s.gd") % classname
		if !ResourceLoader.exists(rscpath) :
			continue
		var scr : Script = load(rscpath)
		if !scr :
			continue
		return scr.new()
	return null

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
	if dict.has("model") or id == 0 :
		dict['__qmapbsp_has_brush'] = true
		dict['__qmapbsp_aabb'] = AABB()
		
	node.name = '%s%d' % [classname, id]
	if node is Node3D and id != 0 :
		var origin : Vector3 = dict.get('origin', Vector3())
		node.position = origin
		
		if !dict.get('__qmapbsp_has_brush', false) : # it isn't a brush entity
			var angle : int = dict.get('angle', 0)
			node.rotation_degrees.y = angle
	if node.has_method(&'_qmapbsp_ent_props_pre') :
		node._qmapbsp_ent_props_pre(dict)
	root.add_child(node)
	if node.has_method(&'_qmapbsp_ent_props_post') :
		node._qmapbsp_ent_props_post(dict)
	if owner : node.owner = owner
	entity_nodes[id] = node
	return node

func _entity_prefers_region_partition(model_id : int) -> bool :
	return model_id == 0 # worldspawn only

func _entity_prefers_occluder(ent_id : int) -> bool :
	var dict : Dictionary = entity_props.get(ent_id, {})
	if dict.get("classname", "") != "func_occluder" : return false
	return true
	
func _get_occluder_shrink_amount() -> float :
	return super._entity_occluder_shrink_amount(0)

func _entity_occluder_shrink_amount(
	ent_id : int
) -> float :
	var dict : Dictionary = entity_props.get(ent_id, {})
	if dict.get("classname", "") == "func_occluder" : return 0.0
	return _get_occluder_shrink_amount()
	
func _build_point_file_lines() -> bool :
	return false

func _get_point_file_points() -> PackedVector3Array :
	return PackedVector3Array()

func _finally() -> void :
	var pfp := _get_point_file_points()
	if pfp.is_empty() : return
	
	# construct point file lines
	var path3d := Path3D.new()
	var curve := Curve3D.new()
	for p in _get_point_file_points() :
		curve.add_point(p)
	path3d.curve = curve
	path3d.name = &'!!! POINTFILE !!!'
	root.add_child(path3d)
	root.move_child(path3d, 0)
	if owner : path3d.owner = owner
