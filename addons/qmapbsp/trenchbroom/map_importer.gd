extends EditorImportPlugin
class_name QmapbspTrenchbroomMapImporterPlugin

func _get_importer_name() -> String :
	return "qmapbsp.trenchbroom_map"

func _get_visible_name() -> String :
	return "Qmapbsp Trenchbroom"

func _get_recognized_extensions() -> PackedStringArray :
	return PackedStringArray(["map"])

func _get_save_extension() -> String :
	return "scn"

func _get_resource_type() -> String :
	return "PackedScene"
	
func _get_priority() -> float : return 1.0
func _get_import_order() -> int : return 0
	
###############################
# Presets

func _get_preset_count() -> int :
	return 1

func _get_preset_name(i : int) -> String :
	return "Default"
	
###############################

func _get_import_options(p : String, i : int) -> Array[Dictionary] :
	return [
		{
			"name" : "game_config_path",
			"default_value" : "",
			"property_hint" : PROPERTY_HINT_FILE,
			"hint_string" : "*.tres,*.res"
		},
		{
			"name" : "map_config_path",
			"default_value" : "",
			"property_hint" : PROPERTY_HINT_FILE,
			"hint_string" : "*.tres,*.res"
		}
	]
	
func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool :
	return true

const MIE := "res://addons/qmapbsp/resource/map_import_error.tscn"
func _save_error(save_path : String, error : StringName, error_ret : Array) :
	var mie := preload(MIE).instantiate()
	mie.error = error
	var strs : PackedStringArray
	strs.resize(error_ret.size())
	for i in strs.size() :
		strs[i] = str(error_ret[i])
	mie.error_data = '\n'.join(strs)
	
	var pscene := PackedScene.new()
	pscene.pack(mie)
	var filename := save_path + "." + _get_save_extension()
	return ResourceSaver.save(pscene, filename)


func _import(
	source_file : String,
	save_path : String,
	options : Dictionary,
	platform_variants : Array[String],
	gen_files : Array[String]
) -> int :
	var file := FileAccess.open(source_file, FileAccess.READ)
	if !file :
		return FileAccess.get_open_error()
		
	var wis : QmapbspWorldImporterTrenchbroom
	var bsp_path : String
	var t_path : String = options.get("game_config_path", "")
	if t_path.is_empty() :
		printerr("No Trenchbroom game config file")
		return _save_error(save_path, &"NO_TRENCHBROOM_GAMECFG_FILE", [])
		
	var gamecfg : QmapbspTrenchbroomGameConfigResource = load(t_path)
	if !gamecfg :
		printerr("Cannot load Trenchbroom game config file")
		return _save_error(save_path, &"CANNOT_LOAD_TRENCHBROOM_GAMECFG_FILE", [])
	t_path = options.get("map_config_path", "")
	var mapcfg : QmapbspTrenchbroomMapConfig
	if !t_path.is_empty() :
		mapcfg = load(t_path)
		
	
	if gamecfg.custom_trenchbroom_world_importer :
		wis = gamecfg.custom_trenchbroom_world_importer.new()
	else :
		wis = QmapbspWorldImporterTrenchbroom.new()
	
	if mapcfg :
		wis.map_config = mapcfg
	else :
		wis.map_config = gamecfg.global_map_config
	if !wis.map_config :
		wis.map_config = QmapbspTrenchbroomMapConfig.new()
	wis.game_config = gamecfg
	bsp_path = wis._compile_bsp(source_file)
		
	var node := Node3D.new()
	node.name = &'map'
	wis.root = node
	wis.owner = node
	
	if bsp_path.is_empty() :
		printerr("No BSP file")
		return _save_error(save_path, &"NO_BSP_FILE_COMPILED", [])
	
	var ret : Array
	
	var err := wis.begin_load_absolute(
		source_file, bsp_path, ret
	)
	
	if err != StringName() :
		return _save_error(save_path, err, ret)
	
	err = StringName()
	while true :
		var reti := wis.poll()
		if reti == &'END' :
			break
		elif reti != StringName() :
			err = reti
			break
			
	if err != StringName() :
		printerr(err)
		return _save_error(save_path, err, [])

	#######################################################

	var pscene := PackedScene.new()
	if pscene.pack(node) :
		return _save_error(save_path, &'CANNOT_SAVE_SCENE', [])

	var filename := save_path + "." + _get_save_extension()
	return ResourceSaver.save(pscene, filename)
