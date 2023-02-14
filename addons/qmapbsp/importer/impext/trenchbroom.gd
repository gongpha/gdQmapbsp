## A world importer with Trenchbroom extension
extends QmapbspWorldImporterCustomTextures
class_name QmapbspWorldImporterTrenchbroom

var game_config : QmapbspTrenchbroomGameConfigResource

func _get_unit_scale_f() -> float :
	return game_config.inverse_scale_factor
	
func _get_region_size() -> float :
	return game_config.mesh_splitting_size
	
func _texture_get_no_texture() -> Material :
	var no := game_config.default_material
	if no : return no
	return super()
	
func _entity_unwrap_uv2(
	id : int, brush_id : int, mesh : ArrayMesh
) -> float :
	return game_config.lightmap_texel if !game_config.use_bsp_lightmap else -1.0

func _compile_bsp(mappath : String) -> String :
	var usercfg := game_config.usercfg
	var cmplwf := usercfg.compilation_workflow
	return cmplwf._compile(mappath)

func _texture_get_dir() -> String :
	return game_config.textures_directory

func _entity_node_directory_paths() -> PackedStringArray :
	return PackedStringArray(
		[game_config.ent_entity_script_directory]
	) + super()

func _entity_your_cooked_properties(id : int, entity : Dictionary) -> void :
	var epd := game_config._entity_properties_def
	var props : Dictionary = epd.get(entity.get("classname", ""), {})
	for k in props :
		if !entity.has(k) : continue
		var v = entity[k]
		var dv = props[k]
		if not v is String : continue
		entity[k] = QmapbspTypeProp.prop_to_var(v, typeof(dv))
	entity.merge(props)
	
	super(id, entity)
	
func _get_entity_node(id : int) -> Node :
	var node : Node = entity_nodes.get(id, null)
	if !node : node = super(id)
	if !node : return null
	
	var dict : Dictionary = entity_props.get(id, {})
	if node is Node3D :
		node.visible = dict.get("visible", true)
	
	return node
