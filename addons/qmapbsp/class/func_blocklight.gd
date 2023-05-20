@tool
extends Node3D
class_name QmapbspBlocklight

func _qmapbsp_is_brush_solid() -> bool : return false

func _init() -> void : set_script.call_deferred(null) # remove itself
