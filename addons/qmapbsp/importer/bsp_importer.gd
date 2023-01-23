extends EditorImportPlugin
class_name QmapbspBSPImporterPlugin

func _get_importer_name() -> String :
	return "qmapbsp.bsp"

func _get_visible_name() -> String :
	return "Qmapbsp"

func _get_recognized_extensions() -> PackedStringArray :
	return PackedStringArray(["bsp"])

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

func _get_preset_name(i) -> String :
	return "Default"
	
###############################

func _get_import_options(p : String, i : int) -> Array[Dictionary] :
	return [
		{
			"name": "extended_importer",
			"property_hint" : PROPERTY_HINT_FILE,
			"default_value" : ""
		}
	]
	
func _get_option_visibility(
	path : String, option_name : StringName, options : Dictionary
) -> bool :
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
		
	var extp : String = options.get("extended_importer", "")
	var ext : Qmapbsp_BSPImporterExtension
	if extp.is_empty() :
		ext = Qmapbsp_BSPImporterExtension.new()
	else :
		ext = load(extp).new()
	var node := Node3D.new()
	node.name = &'map'
	ext.root = node
	var parser := Qmapbsp_BSPParser.new()
	
	var res : StringName = parser.begin_read_file(file, ext)
	
	var retp : int
	while true :
		retp = parser.poll()
		if retp == OK : continue
		elif retp == ERR_FILE_EOF : break
		
	#######################################################
		
	var pscene := PackedScene.new()
	if pscene.pack(node) :
		breakpoint

	var filename := save_path + "." + _get_save_extension()
	return ResourceSaver.save(pscene, filename)
