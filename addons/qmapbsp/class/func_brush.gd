@tool
extends StaticBody3D
class_name QmapbspBrush

func _qmapbsp_get_gi_mode() -> int :
	return GeometryInstance3D.GI_MODE_STATIC

func _init() -> void : set_script.call_deferred(null) # remove itself
