extends QmapbspBaseParser
class_name QmapbspBSPParser

# CURRENTLY SUPPORT QUAKE 1 MAP ONLY

var curr_entry : Vector2i
var bsp_version : int

# in
var scale : float = 1 / 32.0
var read_miptextures : bool = false # includes textures, lightmaps and more
var known_palette : PackedColorArray
var bsp_shader : Shader

var model_map : Dictionary # <model_id : ent_id>

func _init() :
	super()
	tell_entity_props.connect(_tell_entity_props)

func begin_file(f : FileAccess) -> StringName :
	super(f)
	
	bsp_version = file.get_32()
	match bsp_version :
		29 : # OK
			pass
		_ : return &'BSP_VERSION_IS_NOT_SUPPORTED'
	
	_read_dentry()
	return StringName()
	
func _GatheringAllEntities() -> float :
	if !mapf :
		curr_entry = entries['entities']
		file.seek(curr_entry.x)
		var b := file.get_buffer(curr_entry.y).get_string_from_ascii()
		mapf = QmapbspMapFormat.begin_from_text(b)
		#mapf.tell_skip_entity_brushes = true

	var ret : Dictionary

	var err := mapf.poll(__ret)
	_mapf_after_poll(err)
	var prog := _mapf_prog()
	if prog >= 1.0 :
		entities_kv.clear()
		#mapf = null
		kv = {}
		return 1.0
	return prog
	
func _brush_found() :
	# impossible to reach here
	breakpoint
	
func _tell_entity_props(id : int, dict : Dictionary) :
	var model_id : int
	if id == 0 : model_id = 0
	else :
		model_id = QmapbspMapFormat.expect_int(dict.get('model', '*-1').substr(1))
		if model_id == -1 : return
	
	model_map[model_id] = id
	
##############################################

var vertices : PackedVector3Array
var edges : Array[Vector2i]
var edge_list : PackedInt32Array
var planes : Array[Plane]
var planetypes : Array[int]
var textures : Array[Material]
var texinfos : Array[Array]
var models : Array[Array]
var faces : Array[Array]
var clipnodes : Array[Array]
var entities : Array[Array]

var import_tasks := [
	_read_vertices,
	_read_edges,
	_read_ledges,
	_read_planes,
	_read_mip_textures,
	_read_texinfo,
	_read_models,
	_read_faces
]
var import_curr_index : int = 0
var import_curr_func : Callable = import_tasks[0]
var import_local_progress : float = 0.0

func _ImportingData() -> float :
	import_local_progress = import_curr_func.call()
	if import_local_progress >= 1.0 :
		import_curr_index += 1
		import_local_progress = 0.0
		if import_curr_index == import_tasks.size() :
			return 1.0
		import_curr_func = import_tasks[import_curr_index]
		load_index = 0
	return import_get_progress()

func import_get_progress() -> float :
	var stp := 1.0 / import_tasks.size()
	var sec := float(import_curr_index) / import_tasks.size()
	var scp : float = import_local_progress * stp
	return scp + sec

func _read_vertices() -> float :
	if load_index == 0 :
		curr_entry = entries['vertices']
		file.seek(curr_entry.x)
		vertices.resize(curr_entry.y / VEC3_SIZE)
	vertices[load_index] = _qpos_to_vec3(
		Vector3(
			file.get_float(),
			file.get_float(),
			file.get_float()
		)
	)
	load_index += 1
	return float(load_index) / vertices.size()
			
func _read_edges() -> float :
	if load_index == 0 :
		curr_entry = entries['edges']
		file.seek(curr_entry.x)
		edges.resize(curr_entry.y / 4)
	edges[load_index] = Vector2i(
		file.get_16(), # start vertex
		file.get_16() # end vertex
	)
	load_index += 1
	return  float(load_index) / edges.size()
		
