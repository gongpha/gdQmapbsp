extends QmapbspBaseParser
class_name QmapbspBSPParser

# CURRENTLY SUPPORT QUAKE 1 MAP ONLY

var curr_entry : Vector2i
var bsp_version : int

# in
var scale : float = 1 / 32.0
var read_miptextures : bool = false # includes textures
var read_lightmaps : bool = true
var known_palette : PackedColorArray
var bsp_shader : Shader
var known_map_textures : PackedStringArray
# turn these on if no .map file is specified to get collision shapes
var import_clipnodes : bool = true
var import_bspnodes : bool = true
var import_visdata : bool = false

var model_map : Dictionary # <model_id : ent_id>
	
var is_bsp2 := false

func _init() :
	super()
	tell_entity_props.connect(_tell_entity_props)

func begin_file(f : FileAccess) -> StringName :
	super(f)
	
	bsp_version = file.get_32()
	match bsp_version :
		29 : # OK
			pass
		844124994 : # BSP2
			is_bsp2 = true
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

	return super()
	
func _brush_found() -> void :
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
var texture_ids : PackedByteArray # for built-in bsp material
var texinfos : Array[Array]
var models : Array[Array]
var faces : Array[Array]
var face_list : PackedInt32Array
var bspnodes : Array[Array]
var clipnodes : Array[Array]
var entities : Array[Array]
var visilist : PackedByteArray
var leaves : Array[Array]

var level_aabb : AABB

# Built-in BSP material
var global_surface_mat : ShaderMaterial
var global_textures : Array[Texture2D]
var global_textures_fullbright : Array[Texture2D]
var grouped_textures : Array
var grouped_textures_idx : Dictionary # <group_name : String, indexes : PackedIntArray32>
const GLOBAL_TEXTURE_LIMIT := 96 # device dependent

var import_tasks := [
	[_read_vertices, 128],
	[_read_edges, 128],
	[_read_ledges, 256],
	[_read_planes, 128],
	[_read_mip_textures, 16],
	[_read_texinfo, 128],
	[_read_models, 64],
	[_read_faces, 64],
	[_read_bspnodes, 64],
	[_read_clipnodes, 128],
	[_read_lface, 256],
	[_read_visilist, 256],
	[_read_leaves, 64],
	
	[_construct_bspnodes, 16],
	[_construct_clipnodes, 16]
]
var import_curr_index : int = 0
var import_curr_func : Callable = import_tasks[0][0]
var import_curr_ite : int = import_tasks[0][1]
var import_local_progress : float = 0.0

func _ImportingData() -> float :
	for I in import_curr_ite :
		import_local_progress = import_curr_func.call()
		if import_local_progress >= 1.0 :
			import_curr_index += 1
			import_local_progress = 0.0
			if import_curr_index == import_tasks.size() :
				return 1.0
			import_curr_func = import_tasks[import_curr_index][0]
			import_curr_ite = import_tasks[import_curr_index][1]
			load_index = 0
	return import_get_progress()
	
func _BuildingDataCustom() -> float :
	wim._custom_work_bsp(self)
	return 1.0

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
	var v := _qpos_to_vec3(
		Vector3(
			file.get_float(),
			file.get_float(),
			file.get_float()
		)
	)
	vertices[load_index] = v
	level_aabb = level_aabb.expand(v)
	load_index += 1
	return float(load_index) / vertices.size()
			
