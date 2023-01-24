extends RefCounted
class_name QmapbspImporterExtension

var root : Node
var pal : PackedColorArray
var entities_owner : Dictionary # <model_id : Node>

func _start() :
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

func _get_texture(name : String, size : Vector2i) -> Material :
	return null
	
func _get_material_for_bsp_textures(name : String, itex : ImageTexture) -> Material :
	return null

func _get_mesh_instance_per_model(model_id : int) -> MeshInstance3D :
	if !root : return null
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
	if !root : return null
	var meshin := MeshInstance3D.new()
	meshin.name = "worldspawn_%03d_%03d_%03d" % [region.x, region.y, region.z]
	
	entities_owner[0].add_child(meshin)
		
	meshin.owner = root
	return meshin
	
func _get_collision_shape_node(model_id : int, shape_id : int) -> CollisionShape3D :
	if !root : return null
	var col := CollisionShape3D.new()
	col.name = "col%04d" % shape_id
	
	var realroot : Node = entities_owner.get(model_id)
	if !realroot :
		realroot = root
	
	realroot.add_child(col)
	col.owner = root
	return col
	
func _get_entity_node(entity : Dictionary) -> Node :
	var classname : String = entity.get('classname')
	var scrpath := "res://addons/qmapbsp/class/%s.gd" % classname
	if !ResourceLoader.exists(scrpath) :
		return null
	var scr : Script = load(scrpath)
	if !scr :
		return null
	return scr.new()

func _tell_entity(entity : Dictionary, return_data : Dictionary) -> StringName :
	if !root : return &'NO_ROOT'
	var classname : String = entity.get('classname')
	var origin : Vector3 = QmapbspMapFormat.expect_vec3(entity.get('origin', ''))
	var angle : int = QmapbspMapFormat.expect_int(entity.get('angle', ''))
	var model_id : int = QmapbspMapFormat.expect_int(entity.get('model', '*-1').substr(1))
	if classname == 'worldspawn' :
		model_id = 0
	if model_id != -1 :
		return_data['model_id'] = model_id
	
	var node : Node = _get_entity_node(entity)
	if !node : return &'NOT_IMPLEMENTED'
	root.add_child(node)
	node.owner = root
	
	if node is Node3D and model_id != 0 :
		node.position = Vector3(-origin.x, origin.z, origin.y) / _get_unit_scale_f()
		node.rotation_degrees.y = angle + 90.0
		if node is CollisionObject3D :
			return_data['add_col'] = true
	if model_id != -1 :
		entities_owner[model_id] = node
	return StringName()

#########################################

func _on_brush_mesh_updated(region_or_model_id, meshin : MeshInstance3D) :
	pass
