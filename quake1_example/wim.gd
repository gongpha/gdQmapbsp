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
	
func _get_custom_bsp_textures_shader() -> Shader :
	if viewer.rendering != 0 :
		return preload(
			"res://addons/qmapbsp/resource/shader/surface_and_shade.gdshader"
		)
	return super()

func _entity_node_directory_paths() -> PackedStringArray :
	return PackedStringArray(
		["res://quake1_example/class/"]
	) + super()

var specials : Dictionary # <name : ShaderMaterial>
var worldspawn_fluid_brush : PackedInt32Array
var added_brush : Dictionary # <worldspawn_brush_id : col>
	
var fluid_area : QmapbspQuakeFluidVolume
var lava_area : QmapbspQuakeLavaVolume
var slime_area : QmapbspQuakeSlimeVolume

func _new_fluid_area() :
	if fluid_area : return
	fluid_area = QmapbspQuakeFluidVolume.new()
	fluid_area.name = &"FLUID"
	root.add_child(fluid_area)

func _new_lava_area() :
	if lava_area : return
	lava_area = QmapbspQuakeLavaVolume.new()
	lava_area.name = &"FLUID_LAVA"
	root.add_child(lava_area)
	
func _new_slime_area() :
	if slime_area : return
	slime_area = QmapbspQuakeSlimeVolume.new()
	slime_area.name = &"FLUID_SLIME"
	root.add_child(slime_area)

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
			sky.set_meta(&'sky', true)
		viewer.skytex = tex
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
	
func _entity_your_mesh(
	ent_id : int,
	brush_id : int,
	mesh : ArrayMesh, origin : Vector3,
	region
) -> void :
	super(ent_id, brush_id, mesh, origin, region)
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
		# distinquish between Lava, Slime and Water
		var is_fluid : bool = false
		var is_lava : bool = false
		var is_slime : bool = false
		for s in known_texture_names :
			var s_lower = s.to_lower()
			if s_lower.begins_with('*') : 
				if 'water' in s_lower :
					is_fluid = true
					break
				if 'lava' in s_lower :
					is_lava = true
					break
				if 'slime' in s_lower :
					is_slime = true
					break
				
		if is_fluid :
			_new_fluid_area()
			last_added_col.get_parent().remove_child(last_added_col)
			fluid_area.add_child(last_added_col)
			last_added_col.position = origin
		if is_lava :
			_new_lava_area()
			last_added_col.get_parent().remove_child(last_added_col)
			lava_area.add_child(last_added_col)
			last_added_col.position = origin
		if is_slime :
			_new_slime_area()
			last_added_col.get_parent().remove_child(last_added_col)
			slime_area.add_child(last_added_col)
			last_added_col.position = origin

	
	#if ent_id == 0 and last_added_col :
	#	added_brush[brush_id] = last_added_col
	
func _entity_occluder_includes_region(
	ent_id : int,
	occluder : ArrayOccluder3D,
	region
) -> bool :
	if ent_id == 0 :
		if region is int :
			# do not add an occluder to water/sky brushes
			return false
	return super(ent_id, occluder, region)

func _new_entity_node(classname : StringName) -> Node :
	var node : Node = super(classname)
	if !node : return null
	
	if classname == 'worldspawn' :
		viewer.worldspawn = node
	elif classname.begins_with('light') :
		if viewer.rendering == 0 :
			node.hide()
	
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

func _entity_prefers_occluder(ent_id : int) -> bool :
	return ent_id == 0 and viewer.occlusion_culling
