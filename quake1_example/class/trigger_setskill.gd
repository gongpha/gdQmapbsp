extends QmapbspQuakeTrigger
class_name QmapbspQuakeTriggerSetskill

var skill : int = -1
# override because we don't want to show message
func _message(msg : String = '') : return


func _bo_en(b : Node3D) :
	super(b)
	v.set_skill(
		int(String(props.get('message')))
	)
