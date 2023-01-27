extends RefCounted
class_name QmapbspBSPParser

# CURRENTLY SUPPORT QUAKE 1 MAP ONLY

var bsp_version : int
var unit_scale : float
var unit_scale_f : float
var known_palette : PackedColorArray
var region_size : float = 0.5
var bsp_shader : Shader

var ext : QmapbspImporterExtension

var file : FileAccess
var load_section : int
var load_index : int

func _read_dentry() :
	for n in ENTRY_LIST :
		entries[n] = Vector2i(file.get_32(), file.get_32())
		
static func _qnor_to_vec3(q : Vector3) -> Vector3 :
	return Vector3(-q.x, q.z, q.y)
	
static func _read_vec3(f : FileAccess) -> Vector3 :
	return Vector3(
		f.get_float(),
		f.get_float(),
		f.get_float()
	)
	
static func _qnor_to_vec3_read(f : FileAccess) -> Vector3 :
	return _qnor_to_vec3(_read_vec3(f))
	
func _qpos_to_vec3_read(f : FileAccess) -> Vector3 :
	return _qnor_to_vec3(_read_vec3(f)) * unit_scale
	
func _qpos_to_vec3(q : Vector3) -> Vector3 :
	return _qnor_to_vec3(q) * unit_scale
	
const VEC3_SIZE := 4 * 3 # sizeof(float) * 3
const ENTRY_LIST := [
	'entities', 'planes', 'miptex', 'vertices', 'visilist',
	'nodes', 'texinfo', 'faces', 'lightmaps', 'clipnodes',
	'leaves', 'lface', 'edges', 'ledges', 'models',
]
	
enum LoadSection {
	VERTICES, EDGES, LEDGES, PLANES, MIPTEXTURES,
	TEXINFOS, MODELS, FACES, CLIPNODES,
	
	ENTITIES, # TODO : separate these sections to the MAP parsing part (?)
		
	CONSTRUCT_CLIPS, CONSTRUCT_REGIONS, BUILD_REGIONS,
	
	END
}
var sections := {
	LoadSection.VERTICES : [_read_vertices, 'vertices'],
	LoadSection.EDGES : [_read_edges, 'edges'],
	LoadSection.LEDGES : [_read_ledges, 'ledges'],
	LoadSection.PLANES : [_read_planes, 'planes'],
	LoadSection.MIPTEXTURES : [_read_mip_textures, 'miptex'],
	LoadSection.TEXINFOS : [_read_texinfo, 'texinfo'],
	LoadSection.MODELS : [_read_models, 'models'],
	LoadSection.FACES : [_read_faces, 'faces'],
	LoadSection.CLIPNODES : [_read_clipnodes, 'clipnodes'],
	LoadSection.ENTITIES : [_read_entities, 'entities'],
	
	LoadSection.CONSTRUCT_CLIPS : [_construct_clips, ''],
	LoadSection.CONSTRUCT_REGIONS : [_construct_regions, ''],
	LoadSection.BUILD_REGIONS : [_build_regions, ''],
}

var entries : Dictionary # <name : Vector2i (dentry)>

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

var model_desc : Dictionary # <model_id : dict>

func begin_read_file(
	f : FileAccess, ext_ : QmapbspImporterExtension,
) -> StringName :
	file = f
	ext = ext_
	region_size = ext._get_region_size()
	known_palette = ext._get_palette()
	unit_scale_f = ext._get_unit_scale_f()
	unit_scale = 1.0 / unit_scale_f
	bsp_shader = ext._get_custom_bsp_textures_shader()
	
	bsp_version = file.get_32()
	match bsp_version :
		29 : # OK
			pass
		_ : return &'NOT_SUPPORTED'
	
	load_section = 0
	load_index = 0
	ext._start()
	
	_read_dentry()
	#_read_entities(entries, entities)
	
	_update_load_section()
	
	return StringName()
	
