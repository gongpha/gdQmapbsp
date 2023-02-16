extends Node3D
class_name QmapbspQuakePathCorner

var props : Dictionary
func _get_properties(dict : Dictionary) : props = dict

var curve : Curve3D

func _map_ready() :
	# gen path
	curve = Curve3D.new()
	curve.add_point(position)
	
	var t : String = props.get('target', '')
	var added : PackedStringArray
	while !t.is_empty() and !added.has(t) :
		added.append(t)
		t = 'T_' + t
		var node := get_tree().get_first_node_in_group(t)
		if node is QmapbspQuakePathCorner :
			curve.add_point(node.position)
			t = node.props.get('target', '')
		else :
			break
