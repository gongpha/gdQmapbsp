extends OmniLight3D
class_name QmapbspQuakeLight

var props : Dictionary
func _get_properties(dict : Dictionary) : props = dict

func _init() :
	#shadow_enabled = true
	light_bake_mode = Light3D.BAKE_STATIC
	
	var s : String = props.get("light", "300")
	var light := s.to_int()
	omni_range = light / 32.0
	omni_attenuation = 0.00001
	light_indirect_energy = light / 50.0
	distance_fade_enabled = true
	distance_fade_length = 5.0
	
func _map_ready() :
	var spawnflags : int = props.get("spawnflags")
	if spawnflags & 0b1 :
		hide()

func _trigger(b) : visible = !visible
