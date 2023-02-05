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