func _read_ledges() -> float :
	if load_index == 0 :
		curr_entry = entries['ledges']
		file.seek(curr_entry.x)
		edge_list.resize(curr_entry.y / 4)
	edge_list[load_index] = file.get_32()
	load_index += 1
	return float(load_index) / edge_list.size()
		
func _read_planes() -> float :
	if load_index == 0 :
		curr_entry = entries['planes']
		file.seek(curr_entry.x)
		planes.resize(curr_entry.y / 20)
		planetypes.resize(planes.size())
	
	planes[load_index] = Plane(
		_qnor_to_vec3_read(file),
		file.get_float() * unit_scale
	)
	planetypes[load_index] = file.get_32()
	load_index += 1
	return float(load_index) / planes.size()
		
var mipoffsets : PackedInt32Array
func _read_mip_textures() -> float :
	if load_index == 0 :
		curr_entry = entries['miptex']
		file.seek(curr_entry.x)
		var count := file.get_32()
		textures.resize(count)
		
		mipoffsets.resize(count)
		for i in count :
			mipoffsets[i] = file.get_32()
			
	#var skip_mips : bool = true
	var texture_offset := mipoffsets[load_index]
	var mat : Material
	if texture_offset < 0 :
		mat = wim.get_no_texture()
		mat.set_meta(&'size', Vector2i(64, 64))
	else :
		var toffset := curr_entry.x + texture_offset
		file.seek(toffset)
		var tname := file.get_buffer(16).get_string_from_ascii()
		var tsize := Vector2i(file.get_32(), file.get_32())
		mat = wim._texture_get(
			tname,
			tsize
		)
		if !mat and read_miptextures :
			# use a texture inside the bsp file
			var doffset := file.get_32()
			file.seek(toffset + doffset)
			var data := file.get_buffer(tsize.x * tsize.y)
			var im := _make_im_from_pal(tsize, data)
			var itex := ImageTexture.create_from_image(im)
			mat = wim._texture_get_material_for_integrated(tname, itex)
			if !mat :
				mat = ShaderMaterial.new()
				mat.shader = bsp_shader
				mat.set_shader_parameter(&'tex', itex)
				mat.set_meta(&'apply_lightmaps', true)
		if !mat :
			mat = wim.get_no_texture()
		mat.set_meta(&'size', tsize)
		textures[load_index] = mat
		
		#for j in (4 if skip_mips else 3) : file.get_32()
	load_index += 1
	if load_index == mipoffsets.size() :
		mipoffsets.clear()
		return 1.0
	return float(load_index) / mipoffsets.size()
			
func _read_texinfo() -> float :
	if load_index == 0 :
		curr_entry = entries['texinfo']
		file.seek(curr_entry.x)
		texinfos.resize(curr_entry.y / 40)
	texinfos[load_index] = [
		_qnor_to_vec3_read(file), file.get_float(), # S
		_qnor_to_vec3_read(file), file.get_float(), # T
		file.get_32(), # texture index
		file.get_32() # flags
	]
	load_index += 1
	return float(load_index) / texinfos.size()
		
func _read_models() -> float :
	if load_index == 0 :
		curr_entry = entries['models']
		file.seek(curr_entry.x)
		models.resize(curr_entry.y / 64)
	models[load_index] = [
		_qpos_to_vec3_read(file), _qpos_to_vec3_read(file), # bound
		_qpos_to_vec3_read(file), # origin
		file.get_32(), file.get_32(), file.get_32(), file.get_32(), # nodes
		file.get_32(), # leaves
		file.get_32(), # index
		file.get_32() # count
	]
	load_index += 1
	return float(load_index) / models.size()

func _read_faces() -> float :
	if load_index == 0 :
		curr_entry = entries['faces']
		file.seek(curr_entry.x)
		faces.resize(curr_entry.y / 20)
	faces[load_index] = [
		file.get_16(), # plane id
		file.get_16(), # side
		file.get_32(), # first edge on the list
		file.get_16(), # edge count
		file.get_16(), # tinfo id
		file.get_8(), # lightmap type
		file.get_8(), # lightmap offset
		file.get_8(), file.get_8(), # light
		file.get_32(), # lightmap
	]
	load_index += 1
	return float(load_index) / faces.size()
	
