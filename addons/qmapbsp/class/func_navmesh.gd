@tool
extends NavigationRegion3D
class_name QmapbspFuncNavmesh

func _qmapbsp_is_brush_solid() -> bool : return false

func _init() -> void : set_script.call_deferred(null) # remove itself
