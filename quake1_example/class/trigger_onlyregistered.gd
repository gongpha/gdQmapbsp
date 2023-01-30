extends QmapbspQuakeTrigger
class_name QmapbspQuakeTriggerOnlyregistered

func _bo_en(b : Node3D) :
	if (get_meta(&'viewer') as QmapbspQuakeViewer).registered :
		_trigger(b)
		return
	_message()
