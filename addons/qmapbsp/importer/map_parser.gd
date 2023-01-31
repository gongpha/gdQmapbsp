extends QmapbspBaseParser
class_name QmapbspMAPParser

#var enable_collision_shapes : bool = false
signal tell_collision_shapes(
	entity_curr_idx : int, entity_curr_brush_idx : int, shape : Shape3D, origin : Vector3
)

func begin_file(f : FileAccess) -> StringName :
	super(f)
	mapf = QmapbspMapFormat.begin_from_text(f.get_as_text(true))
	return StringName()

func _GatheringAllEntities() -> float :
	var err : int = mapf.poll(__ret)
	_mapf_after_poll(err)
	
	var prog := _mapf_prog()
	if prog >= 1.0 :
		entities_kv.clear()
		#mapf = null
		kv = {}
		return 1.0
	return prog

func _brush_found() :
	#if enable_collision_shapes :
	var vertices := planes_intersect(mapf.brush_planes)
	var V := Vector3()
	for i in vertices.size() :
		var v := vertices[i]
		v = _qpos_to_vec3(v * -1)
		vertices[i] = v
		V += v
	V /= vertices.size()
	for i in vertices.size() :
		vertices[i] -= V
	var shape := ConvexPolygonShape3D.new()
	shape.points = vertices
	tell_collision_shapes.emit(
		entity_curr_idx, entity_curr_brush_idx, shape, V,
		mapf.brush_textures
	)
	
const EPS := 0.000001
func planes_intersect(planes : Array[Plane]) -> PackedVector3Array :
	var vv := PackedVector3Array()

	for i in planes.size() - 2 :
		for j in range(i + 1, planes.size() - 1) :
			for k in range(j + 1, planes.size()) :
				var n0 := planes[i].normal
				var n1 := planes[j].normal
				var n2 := planes[k].normal
				var d0 := planes[i].d * -1
				var d1 := planes[j].d * -1
				var d2 := planes[k].d * -1
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
					if l != i and l != j and l != k and v.dot(lp.normal) < (lp.d  * -1)+ EPS :
						yes = false
						break
				if yes :
					vv.append(v)
	return vv