var entity_geo : Dictionary # <model_id : <region or 0 : [...]> >
var lightmapdata : PackedByteArray
var ip : QuakeImagePacker
var unlit : int
func _ConstructingData() -> float : # per model
	if load_index == 0 and loc_load_index == 0 :
		if read_miptextures :
			var lightmaps_e : Vector2i = entries.lightmaps
			file.seek(lightmaps_e.x)
			lightmapdata = file.get_buffer(lightmaps_e.y)
			ip = QuakeImagePacker.new()
			
			# for unlit surfaces
			unlit = ip.add(Vector2i(2, 2),
				Image.create_from_data(2, 2, false, Image.FORMAT_L8, [
					255, 255, 255, 255
				]
			))
	
	if wim._entity_prefers_bsp_geometry(load_index) :
		if _model_geo() :
			load_index += 1
			loc_load_index = 0
	else :
		load_index += 1
			
	if load_index == models.size() :
		lightmapdata.clear()
		return 1.0
	return float(load_index) / models.size()
	
var loc_load_index : int
var entity_geo_d : Dictionary
var model : Array
var bound_min : Vector3
var bound_max : Vector3
var extents : Vector3
var face_count : int
var face_indexf : int
var unit_scale_f : float
var region_size : float
func _model_geo() -> bool :
	if loc_load_index == 0 :
		model = models[load_index]
		entity_geo_d = {}
		entity_geo[load_index] = entity_geo_d
		
		bound_min = model[0]
		bound_max = model[1]
		
		extents = (bound_max - bound_min) / 2
		
		extents = Vector3(abs(extents.x), abs(extents.y), abs(extents.z))
		
		face_count = model[9]
		face_indexf = model[8]
		unit_scale_f = 1.0 / unit_scale
		region_size = wim._get_region_size()
	elif loc_load_index == face_count :
		loc_load_index = 0
		return true
		
	var face_array_index : int = face_indexf + loc_load_index
	var face : Array = faces[face_array_index]
	
	var face_vertices : PackedVector3Array
	var face_normals : PackedVector3Array
	var face_uvs : PackedVector2Array
	var face_uvrs : PackedVector2Array

	var edge_start : int = face[2]
	var edge_count : int = face[3]

	face_vertices.resize(edge_count)
	face_normals.resize(edge_count)
	face_uvs.resize(edge_count)
	if read_miptextures :
		face_uvrs.resize(edge_count)
	
	var centroid : Vector3
	
	var texture_info : Array = texinfos[face[4]] # tinfo id
	var texture : Material = textures[texture_info[4]] # from texture index

	var tsize : Vector2i = texture.get_meta(&'size') if texture else Vector2i()
	
	var tscale := Vector2(
		1.0 / (tsize.x * unit_scale),
		1.0 / (tsize.y * unit_scale)
	)
	#var tscale := tsize

	var plane_normal : Vector3 = planes[face[0]].normal * (
		# flip if it's backface (behind the plane)
		-1 if face[1] == 1 else 1
	)
	
	var uv_min := Vector2(INF, INF)
	var uv_max := Vector2(-INF, -INF)
	
	for k in edge_count :
		var edge_index : int = edge_list[edge_start + k]
		var v0 : int
		if edge_index < 0 :
			edge_index = -edge_index
			v0 = edges[edge_index][1]
		else :
			v0 = edges[edge_index][0]
		var vert : Vector3 = vertices[v0]
		face_vertices[k] = vert
		face_normals[k] = plane_normal
		var t_s : Vector3 = texture_info[0]
		var f_s : float = texture_info[1]
		var t_t : Vector3 = texture_info[2]
		var f_t : float = texture_info[3]
		
		var uv := Vector2(
			vert.dot(t_s) * tscale.x +
			f_s / tsize.x,
			vert.dot(t_t) * tscale.y +
			f_t / tsize.y
		)
		face_uvs[k] = uv
		
		if read_miptextures :
			uv = Vector2(
				vert.dot(t_s) * unit_scale_f +
				f_s,
				vert.dot(t_t) * unit_scale_f +
				f_t
			)
			face_uvrs[k] = uv
		
		if uv.x < uv_min.x : uv_min.x = uv.x
		if uv.y < uv_min.y : uv_min.y = uv.y
		if uv.x > uv_max.x : uv_max.x = uv.x
		if uv.y > uv_max.y : uv_max.y = uv.y
		centroid += vert
		
	var center := centroid
	centroid /= face_vertices.size()
	var region_or_alone
	if wim._entity_prefers_region_partition(load_index) : 
		region_or_alone = Vector3i((centroid / (
			region_size * unit_scale_f
		) + Vector3(0.5, 0.5, 0.5)).floor())
	else : region_or_alone = 0
	
	var lsize : Vector2
	var lid := -1
	
	if read_miptextures :
		var min : Vector2i = (uv_min / 16.0).floor()
		var max : Vector2i = (uv_max / 16.0).ceil()
		var extent := (max - min) * 16
		lsize = Vector2((extent.x >> 4) + 1, (extent.y >> 4) + 1)
		var lim := _gen_lightmap(lightmapdata, face[9], lsize)
		if lim :
			lid = ip.add(lsize, lim)
		else :
			lid = unlit
			
		for i in face_uvrs.size() :
			var uv := face_uvrs[i]
			uv.x = inverse_lerp(uv_min.x, uv_max.x, uv.x)
			uv.y = inverse_lerp(uv_min.y, uv_max.y, uv.y)
			face_uvrs[i] = uv
	
	if entity_geo_d.has(region_or_alone) :
		var arr : Array = entity_geo_d[region_or_alone]
		arr[0].append([
			face_vertices, face_normals, face_uvs,
			lsize, lid, face_uvrs
		])
		var texdict : Dictionary = arr[1]
		if texdict.has(texture) :
			texdict[texture].append(arr[0].size() - 1)
		else :
			texdict[texture] = PackedInt32Array([arr[0].size() - 1])
		arr[2] += center
		arr[4] += face_vertices.size()
	else :
		entity_geo_d[region_or_alone] = [
			[
				[
					face_vertices, face_normals, face_uvs,
					lsize, lid, face_uvrs
				]
			],
			{texture : PackedInt32Array([0])},
			center,
			extents,
			face_vertices.size()
		]
		
	loc_load_index += 1
	return false
			
