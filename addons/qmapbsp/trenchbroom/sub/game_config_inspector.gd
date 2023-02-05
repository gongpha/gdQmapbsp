@tool
extends VBoxContainer
class_name QmapbspTrenchbroomGameConfigResourceInspector

var game_config : QmapbspTrenchbroomGameConfigResource

var done_streak : int = 0

func _on_export_pressed() :
	game_config.export_cfg()
	done_streak += 1
	if done_streak == 1 :
		$export.text = "Done !"
	else :
		$export.text = "Done (%d)" % done_streak
