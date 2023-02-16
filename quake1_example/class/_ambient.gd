extends AudioStreamPlayer3D
class_name QmapbspQuakeAmbient

var viewer : QmapbspQuakeViewer
var props : Dictionary
func _qmapbsp_is_brush_visible() -> bool : return false
func _get_properties(dict : Dictionary) : props = dict

signal emit_message_state(m : String, show : bool)

func _show_message_start(msg : String) : return
func _show_message_end() : return

func _ready() :
	viewer = get_meta(&'viewer')

func _map_ready() :
	unit_size = 1.0
	stream = viewer.hub.load_audio(_audiopath())
	finished.connect(func() : play())
	play()

func _audiopath() -> String :
	return "misc/null.wav"
