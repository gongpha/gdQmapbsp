extends QmapbspImporterExtension
class_name QmapbspImporterExtensionQuake1

func _get_entity_node(entity : Dictionary) -> Node :
	var classname : String = entity.get('classname')
	var scrpath := "res://quake1_example/class/%s.gd" % classname
	if !ResourceLoader.exists(scrpath) :
		return super(entity)
	var scr : Script = load(scrpath)
	if !scr :
		return super(entity)
	return scr.new()

func _on_brush_mesh_updated(region_or_model_id, meshin : MeshInstance3D) :
	var shape : Shape3D
	var root : Node
	if region_or_model_id is Vector3i :
		shape = meshin.mesh.create_trimesh_shape()
		root = entities_owner[0] # worldspawn
	else :
		shape = meshin.mesh.create_convex_shape()
		root = entities_owner[region_or_model_id]
	
	var col := CollisionShape3D.new()
	col.shape = shape
	col.name = &'generated_col'
	col.position = meshin.position
	root.add_child(col)
	
var skies : Dictionary # <name : ShaderMaterial>
	
func _get_material_for_bsp_textures(name : String, itex : ImageTexture) -> Material :
	if name.begins_with('sky') :
		var sky : ShaderMaterial = skies.get(name)
		if !sky :
			sky = load("res://quake1_example/material/sky.tres")
			sky.set_shader_parameter(&'skytex', itex)
			skies[name] = sky
		return sky
	return super(name, itex)
