extends EditorInspectorPlugin
class_name QmapbspMapInspectorPlugin

func _can_handle(o) -> bool :
	return o is QmapbspMap
	
func _parse_begin(o) :
	var pscene := preload("sub/map_quake_inspector_control.tscn")
	add_custom_control(pscene.instantiate())
