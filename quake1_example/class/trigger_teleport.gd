extends QmapbspQuakeTrigger
class_name QmapbspQuakeTriggerTeleport

func _trigger(b : Node3D) :
	for n in get_overlapping_bodies() :
		_teleport(b)

func _bo_en(b : Node3D) :
	if props.has("targetname") : return
	_teleport(b)
	
func _teleport(b : Node3D) :
	var dest : Node3D = get_tree().get_first_node_in_group(
		'T_' + props.get('target')
	)
	if !dest : return
	if b is QmapbspQuakePlayer :
		b.teleport_to(dest, true)
