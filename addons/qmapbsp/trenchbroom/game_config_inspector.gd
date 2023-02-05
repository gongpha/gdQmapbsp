extends EditorInspectorPlugin
class_name QmapbspTrenchbroomGameConfigResourceInspectorPlugin

func _can_handle(o) -> bool :
	return o is QmapbspTrenchbroomGameConfigResource
	
func _parse_begin(o) :
	var pscene := preload("sub/game_config_inspector.tscn")
	var insp : QmapbspTrenchbroomGameConfigResourceInspector = (
		pscene.instantiate()
	)
	insp.game_config = o
	add_custom_control(insp)