var entity_geo_keys : Array
var pos_list : PackedVector2Array
var lightmap_image : Image
var lightmap_size : Vector2
var lmtex : ImageTexture
func _BuildingData() -> float :
	if load_index == 0 and loc_load_index == 0 :
		if read_miptextures :
			lightmap_image = ip.commit(Image.FORMAT_L8, pos_list)
			lightmap_size = lightmap_image.get_size()
			lmtex = ImageTexture.create_from_image(lightmap_image)
			#lightmap_image.save_png('a.png')
		entity_geo_keys = entity_geo.keys()
		if entity_geo_keys.is_empty() : return 1.0
	
	
	
	if wim._entity_prefers_bsp_geometry(load_index) :
		if _build_geo() :
			loc_load_index = 0
			load_index += 1
	else :
		load_index += 1
	
	if load_index == entity_geo_keys.size() :
		entity_geo_keys.clear()
		pos_list.clear()
		lightmap_image = null
		lmtex = null
		entity_geo.clear()
		lightmapdata.clear()
		ip = null
		return 1.0
	return float(load_index) / entity_geo_keys.size()
	
var regions : Dictionary
var region_keys : Array
var target_ent : int = -1
func _build_geo() -> bool :
	if loc_load_index == 0 :
		target_ent = model_map.get(load_index, -1)
		if target_ent == -1 :
			region_keys.clear()
			return true # orphan model ?
		regions = entity_geo[entity_geo_keys[load_index]]
		region_keys = regions.keys()
	elif loc_load_index == region_keys.size() :
		region_keys.clear()
		return true
		
	var rarray : Array = regions[region_keys[loc_load_index]]
	var surfaces : Array[Array] = rarray[0]
	var texdict : Dictionary = rarray[1]
	var center : Vector3 = rarray[2] / rarray[4]
	var extents : Vector3 = rarray[3]
	var mesh : ArrayMesh
	
	for s in texdict :
		var surface_tool := SurfaceTool.new()
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var indexes : PackedInt32Array = texdict[s]
		surface_tool.set_material(s)
		if s is ShaderMaterial :
			s.set_shader_parameter(&'lmp', lmtex)
		var tsize : Vector2 = (
			s.get_meta(&'size') if s else Vector2()
		)
		for t in indexes :
			var surface : Array = surfaces[t]
			var verts : PackedVector3Array = surface[0]
			var lid : int = surface[4]
			var uvs : PackedVector2Array = surface[2]
			var uvrs : PackedVector2Array = surface[5]
			var pos : Vector2
			var offset : Vector2
			if read_miptextures :
				pos = pos_list[lid]
				offset = (
					pos / lightmap_size
				)
			
			for i in verts.size() : verts[i] -= center
			
			if read_miptextures :
				if lid == unlit :
					var fsize := (Vector2(2, 2) / lightmap_size)
					for i in uvrs.size() :
						uvrs[i] = (uvrs[i] * fsize) + offset
				else :
					var lsize : Vector2 = surface[3]
					var fsize := (lsize / lightmap_size)
					
					for i in uvrs.size() :
						var uv := uvrs[i]
						# avoiding bleeding
						# (definitely not the right solution. but it works well)
						uv.x = inverse_lerp(-0.5, lsize.x + 0.5, uv.x * lsize.x)
						uv.y = inverse_lerp(-0.5, lsize.y + 0.5, uv.y * lsize.y)
						uvrs[i] = (uv * fsize) + offset
				
			surface_tool.add_triangle_fan(
				verts, uvs,
				[], uvrs, surface[1]
			)
		surface_tool.generate_tangents()
		mesh = surface_tool.commit(mesh)
	wim._entity_your_mesh(target_ent, loc_load_index, mesh, center)
	loc_load_index += 1
	return false

