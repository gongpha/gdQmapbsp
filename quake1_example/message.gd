extends QmapbspQuakeDraw
class_name QmapbspQuakeViewerMessage

var current_emitter : Node
var current_message : String
@onready var talk : AudioStreamPlayer = $talk
@onready var life : Timer = $life

func _ready() :
	life.timeout.connect(_on_life_timeout)

func clear() :
	set_emitter('', true, null)

func set_emitter(msg : String, show : bool, from : Node) :
	if msg == current_message : return
	if show :
		current_emitter = from
		_show(msg)
		
	else :
		if current_emitter == from :
			current_emitter = null
		
func _show(m : String) :
	current_message = m
	
	if current_emitter :
		life.start()
		_on_life_timeout()
	
	queue_redraw()
	
func _draw() :
	draw_quake_text(
		Vector2(), current_message, 0, Vector2(3, 3), true
	)


func _on_life_timeout() :
	if current_emitter :
		talk.play()
	else :
		clear()
