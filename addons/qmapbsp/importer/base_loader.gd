extends RefCounted
class_name QmapbspBaseLoader

var load_section : int
var section_keys : Array
var load_index : int

var curr_section : Array
var curr_section_call : Callable
var local_progress : float

func __end_section__() -> int : return __sections__().size()
var __end := __end_section__()
func __sections__() -> Dictionary : return {}
var __sections := __sections__()
var __error : StringName
var __ret : Array

func _init() :
	section_keys = __sections.keys()
	_update_load_section()

func poll(known_delta : float = INF) -> StringName :
	local_progress = curr_section_call.call()
	if __error != StringName() :
		return __error
	if local_progress >= 1.0 :
		load_section += 1
		local_progress = 0.0
		if load_section == __end :
			return &'END'
		_update_load_section()
		load_index = 0
	return StringName()
	
func _update_load_section() :
	curr_section_call = __sections[section_keys[load_section]]
	#curr_section_call = curr_section[0]

func get_progress() -> float :
	var stp := 1.0 / __end
	var sec := float(load_section) / __end
	var scp : float = local_progress * stp
	return scp + sec
	
func get_local_progress() -> float :
	return local_progress
