@icon("res://addons/qmapbsp/icon/icon_node3d_error.svg")
extends Node3D
class_name QmapbspMapImportError

## Created instead of an actual result when the importing progress was failed

@export var error : String
@export_multiline var error_data : String
