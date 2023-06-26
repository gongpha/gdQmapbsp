extends QmapbspQuakeFluidVolume
class_name QmapbspQuakeLavaVolume

func _damage() -> int : return 10
func _liquid_type() -> StringName : return &'lava'
