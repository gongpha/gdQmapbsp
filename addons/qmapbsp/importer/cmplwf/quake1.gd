@tool
extends QmapbspCompilationWorkflow
class_name QmapbspCompilationWorkflowQuake1

@export_global_file var qbsp_path : String
#@export_global_file var vis_path : String
#@export_global_file var light_path : String

func _compile(map_filepath : String) -> String :
	if qbsp_path.is_empty() :
		printerr("No QBSP path specified")
		return ""
	var o : Array
	
	DirAccess.make_dir_recursive_absolute("res://.godot/qmapbsp/artifact")
	var out := ProjectSettings.globalize_path("res://.godot/qmapbsp/artifact".path_join(
		map_filepath.get_file()
	))
	out = out.get_basename() + ".bsp"
	OS.execute(qbsp_path, [
		'-wrbrushesonly',
		'-notex',
		ProjectSettings.globalize_path(map_filepath),
		out
	], o)
	return out
