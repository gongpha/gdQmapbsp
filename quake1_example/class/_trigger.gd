extends Area3D
class_name QmapbspQuakeTrigger

var props : Dictionary
var v : QmapbspQuakeViewer
var blocked : bool = false

signal emit_message_state(m : String, show : bool)


func _qmapbsp_is_brush_visible() -> bool : return false
func _get_properties(dict : Dictionary) : props = dict


func _flag(spawnflag : int) -> bool :
	if not props.has(&'spawnflags') : 
		printerr('Missing Spawnflags! ', spawnflag, ' ', self)
		return false
	var result : bool = _prop(&'spawnflags', 0) & spawnflag
	return result


func _prop(name : StringName, def) :
	var result = props.get(name, def)
	if typeof(result) == typeof(def) : return result
	match typeof(def) :
		TYPE_NIL:
			result = def
		TYPE_BOOL:
			result = result.to_bool()
		TYPE_INT:
			result = result.to_int()
		TYPE_FLOAT:
			result = result.to_float()
		TYPE_STRING:
			result = str(result)
		_ :
			result = def
	return result


func _show_message_start(msg : String) :
	emit_message_state.emit(msg, true)
	
	
func _show_message_end() :
	emit_message_state.emit('', false)


func _ready() :
	v = get_meta(&'viewer')
	set_deferred(&'monitorable', false)
	collision_mask = 0b10
	body_entered.connect(_bo_en)
	body_exited.connect(_bo_ex)
	
	
func _bo_en(b : Node3D) :
	blocked = true
	_message()
	_trigger(b)


func _bo_ex(b : Node3D) :
	blocked = false
	_show_message_end()
	_trigger_exit(b)


func _message() :
	var message = _prop(&'message', '')
	if not message.is_empty() :
		_show_message_start(message)


func _trigger(b : Node3D) :
	var delay : float = _prop(&'delay', 0)
	if delay > 0 :
		get_tree().create_timer(delay, false).timeout.connect(
			_trigger_now.bind(b)
		)
	else :
		_trigger_now(b)
	

func _trigger_exit(b : Node3D) :
	var delay : float = _prop(&'delay', 0)
	if delay > 0 :
		get_tree().create_timer(delay, false).timeout.connect(
			_trigger_exit_now.bind(b)
		)
	else :
		_trigger_exit_now(b)

	
func _trigger_now(b : Node3D) :
	var target : String = _prop(&'target', '')
	if !target.is_empty() :
		v.trigger_targets(target, b)
	var killtarget : String = _prop(&'killtarget', '')
	if !killtarget.is_empty() :
		v.killtarget(killtarget)


func _trigger_exit_now(b: Node3D) :
	var target : String = _prop(&'target', '')
	if !target.is_empty() :
		v.trigger_targets_exit(target, b)
