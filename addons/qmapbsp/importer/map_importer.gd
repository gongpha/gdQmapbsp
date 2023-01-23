extends EditorImportPlugin
class_name QmapbspMapImporterPlugin

func _get_importer_name() -> String :
	return "qmapbsp.map"

func _get_visible_name() -> String :
	return "Qmapbsp"

func _get_recognized_extensions() -> PackedStringArray :
	return PackedStringArray(["map"])

func _get_save_extension() -> String :
	return "tres"

func _get_resource_type() -> String :
	return "Resource"
	
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
	return [{"name": "my_option", "default_value": false}]

func _import(
	source_file : String,
	save_path : String,
	options : Dictionary,
	platform_variants : Array[String],
	gen_files : Array[String]
) -> int :
	var filename := save_path + "." + _get_save_extension()
	return ResourceSaver.save(MapQuake.new(), filename)
