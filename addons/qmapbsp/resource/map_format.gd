extends Resource
class_name QmapbspMapFormat

var error : StringName

@export var data : Array[Dictionary]

static func from_text(text : String) -> QmapbspMapFormat :
	var kv := QmapbspMapFormat.new()
	var i := 0
	if text.is_empty() : return kv
	
	var top : Dictionary
	var stacks : Array[Dictionary]
	var parsing : int = 0
	
	var str_begin : int
	
	var pushed = null
	
	while true :
		if i >= text.length() :
			break
		var c := text.unicode_at(i)
		match parsing :
			1 : # literal string
				match c :
					0x5c : # \
						parsing = 2
					0x22 : # "
						# end of the literal string
						var v := (
							text.substr(str_begin, i - str_begin).c_unescape()
						)
						if pushed == null :
							pushed = v
						else :
							# new entry
							top[pushed] = v
							pushed = null
						parsing = 0
			2 : # escaping
				parsing = 1
			0 : # other
				match c :
					0x7b : # {
						var new := {}
						if top.has(1) :
							top[1].append(new)
						else :
							top[1] = [new]
						top = new
						if stacks.is_empty() :
							kv.data.append(top)
						stacks.append(top)
					0x7d : # }
						stacks.pop_back()
						top = {} if stacks.is_empty() else stacks.back()
					0x22 : # "
						str_begin = i + 1
						parsing = 1
		i += 1
						
	if !stacks.is_empty() :
		kv.error = &"UNBALANCED_PARENTHESIS"
	if pushed :
		kv.error = &"INCOMPLETE_KEY"
	return kv

static func expect_vec3(v : String) -> Vector3 :
	var s := v.split(' ') if !v.is_empty() else PackedStringArray()
	if s.size() < 3 : return Vector3()
	return Vector3(float(s[0]), float(s[1]), float(s[2]))

static func expect_int(v : String) -> int :
	return v.to_int()