func load_file(path : String, ext_ := QmapbspImporterExtension.new(), return_code : Array = []) -> StringName :
	var f := FileAccess.open(path, FileAccess.READ)
	if FileAccess.get_open_error() != OK :
		return_code.append(FileAccess.get_open_error())
		return &'CANNOT_OPEN_FILE'
	
	var ret := begin_read_file(f, ext_)
	if ret != StringName() : return ret
	while true :
		var reti := poll()
		if reti == ERR_FILE_EOF : break
		
	return StringName()
	
func _update_load_section() :
	curr_section = sections[load_section]
	curr_section_call = curr_section[0]
	curr_entry = entries.get(curr_section[1], Vector2i())
	
var curr_section : Array
var curr_section_call : Callable
var curr_entry : Vector2i
var local_progress : float
func poll() -> int :
	local_progress = curr_section_call.call()
	if local_progress >= 1.0 :
		load_section += 1
		local_progress = 0.0
		#print(load_section)
		if load_section == LoadSection.END :
			return ERR_FILE_EOF
		_update_load_section()
		load_index = 0
	return OK
	
func get_progress() -> float :
	var stp := 1.0 / LoadSection.END
	var sec := float(load_section) / LoadSection.END
	var scp : float = local_progress * stp
	return scp + sec
	
func _read_vertices() -> float :
	if load_index == 0 :
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
		file.seek(curr_entry.x)
		edge_list.resize(curr_entry.y / 4)
	edge_list[load_index] = file.get_32()
	load_index += 1
	return float(load_index) / edge_list.size()
		
func _read_planes() -> float :
	if load_index == 0 :
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
		file.seek(curr_entry.x)
		var count := file.get_32()
		mipoffsets.resize(count)
		
		textures.resize(count)
		for i in count :
			mipoffsets[i] = file.get_32()
			
	#var skip_mips : bool = true
	var texture_offset := mipoffsets[load_index]
	var mat : Material
	if texture_offset < 0 :
		mat = ext.get_no_texture()
		mat.set_meta(&'size', Vector2i(64, 64))
	else :
		var toffset := curr_entry.x + texture_offset
		file.seek(toffset)
		var tname := file.get_buffer(16).get_string_from_ascii()
		var tsize := Vector2i(file.get_32(), file.get_32())
		mat = ext._get_texture(
			tname,
			tsize
		)
		if !mat :
			# use a texture inside the bsp file
			var doffset := file.get_32()
			file.seek(toffset + doffset)
			var data := file.get_buffer(tsize.x * tsize.y)
			var im := _make_im_from_pal(tsize, data)
			var itex := ImageTexture.create_from_image(im)
			mat = ext._get_material_for_bsp_textures(tname, itex)
			if !mat :
				mat = ShaderMaterial.new()
				mat.shader = bsp_shader
				mat.set_shader_parameter(&'tex', itex)
				mat.set_meta(&'apply_lightmaps', true)
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
	
func _read_clipnodes() -> float :
	if load_index == 0 :
		file.seek(curr_entry.x)
		clipnodes.resize(curr_entry.y / 8)
	clipnodes[load_index] = [
		file.get_32(), # plane
		file.get_16(), # front
		file.get_16(), # back
	]
	load_index += 1
	return float(load_index) / clipnodes.size()
	
var entities_kv : Array[Dictionary]
func _read_entities() -> float :
	if load_index == 0 :
		file.seek(curr_entry.x)
		var b := file.get_buffer(curr_entry.y).get_string_from_ascii()
		var kv := QmapbspMapFormat.from_text(b)
		b = ''
		entities_kv = kv.data
		
	var ret : Dictionary
	var rets : StringName = ext._tell_entity(entities_kv[load_index], ret)
	var model_id : int = ret.get('model_id', -1)
	if model_id >= 0 :
		if rets != StringName() :
			# delete
			ret['omit'] = true
		model_desc[model_id] = ret
		
		
	load_index += 1
	if load_index == entities_kv.size() :
		entities_kv.clear()
		return 1.0
	return float(load_index) / entities_kv.size()
		
