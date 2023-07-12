extends QmapbspQuakeTrigger
class_name QmapbspQuakeTriggerCounter

# Spawnflags:
# 1: "No Message" : 0
const NO_MESSAGE : int = 1

var counter : int = 0
var counter_max : int = 0

func _bo_en(b : Node3D) : return
func _bo_ex(b : Node3D) : return


func _map_ready() :
	counter_max = props.get('count', '0').to_int()


func _trigger(b : Node3D) :
	counter += 1
	if counter == counter_max :
		super(b)
