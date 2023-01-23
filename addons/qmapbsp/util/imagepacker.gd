extends RefCounted
class_name QuakeImagePacker

var stack_size : PackedVector2Array
var stack_data : Array[Image]

func add(size : Vector2i, im : Image) -> int :
	stack_size.append(size)
	stack_data.append(im)
	return stack_size.size() - 1
	
func commit(format : int, pos_list : PackedVector2Array, po2 : bool = true) -> Image :
	if stack_size.is_empty() : return null
	var dict := Geometry2D.make_atlas(stack_size)
	var points : PackedVector2Array = dict['points']
	var size : Vector2i = dict['size']
	if po2 :
		size = Vector2i(nearest_po2(size.x), nearest_po2(size.y))
	var im := Image.create(size.x, size.y, false, format)
	for i in points.size() :
		im.blit_rect(stack_data[i], Rect2i(Vector2(), stack_size[i]), points[i])
	pos_list.append_array(points)
	return im
