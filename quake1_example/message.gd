extends QmapbspQuakeDraw
class_name QmapbspQuakeViewerMessage

var current_emitter : Node
var current_message : String
@onready var talk : AudioStreamPlayer = $talk
@onready var life : Timer = $life

func _ready() :
	life.timeout.connect(_on_life_timeout)

func clear() :
	talk.stream = null
	current_message = ''
	current_emitter = null
	queue_redraw()
	
func set_talk_sound(audio : AudioStream) :
	if talk.stream == audio : return
	talk.stream = audio

func set_emitter(msg : String, show : bool, from : Node) :
	if msg == current_message : return
	if from == null : current_emitter = null
	if show :
		current_emitter = from
		_show(msg)
		talk.play()
	elif current_emitter == from : current_emitter = null


func _show(m : String) :
	current_message = m
	life.start()
	queue_redraw()
	
func _draw() :
	draw_quake_text(
		Vector2(), current_message, 0, Vector2(3, 3), true
	)


func _on_life_timeout() :
	clear()
