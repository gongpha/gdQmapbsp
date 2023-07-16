extends QmapbspQuakeTrigger
class_name QmapbspQuakeTriggerOnlyregistered

# Spawnflags:
# 1: "Not touchable" : 0
const NO_TOUCH : int = 1


func _bo_en(b : Node3D) :
	if _flag(NO_TOUCH) : return
	
	if (get_meta(&'viewer') as QmapbspQuakeViewer).registered :
		_trigger(b)
		return
	_message()
	
	
func _bo_ex(b : Node3D) :
	if _flag(NO_TOUCH) : return
	
	super(b)
