extends QmapbspQuakeTrigger
class_name QmapbspQuakeTriggerSetskill

var skill : int = -1
func _message() : return

func _bo_en(b : Node3D) :
	super(b)
	v.set_skill(
		int(props.get('message'))
	)
