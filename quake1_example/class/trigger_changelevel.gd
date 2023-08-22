extends QmapbspQuakeTrigger
class_name QmapbspQuakeTriggerChangeLevel

# Spawnflags:
# 1: "No intermission" : 0
const NO_INTERMISSION : int = 1


func _trigger(b : Node3D) :
	v.change_level(props.get('map', ''))
