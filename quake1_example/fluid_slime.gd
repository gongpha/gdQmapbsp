extends "res://quake1_example/fluid.gd"
class_name QmapbspQuakeSlimeVolume

func _damage() -> int : return 2
func _liquid_type() -> StringName : return &'slime'
func _decay_time() -> float : return 5 # in seconds
