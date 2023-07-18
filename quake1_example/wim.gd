## An example extension that loads Quake1 maps from pak files
extends QmapbspWorldImporterScene
class_name QmapbspWorldImporterQuake1

var viewer : QmapbspQuakeViewer
var surface : ShaderMaterial
var pal : PackedColorArray
func _get_bsp_palette() -> PackedColorArray : return pal

func _texture_include_bsp_textures() -> bool : return true

var importing_clip_shape := false

func _texture_get_global_surface_material() -> ShaderMaterial :
	surface = ShaderMaterial.new()
	viewer.world_surface = surface
	surface.set_shader_parameter(&'mode', viewer.mode)
	surface.set_shader_parameter(&'lmboost', viewer.lightmap_boost)
	surface.set_shader_parameter(&'regionhl', viewer.region_highlighting)
	return surface
	
func _texture_your_bsp_textures(
	textures : Array,
	textures_fullbright : Array
) -> void :
	viewer.bsp_textures = textures
	viewer.bsp_textures_fullbright = textures_fullbright
	
func _texture_get_animated_textures_group(
	name : String
) -> Array :
	if name.unicode_at(0) == 43 : # +
		var groupi : String
		var framei : int
		var u := name.unicode_at(1)
		if u >= 48 and u <= 57 :
			groupi = '0'
			framei = u - 48
		elif u >= 97 and u <= 106 :
			groupi = '1'
			framei = u - 97
		return [groupi + name.substr(2), framei] # remove first two characters
	return []
	
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
	
var empty_area : QmapbspQuakeLeafVolume
var fluid_area : QmapbspQuakeFluidVolume
var lava_area : QmapbspQuakeLavaVolume
var slime_area : QmapbspQuakeSlimeVolume

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
	metadata : Dictionary
) -> void :
	var imported_from : StringName = metadata.get('from', &'')
	if imported_from == &'CLIP' :
		importing_clip_shape = true
	super(ent_id, brush_id, shape, origin, metadata)
	importing_clip_shape = false
	
	# -2 = delete
	# -1 = do not create a volume
	#  0 = empty
	#  1 = water
	#  2 = lava
	#  3 = slime
	var what : int = -1
	
	if imported_from == &'MAP_BRUSH' :
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
						
	elif imported_from == &'BSP' :
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
	
func _try_create_clipbody(node : Node) -> Node :
	if importing_clip_shape :
		var clip_body : CollisionObject3D = node.get_node_or_null(^'CLIPBODY')
		if !clip_body :
			# new
			if node is StaticBody3D :
				clip_body = QmapbspQuakeClipProxyStatic.new()
			elif node is AnimatableBody3D :
				clip_body = QmapbspQuakeClipProxyAnimated.new()
			elif node is Area3D :
				clip_body = QmapbspQuakeClipProxyArea.new()
				clip_body.set_area(node)
			else :
				clip_body = Area3D.new()
				
			if node is CollisionObject3D :
				var m : int
				m = node.collision_layer
				if m & 0b1 :
					m = (m | 0b100) & ~(0b1)
				clip_body.collision_layer = m
				
				m = node.collision_mask
				if m & 0b1 :
					m = (m | 0b100) & ~(0b1)
				clip_body.collision_mask = m
				
			clip_body.name = &'CLIPBODY'
			node.add_child(clip_body)
		return clip_body
	return node

func _new_entity_node(classname : StringName) -> Node :
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
		
	return _try_create_clipbody(node)

func _entity_prefers_occluder(ent_id : int) -> bool :
	return ent_id == 0 and viewer.occlusion_culling
		
func _load_bsp_nodes(model_id : int) -> bool :
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
