extends Object
class_name QmapbspTypeProp

static func var_to_prop(v) -> Array :
	var vv : String
	var typev : String = "string"
	match typeof(v) :
		TYPE_OBJECT, TYPE_MAX :
			printerr("Cannot export objects")
			return ["", "string"]
		TYPE_INT : typev = "integer"
		TYPE_FLOAT : typev = "float"
		TYPE_STRING : typev = "string"
		TYPE_BOOL : typev = "boolean"
		
	match typeof(v) :
		TYPE_COLOR :
			vv = "%d %d %d" % [v.r * 255, v.g * 255, v.b * 255]
		_ :
			vv = var_to_str(v)
	return [vv, typev]
	
static func prop_to_var(p : StringName, known_type : int = -1) :
	match known_type :
		TYPE_COLOR :
			var S := p.split(' ')
			if S.size() < 3 : return Color()
			return Color(
				int(S[0]) / 255.0,
				int(S[1]) / 255.0,
				int(S[2]) / 255.0,
			)
		TYPE_STRING, TYPE_STRING_NAME : return p
	return str_to_var(p)

#TYPE_AABB, TYPE_ARRAY, TYPE_BASIS,
#TYPE_CALLABLE, TYPE_COLOR, TYPE_DICTIONARY,
#TYPE_NIL, TYPE_NODE_PATH,
#TYPE_PACKED_BYTE_ARRAY,
#TYPE_PACKED_COLOR_ARRAY,
#TYPE_PACKED_FLOAT32_ARRAY,
#TYPE_PACKED_FLOAT64_ARRAY,
#TYPE_PACKED_INT32_ARRAY,
#TYPE_PACKED_INT64_ARRAY,
#TYPE_PACKED_STRING_ARRAY,
#TYPE_PACKED_VECTOR2_ARRAY,
#TYPE_PACKED_VECTOR3_ARRAY,
#TYPE_PLANE,
#TYPE_PROJECTION,
#TYPE_QUATERNION,
#TYPE_RECT2,
#TYPE_RECT2I,
#TYPE_RID,
#TYPE_SIGNAL,
#TYPE_STRING,
#TYPE_STRING_NAME,
#TYPE_TRANSFORM2D,
#TYPE_TRANSFORM3D,
#TYPE_VECTOR2,
#TYPE_VECTOR2I,
#TYPE_VECTOR3,
#TYPE_VECTOR3I,
#TYPE_VECTOR4,
#TYPE_VECTOR4I,
