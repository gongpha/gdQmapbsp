extends RefCounted
class_name QmapbspLmpFile

static func load_from_file(
	path : String, f : FileAccess, res : Array
) -> StringName :
	# returns PackedColorArray if it's a palette lump file
	# returns [PackedColorArray...] if it's a colormap lump file
	# returns [size, data] if it's a picture lump file
	
	if path.ends_with('palette.lmp') :
		res.append(_pal(f))
		return &'pal'
	if path.ends_with('colormap.lmp') :
		var arr : Array[PackedColorArray]
		arr.resize(32)
		for i in 32 :
			arr[i] = _pal(f)
		res.append(arr)
		return &'map'
		
	var psize := Vector2i(f.get_32(), f.get_32())
	res.append([
		psize,
		f.get_buffer(psize.x * psize.y)
	])
	return &'pic'
		
		
static func _pal(f : FileAccess) -> PackedColorArray :
	var pal : PackedColorArray
	pal.resize(256)
	for i in 256 : pal[i] = Color(
		f.get_8() / 255.0,
		f.get_8() / 255.0,
		f.get_8() / 255.0
	)
	return pal
