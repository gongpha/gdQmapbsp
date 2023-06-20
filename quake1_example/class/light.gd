extends OmniLight3D
class_name QmapbspQuakeLight

var props : Dictionary
func _get_properties(dict : Dictionary) : props = dict

var style : int

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
	# misc.qc line 59
	if !props.has("targetname") :
		# inert light
		queue_free()
		return
		
	style = props.get("style", &'0').to_int()
	
	if style >= 32 :
		var viewer : QmapbspQuakeViewer = get_meta(&'viewer')
		
		var spawnflags : int = props.get("spawnflags")
		if spawnflags & 0b1 :
			hide()
			viewer.qc_lightstyle(style, 'a')
		else :
			viewer.qc_lightstyle(style, 'm')

func _trigger(b) :
	# misc.qc line 67
	var spawnflags : int = props.get("spawnflags")
	var viewer : QmapbspQuakeViewer = get_meta(&'viewer')
	if !visible :
		viewer.qc_lightstyle(style, 'm')
	else :
		viewer.qc_lightstyle(style, 'a')
	
	visible = !visible

