## A simple extension for loading map into the nodes.
extends QmapbspWorldImporter
class_name QmapbspWorldImporterScene

# Inputs (can be assigned outside of the class)
var root : Node3D
var owner : Node

var entity_props : Dictionary # <id : Dict>
var entity_nodes : Dictionary # <id : Node>
var entity_navreg : Dictionary # <id : NavigationRegion3D>
var entity_navreg_raw : Dictionary # <id : NavigationRegion3D>
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
		
	var dict : Dictionary = entity_props.get(ent_id, {})
	var classname : StringName = dict.get("classname", &"")
		
	var navmesh_tem := _get_navmesh_template()
	if navmesh_tem and classname != &'func_navmesh' :
		var navreg : NavigationRegion3D = entity_navreg.get(ent_id, null)
		if !navreg :
			navreg = NavigationRegion3D.new()
			navreg.name = &'nav'
			node.add_child(navreg)
			if owner : navreg.owner = owner
			var navmesh := navmesh_tem.duplicate()
			navreg.navigation_mesh = navmesh
			entity_navreg[ent_id] = navreg
	node.add_child(last_added_meshin)
	if owner : last_added_meshin.owner = owner
	
	if dict.has('__qmapbsp_aabb') :
		var aabb : AABB = dict['__qmapbsp_aabb']
		var aabbb := mesh.get_aabb()
		aabbb.position += origin

		dict['__qmapbsp_aabb'] = aabb.merge(aabbb)
		
	var texel := _entity_unwrap_uv2(ent_id, brush_id, mesh)
	
	if classname == &"func_blocklight" :
		# only casts shadow
		last_added_meshin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		for i in mesh.get_surface_count() :
			mesh.surface_set_material(i, null)
		texel = 128.0
		mesh.lightmap_size_hint = Vector2i(1, 1)
		last_added_meshin.gi_mode = GeometryInstance3D.GI_MODE_STATIC
	elif classname == &'func_navmesh' :
		# actual navmesh
		var n3d : QmapbspFuncNavmesh = node
		n3d.navigation_layers = dict.get("layer", &"1").to_int()

		entity_navreg_raw[ent_id] = node
	else :
		if dict.has('__qmapbsp_lmscale') :
			texel *= float(String(dict['__qmapbsp_lmscale']))
			
		if node.has_method(&'_qmapbsp_get_gi_mode') :
			last_added_meshin.gi_mode = node._qmapbsp_get_gi_mode()
		
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

func _new_entity_node(classname : StringName) -> Node :
	if classname == &"func_occluder" :
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
	return QmapbspUnknownClassname.new()

func _get_entity_node(id : int) -> Node :
	var node : Node = entity_nodes.get(id, null)
	if node : return node
	
	# new node
	var dict : Dictionary = entity_props.get(id, {})
	var classname : StringName = dict.get('classname', &'')
	node = _new_entity_node(classname)
	if !node :
		return null
	elif node is QmapbspUnknownClassname :
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
	if dict.get("classname", &"") != &"func_occluder" : return false
	return true
	
func _get_occluder_shrink_amount() -> float :
	return super._entity_occluder_shrink_amount(0)

func _entity_occluder_shrink_amount(
	ent_id : int
) -> float :
	var dict : Dictionary = entity_props.get(ent_id, {})
	if dict.get("classname", &"") == &"func_occluder" : return 0.0
	return _get_occluder_shrink_amount()
	
func _build_point_file_lines() -> bool :
	return false

func _get_point_file_points() -> PackedVector3Array :
	return PackedVector3Array()
	
func _point_files_simplify_angle() -> float :
	return 0.001

func _finally() -> void :
	var pfp := _get_point_file_points()
	if !pfp.is_empty() :
		# construct point file lines
		var path3d := Path3D.new()
		var curve := Curve3D.new()
		var dir : Vector3
		var dir_passed : int = 0
		
		# simplify lines
		var langle := _point_files_simplify_angle()
		for p in pfp :
			if langle > 0.0 :
				if dir_passed < 2 :
					dir_passed += 1
					if dir_passed == 2 :
						dir = curve.get_point_position(0).direction_to(
							curve.get_point_position(1)
						)
				else :
					var last := curve.point_count - 1
					var ndir = curve.get_point_position(last).direction_to(p)
					if dir.angle_to(ndir) < langle :
						dir = ndir
						curve.set_point_position(last, p)
						continue
					dir = ndir
			curve.add_point(p)
		path3d.curve = curve
		path3d.name = &'!!! POINTFILE !!!'
		root.add_child(path3d)
		root.move_child(path3d, 0)
		if owner : path3d.owner = owner
		
	for k in entity_navreg_raw :
		var n3d : QmapbspFuncNavmesh = entity_navreg_raw[k]
		var nmesh := NavigationMesh.new()
		for m in n3d.get_children() :
			if m is MeshInstance3D :
				nmesh.create_from_mesh(m.mesh)
				m.free()
		n3d.navigation_mesh = nmesh
	entity_navreg_raw.clear()
		
	for k in entity_navreg :
		var n3d : NavigationRegion3D = entity_navreg[k]
		print_verbose("Baking Navmesh %d" % k)
		NavigationServer3D.region_bake_navigation_mesh(
			n3d.navigation_mesh, entity_nodes.get(k)
		)
	entity_navreg.clear()

func _get_navmesh_template() -> NavigationMesh :
	return null
