extends Resource
class_name QmapbspMDLFile

## ded file

var scale : Vector3
var origin : Vector3
var radius : float
var offsets : Vector3

var numskins : int
var skinwidth : int
var skinheight : int
var numverts : int
var numtris : int
var numframes : int
var synctype : int
var flags : int
var size : float

static func load_from_file(f : FileAccess, pal_ : PackedColorArray) :
	# HEADER
	var begin := f.get_position()
	if f.get_32() != 0x4F504449 : return &"MDL_INVALID_MAGIC"
	if f.get_32() != 0x00000006 : return &"MDL_VERSION_NOT_SUPPORTED"
	
	
	var mdl := QmapbspMDLFile.new()
	mdl.pal = pal_
	mdl.scale = QmapbspBaseParser._qnor_to_vec3_read(f)
	mdl.origin = QmapbspBaseParser._qnor_to_vec3_read(f)
	mdl.radius = f.get_float()
	mdl.offsets = QmapbspBaseParser._qnor_to_vec3_read(f)
	
	mdl.numskins = f.get_32()
	mdl.skinwidth = f.get_32()
	mdl.skinheight = f.get_32()
	mdl.numverts = f.get_32()
	mdl.numtris = f.get_32()
	mdl.numframes = f.get_32()
	mdl.synctype = f.get_32()
	mdl.flags = f.get_32()
	mdl.size = f.get_float()
	
	mdl.load(f)
	
	return mdl

var pal : PackedColorArray
var skins : Array[Array]
var skinvertices : PackedVector3Array
var triangles : PackedColorArray
var frames : Array[Array]

func load(f : FileAccess) :
	# skins
	skins.resize(numskins)
	
	var image := QmapbspPakFile._make_image([
		Vector2i(skinwidth, skinheight),
		f.get_buffer(skinwidth * skinheight)
	], pal)
	
	var g : int = f.get_32()
	for i in numskins :
		skins[i] = [
			g,
			image
		]
		
	# skinvertices
	skinvertices.resize(numverts)
	for i in numverts :
		skinvertices[i] = Vector3(
			f.get_32(),
			f.get_32(),
			f.get_32()
		)
		
	# tris
	triangles.resize(numtris)
	for i in numtris :
		triangles[i] = Color(
			f.get_32(),
			f.get_32(),
			f.get_32(),
			f.get_32()
		)
		
#	# frames
#	frames.resize(numframes)
#	for i in numframes :
#		if f.get_32() == 0 :
#			numframes[i] = [_get_simpleframe_t]
#		else :
#			numframes[i] = [
#				_get_trivertx_t(f),
#				_get_trivertx_t(f),
#				func() :
#					var arr : PackedFloat32Array
#					arr.resize(numverts)
#					for i in numverts :
#						arr[i] = _get_trivertx_t(f)
#					return arr
#				[_get_simpleframe_t]
#			]
			
func _get_simpleframe_t(f : FileAccess) -> PackedByteArray :
	return [
		_get_trivertx_t(f),
		_get_trivertx_t(f),
		f.get_buffer(16).get_string_from_ascii(),
		func() :
			var arr : Array
			arr.resize(numverts)
			for i in numverts :
				arr[i] = _get_trivertx_t(f)
			return arr
	]

func _get_trivertx_t(f : FileAccess) -> PackedByteArray :
	return f.get_buffer(4)
