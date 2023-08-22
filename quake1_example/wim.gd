## An example extension that loads Quake1 maps from pak files
extends QmapbspWorldImporterQuake1Style
class_name QmapbspWorldImporterQuake1

var viewer : QmapbspQuakeViewer
var surface : ShaderMaterial
var pal : PackedColorArray
func _get_bsp_palette() -> PackedColorArray : return pal

func _texture_include_bsp_textures() -> bool : return true

func _begin() -> void :
	super()
	viewer.world_shader = surface_shader

func _entity_node_directory_paths() -> PackedStringArray :
	return PackedStringArray(
		["res://quake1_example/class/"]
	) + super()

var worldspawn_fluid_brush : PackedInt32Array
var added_brush : Dictionary # <worldspawn_brush_id : col>
	
var empty_area : QmapbspQuakeLeafVolume
var fluid_area : QmapbspQuakeFluidVolume
var lava_area : QmapbspQuakeLavaVolume
var slime_area : QmapbspQuakeSlimeVolume
	
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
	metadata : Dictionary
) -> void :
	# -2 : MAP brushes
	# 0 : BSP
	# 1 : CLIP_HUMAN
	# 2 : CLIP_LARGE
	var hull : int = metadata.get('hull', -1)
	super(ent_id, brush_id, shape, origin, metadata)
	
	# -2 = delete
	# -1 = do not create a volume
	#  0 = empty
	#  1 = water
	#  2 = lava
	#  3 = slime
	var what : int = -1
	
	if hull == -2 : # hull from MAP brushes
		var known_texture_names : PackedStringArray = metadata.get(
			'known_texture_names', PackedStringArray()
		)
		
		if ent_id == 0 :
			# The BSP tree has already done the collision shape creation process
			for s in known_texture_names :
				var s_lower = s.to_lower()
				if s_lower.begins_with('*') : 
					if 'water' in s_lower :
						what = -2
						break
					if 'lava' in s_lower :
						what = -2
						break
					if 'slime' in s_lower :
						what = -2
						break
						
						
	# actually, we already have configured to omit clips (hull 1, 2)
	# but decided to add the below condition to making more sure
	elif hull == 0 : # is bsp (hull 0 point)
		var leaf_type : int = metadata.get(
			'leaf_type', -1
		)
		var ambsnds : Vector4 = metadata.get(
			'ambsnds', Vector4()
		)
		
		# set ambsnds data to each colshape
		last_added_col.set_meta(&'ambsnds', ambsnds)
		
		match leaf_type :
			QmapbspBSPParser.CONTENTS_EMPTY : what = 0
			QmapbspBSPParser.CONTENTS_WATER : what = 1
			QmapbspBSPParser.CONTENTS_LAVA : what = 2
			QmapbspBSPParser.CONTENTS_SLIME : what = 3
					
	if what == -2 :
		last_added_col.free()
	elif what != -1 :
		# create a leaf volume
		var new_area : Area3D
		match what :
			0 :
				if !empty_area :
					empty_area = QmapbspQuakeLeafVolume.new()
					empty_area.name = &"FLUID"
					root.add_child(empty_area)
					empty_area.set_meta(&'viewer', viewer)
				new_area = empty_area
			1 :
				if !fluid_area :
					fluid_area = QmapbspQuakeFluidVolume.new()
					fluid_area.name = &"FLUID"
					root.add_child(fluid_area)
					fluid_area.set_meta(&'viewer', viewer)
				new_area = fluid_area
			2 :
				if !lava_area :
					lava_area = QmapbspQuakeLavaVolume.new()
					lava_area.name = &"FLUID_LAVA"
					root.add_child(lava_area)
					lava_area.set_meta(&'viewer', viewer)
				new_area = lava_area
			3 :
				if !slime_area :
					slime_area = QmapbspQuakeSlimeVolume.new()
					slime_area.name = &"FLUID_SLIME"
					root.add_child(slime_area)
					slime_area.set_meta(&'viewer', viewer)
				new_area = slime_area
				
		last_added_col.get_parent().remove_child(last_added_col)
		new_area.add_child(last_added_col)
		
		if what >= 1 and what <= 3 : # fluid types
			new_area.collision_layer = 0b10
			new_area.collision_mask = 0b10
		elif what == 0 :
			new_area.collision_layer = 0b1000
			new_area.collision_mask = 0b1000
		last_added_col.position = origin
	
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
	
	if node.has_signal(&'emit_message_state') :
		node.connect(&'emit_message_state',
			viewer.emit_message_state.bind(node)
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
		
func _load_bsp_nodes() -> bool :
	return true

func _leaf_your_bsp_planes(
	model_id : int, leaf_type : int,
	planes_const : Array[Plane]
) -> bool :
	# only create collision shapes for fluid and empty spaces (for ambient sounds)
	return leaf_type != QmapbspBSPParser.CONTENTS_SOLID
	
func _leaf_your_clip_planes(
	model_id : int,
	planes_const : Array[Plane]
) -> bool :
	return false
