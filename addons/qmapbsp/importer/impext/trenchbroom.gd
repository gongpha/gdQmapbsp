## A world importer with Trenchbroom extension
extends QmapbspWorldImporterCustomTextures
class_name QmapbspWorldImporterTrenchbroom

var game_config : QmapbspTrenchbroomGameConfigResource
var map_config : QmapbspTrenchbroomMapConfig

var point_file_points : PackedVector3Array

func _get_unit_scale_f() -> float :
	return map_config.inverse_scale_factor
	
func _entity_region_size(ent_id : int) -> float :
	return map_config.mesh_splitting_size
	
func _texture_get_missing_texture() -> Array :
	var no := map_config.default_material
	if no : return [no, map_config.default_material_texture_size]
	return super()
	
func _entity_unwrap_uv2(
	id : int, brush_id : int, mesh : ArrayMesh
) -> float :
	return map_config.lightmap_texel if !map_config.use_bsp_lightmap else -1.0

func _build_point_file_lines() -> bool :
	return map_config.load_point_file

func _compile_bsp(mappath : String) -> String :
	var usercfg := game_config.usercfg
	var cmplwf := usercfg.compilation_workflow
	var result_path := cmplwf._compile(mappath)
	
	# Check for a point file
	if map_config.load_point_file :
		var pts := FileAccess.open(result_path.get_basename() + ".pts", FileAccess.READ)
		if pts :
			var l := pts.get_line()
			var points : PackedVector3Array
			var isf := _get_unit_scale_f()
			while true :
				if l.is_empty() : break
				
				var psa := l.split(' ')
				if psa.size() != 3 :
					# cannot load
					return result_path
				points.append(QmapbspBaseParser._qnor_to_vec3(Vector3(
					float(psa[0]), float(psa[1]), float(psa[2])
				) / isf))
				l = pts.get_line()
			point_file_points = points
	return result_path
	
func _get_point_file_points() -> PackedVector3Array :
	return point_file_points
	
func _point_files_simplify_angle() -> float :
	return super() if map_config.simplify_point_files else 0.0

func _texture_get_dir() -> String :
	return game_config.textures_directory

func _entity_node_directory_paths() -> PackedStringArray :
	return PackedStringArray(
		[game_config.ent_entity_script_directory]
	) + super()

func _entity_your_cooked_properties(id : int, entity : Dictionary) -> void :
	var epd := game_config._entity_properties_def
	var props : Dictionary = epd.get(entity.get("classname", &""), {})
	for k in props :
		if !entity.has(k) : continue
		var v = entity[k]
		var dv = props[k]
		if not v is StringName : continue
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

func _entity_prefers_occluder(ent_id : int) -> bool :
	return super(ent_id) or (ent_id == 0 and map_config.occ_bake_occluders)

func _get_occluder_shrink_amount() -> float :
	return map_config.occ_shrink_amount

func _entity_get_collision_shape_method(ent_id : int) -> int :
	return map_config.collsion_constructing_method

func _get_navmesh_template() -> NavigationMesh :
	return map_config.navmesh_template

func _entity_auto_smooth_degree() -> float :
	return map_config.auto_smooth_max_angle
