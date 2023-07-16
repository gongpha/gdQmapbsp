extends QmapbspQuakeTrigger
class_name QmapbspQuakeTriggerOnce

# Spawnflags:
# 1: "Not touchable" : 0
const NO_TOUCH : int = 1

func _trigger(b : Node3D) :
	_trigger_now(b)

func _trigger_now(b : Node3D) :
	super(b)
	queue_free()
