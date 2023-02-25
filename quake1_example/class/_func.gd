extends AnimatableBody3D
class_name QmapbspQuakeFunctionBrush

var props : Dictionary
func _get_properties(dict : Dictionary) : props = dict

var aabb : AABB

func _gen_aabb() :
	#aabb.position = global_position
	for m in get_children() :
		if m is GeometryInstance3D :
			aabb = aabb.merge(m.get_aabb())
	aabb.position += global_position
