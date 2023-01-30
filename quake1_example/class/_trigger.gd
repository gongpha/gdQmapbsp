extends Area3D
class_name QmapbspQuakeTrigger
var props : Dictionary
var v : QmapbspQuakeViewer
func _is_brush_visible() -> bool : return false
func _get_properties(dict : Dictionary) : props = dict

signal emit_message_state(m : String)

func _show_message_start(msg : String) :
	emit_message_state.emit(msg, true)
	
func _show_message_end() :
	emit_message_state.emit('', false)

func _ready() :
	v = get_meta(&'viewer')
	monitorable = false
	collision_mask = 0b10
	body_entered.connect(_bo_en)
	body_exited.connect(_bo_ex)
	
func _bo_en(b : Node3D) :
	_message()
	_trigger(b)

func _bo_ex(b : Node3D) :
	_show_message_end()

func _message() :
	var message = props.get('message', null)
	if message is String :
		_show_message_start(message)

func _trigger(b : Node3D) :
	var target : String = props.get("target", '')
	if !target.is_empty() :
		v.trigger_targets(target, b)
	var killtarget : String = props.get("killtarget", '')
	if !killtarget.is_empty() :
		v.killtarget(killtarget)
