extends QmapbspQuakeTrigger
class_name QmapbspQuakeTriggerChangeLevel

func _trigger(b : Node3D) :
	v.change_level(props.get('map', ''))
