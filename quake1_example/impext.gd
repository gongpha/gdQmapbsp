## An example extension that loads Quake1 maps from their pak files
extends QmapbspWorldImporterBasic
class_name QmapbspWorldImporterQuake1

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
var skies : Dictionary # <name : ShaderMaterial>

func _texture_get_material_for_integrated(name : String, itex : ImageTexture) -> Material :
	if name.begins_with('sky') :
		var sky : ShaderMaterial = skies.get(name)
		if !sky :
			sky = load("res://quake1_example/material/sky.tres")
			sky.set_shader_parameter(&'skytex', itex)
			skies[name] = sky
		return sky
	return super(name, itex)
