extends RefCounted
class_name Qmapbsp_BSPImporterExtension

var root : Node
var pal : PackedColorArray

#var entities : Node
var entities_owner : Dictionary # <model_id : Node>

func _start() :
	#entities = Node.new()
	#entities.name = &'entities'
	#root.add_child(entities)
	pass
	
func _get_palette() -> PackedColorArray : return pal
func _get_region_size() -> float : return 0.5
func _get_unit_scale_f() -> float : return 32.0
func _get_custom_bsp_textures_shader() -> Shader :
	return preload(
		"../resource/shader/surface.gdshader"
	)

var no_texture : Material
func get_no_texture() -> Material :
	if !no_texture : no_texture = _get_no_texture()
	return no_texture

func _get_no_texture() -> Material :
	var t := StandardMaterial3D.new()
	t.albedo_color = Color.RED
	return t

func _get_texture(name : String, size : Vector2i) :
	return null # uses textures inside the bsp file
#	var path := "res://textures/{name}".format({
#		'name' : name
#	})
#	var mat : Material = load(path)
#	if !mat : mat = get_no_texture()
#	return mat

func _get_mesh_instance_per_model(model_id : int) -> MeshInstance3D :
	var meshin := MeshInstance3D.new()
	meshin.name = "mesh%04d" % model_id
	
	var realroot : Node = entities_owner.get(model_id)
	if !realroot :
		realroot = root
	
	realroot.add_child(meshin)
	var ameshin = MeshInstance3D.new()
	ameshin.rotation = Vector3(randf(), randf(), randf())
	ameshin.mesh = BoxMesh.new()
	meshin.add_child(ameshin)
	meshin.owner = root
	return meshin

func _get_worldspawn_mesh_instance(region : Vector3i) -> MeshInstance3D :
	var meshin := MeshInstance3D.new()
	meshin.name = "worldspawn_%03d_%03d_%03d" % [region.x, region.y, region.z]
	
	entities_owner[0].add_child(meshin)
		
	meshin.owner = root
	return meshin
	
func _get_collision_shape_node(model_id : int, shape_id : int) -> CollisionShape3D :
	var col := CollisionShape3D.new()
	col.name = "col%04d" % shape_id
	
	var realroot : Node = entities_owner.get(model_id)
	if !realroot :
		realroot = root
	
	realroot.add_child(col)
	col.owner = root
	return col

func _tell_entity(entity : Dictionary, return_data : Dictionary) -> StringName :
	var classname : String = entity.get('classname')
	var origin : Vector3 = QmapbspMapFormat.expect_vec3(entity.get('origin', ''))
	var angle : int = QmapbspMapFormat.expect_int(entity.get('angle', ''))
	var model_id : int = QmapbspMapFormat.expect_int(entity.get('model', '*-1').substr(1))
	if classname == 'worldspawn' :
		model_id = 0
	if model_id != -1 :
		return_data['model_id'] = model_id
	
	var node : Node
	var scrpath := "res://addons/quake_bsp_parser/class/quake1/%s.gd" % classname
	if !ResourceLoader.exists(scrpath) :
		return &'NOT_IMPLEMENTED'
	var scr : Script = load(scrpath)
	if !scr :
		return &'NOT_IMPLEMENTED'

	node = scr.new()
	root.add_child(node)
	node.owner = root
	
	if node is Node3D :
		node.position = Vector3(-origin.x, origin.z, origin.y) / _get_unit_scale_f()
		node.rotation_degrees.y = angle
		if node is CollisionObject3D :
			return_data['add_col'] = true
	if model_id != -1 :
		entities_owner[model_id] = node
	return StringName()
