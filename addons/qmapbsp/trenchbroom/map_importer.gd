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
		}
	]
	
func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool :
	return true

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
	wis = QmapbspWorldImporterTrenchbroom.new()
	var t_path : String = options.get("game_config_path", "")
	if t_path.is_empty() :
		printerr("No Trenchbroom game config file")
		return ERR_FILE_CANT_OPEN
	wis.game_config = load(t_path)
	bsp_path = wis._compile_bsp(source_file)
		
	var node := Node3D.new()
	node.name = &'map'
	wis.root = node
	wis.owner = node
	
	if bsp_path.is_empty() :
		printerr("No BSP file")
		return ERR_FILE_CANT_OPEN
	
	var ret : Array
	
	var err := wis.begin_load_absolute(
		source_file, bsp_path, ret
	)
	
	if err != StringName() :
		printerr(err)
		printerr(ret)
		return ERR_FILE_CANT_OPEN
	
	#print(":OWO")
	#return ERR_ALREADY_EXISTS
	err = StringName()
	while true :
		var reti := wis.poll()
		if reti == &'END' :
			break
		elif reti != StringName() :
			err = reti
			break
		print(wis.get_progress())
			
	if err != StringName() :
		printerr(err)
		return ERR_FILE_CANT_OPEN

	#######################################################

	var pscene := PackedScene.new()
	if pscene.pack(node) :
		return ERR_CANT_CREATE

	var filename := save_path + "." + _get_save_extension()
	return ResourceSaver.save(pscene, filename)
