extends QmapbspQuakeTrigger
class_name QmapbspQuakeTriggerOnce

func _trigger(b : Node3D) :
	super(b)
	queue_free()
