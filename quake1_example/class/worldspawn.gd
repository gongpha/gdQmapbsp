extends StaticBody3D
class_name QmapbspQuakeWorldspawn

@onready var music := $music

var props : Dictionary
func _get_properties(dict : Dictionary) : props = dict

func _map_ready() :
	var viewer : QmapbspQuakeViewer = get_meta(&'viewer', null)
	if viewer :
		music.stream = viewer.get_music(props.get('sounds', '0').to_int())
		music.play()
