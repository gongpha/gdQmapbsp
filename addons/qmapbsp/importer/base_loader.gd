extends RefCounted
class_name QmapbspBaseLoader

var load_section : int
var section_keys : Array
var section_ratios : PackedFloat32Array
var section_ratio_totals : PackedFloat32Array
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
	section_ratios.resize(__sections.size())
	section_ratio_totals.resize(__sections.size())
	var V : Array = __sections.values()
	var total : float = 0.0
	for i in V.size() :
		var v = V[i]
		var r : float
		if v is Array :
			r = v[1]
			
		else :
			r = 1.0
		total += r
		section_ratios[i] = r
	for i in V.size() :
		section_ratios[i] /= total
		
	for i in section_ratio_totals.size() - 1 :
		var t : float = section_ratios[i]
		if i > 0 :
			t += section_ratio_totals[i]
		section_ratio_totals[i + 1] = t
		
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
			_end()
			return &'END'
		_update_load_section()
		load_index = 0
	return StringName()
	
func _update_load_section() :
	var that = __sections[section_keys[load_section]]
	if that is Array :
		curr_section_call = that[0]
		return
	curr_section_call = that

func get_progress() -> float :
	if load_section >= __end : return 1.0
	#var stp := 1.0 / __end
	var sec := section_ratio_totals[load_section]
	var scp : float = local_progress * section_ratios[load_section]
	return scp + sec
	
func get_local_progress() -> float :
	return local_progress

func _end() : pass
