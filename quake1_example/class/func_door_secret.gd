extends QmapbspQuakeFunctionDoor
class_name QmapbspQuakeFunctionDoorSecret

func _starts_open() :
	return
	
func _map_ready() :
	super()
	if props.get('spawnflags', 0) & 0b01 :
		wait = -1.0
