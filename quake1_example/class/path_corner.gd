extends Node3D
class_name QmapbspQuakePathCorner

var props : Dictionary
func _get_properties(dict : Dictionary) : props = dict

var linked : Array = []

func _map_ready() :
	linked.append(self)
	
	var t : String = props.get('target', '')
	var added : PackedStringArray
	while !t.is_empty() and !added.has(t) :
		added.append(t)
		t = 'T_' + t
		var node := get_tree().get_first_node_in_group(t)
		if node is QmapbspQuakePathCorner :
			linked.append(node)
			t = node.props.get('target', '')
		else :
			break