const QUAKE_PLAYER_HULL := Vector3(32, 56, 32)
func _get_plane_tree(nodeindex : int, bucket : Array[Plane], add : bool) :
	var arr : Array = clipnodes[nodeindex]
	var plane : Plane = planes[arr[0]]
	var plane_t : int = planetypes[arr[0]]
	var front : int = arr[1]
	var back : int = arr[2]
	var p := plane
	
	# shrinks the boundary back.
	# because the clip nodes were expanded for handling
	# a single point collision of the player entity.
	# I LOVE HOW PERFORMANCE BOOST IT WAS. BUT right now ? NO, thank you.
	var X := QUAKE_PLAYER_HULL * 0.5 * unit_scale * (
		# a dumb way to get squared normal
		(p.normal * 2.0).clamp(-Vector3.ONE, Vector3.ONE)
	)
	p.d += sign(-p.d) * X.length()
	# these WON'T 100% match the original shapes for non-axial planes.
	
	var model_center := Vector3()
	var plane_point := p.normal * p.d
	var plane_dir := (plane_point - model_center).normalized()
	if plane_dir.dot(p.normal) > 0 :
		p.normal *= -1
		p.d *= -1
	
	if add :
		bucket.append(p)
	
	prints(nodeindex, p, arr[1], arr[2], '<>', plane_t)
	
	if front != 65535 and front != 65534 :
		_get_plane_tree(front, bucket, true)
	if back != 65535 and back != 65534 :
		_get_plane_tree(back, bucket, true)
	
const EPS := 0.000001
func planes_intersect(planes : Array[Plane]) -> PackedVector3Array :
	var vv := PackedVector3Array()
	
	for i in planes.size() - 2 :
		for j in range(i + 1, planes.size() - 1) :
			for k in range(j + 1, planes.size()) :
				var n0 := planes[i].normal
				var n1 := planes[j].normal
				var n2 := planes[k].normal
				var d0 := planes[i].d
				var d1 := planes[j].d
				var d2 := planes[k].d
				var t : float = (
					n0.x * (n1.y * n2.z - n1.z * n2.y) +
					n0.y * (n1.z * n2.x - n1.x * n2.z) +
					n0.z * (n1.x * n2.y - n1.y * n2.x)
				)
				if abs(t) < EPS : continue
				
				var v := Vector3(
					(d0 * (n1.z * n2.y - n1.y * n2.z) + d1 * (n0.y * n2.z - n0.z * n2.y) + d2 * (n0.z * n1.y - n0.y * n1.z)) / -t,
					(d0 * (n1.x * n2.z - n1.z * n2.x) + d1 * (n0.z * n2.x - n0.x * n2.z) + d2 * (n0.x * n1.z - n0.z * n1.x)) / -t,
					(d0 * (n1.y * n2.x - n1.x * n2.y) + d1 * (n0.x * n2.y - n0.y * n2.x) + d2 * (n0.y * n1.x - n0.x * n1.y)) / -t
				)
				var yes := true
				for l in planes.size() :
					var lp := planes[l]
					if l != i and l != j and l != k and v.dot(lp.normal) < lp.d + EPS :
						yes = false
						break
				if yes :
					v.y += 4 * unit_scale
					vv.append(v)
	return vv

func _construct_clips() :
	var model : Array = models[load_index]
	var node_left : int = model[4]
	var node_right : int = model[5]
	
	var arr : Array[Plane]
	_get_plane_tree(node_left, arr, true)
	var vv := planes_intersect(arr)
	print()
	#arr.clear()
	#_get_plane_tree(node_right, arr, true)
	
	var convex := ConvexPolygonShape3D.new()
	convex.points = vv

	var node := ext._get_collision_shape_node(load_index, 0)
	node.shape = convex

	load_index += 1
	if load_index == models.size() :
		return true
	return false

