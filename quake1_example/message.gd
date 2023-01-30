extends QmapbspQuakeDraw
class_name QmapbspQuakeViewerMessage

var current_emitter : Node
var current_message : String

func clear() :
	set_emitter('', true, null)

func set_emitter(msg : String, show : bool, from : Node) :
	if show :
		current_emitter = from
		_show(msg)
		
	else :
		if current_emitter == from :
			current_emitter = null
		
func _show(m : String) :
	current_message = m
	queue_redraw()
	
func _draw() :
	draw_quake_text(
		Vector2(), current_message, 0, Vector2(3, 3), true
	)
