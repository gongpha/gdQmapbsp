<<<<<<< HEAD
extends "res://quake1_example/fluid.gd"
class_name QmapbspQuakeLavaVolume

func _damage() -> int : return 10
func _liquid_type() -> String : return 'lava'
=======
extends QmapbspQuakeFluidVolume
class_name QmapbspQuakeLavaVolume

func _damage() -> int : return 10
func _liquid_type() -> StringName : return &'lava'
>>>>>>> liquid-volumes