# key = Vector2i : Worldspawn meshes
# key = int : Other meshes
var worldspawn_regions : Dictionary
var lightmapdata : PackedByteArray
var ip : QuakeImagePacker
var unlit : int
func _construct_regions() -> float :
	
	if load_index == 0 :
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
	
	
	var is_worldspawn := load_index == 0
	#if is_worldspawn : continue
	
	var model : Array = models[load_index]
	
	var bound_min : Vector3 = model[0]
	var bound_max : Vector3 = model[1]
	
	var extents := (bound_max - bound_min) / 2
	
	extents = Vector3(abs(extents.x), abs(extents.y), abs(extents.z))
	
	var face_count : int = model[9]
	var face_index : int = model[8]
		
	var desc : Dictionary = model_desc.get(load_index, {})
	if !desc.get('omit', false) :
		for j in face_count :
			var face_array_index : int = face_index + j
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
			var region
			if is_worldspawn : 
				region = Vector3i((centroid / (
					region_size * unit_scale_f
				) + Vector3(0.5, 0.5, 0.5)).floor())
			else : region = load_index
			
			var min : Vector2i = (uv_min / 16.0).floor()
			var max : Vector2i = (uv_max / 16.0).ceil()
			var extent := (max - min) * 16
			var lsize := Vector2((extent.x >> 4) + 1, (extent.y >> 4) + 1)
			var lid := -1
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
			
			if worldspawn_regions.has(region) :
				var arr : Array = worldspawn_regions[region]
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
				worldspawn_regions[region] = [
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
			
	load_index += 1
			
	if load_index == models.size() :
		lightmapdata.clear()
		return 1.0
	return float(load_index) / models.size()
		
var region_keys : Array
var pos_list : PackedVector2Array
var lightmap_image : Image
var lightmap_size : Vector2
var lmtex : ImageTexture

func _build_regions() -> float :
	if load_index == 0 :
		lightmap_image = ip.commit(Image.FORMAT_L8, pos_list)
		lightmap_size = lightmap_image.get_size()
		lmtex = ImageTexture.create_from_image(lightmap_image)
		#lightmap_image.save_png('a.png')
		region_keys = worldspawn_regions.keys()
	
	if region_keys.is_empty() : return 1.0
	
	var mesh : ArrayMesh
	var r = region_keys[load_index]
	var rarray : Array = worldspawn_regions[r]
	var surfaces : Array[Array] = rarray[0]
	var texdict : Dictionary = rarray[1]
	var center : Vector3 = rarray[2] / rarray[4]
	var desc : Dictionary = model_desc.get(0 if r is Vector3i else load_index, {}) # for non-worldspawn entities
	var extents : Vector3 = rarray[3]
	
	if !desc.get('omit', false) :
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
				var pos : Vector2 = pos_list[lid]
				var offset := (
					pos / lightmap_size
				)
				
				for i in verts.size() : verts[i] -= center
				
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
		var meshin : MeshInstance3D
		if r is Vector3i :
			meshin = ext._get_worldspawn_mesh_instance(r)
			meshin.set_instance_shader_parameter(&'region', r)
			meshin.position = center
		else :
			meshin = ext._get_mesh_instance_per_model(r)
#			var parent := meshin.get_parent()
#			if parent == ext.root :
#				pass
#			if parent is Node3D :
#				parent.position = center
#				if desc.get('add_col', false) :
#					var box := BoxShape3D.new()
#					box.extents = extents
#					var col := CollisionShape3D.new()
#					col.shape = box
#					col.name = &'col000'
#					parent.add_child(col, true)
#					print(parent)
		meshin.mesh = mesh
		ext._on_brush_mesh_updated(r, meshin)
	
	load_index += 1
	
	if load_index == region_keys.size() :
		region_keys.clear()
		pos_list.clear()
		lightmap_image = null
		lmtex = null
		worldspawn_regions.clear()
		lightmapdata.clear()
		ip = null
		return 1.0
	return float(load_index) / region_keys.size()

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
