extends Resource
class_name QmapbspMDLFile

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

static func load_from_file(
	f : FileAccess, pal_ : PackedColorArray,
	inverse_scale_factor := 32.0
) :
	# HEADER
	var begin := f.get_position()
	if f.get_32() != 0x4F504449 : return &"MDL_INVALID_MAGIC"
	if f.get_32() != 0x00000006 : return &"MDL_VERSION_NOT_SUPPORTED"
	
	
	var mdl := QmapbspMDLFile.new()
	mdl.pal = pal_
	mdl.quake_scale = QmapbspBaseParser._read_vec3(f) / inverse_scale_factor
	mdl.quake_origin = QmapbspBaseParser._read_vec3(f) / inverse_scale_factor
	mdl.radius = f.get_float()
	mdl.offsets = QmapbspBaseParser._read_vec3(f)
	
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
	mdl.make_base_model()
	mdl.bake_animations()
	mdl.clean()
	
	return mdl

var pal : PackedColorArray
var skins : Array[Array]
var skinvertices : PackedVector3Array
var triangles : PackedColorArray
var frames : Array[Array]

#############

@export var base_mesh : ArrayMesh
@export var quake_scale : Vector3
@export var quake_origin : Vector3
@export var animation : ImageTexture
@export var skin : ImageTexture

const UUU := 0.0
func make_base_model() -> void :
	var st := SurfaceTool.new()
	var skinarr : Array = skins[0]
	var im : Image
	if skinarr[0] == 0 :
		im = skinarr[1]
	else :
		im = skinarr[-1][0]
	skin = ImageTexture.create_from_image(im)
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_R_FLOAT)
	
	for t in triangles :
		var v := Vector3i(
			t[1], t[2], t[3]
		)
		var s0 := skinvertices[v[0]]
		var s1 := skinvertices[v[1]]
		var s2 := skinvertices[v[2]]
		if int(t[0]) == 0 : # front
			if int(s0[0]) == 0x20 and s0[1] <= 0.5 : s0[1] += 0.5
			if int(s1[0]) == 0x20 and s1[1] <= 0.5 : s1[1] += 0.5
			if int(s2[0]) == 0x20 and s2[1] <= 0.5 : s2[1] += 0.5
		else :
			if int(s0[0]) == 0x20 and s0[1] >= 0.5 : s0[1] -= 0.5
			if int(s1[0]) == 0x20 and s1[1] >= 0.5 : s1[1] -= 0.5
			if int(s2[0]) == 0x20 and s2[1] >= 0.5 : s2[1] -= 0.5
		
		
		var first_frame : Array[PackedByteArray]
		if frames[0][0] == 0 :
			first_frame = frames[0][-1][3]
		else :
			first_frame = frames[0][-1][0][3]
		
		var first_frame_verts : PackedByteArray = first_frame[v[0]]
		st.set_uv(Vector2(s0[1] , s0[2]))
		st.set_normal(QmapbspBaseParser._qnor_to_vec3(NORMS[first_frame_verts[3]]))
		st.set_custom(0, Color(v[0] / float(numverts), UUU, UUU))
		st.add_vertex(QmapbspBaseParser._qnor_to_vec3(Vector3(
			first_frame_verts[0],
			first_frame_verts[1],
			first_frame_verts[2]
		) * quake_scale + quake_origin))
		first_frame_verts = first_frame[v[1]]
		st.set_uv(Vector2(s1[1], s1[2]))
		st.set_normal(QmapbspBaseParser._qnor_to_vec3(NORMS[first_frame_verts[3]]))
		st.set_custom(0, Color(v[1] / float(numverts), UUU, UUU))
		st.add_vertex(QmapbspBaseParser._qnor_to_vec3(Vector3(
			first_frame_verts[0],
			first_frame_verts[1],
			first_frame_verts[2]
		) * quake_scale + quake_origin))
		first_frame_verts = first_frame[v[2]]
		st.set_uv(Vector2(s2[1], s2[2]))
		st.set_normal(QmapbspBaseParser._qnor_to_vec3(NORMS[first_frame_verts[3]]))
		st.set_custom(0, Color(v[2] / float(numverts), UUU, UUU))
		st.add_vertex(QmapbspBaseParser._qnor_to_vec3(Vector3(
			first_frame_verts[0],
			first_frame_verts[1],
			first_frame_verts[2]
		) * quake_scale + quake_origin))
		
	base_mesh = st.commit()
	#print(scale)
	#print(origin)
	#ResourceSaver.save(base_mesh, "res://a.mesh")

