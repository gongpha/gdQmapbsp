extends QmapbspQuakeFluidVolume
class_name QmapbspQuakeSlimeVolume

func damage() -> int : return 5
func liquid_type() -> StringName : return &'slime'
func duration() -> float : return 3 # in seconds
