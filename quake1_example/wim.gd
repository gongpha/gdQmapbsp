## An example extension that loads Quake1 maps from pak files
extends QmapbspWorldImporterScene
class_name QmapbspWorldImporterQuake1

var viewer : QmapbspQuakeViewer
var surface : ShaderMaterial
var pal : PackedColorArray
func _get_bsp_palette() -> PackedColorArray : return pal

func _texture_include_bsp_textures() -> bool : return true

func _texture_get_global_surface_material() -> ShaderMaterial :
	surface = ShaderMaterial.new()
	viewer.world_surface = surface
	surface.set_shader_parameter(&'mode', viewer.mode)
	surface.set_shader_parameter(&'lmboost', viewer.lightmap_boost)
	surface.set_shader_parameter(&'regionhl', viewer.region_highlighting)
	var node : Node = entity_nodes.get(0)
	if node is QmapbspQuakeWorldspawn :
		node.surface = surface
	return surface

func _entity_node_directory_paths() -> PackedStringArray :
	return PackedStringArray(
		["res://quake1_example/class/"]
	) + super()

var specials : Dictionary # <name : ShaderMaterial>
var worldspawn_fluid_brush : PackedInt32Array
var added_brush : Dictionary # <worldspawn_brush_id : col>
	
var fluid_area : QmapbspQuakeFluidVolume

func _new_fluid_area() :
	if fluid_area : return
	fluid_area = QmapbspQuakeFluidVolume.new()
	fluid_area.name = &"FLUID"
	root.add_child(fluid_area)

func _texture_get_material_for_integrated(
	name : String, tex : Texture2D
) -> Material :
	if name.begins_with('sky') :
		var sky : ShaderMaterial = specials.get(name)
		if !sky :
			sky = load("res://quake1_example/material/sky.tres")
			sky.set_shader_parameter(&'skytex', tex)
			if name == 'sky4' :
				sky.set_shader_parameter(&'threshold', 0.4)
			specials[name] = sky
		return sky
	elif name.begins_with('*') :
		var fluid : ShaderMaterial = specials.get(name)
		if !fluid :
			fluid = ShaderMaterial.new()
			fluid.shader = preload("res://quake1_example/material/fluid.gdshader")
			fluid.set_shader_parameter(&'tex', tex)
			fluid.set_meta(&'fluid', true)
			specials[name] = fluid
		return fluid
	return super(name, tex)
	
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
	if region is Vector3i :
		last_added_meshin.set_instance_shader_parameter(
			&'region', region
		)
		
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
	
	#if node is QmapbspQuakeWorldspawn :
	#	node.surface = surface
	
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
