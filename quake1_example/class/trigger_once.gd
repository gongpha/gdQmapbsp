extends QmapbspQuakeTrigger
class_name QmapbspQuakeTriggerOnce

# Spawnflags:
# 1: "Not touchable" : 0
const NO_TOUCH : int = 1


func _bo_en(b : Node3D) :
	if not _flag(NO_TOUCH) : super(b)


func _bo_ex(b : Node3D) :
	if not _flag(NO_TOUCH) : super(b)


func _trigger_now(b : Node3D) :
	super(b)
	_message()
	queue_free()
