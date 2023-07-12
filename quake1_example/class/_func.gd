extends AnimatableBody3D
class_name QmapbspQuakeFunctionBrush

# Spawnflags:
# 256 = Not on Easy
# 512 = Not on Normal
# 1024 = Not on Hard
# 2048 = Not in Deathmatch
const NOT_IN_EASY : int = 256
const NOT_IN_NORMAL : int = 512
const NOT_IN_HARD : int = 1024
const NOT_IN_DM : int = 2048

var props : Dictionary
func _get_properties(dict : Dictionary) : props = dict

var aabb : AABB


func _flag(spawnflag : int) -> bool :
	if not props.has(&'spawnflags') : print('WARNING: Missing Spawnflags! ', self)
	var result : bool = props.get(&'spawnflags', 0) & spawnflag
	return result


func _gen_aabb() :
	for m in get_children() :
		if m is GeometryInstance3D :
			aabb = aabb.merge(m.get_aabb())
	aabb.position += global_position


func _touch_horizontal(nor : Vector3) -> bool :
	return (abs(nor.x) > 0.9 || abs(nor.z) > 0.9)


func _touch_vertical(nor : Vector3) -> bool :
	return abs(nor.y) > 0.9
