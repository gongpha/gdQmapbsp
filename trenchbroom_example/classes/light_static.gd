@tool
extends "res://trenchbroom_example/classes/light.gd"

func _init() :
	super()
	shadow_enabled = true

func _qmapbsp_ent_props_pre(d : Dictionary) :
	super(d)
	light_bake_mode = Light3D.BAKE_STATIC