##############################################

var entries : Dictionary # <name : Vector2i (dentry)>

func _read_dentry() :
	for n in ENTRY_LIST :
		entries[n] = Vector2i(file.get_32(), file.get_32())
	
const VEC3_SIZE := 4 * 3 # sizeof(float) * 3
const ENTRY_LIST := [
	'entities', 'planes', 'miptex', 'vertices', 'visilist',
	'nodes', 'texinfo', 'faces', 'lightmaps', 'clipnodes',
	'leaves', 'lface', 'edges', 'ledges', 'models',
]

# it's literally the same as the method inside QmapbspPakFile
func _make_im_from_pal(
	s : Vector2i, d : PackedByteArray
) -> Image :
	if known_palette.size() < 256 :
		known_palette.resize(256) # dummy pal for avoiding errors
	var im := Image.create(s.x, s.y, false, Image.FORMAT_RGB8)
	for i in d.size() :
		var p := d[i]
		im.set_pixelv(Vector2i(
			i % s.x, i / s.x
		), known_palette[p])
	return im

func _gen_lightmap(
	lightmapdata : PackedByteArray, offset : int, size : Vector2i
) -> Image :
	if offset == 4294967295 : # -1 (will find out why it overflowed later)
		return null
	var c := lightmapdata.slice(offset, offset + size.x * size.y)
	return Image.create_from_data(
		size.x, size.y, false, Image.FORMAT_L8,
		c
	)