func bake_animations() -> void :
	var im := Image.create(numverts, numframes, false, Image.FORMAT_RGB8)
	for f in numframes :
		var simpleframe : Array = frames[f][-1]
		
		var vertices : Array[PackedByteArray]
		if frames[f][0] == 0 :
			vertices = simpleframe[3]
		else :
			vertices = simpleframe[0][3]
		
		for i in vertices.size() :
			var V := vertices[i]
			var v := Vector3(
				V[0], V[1], V[2]
			) / 255
			im.set_pixel(i, f, Color(
				v.x, v.y, v.z
			))
	animation = ImageTexture.create_from_image(im)

func clean() -> void :
	pal = PackedColorArray()
	skins.clear()
	skinvertices.clear()
	triangles.clear()
	frames.clear()

func load(f : FileAccess) :
	# skins
	skins.resize(numskins)
	
	for i in numskins :
		if f.get_32() == 0 :
			skins[i] = [
				0,
				QmapbspPakFile._make_image([
					Vector2i(skinwidth, skinheight),
					f.get_buffer(skinwidth * skinheight)
				], pal)
			]
		else :
			var nb := f.get_32()
			skins[i] = [
				nb,
				(
					func() :
						var pf32 : PackedFloat32Array
						pf32.resize(nb)
						for j in nb : pf32[j] = f.get_32()
						return pf32
						).call(),
				(
					func() :
						var iarr : Array[Image]
						for j in nb : iarr[j] = QmapbspPakFile._make_image([
							Vector2i(skinwidth, skinheight),
							f.get_buffer(skinwidth * skinheight)
						], pal)
						return iarr
						).call()
			]
		
	# skinvertices
	skinvertices.resize(numverts)
	for i in numverts :
		skinvertices[i] = Vector3(
			f.get_32(),
			float(f.get_32()) / skinwidth,
			float(f.get_32()) / skinheight
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
		
	# frames
	frames.resize(numframes)
	for i in numframes :
		var type := f.get_32()
		if type == 0 :
			frames[i] = [
				# single
				type,
				_get_simpleframe_t(f)
			]
		else :
			var nb := f.get_32()
			frames[i] = [
				# group
				type,
				nb, # nb
				_get_trivertx_t(f), # min
				_get_trivertx_t(f), # max
				
				(
					func() :
						var pf32 : PackedFloat32Array
						pf32.resize(nb)
						for j in nb : pf32[j] = f.get_32()
						return pf32
						).call(),
				(
					func() :
						var simpleframes : Array[Array]
						simpleframes.resize(nb)
						for j in nb : simpleframes[j] = _get_simpleframe_t(f)
						return simpleframes
						).call(),
				
			]
	pass
			
func _get_simpleframe_t(f : FileAccess) -> Array :
	return [
		_get_trivertx_t(f),
		_get_trivertx_t(f),
		f.get_buffer(16).get_string_from_ascii(),
		(
			func() :
				var arr : Array[PackedByteArray]
				arr.resize(numverts)
				for i in numverts :
					arr[i] = _get_trivertx_t(f)
				return arr
				).call()
	]

func _get_trivertx_t(f : FileAccess) -> PackedByteArray :
	return f.get_buffer(4)

# 162 precalculated normals
const NORMS : PackedVector3Array = [
	Vector3(-0.525731, 0.000000, 0.850651),
	Vector3(-0.442863, 0.238856, 0.864188),
	Vector3(-0.295242, 0.000000, 0.955423),
	Vector3(-0.309017, 0.500000, 0.809017),
	Vector3(-0.162460, 0.262866, 0.951056),
	Vector3(0.000000, 0.000000, 1.000000),
	Vector3(0.000000, 0.850651, 0.525731),
	Vector3(-0.147621, 0.716567, 0.681718),
	Vector3(0.147621, 0.716567, 0.681718),
	Vector3(0.000000, 0.525731, 0.850651),
	Vector3(0.309017, 0.500000, 0.809017),
	Vector3(0.525731, 0.000000, 0.850651),
	Vector3(0.295242, 0.000000, 0.955423),
	Vector3(0.442863, 0.238856, 0.864188),
	Vector3(0.162460, 0.262866, 0.951056),
	Vector3(-0.681718, 0.147621, 0.716567),
	Vector3(-0.809017, 0.309017, 0.500000),
	Vector3(-0.587785, 0.425325, 0.688191),
	Vector3(-0.850651, 0.525731, 0.000000),
	Vector3(-0.864188, 0.442863, 0.238856),
	Vector3(-0.716567, 0.681718, 0.147621),
	Vector3(-0.688191, 0.587785, 0.425325),
	Vector3(-0.500000, 0.809017, 0.309017),
	Vector3(-0.238856, 0.864188, 0.442863),
	Vector3(-0.425325, 0.688191, 0.587785),
	Vector3(-0.716567, 0.681718, -0.147621),
	Vector3(-0.500000, 0.809017, -0.309017),
	Vector3(-0.525731, 0.850651, 0.000000),
	Vector3(0.000000, 0.850651, -0.525731),
	Vector3(-0.238856, 0.864188, -0.442863),
	Vector3(0.000000, 0.955423, -0.295242),
	Vector3(-0.262866, 0.951056, -0.162460),
	Vector3(0.000000, 1.000000, 0.000000),
	Vector3(0.000000, 0.955423, 0.295242),
	Vector3(-0.262866, 0.951056, 0.162460),
	Vector3(0.238856, 0.864188, 0.442863),
	Vector3(0.262866, 0.951056, 0.162460),
	Vector3(0.500000, 0.809017, 0.309017),
	Vector3(0.238856, 0.864188, -0.442863),
	Vector3(0.262866, 0.951056, -0.162460),
	Vector3(0.500000, 0.809017, -0.309017),
	Vector3(0.850651, 0.525731, 0.000000),
	Vector3(0.716567, 0.681718, 0.147621),
	Vector3(0.716567, 0.681718, -0.147621),
	Vector3(0.525731, 0.850651, 0.000000),
	Vector3(0.425325, 0.688191, 0.587785),
	Vector3(0.864188, 0.442863, 0.238856),
	Vector3(0.688191, 0.587785, 0.425325),
	Vector3(0.809017, 0.309017, 0.500000),
	Vector3(0.681718, 0.147621, 0.716567),
	Vector3(0.587785, 0.425325, 0.688191),
	Vector3(0.955423, 0.295242, 0.000000),
	Vector3(1.000000, 0.000000, 0.000000),
	Vector3(0.951056, 0.162460, 0.262866),
	Vector3(0.850651, -0.525731, 0.000000),
	Vector3(0.955423, -0.295242, 0.000000),
	Vector3(0.864188, -0.442863, 0.238856),
	Vector3(0.951056, -0.162460, 0.262866),
	Vector3(0.809017, -0.309017, 0.500000),
	Vector3(0.681718, -0.147621, 0.716567),
	Vector3(0.850651, 0.000000, 0.525731),
	Vector3(0.864188, 0.442863, -0.238856),
	Vector3(0.809017, 0.309017, -0.500000),
	Vector3(0.951056, 0.162460, -0.262866),
	Vector3(0.525731, 0.000000, -0.850651),
	Vector3(0.681718, 0.147621, -0.716567),
	Vector3(0.681718, -0.147621, -0.716567),
	Vector3(0.850651, 0.000000, -0.525731),
	Vector3(0.809017, -0.309017, -0.500000),
	Vector3(0.864188, -0.442863, -0.238856),
	Vector3(0.951056, -0.162460, -0.262866),
	Vector3(0.147621, 0.716567, -0.681718),
	Vector3(0.309017, 0.500000, -0.809017),
	Vector3(0.425325, 0.688191, -0.587785),
	Vector3(0.442863, 0.238856, -0.864188),
	Vector3(0.587785, 0.425325, -0.688191),
	Vector3(0.688191, 0.587785, -0.425325),
	Vector3(-0.147621, 0.716567, -0.681718),
	Vector3(-0.309017, 0.500000, -0.809017),
	Vector3(0.000000, 0.525731, -0.850651),
	Vector3(-0.525731, 0.000000, -0.850651),
	Vector3(-0.442863, 0.238856, -0.864188),
	Vector3(-0.295242, 0.000000, -0.955423),
	Vector3(-0.162460, 0.262866, -0.951056),
	Vector3(0.000000, 0.000000, -1.000000),
	Vector3(0.295242, 0.000000, -0.955423),
	Vector3(0.162460, 0.262866, -0.951056),
	Vector3(-0.442863, -0.238856, -0.864188),
	Vector3(-0.309017, -0.500000, -0.809017),
	Vector3(-0.162460, -0.262866, -0.951056),
	Vector3(0.000000, -0.850651, -0.525731),
	Vector3(-0.147621, -0.716567, -0.681718),
	Vector3(0.147621, -0.716567, -0.681718),
	Vector3(0.000000, -0.525731, -0.850651),
	Vector3(0.309017, -0.500000, -0.809017),
	Vector3(0.442863, -0.238856, -0.864188),
	Vector3(0.162460, -0.262866, -0.951056),
	Vector3(0.238856, -0.864188, -0.442863),
	Vector3(0.500000, -0.809017, -0.309017),
	Vector3(0.425325, -0.688191, -0.587785),
	Vector3(0.716567, -0.681718, -0.147621),
	Vector3(0.688191, -0.587785, -0.425325),
	Vector3(0.587785, -0.425325, -0.688191),
	Vector3(0.000000, -0.955423, -0.295242),
	Vector3(0.000000, -1.000000, 0.000000),
	Vector3(0.262866, -0.951056, -0.162460),
	Vector3(0.000000, -0.850651, 0.525731),
	Vector3(0.000000, -0.955423, 0.295242),
	Vector3(0.238856, -0.864188, 0.442863),
	Vector3(0.262866, -0.951056, 0.162460),
	Vector3(0.500000, -0.809017, 0.309017),
	Vector3(0.716567, -0.681718, 0.147621),
	Vector3(0.525731, -0.850651, 0.000000),
	Vector3(-0.238856, -0.864188, -0.442863),
	Vector3(-0.500000, -0.809017, -0.309017),
	Vector3(-0.262866, -0.951056, -0.162460),
	Vector3(-0.850651, -0.525731, 0.000000),
	Vector3(-0.716567, -0.681718, -0.147621),
	Vector3(-0.716567, -0.681718, 0.147621),
	Vector3(-0.525731, -0.850651, 0.000000),
	Vector3(-0.500000, -0.809017, 0.309017),
	Vector3(-0.238856, -0.864188, 0.442863),
	Vector3(-0.262866, -0.951056, 0.162460),
	Vector3(-0.864188, -0.442863, 0.238856),
	Vector3(-0.809017, -0.309017, 0.500000),
	Vector3(-0.688191, -0.587785, 0.425325),
	Vector3(-0.681718, -0.147621, 0.716567),
	Vector3(-0.442863, -0.238856, 0.864188),
	Vector3(-0.587785, -0.425325, 0.688191),
	Vector3(-0.309017, -0.500000, 0.809017),
	Vector3(-0.147621, -0.716567, 0.681718),
	Vector3(-0.425325, -0.688191, 0.587785),
	Vector3(-0.162460, -0.262866, 0.951056),
	Vector3(0.442863, -0.238856, 0.864188),
	Vector3(0.162460, -0.262866, 0.951056),
	Vector3(0.309017, -0.500000, 0.809017),
	Vector3(0.147621, -0.716567, 0.681718),
	Vector3(0.000000, -0.525731, 0.850651),
	Vector3(0.425325, -0.688191, 0.587785),
	Vector3(0.587785, -0.425325, 0.688191),
	Vector3(0.688191, -0.587785, 0.425325),
	Vector3(-0.955423, 0.295242, 0.000000),
	Vector3(-0.951056, 0.162460, 0.262866),
	Vector3(-1.000000, 0.000000, 0.000000),
	Vector3(-0.850651, 0.000000, 0.525731),
	Vector3(-0.955423, -0.295242, 0.000000),
	Vector3(-0.951056, -0.162460, 0.262866),
	Vector3(-0.864188, 0.442863, -0.238856),
	Vector3(-0.951056, 0.162460, -0.262866),
	Vector3(-0.809017, 0.309017, -0.500000),
	Vector3(-0.864188, -0.442863, -0.238856),
	Vector3(-0.951056, -0.162460, -0.262866),
	Vector3(-0.809017, -0.309017, -0.500000),
	Vector3(-0.681718, 0.147621, -0.716567),
	Vector3(-0.681718, -0.147621, -0.716567),
	Vector3(-0.850651, 0.000000, -0.525731),
	Vector3(-0.688191, 0.587785, -0.425325),
	Vector3(-0.587785, 0.425325, -0.688191),
	Vector3(-0.425325, 0.688191, -0.587785),
	Vector3(-0.425325, -0.688191, -0.587785),
	Vector3(-0.587785, -0.425325, -0.688191),
	Vector3(-0.688191, -0.587785, -0.425325)
]
