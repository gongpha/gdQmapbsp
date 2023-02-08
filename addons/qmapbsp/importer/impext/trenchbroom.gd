## A world importer with Trenchbroom extension
extends QmapbspWorldImporterCustomTextures
class_name QmapbspWorldImporterTrenchbroom

var game_config : QmapbspTrenchbroomGameConfigResource

func _compile_bsp(mappath : String) -> String :
	var usercfg := game_config.usercfg
	var cmplwf := usercfg.compilation_workflow
	return cmplwf._compile(mappath)

func _texture_get_dir() -> String :
	return game_config.textures_dir

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
		entity[k] = QmapbspTypeProp.prop_to_var(v, typeof(v))
	entity.merge(props)
	super(id, entity)
