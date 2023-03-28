extends QmapbspBaseParser
class_name QmapbspMAPParser

#var enable_collision_shapes : bool = false
signal tell_collision_shapes(
	entity_curr_idx : int, entity_curr_brush_idx : int, shape : Shape3D, origin : Vector3
)

var known_textures : PackedStringArray

var generated_box_shapes : Array[BoxShape3D]
var generated_box_shapes_size : PackedVector3Array

var parsed_shapes : Array[Array] # [shape, origin, textures]

func begin_file(f : FileAccess) -> StringName :
	super(f)
	mapf = QmapbspMapFormat.begin_from_text(f.get_as_text(true))
	return StringName()

func _brush_found() :
	if wim._entity_prefers_collision_shape(entity_idx) :
		_parse_shape()
	
	for t in mapf.brush_textures :
		if known_textures.has(t) : continue
		known_textures.append(t)
		
func _parse_shape() -> void :
	var shape : Shape3D
	var V := Vector3()
	var aabb : AABB
	if !entity_is_illusionary :
		var planes : Array[Plane] = mapf.brush_planes
		var is_box := true
		if planes.size() == 6 :
			# if it was a box. create a box shape instead of a convex shape.
			var x := Vector2(INF, -INF) # min, max
			var y := x
			var z := x
			for i in 6 :
				var plane := planes[i]
				var d := plane.d
				match plane.normal :
					Vector3(1, 0, 0) :
						x = Vector2(
							minf(plane.d, x.x),
							maxf(plane.d, x.y),
						)
					Vector3(-1, 0, 0) :
						x = Vector2(
							minf(-plane.d, x.x),
							maxf(-plane.d, x.y),
						)
					Vector3(0, 1, 0) :
						y = Vector2(
							minf(plane.d, y.x),
							maxf(plane.d, y.y),
						)
					Vector3(0, -1, 0) :
						y = Vector2(
							minf(-plane.d, y.x),
							maxf(-plane.d, y.y),
						)
					Vector3(0, 0, 1) :
						z = Vector2(
							minf(plane.d, z.x),
							maxf(plane.d, z.y),
						)
					Vector3(0, 0, -1) :
						z = Vector2(
							minf(-plane.d, z.x),
							maxf(-plane.d, z.y),
						)
					_ :
						is_box = false
						break
			aabb.position = _qpos_to_vec3(Vector3(x.x, y.x, z.x))
			
			aabb = aabb.expand(_qpos_to_vec3(Vector3(x.y, y.y, z.y)))
		else : is_box = false
		
		if is_box :
			var s := aabb.size
			var i := generated_box_shapes_size.find(s)
			if i == -1 :
				shape = BoxShape3D.new()
				(shape as BoxShape3D).size = s
				generated_box_shapes.append(shape)
				generated_box_shapes_size.append(s)
			else :
				shape = generated_box_shapes[i]
			V = aabb.get_center()
		else :
			var vertices := planes_intersect(planes)
			var vs := vertices.size()
			
			for i in vs :
				var v := vertices[i]
				v = _qpos_to_vec3(v * -1)
				vertices[i] = v
				V += v
			V /= vs
			for i in vs :
				vertices[i] -= V
			
			shape = ConvexPolygonShape3D.new()
			shape.points = vertices
			
		parsed_shapes.append([shape, V, mapf.brush_textures.duplicate()])
		
func _end_entity(idx : int) :
	for i in parsed_shapes.size() :
		var arr : Array = parsed_shapes[i]
		tell_collision_shapes.emit(
			idx, i, arr[0], arr[1], arr[2]
		)
	parsed_shapes.clear()
	
const EPS := 0.000001
# https://math.stackexchange.com/a/1884181
static func planes_intersect(planes : Array[Plane]) -> PackedVector3Array :
	var vv := PackedVector3Array()

	for i in planes.size() - 2 :
		for j in range(i + 1, planes.size() - 1) :
			for k in range(j + 1, planes.size()) :
				var n0 := planes[i].normal
				var n1 := planes[j].normal
				var n2 := planes[k].normal
				var d0 := planes[i].d * -1.0
				var d1 := planes[j].d * -1.0
				var d2 := planes[k].d * -1.0
				var t : float = (
					n0.x * (n1.y * n2.z - n1.z * n2.y) +
					n0.y * (n1.z * n2.x - n1.x * n2.z) +
					n0.z * (n1.x * n2.y - n1.y * n2.x)
				)
				if absf(t) < EPS : continue
				var v := Vector3(
					(d0 * (n1.z * n2.y - n1.y * n2.z) + d1 * (n0.y * n2.z - n0.z * n2.y) + d2 * (n0.z * n1.y - n0.y * n1.z)) / -t,
					(d0 * (n1.x * n2.z - n1.z * n2.x) + d1 * (n0.z * n2.x - n0.x * n2.z) + d2 * (n0.x * n1.z - n0.z * n1.x)) / -t,
					(d0 * (n1.y * n2.x - n1.x * n2.y) + d1 * (n0.x * n2.y - n0.y * n2.x) + d2 * (n0.y * n1.x - n0.x * n1.y)) / -t
				)
				var yes := true
				for l in planes.size() :
					var lp := planes[l]
					if l != i and l != j and l != k and v.dot(lp.normal) < (lp.d  * -1) + EPS :
						yes = false
						break
				if yes :
					vv.append(v)
	return vv
