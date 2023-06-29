extends MeshInstance3D
class_name QmapbspMDLInstance

var mat : ShaderMaterial

@export var mdl : QmapbspMDLFile :
	set(v) :
		if mdl == v : return
		if mdl :
			mesh.surface_set_material(0, null)
		mdl = v
		mesh = v.base_mesh
		
		if !mat :
			mat = ShaderMaterial.new()
			mat.shader = preload("res://quake1_example/material/mdl_animated.gdshader")
		mesh.surface_set_material(0, mat)
		
		mat.set_shader_parameter(&'skin', v.skin)
		mat.set_shader_parameter(&'scale', v.quake_scale)
		mat.set_shader_parameter(&'origin', v.quake_origin)
		mat.set_shader_parameter(&'animation', v.animation)
		mat.set_shader_parameter(&'skin', v.skin)
		
		mat.set_shader_parameter(&'seek', seek)
		
@export var seek : float :
	set(v) :
		if mat :
			mat.set_shader_parameter(&'seek', v)
		seek = v

func _init() -> void :
	pass
