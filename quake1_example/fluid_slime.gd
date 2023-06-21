extends "res://quake1_example/fluid.gd"
class_name QmapbspQuakeSlimeVolume

func _damage() -> int : return 2
func _liquid_type() -> String : return 'slime'
func _decay_time() -> int : return 5 # in seconds
