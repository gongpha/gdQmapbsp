extends AudioStreamPlayer3D
class_name QmapbspQuakeAmbient

var viewer : QmapbspQuakeViewer
var props : Dictionary
func _is_brush_visible() -> bool : return false
func _get_properties(dict : Dictionary) : props = dict

signal emit_message_state(m : String, show : bool)

func _show_message_start(msg : String) :
	emit_message_state.emit(msg, true)
	
func _show_message_end() :
	emit_message_state.emit('', false)

func _ready() :
	viewer = get_meta(&'viewer')

func _map_ready() :
	unit_size = 5.0
	stream = viewer.hub.load_audio(_audiopath())
	finished.connect(func() : play())
	play()

func _audiopath() -> String :
	return "misc/null.wav"
