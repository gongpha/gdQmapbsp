extends Area3D
class_name QmapbspQuakeLeafVolume

func _ready() :
	body_shape_entered.connect(_bo_en)
	body_shape_exited.connect(_bo_ex)

func _bo_en(
	rid : RID, b : Node3D,
	body_shape_index : int, local_shape_index : int
) :
	
	var shape_node : CollisionShape3D = shape_owner_get_owner(shape_find_owner(local_shape_index))
	if b is QmapbspQuakePlayer :
		var viewer : QmapbspQuakeViewer = get_meta(&'viewer', null)
		viewer.set_ambsnds(shape_node, shape_node.get_meta(&'ambsnds'))
		#prints("EN", shape_node.get_meta(&'ambsnds'))

func _bo_ex(
	rid : RID, b : Node3D,
	body_shape_index : int, local_shape_index : int
) :
	
	var shape_node : CollisionShape3D = shape_owner_get_owner(shape_find_owner(local_shape_index))
	if b is QmapbspQuakePlayer :
		var viewer : QmapbspQuakeViewer = get_meta(&'viewer', null)
		viewer.set_ambsnds(shape_node, Vector4(-1, -1, -1, -1))
		#prints("EX", shape_node.get_meta(&'ambsnds'))
