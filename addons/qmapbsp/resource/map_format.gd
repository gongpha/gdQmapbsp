extends Resource
class_name QmapbspMapFormat

############################
var src : String
var i : int = -1
var level : int = 0

enum PollResult {
	BEGIN_ENTITY, # (no return results)
	FOUND_KEYVALUE, # [key, value]
	FOUND_BRUSH, # 
	END_ENTITY,
	END, # (no return results)
		
	ERR, # [StringName]
}

 # AFTER BEGIN_ENTITY ONLY
var tell_skip_entity_entries : bool = false
var tell_skip_entity_brushes : bool = false

var tell_valve_format : bool = false

# outputs
var out : Array
var brush_planes : Array[Plane]
var brush_textures : PackedStringArray
var brush_offsets : PackedVector2Array
var brush_offsets1_valve : PackedColorArray
var brush_offsets2_valve : PackedColorArray
var brush_rotations : PackedFloat32Array
var brush_scales : PackedVector2Array

func export_brush() -> Array :
	return [
		brush_planes,
		brush_textures,
		brush_offsets,
		brush_offsets1_valve,
		brush_offsets2_valve,
		brush_rotations,
		brush_scales,
	]

func poll(result : Array) -> int :
	var parsing : int = 0
	var str_begin : int
	var pushed = null
	
	
	while i < src.length() :
		var c := src.unicode_at(i)
		
		match parsing :
			1 : # literal string
				match c :
					0x5c : # \
						parsing = 2
					0x22 : # "
						# end of the literal string
						var v := (
							src.substr(str_begin, i - str_begin).c_unescape()
						)
						i += 1
						parsing = 0
						if pushed == null :
							pushed = v
						else :
							# new entry
							out = [pushed, v]
							pushed = null
							return PollResult.FOUND_KEYVALUE
				i += 1
			2 : # escaping
				parsing = 1
			3 : # comment
				if c == 0x10 : # newline
					parsing = 0
				i += 1
			0 : # other
				match c :
					0x7b : # {
						level += 1
						i += 1
						if level == 1 :
							return PollResult.BEGIN_ENTITY
						elif level == 2 :
							# begin brush
							brush_planes = []
							brush_textures = PackedStringArray()
							brush_offsets = PackedVector2Array()
							brush_offsets1_valve = PackedColorArray()
							brush_offsets2_valve = PackedColorArray()
							brush_rotations = PackedFloat32Array()
							brush_scales = PackedVector2Array()
						else :
							result.append(&'UNEXPECTED_LEVEL')
							return PollResult.ERR
							
					0x7d : # }
						level -= 1
						i += 1
						if level < 0 :
							result.append(&'UNMATCHED_BRACES')
							return PollResult.ERR
						elif level == 0 :
							return PollResult.END_ENTITY
						elif level == 1 :
							return PollResult.FOUND_BRUSH
					0x22 : # "
						if !tell_skip_entity_entries :
							str_begin = i + 1
							parsing = 1
						i += 1
					0x27 : # /
						if src.length() - i - 1 == 0 :
							result.append(&'FOUND_SLASH_AT_EOF')
							return PollResult.ERR
						i += 1
						if src.unicode_at(i + 1) == 0x27 :
							# //
							parsing = 3
					0x28 : # (
						if tell_skip_entity_brushes :
							i += 1
							continue
							
						var bs := src.substr(
							i, src.find('\n', i) - i
						)
						i += bs.length()
						
						var comment : int = bs.find('//', bs.length() - 1)
						if comment != -1 :
							bs = bs.substr(0, comment)
						
						var S := bs.split(' ')
							
						if tell_valve_format :
							if S.size() != 31 :
								result.append(&'INVALID_VALVE_BRUSH_PLANE')
								return PollResult.ERR
							
							brush_planes.append(Plane(
								Vector3(float(S[1]), float(S[2]), float(S[3])),
								Vector3(float(S[6]), float(S[7]), float(S[8])),
								Vector3(float(S[11]), float(S[12]), float(S[13])),
							))
							brush_textures.append(S[15])
							brush_offsets1_valve.append(Color(
								float(S[17]), float(S[18]), float(S[19]), float(S[20])
							))
							brush_offsets2_valve.append(Color(
								float(S[23]), float(S[24]), float(S[25]), float(S[26])
							))
							brush_rotations.append(float(S[28]))
							brush_scales.append(Vector2(float(S[29]), float(S[30])))
						else :
							if S.size() != 21 :
								result.append(&'INVALID_BRUSH_PLANE')
								return PollResult.ERR
							
							brush_planes.append(Plane(
								Vector3(float(S[1]), float(S[2]), float(S[3])),
								Vector3(float(S[6]), float(S[7]), float(S[8])),
								Vector3(float(S[11]), float(S[12]), float(S[13])),
							))
							brush_textures.append(S[15])
							brush_offsets.append(Vector2(float(S[16]), float(S[17])))
							brush_rotations.append(float(S[18]))
							brush_scales.append(Vector2(float(S[19]), float(S[20])))
								
					_ :
						i += 1
						continue
	if level != 0 :
		result.append(&"UNMATCHED_BRACES")
		return PollResult.ERR
	if pushed :
		result.append(&"INCOMPLETE_KEY")
		return PollResult.ERR
	return PollResult.END
	
static func begin_from_text(text : String) -> QmapbspMapFormat :
	var kv := QmapbspMapFormat.new()
	kv.i = 0
	kv.src = text
	return kv

static func expect_vec3(v : String) -> Vector3 :
	var s := v.split(' ') if !v.is_empty() else PackedStringArray()
	if s.size() < 3 : return Vector3()
	return Vector3(float(s[0]), float(s[1]), float(s[2]))

static func expect_int(v : String) -> int :
	return v.to_int()
