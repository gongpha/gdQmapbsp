## An example extension that loads Quake1 maps from their pak files
extends QmapbspWorldImporterBasic
class_name QmapbspWorldImporterQuake1

var viewer : QmapbspQuakeViewer
var pal : PackedColorArray
func _get_bsp_palette() -> PackedColorArray : return pal

func _texture_include_bsp_textures() -> bool : return true

func _entity_node_directory_path() -> String :
	return "res://quake1_example/class/"

#func _on_brush_mesh_updated(region_or_model_id, meshin : MeshInstance3D) :
#	var shape : Shape3D
##	var root : Node
#	if region_or_model_id is Vector3i :
#		shape = meshin.mesh.create_trimesh_shape()
##		root = entities_owner[0] # worldspawn
##	else :
##		shape = meshin.mesh.create_convex_shape()
##		root = entities_owner[region_or_model_id]
#
#	var col := CollisionShape3D.new()
#	col.shape = shape
#	col.name = &'generated_col'
#	col.position = meshin.position
#	root.add_child(col)
#

var specials : Dictionary # <name : ShaderMaterial>
var worldspawn_fluid_brush : PackedInt32Array
var added_brush : Dictionary # <worldspawn_brush_id : col>
	
var fluid_area : QmapbspQuakeFluidVolume

func _new_fluid_area() :
	if fluid_area : return
	fluid_area = QmapbspQuakeFluidVolume.new()
	fluid_area.name = &"FLUID"
	root.add_child(fluid_area)

func _texture_get_material_for_integrated(name : String, itex : ImageTexture) -> Material :
	if name.begins_with('sky') :
		var sky : ShaderMaterial = specials.get(name)
		if !sky :
			sky = load("res://quake1_example/material/sky.tres")
			sky.set_shader_parameter(&'skytex', itex)
			if name == 'sky4' :
				sky.set_shader_parameter(&'threshold', 0.4)
			specials[name] = sky
		return sky
	elif name.begins_with('*') :
		var fluid : ShaderMaterial = specials.get(name)
		if !fluid :
			fluid = ShaderMaterial.new()
			fluid.shader = preload("res://quake1_example/material/fluid.gdshader")
			fluid.set_shader_parameter(&'tex', itex)
			fluid.set_meta(&'fluid', true)
			specials[name] = fluid
		return fluid
	return super(name, itex)
	
func _model_get_region(
	model_id : int,
	face_index : int, facemat : Material
) :
	if model_id == 0 :
		if facemat.get_meta(&'fluid', false) :
			return 1 # water (or whatever)
	return 0
	
func _entity_your_mesh(
	ent_id : int,
	brush_id : int,
	mesh : ArrayMesh, origin : Vector3,
	region
) -> void :
	super(ent_id, brush_id, mesh, origin, region)
	if ent_id == 0 and region is int and region == 0 :
		# water (or whatever)
		_new_fluid_area()
		# MOVE
		last_added_meshin.get_parent().remove_child(last_added_meshin)
		fluid_area.add_child(last_added_meshin)
		last_added_meshin.global_position = origin
		
func _entity_your_shape(
	ent_id : int,
	brush_id : int,
	shape : Shape3D, origin : Vector3,
	
	known_texture_names : PackedStringArray
) -> void :
	super(ent_id, brush_id, shape, origin, known_texture_names)
	
	if ent_id == 0 :
		var is_fluid : bool = false
		for s in known_texture_names :
			if s.begins_with('*') :
				is_fluid = true
				break
		if is_fluid :
			_new_fluid_area()
			# MOVE
			last_added_col.get_parent().remove_child(last_added_col)
			fluid_area.add_child(last_added_col)
			last_added_col.position = origin

	
	#if ent_id == 0 and last_added_col :
	#	added_brush[brush_id] = last_added_col
		

func _new_entity_node(classname : String) -> Node :
	var node : Node = super(classname)
	if !node : return null
	
	if classname == 'worldspawn' :
		viewer.worldspawn = node
	
	if node.has_signal(&'emit_message_state') :
		node.connect(&'emit_message_state',
			viewer._emit_message_state.bind(node)
		)
	if node.has_signal(&'emit_message_once') :
		node.connect(&'emit_message_once',
			viewer.emit_message_once.bind(node)
		)
		
	node.set_meta(&'viewer', viewer)
	node.set_meta(&'scale', _get_unit_scale_f())
	node.add_to_group(&'entities')
	
	return node

func _get_entity_node(id : int) -> Node :
	var node := super(id)
	if !node : return null
	
	var dict : Dictionary = entity_props.get(id, {})
	
	for d in [
		[0, 256],
		[1, 512],
		[2, 1024],
		[4, 2048],
	] :
		if viewer.skill == d[0] and dict.get('spawnflags', 0) & d[1] :
			node.free()
			entity_nodes.erase(id)
			return null
	
	if dict.has('targetname') :
		node.add_to_group('T_' + dict['targetname'])
	return node
		
func _custom_work_bsp(bsp : RefCounted) -> void :
	return
