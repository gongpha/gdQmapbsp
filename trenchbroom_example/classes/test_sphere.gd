@tool
extends RigidBody3D

func _ent_props_post(d : Dictionary) :
	var radius : float = d.get('radius', 0.5)
	if radius != 0.5 :
		# clone
		var ncol : CollisionShape3D = $col
		var nmesh : MeshInstance3D = $mesh
		get_parent().set_editable_instance(self, true)
		var col : SphereShape3D = ncol.shape.duplicate()
		var mesh : SphereMesh = nmesh.mesh.duplicate()
		col.radius = radius
		mesh.radius = radius
		mesh.height = radius * 2.0
		ncol.shape = col
		nmesh.mesh = mesh

func _qmapbsp_get_fgd_info() -> Dictionary :
	return {
		"radius" : ["The sphere's radius", 0.5],
	}