var smooth_angle : float
var smooth_group_faces : PackedInt32Array # <numfaces> smooth group id
var smooth_group_fofv : Array[PackedInt32Array] # <numvertices> face ids...
var smooth_group_n : int = 0
func _read_edges() -> float :
	if load_index == 0 :
		curr_entry = entries['edges']
		file.seek(curr_entry.x)
		edges.resize(curr_entry.y / (8 if is_bsp2 else 4))
		smooth_angle = deg_to_rad(wim._entity_auto_smooth_degree())
		if smooth_angle >= 0 :
			smooth_group_fofv.resize(vertices.size())
	edges[load_index] = Vector2i(
		# BSP2
		file.get_32(), # start vertex
		file.get_32() # end vertex
	) if is_bsp2 else Vector2i(
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
		texture_ids.resize(count)
		
		mipoffsets.resize(count)
		for i in count :
			mipoffsets[i] = file.get_32()
			
	#var skip_mips : bool = true
	var texture_offset := mipoffsets[load_index]
	var mat : Material
	
	var ret
	var tsize : Vector2i
	var tname : String
	if texture_offset >= 0 :
		var toffset := curr_entry.x + texture_offset
		file.seek(toffset)
		tname = file.get_buffer(16).get_string_from_ascii()
		tsize = Vector2i(file.get_32(), file.get_32())
		ret = wim._texture_get(
			tname,
			tsize
		)
	elif known_map_textures.size() > load_index :
		ret = wim._texture_get(
			known_map_textures[load_index],
			Vector2i(-1, -1)
		)
	else :
		mat = wim.get_missing_texture()
		mat.set_meta(&'size', Vector2i(64, 64))
		
	var tex : Texture2D
	var tex2 : Texture2D
	if ret is Texture2D :
		tsize = ret.get_size()
		tex = ret
	elif ret is Material :
		if ret is BaseMaterial3D :
			var t : Texture2D = ret.albedo_texture
			if t :
				tsize = t.get_size()
		mat = ret
		
	if !mat and read_miptextures :
		# use a texture inside the bsp file
		if !tex and texture_offset >= 0 :
			var toffset := curr_entry.x + texture_offset
			var doffset := file.get_32()
			file.seek(toffset + doffset)
			var data := file.get_buffer(tsize.x * tsize.y)
			var im := _make_im_from_pal(tsize, data)
			tex = ImageTexture.create_from_image(im[0])
			tex2 = ImageTexture.create_from_image(im[1])
		mat = wim._texture_get_material_for_integrated(tname, tex)
		
		if !mat :
			if global_textures.size() > GLOBAL_TEXTURE_LIMIT :
				# oof
				printerr("You hit the texture limit ! (> %d)" % GLOBAL_TEXTURE_LIMIT)
			else :
				texture_ids[load_index] = global_textures.size()
				global_textures.append(tex)
				global_textures_fullbright.append(tex2)
				
				var group : Array = wim._texture_get_animated_textures_group(tname)
				if !group.is_empty() :
					var group_name : String = group[0]
					var frame_index : int = group[1]
					if !group_name.is_empty() :
						var pia32 := PackedInt32Array()
						if grouped_textures_idx.has(group_name) :
							pia32 = grouped_textures_idx[group_name]
						else :
							pia32.fill(-1)
							grouped_textures_idx[group_name] = pia32
							
						if frame_index >= pia32.size() :
							pia32.resize(frame_index + 1)
						pia32[frame_index] = global_textures.size() - 1
			
			if !global_surface_mat :
				global_surface_mat = wim._texture_get_global_surface_material()
				global_surface_mat.shader = bsp_shader
				# set a texture later
				global_surface_mat.set_meta(&'apply_lightmaps', true)
			mat = global_surface_mat
	if !mat :
		mat = wim.get_missing_texture()
	mat.set_meta(&'size', tsize)
	textures[load_index] = mat
		
		#for j in (4 if skip_mips else 3) : file.get_32()
	load_index += 1
	if load_index == mipoffsets.size() :
		mipoffsets.clear()
		if !global_surface_mat :
			read_lightmaps = false
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
	
const B15 = 1 << 15
const B16 = 1 << 16
const B31 = 1 << 31
const B32 = 1 << 32

func u32toi32(u : int) -> int :
	return (u + B31) % B32 - B31
func u16toi16(u : int) -> int :
	return (u + B15) % B16 - B15

func _read_faces() -> float :
	if load_index == 0 :
		curr_entry = entries['faces']
		file.seek(curr_entry.x)
		faces.resize(curr_entry.y / (28 if is_bsp2 else 20))
		if smooth_angle >= 0 :
			smooth_group_faces.resize(faces.size())
			smooth_group_faces.fill(-1)
			
	faces[load_index] = [
		(file.get_32() if is_bsp2 else file.get_16()), # plane id
		(file.get_32() if is_bsp2 else file.get_16()), # side (unused ?)
		file.get_32(), # first edge on the list
		(file.get_32() if is_bsp2 else file.get_16()), # edge count
		(file.get_32() if is_bsp2 else file.get_16()), # tinfo id
		file.get_8(), file.get_8(), # LM1, LM2
		file.get_8(), file.get_8(), # LM3, LM4
		u32toi32(file.get_32()), # lightmap
	]
	load_index += 1
	return float(load_index) / faces.size()
	
func _read_bspnodes() -> float :
	if load_index == 0 :
		if !import_bspnodes : return 1.0
		curr_entry = entries['nodes']
		file.seek(curr_entry.x)
		bspnodes.resize(curr_entry.y / (44 if is_bsp2 else 24))
		if bspnodes.is_empty() : return 1.0
	bspnodes[load_index] = [
		file.get_32(), # plane
		file.get_32() if is_bsp2 else _get16as32(file), # front
		file.get_32() if is_bsp2 else _get16as32(file), # back
		_read_bbfloat(file) if is_bsp2 else _read_bbshort(file), # boundbox short
		file.get_32() if is_bsp2 else file.get_16(),
		file.get_32() if is_bsp2 else file.get_16() # face id, num
	]
	#print(bspnodes[load_index][3])
	load_index += 1
	return float(load_index) / bspnodes.size()
	
func _read_clipnodes() -> float :
	if load_index == 0 :
		if !import_clipnodes : return 1.0
		curr_entry = entries['clipnodes']
		file.seek(curr_entry.x)
		clipnodes.resize(curr_entry.y / (12 if is_bsp2 else 8))
		if clipnodes.is_empty() : return 1.0
	clipnodes[load_index] = [
		file.get_32(), # plane
		file.get_32() if is_bsp2 else _get16as32(file), # front
		file.get_32() if is_bsp2 else _get16as32(file), # back
	]
	load_index += 1
	return float(load_index) / clipnodes.size()
	
func _read_lface() -> float :
	if load_index == 0 :
		curr_entry = entries['lface']
		file.seek(curr_entry.x)
		face_list.resize(curr_entry.y / 2)
	face_list[load_index] = file.get_16()
	load_index += 1
	return float(load_index) / face_list.size()
	
func _read_visilist() -> float :
	if !import_visdata : return 1.0
	curr_entry = entries['visilist']
	file.seek(curr_entry.x)
	visilist = file.get_buffer(curr_entry.y)
	return 1.0
	
func _read_leaves() -> float :
	if load_index == 0 :
		if !(import_bspnodes or import_visdata) : return 1.0
		curr_entry = entries['leaves']
		file.seek(curr_entry.x)
		leaves.resize(curr_entry.y / 28)
		
	var arr : Array = leaves[load_index]
	arr.append_array([
		u32toi32(file.get_32()), # type 0
		u32toi32(file.get_32()), # vislist 1
		_qpos_to_vec3_read_16(file), _qpos_to_vec3_read_16(file), # bound 2 3
		file.get_16(), # f_id 4
		file.get_16(), # f_num 5
		
		# ambient sounds 6
		Vector4(
			file.get_8() / 255.0, # water
			file.get_8() / 255.0, # sky
			file.get_8() / 255.0, # slime
			file.get_8() / 255.0  # lava
		)
	])
	
	load_index += 1
	return float(load_index) / leaves.size()
	
func _dump_bspnodes_tree(node : int, is_bsp : bool, deep : int = 0) -> void :
	var nodearr : Array = (bspnodes if is_bsp else clipnodes)[node]
	
	var plane : Plane = planes[nodearr[0]]
	print("-".repeat(deep), plane)
	for i in [0, 1] :
		var child : int = nodearr[1 + i]
		if child >= 0 :
			print("-".repeat(deep), i)
			_dump_bspnodes_tree(child, is_bsp, deep + 1)
		else :
			print("-".repeat(deep), i, " ", leaves[~child][0] if is_bsp else child)
	
var expanded_aabb : AABB
func _construct_bspnodes() -> float :
	return _construct_nodes(true)
	
func _construct_clipnodes() -> float :
	return _construct_nodes(false)
	
func _construct_nodes(is_bsp : bool) -> float :
	# load_index is MODEL ID. NOT ENTITY ID !!!
	if load_index == 0 :
		if !(import_bspnodes if is_bsp else import_clipnodes) : return 1.0
		expanded_aabb = level_aabb.grow(4.0)
	var convexplanes : Array[Array]
	var tempplanes : Array[Plane]
	
	#_dump_bspnodes_tree(models[load_index][3 if is_bsp else 4], is_bsp)
	
	_node_cut(models[load_index][3 if is_bsp else 4],
		tempplanes, convexplanes,
		is_bsp
	)
		
	for o in convexplanes :
		var cvx := ConvexPolygonShape3D.new()
		cvx.points = o[1]
		
		# use node id instead of brush id
		var metadata : Dictionary = { 'from' : &'BSP' if is_bsp else &'CLIP' }
		metadata.merge(o[2])
		
		wim._entity_your_shape(model_map[load_index], o[0], cvx, Vector3(), metadata)
	
	load_index += 1
	return float(load_index) / models.size()
	
# outplanes : [node_id : int, planes : Array[Plane]]...
func _node_cut(
	node : int,
	tempplanes : Array[Plane],
	convexplanes : Array[Array],
	is_bsp : bool
) -> void :
	var arr : Array[Array] = (bspnodes if is_bsp else clipnodes)
	var nodearr : Array = arr[node] if arr.size() > node else []
	if nodearr.is_empty() : return
	
	for i in 2 :
		var plane : Plane = planes[nodearr[0]]
		if i == 0 :
			# front
			plane.normal *= -1
			plane.d *= -1
			
		tempplanes.append(plane)
		
		var child : int = nodearr[1 + i]
		if child >= 0 :
			# child node
			_node_cut(
				child, tempplanes,
				convexplanes, is_bsp
			)
		else :
			var create_volume : bool = false
			var leaf_type : int
			var ambsnds : Vector4
			if is_bsp :
				var leaf : Array = leaves[~child]
				leaf_type = leaf[0]
				ambsnds = leaf[6]
				if leaf_type != CONTENTS_EMPTY :
					create_volume = true
				if !ambsnds.is_zero_approx() :
					# this volume plays sound
					create_volume = true
			else :
				if child == -2 :
					create_volume = true
			
			if create_volume :
				# solid/liquid area
				var j := tempplanes.size() - 1
				var clipper := QmapbspClipper.new()
				clipper.begin(expanded_aabb)
				for k in j + 1 :
					var p := tempplanes[k]
					clipper.clip_plane(p)
				clipper.filter_and_clean()
				
				if clipper.vertices.size() >= 3 :
					convexplanes.append(
						[node, clipper.vertices, {
							'leaf_type' : leaf_type,
							'ambsnds' : ambsnds,
						} if is_bsp else {}]
					)
			
		tempplanes.pop_back()
		
var entity_geo : Dictionary # <model_id : <region or 0 : [...]> >
var lightmapdata : PackedByteArray
var ip : QmapbspImagePacker
var unlit : int
func _ConstructingData() -> float : # per model
	if load_index == 0 and loc_load_index == 0 :
		if read_lightmaps :
			var lightmaps_e : Vector2i = entries.lightmaps
			file.seek(lightmaps_e.x)
			lightmapdata = file.get_buffer(lightmaps_e.y)
			ip = QmapbspImagePacker.new()
			
			# for unlit surfaces
			unlit = ip.add(Vector2i(2, 2),
				Image.create_from_data(2, 2, false, Image.FORMAT_L8, [
					255, 255, 255, 255
				]
			))
	
	for I in 32 :
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
	
func get_real_normal(face : Array) -> Vector3 :
	return planes[face[0]].normal * (
		# flip if it's backface (behind the plane)
		-1 if face[1] == 1 else 1
	)
	
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
		extents = Vector3(absf(extents.x), absf(extents.y), absf(extents.z))
		
		face_count = model[9]
		face_indexf = model[8]
		unit_scale_f = 1.0 / unit_scale
		region_size = wim._entity_region_size(
			model_map[load_index]
		)
	if loc_load_index == face_count :
		loc_load_index = 0
		return true
		
	var face_array_index : int = face_indexf + loc_load_index
	var face : Array = faces[face_array_index]
	
	var face_vertices : PackedVector3Array
	var face_vertex_face_ids : PackedInt32Array
	var face_normals : PackedVector3Array
	var face_uvs : PackedVector2Array
	var face_uvrs : PackedVector2Array
	#var face_colors : PackedColorArray

	var edge_start : int = face[2]
	var edge_count : int = face[3]

	face_vertices.resize(edge_count)
	face_vertex_face_ids.resize(edge_count)
	face_normals.resize(edge_count)
	face_uvs.resize(edge_count)
	#face_colors.resize(edge_count)
	if read_lightmaps :
		face_uvrs.resize(edge_count)
	
	var centroid : Vector3
	
	var texture_info : Array = texinfos[face[4]] # tinfo id
	var texture : Material = textures[texture_info[4]] # from texture index

	var tsize : Vector2i
	if texture == global_surface_mat and texture != null :
		var tex := global_textures[texture_ids[texture_info[4]]]
		if tex :
			tsize = tex.get_size()
	else :
		tsize = texture.get_meta(&'size') if texture else Vector2i()
	
	tsize.x = 16 if tsize.x == 0 else tsize.x
	tsize.y = 16 if tsize.y == 0 else tsize.y
	
	var tscale := Vector2(
		1.0 / (tsize.x * unit_scale),
		1.0 / (tsize.y * unit_scale)
	)

	var plane_normal : Vector3 = get_real_normal(face)
	
	var uv_min := Vector2(INF, INF)
	var uv_max := Vector2(-INF, -INF)
	
	var smooth_group : int = -1
	
	for k in edge_count :
		var edge_index : int = edge_list[edge_start + k]
		var v0 : int
		if edge_index < 0 :
			edge_index = -edge_index
			v0 = edges[edge_index][1]
		else :
			v0 = edges[edge_index][0]
		var vert : Vector3 = vertices[v0]
		
		if !smooth_group_fofv.is_empty() :
			var exist_faces := smooth_group_fofv[v0]
			if !exist_faces.is_empty() :
				for f in exist_faces :
					var n2 := get_real_normal(faces[f])
					var angle := plane_normal.angle_to(n2)
					if angle <= smooth_angle and angle != 0.0 :
						# merge all the faces that are inside it too
						var newgroup := smooth_group_faces[f]
						if smooth_group != -1 :
							for i in smooth_group_faces.size() :
								if smooth_group_faces[i] == smooth_group :
									smooth_group_faces[i] = newgroup
						smooth_group = newgroup
						
			if smooth_group == -1 :
				smooth_group = smooth_group_n
				smooth_group_n += 1
			face_vertex_face_ids[k] = face_array_index
		
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
		
		if read_lightmaps :
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
	var region_or_alone = wim._model_get_region(
		load_index, face_array_index, texture
	)
	
	if smooth_group != -1 :
		for k in edge_count :
			var edge_index : int = edge_list[edge_start + k]
			var v0 : int
			if edge_index < 0 :
				edge_index = -edge_index
				v0 = edges[edge_index][1]
			else :
				v0 = edges[edge_index][0]
				
			smooth_group_fofv[v0].append(face_array_index)
		smooth_group_faces[face_array_index] = smooth_group
	
	if region_or_alone == null : 
		if wim._entity_prefers_region_partition(load_index) :
			region_or_alone = Vector3i((centroid / (
				region_size
			) + Vector3(0.5, 0.5, 0.5)).floor())
		else :
			region_or_alone = 0
	
	var lsize : Vector2
	var lstyle : int = 1
	var lid := -1
	
	if read_lightmaps :
		var min : Vector2i = (uv_min / 16.0).floor()
		var max : Vector2i = (uv_max / 16.0).ceil()
		var extent := (max - min) * 16
		lsize = Vector2((extent.x >> 4) + 1, (extent.y >> 4) + 1)
		var retlst : PackedByteArray
		var lim := _gen_lightmap(lightmapdata, face[9], lsize, [
			face[5], face[6], face[7], face[8]
		], retlst)
		lstyle = retlst[0]
		if lim :
			lid = ip.add(lim.get_size(), lim)
		else :
			lid = unlit
			
		for i in face_uvrs.size() :
			var uv := face_uvrs[i]
			uv.x = inverse_lerp(uv_min.x, uv_max.x, uv.x)
			uv.y = inverse_lerp(uv_min.y, uv_max.y, uv.y)
			face_uvrs[i] = uv
	
	var texturekey = (
		texture_ids[texture_info[4]]
		if texture == global_surface_mat
		else texture
	)
	
	if entity_geo_d.has(region_or_alone) :
		var arr : Array = entity_geo_d[region_or_alone]
		arr[0].append([
			face_vertices, face_vertex_face_ids, face_normals, face_uvs,
			lsize, lid, face_uvrs, Color(
				face[5], face[6], face[7], face[8]
			), lstyle
		])
		var texdict : Dictionary = arr[1]
		if texdict.has(texturekey) :
			texdict[texturekey].append(arr[0].size() - 1)
		else :
			texdict[texturekey] = PackedInt32Array([arr[0].size() - 1])
		arr[2] += center
		arr[4] += face_vertices.size()
	else :
		entity_geo_d[region_or_alone] = [
			[
				[
					face_vertices, face_vertex_face_ids, face_normals, face_uvs,
					lsize, lid, face_uvrs, Color(
						face[5], face[6], face[7], face[8]
					), lstyle
				]
			],
			{texturekey : PackedInt32Array([0])},
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
var palette_tex : ImageTexture
func _BuildingData() -> float :
	if load_index == 0 and loc_load_index == 0 :
		if read_lightmaps :
			lightmap_image = ip.commit(Image.FORMAT_L8, pos_list)
			lightmap_size = lightmap_image.get_size()
			lmtex = ImageTexture.create_from_image(lightmap_image)
			
			var paldata : PackedByteArray
			paldata.resize(3 * known_palette.size())
			for i in known_palette.size() :
				var col := known_palette[i]
				paldata[i * 3 + 0] = col.r * 255.0
				paldata[i * 3 + 1] = col.g * 255.0
				paldata[i * 3 + 2] = col.b * 255.0
			palette_tex = lmtex.create_from_image(Image.create_from_data(
				known_palette.size(), 1, false, Image.FORMAT_RGB8, paldata
			))
			
		entity_geo_keys = entity_geo.keys()
		if entity_geo_keys.is_empty() : return 1.0
	
	for I in 16 :
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
			smooth_group_faces.clear()
			ip = null
			return 1.0
	return float(load_index) / entity_geo_keys.size()
	
const EPS := 0.0001
const UUU := 0.0 # unused
var regions : Dictionary
var region_keys : Array
var target_ent : int = -1

var occ : ArrayOccluder3D
var occ_shrinking : float
var occ_verts : PackedVector3Array
var occ_nor_seq : Array[PackedVector3Array]
var occ_indices : PackedInt32Array

func _build_geo() -> bool :
	if loc_load_index == 0 :
		# CALL ONCE
		target_ent = model_map.get(load_index, -1)
		if target_ent == -1 :
			region_keys.clear()
			return true # orphan model ?
		regions = entity_geo[entity_geo_keys[load_index]]
		region_keys = regions.keys()
		
		occ = null
		occ_shrinking = wim._entity_occluder_shrink_amount(target_ent)
		occ_verts = PackedVector3Array()
		occ_nor_seq = []
		occ_indices = PackedInt32Array()
		
		if global_surface_mat :
			global_textures.resize(GLOBAL_TEXTURE_LIMIT)
			global_textures_fullbright.resize(GLOBAL_TEXTURE_LIMIT)
			global_surface_mat.set_shader_parameter(&'texs', global_textures)
			global_surface_mat.set_shader_parameter(&'texfs', global_textures)
			global_surface_mat.set_shader_parameter(&'lmp', lmtex)
			
			var texseqs : Array
			var texfseqs : Array
			texseqs.resize(global_textures.size())
			texfseqs.resize(global_textures.size())
			for i in global_textures.size() :
				texseqs[i] = global_textures[i]
				texfseqs[i] = global_textures_fullbright[i]
			# 1 3 5
			# 2 4 6
			var grouped_textures_tex : Dictionary # <group : array of texture2d>
			for k in grouped_textures_idx :
				var arr : Array[Texture2D]
				var arr2 : Array[Texture2D]
				var pia32 : PackedInt32Array = grouped_textures_idx[k]
				for l in pia32 :
					arr.append(global_textures[l])
					arr2.append(global_textures_fullbright[l])
					texseqs[l] = arr
					texfseqs[l] = arr2
				pass
			wim._texture_your_bsp_textures(texseqs, texfseqs)
			
		if wim._entity_prefers_occluder(target_ent) :
			occ = ArrayOccluder3D.new()
			
		smooth_group_fofv.clear()
		
	if loc_load_index == region_keys.size() :
		if occ :
			if occ_shrinking != 0.0 :
				for i in occ_verts.size() :
					var N : Vector3
					for j in occ_nor_seq[i] :
						N += j
					occ_verts[i] -= N.normalized() * occ_shrinking
			occ.set_arrays(occ_verts, occ_indices)
			wim._entity_your_occluder(target_ent, occ)
		region_keys.clear()
		return true
		
	var r = region_keys[loc_load_index]
	var rarray : Array = regions[r]
	var surfaces : Array = rarray[0]
	var texdict : Dictionary = rarray[1]
	var center : Vector3 = rarray[2] / rarray[4]
	var extents : Vector3 = rarray[3]
	var mesh : ArrayMesh
	
	var global_surface_tool : SurfaceTool
	var surface_tool : SurfaceTool
	
	var mat : Material
	
	for s in texdict :
		var is_global := s is int
		if !surface_tool or !is_global :
			if is_global :
				if !global_surface_tool :
					global_surface_tool = SurfaceTool.new()
					global_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
					global_surface_tool.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_HALF)
					global_surface_tool.set_custom_format(1, SurfaceTool.CUSTOM_RGBA_HALF)
					global_surface_tool.set_material(global_surface_mat)
					mat = global_surface_mat
				surface_tool = global_surface_tool
			else :
				surface_tool = SurfaceTool.new()
				surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
				surface_tool.set_material(s)
				mat = s
		
		surface_tool.set_smooth_group(-1)
		var C_UV := surface_tool.set_uv
		var C_UV2 := surface_tool.set_uv2
		var C_NM := surface_tool.set_normal
		var C_CT := surface_tool.set_custom
		var C_VT := surface_tool.add_vertex
		var C_SG : Callable = surface_tool.set_smooth_group if smooth_group_faces.size() > 0 else Callable()
		
		var indexes : PackedInt32Array = texdict[s]
		var refv := [
			-1 # last smooth group
		]
		
		for t in indexes :
			var surface : Array = surfaces[t]
			var verts : PackedVector3Array = surface[0]
			var faceids : PackedInt32Array = surface[1]
			var lid : int = surface[5]
			var uvs : PackedVector2Array = surface[3]
			var lsize : Vector2 = surface[4]
			var nors : PackedVector3Array = surface[2]
			var uvrs : PackedVector2Array = surface[6]
			var lights : Color = surface[7]
			var lstyle : int = surface[8]
			
			
			
			var ADD := func(i : int, ref : Array) :
				C_UV.call(uvs[i])
				if !uvrs.is_empty() :
					C_UV2.call(uvrs[i])
				if is_global :
					C_CT.call(0, Color(s, lstyle, lsize.x / lightmap_size.x, UUU))
					C_CT.call(1, lights)
				var V := verts[i]
				var nor := nors[i]
				
				if C_SG.is_valid() :
					var sg := smooth_group_faces[faceids[i]]
					if sg != ref[0] :
						C_SG.call(sg)
						ref[0] = sg
				else :
					C_NM.call(nor)
				
				C_VT.call(V - center)
				
				var include_in_occ := true
				if (
					mat is StandardMaterial3D and
					mat.get_transparency() != BaseMaterial3D.TRANSPARENCY_DISABLED
				) :
					include_in_occ = false
				
				if occ and include_in_occ :
					var idx := occ_verts.find(V)
					var shrinking = occ_shrinking != 0.0
					if idx == -1 :
						occ_indices.append(occ_verts.size())
						occ_verts.append(V)
						if shrinking :
							occ_nor_seq.append(PackedVector3Array([nor]))
					else :
						occ_indices.append(idx)
						if shrinking :
							var L := occ_nor_seq[idx]
							if !L.has(nor) :
								L.append(nor)
						
			var pos : Vector2
			var offset : Vector2
			if read_lightmaps :
				pos = pos_list[lid]
				offset = (
					pos / lightmap_size
				)
			
			if read_lightmaps :
				if lid == unlit :
					var fsize := (Vector2(2, 2) / lightmap_size)
					for i in uvrs.size() :
						uvrs[i] = (uvrs[i] * fsize) + offset
				else :
					var fsize := (lsize / lightmap_size)
					
					for i in uvrs.size() :
						var uv := uvrs[i]
						# avoiding bleeding
						# (definitely not the right solution. but it works well)
						uv.x = inverse_lerp(-0.6, lsize.x + 0.6, uv.x * lsize.x)
						uv.y = inverse_lerp(-0.6, lsize.y + 0.6, uv.y * lsize.y)
						uvrs[i] = (uv * fsize) + offset
				
			for i in verts.size() - 2 :
				ADD.call(0, refv)
				ADD.call(i + 1, refv)
				ADD.call(i + 2, refv)
		
		if !is_global :
			if smooth_group_faces.size() > 0 :
				surface_tool.generate_normals()
			surface_tool.generate_tangents()
			mesh = surface_tool.commit(mesh)
			surface_tool = null
	if global_surface_tool :
		if smooth_group_faces.size() > 0 :
			global_surface_tool.generate_normals()
		global_surface_tool.generate_tangents()
		mesh = global_surface_tool.commit(mesh)
	wim._entity_your_mesh(target_ent, loc_load_index, mesh, center, r)
	loc_load_index += 1
	return false
	
func _end_entity(idx : int) :
	tell_entity_props.emit(idx, entity_dict)

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

const CONTENTS_EMPTY  := -1
const CONTENTS_SOLID  := -2
const CONTENTS_WATER  := -3
const CONTENTS_SLIME  := -4
const CONTENTS_LAVA   := -5
const CONTENTS_SKY    := -6
const CONTENTS_ORIGIN := -7
const CONTENTS_CLIP   := -8

func _make_im(
	s : Vector2i, d : PackedByteArray
) -> Image :
	var im := Image.create_from_data(
		s.x, s.y, false, Image.FORMAT_R8, d
	)
	return im

func _make_im_from_pal(
	s : Vector2i, d : PackedByteArray
) -> Array :
	if known_palette.size() < 256 :
		known_palette.resize(256) # dummy pal for avoiding errors
	var im := Image.create(s.x, s.y, false, Image.FORMAT_RGB8)
	var im2 := Image.create(s.x, s.y, false, Image.FORMAT_L8)
	for i in d.size() :
		var p := d[i]
		var v := Vector2i(
			i % s.x, i / s.x
		)
		var c := known_palette[p]
		var c2 := 1.0 if p >= 240 else 0.0
		im.set_pixelv(v, c)
		im2.set_pixelv(v, Color(c2, c2, c2))
	return [im, im2]

const MAX_LIGHTMAPS := 4
func _gen_lightmap(
	lightmapdata : PackedByteArray, offset : int, size : Vector2i,
	lightstyles : PackedByteArray, ret_lstyle : PackedByteArray
) -> Image :
	if offset == -1 :
		ret_lstyle.append(0)
		return null
	var lightmaps : int = 0
	var ist : int = 0 # bitmask
	for i in MAX_LIGHTMAPS :
		if lightstyles[i] == 255 : continue
		lightmaps += 1
		ist |= 1 << i
		
	var im := Image.create(size.x * lightmaps, size.y, false, Image.FORMAT_L8)
	var xpos : int = 0
	for l in MAX_LIGHTMAPS :
		if lightstyles[l] == 255 : continue
		var new := offset + size.x * size.y
		
		var c := lightmapdata.slice(offset, new)
		var sim := Image.create_from_data(
			size.x, size.y, false, Image.FORMAT_L8,
			c
		)
		im.blit_rect(sim, Rect2i(0.0, 0.0, size.x, size.y), Vector2(xpos * size.x, 0.0))
		offset = new
		xpos += 1
	ret_lstyle.append(ist)
	return im
