extends QmapbspQuakeTrigger
class_name QmapbspQuakeTriggerCounter

# Spawnflags:
# 1: "No Message" : 0
const NO_MESSAGE : int = 1
const COUNT : int = 2

var counter : int = 0
var counter_max : int = 0

func _bo_en(b : Node3D) : return
func _bo_ex(b : Node3D) : return


func _map_ready() :
	counter_max = _prop(&'count', COUNT)


func _trigger(b : Node3D) :
	counter += 1
	
	if not _flag(NO_MESSAGE) :
		if (counter_max - counter) >= 4 : _message("There are more to go...")
		elif (counter_max - counter) == 3 : _message("Only 3 more to go...")
		elif (counter_max - counter) == 2 : _message("Only 2 more to go...")
		elif (counter_max - counter) == 1 : _message("Only 1 more to go...")

	if counter == counter_max :
		super(b)
