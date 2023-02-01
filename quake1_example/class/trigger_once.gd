extends QmapbspQuakeTrigger
class_name QmapbspQuakeTriggerOnce

func _trigger_now(b : Node3D) :
	super(b)
	queue_free()
