extends RefCounted
class_name QmapbspPakFile

const ENTRY_SIZE = 64
var filename : String # pak0.pak
var loadrsc_f : FileAccess
var loadrsc_pathlist : PackedStringArray
var loadrsc_entries : PackedInt32Array # [offset, size]
var loadrsc_index : int = -1
var loadrsc_status : int
var loaded_entries : Array[Resource]

var global_pal : PackedColorArray
var global_map : Array[PackedColorArray]
var convert_indexes : PackedInt32Array
var convert_entries : Array

static func begin(p : String, ret : Array = []) -> QmapbspPakFile :
	var f := FileAccess.open(p, FileAccess.READ)
	if !f :
		ret.append_array([
			&"OPEN_FILE_ERROR"
		])
		return null
	
	# HEADER
	var header : int = f.get_32()
	if header != 1262698832 :
		ret.append(&"INVALID_MAGIC_NUMBER")
		return null
		
	var pak := QmapbspPakFile.new()
	pak.filename = p.get_file()
	pak.loadrsc_f = f
		
	var diroffset : int = f.get_32()
	var dirsize : int = f.get_32()
	
	var L1 := pak.loadrsc_pathlist
	var L2 := pak.loadrsc_entries
	
	L1.resize(dirsize / ENTRY_SIZE)
	L2.resize(L1.size() * 2)
	pak.loaded_entries.resize(L1.size())
	
	for i in L1.size() :
		f.seek(diroffset + ENTRY_SIZE * i)
		L1[i] = f.get_buffer(0x38).get_string_from_ascii()
		L2[i * 2 + 0] = f.get_32()
		L2[i * 2 + 1] = f.get_32()
	pak.loadrsc_index = 0
	pak.loadrsc_status = LoadingStatus.READ_FILES
	return pak
	
enum LoadingStatus {
	READ_FILES, CONVERTING
}

func get_progress() -> float :
	if loadrsc_index == -1 : return 1.0
	match loadrsc_status :
		LoadingStatus.READ_FILES :
			return 0.0 + (float(loadrsc_index) / loaded_entries.size()) * 0.5
		LoadingStatus.CONVERTING :
			return 0.5 + (float(loadrsc_index) / convert_entries.size()) * 0.5
	return 0.0
	
func poll() -> StringName :
	if loadrsc_index == -1 : return &'UNINITIALIZED'
	match loadrsc_status :
		LoadingStatus.READ_FILES :
			return _poll_read_file()
		LoadingStatus.CONVERTING :
			return _poll_converting()
	return &''
			
func _poll_read_file() -> StringName :
	var rsc : Resource
	var path := loadrsc_pathlist[loadrsc_index]
	
	loadrsc_f.seek(loadrsc_entries[loadrsc_index * 2 + 0])
	var datasize := loadrsc_entries[loadrsc_index * 2 + 1]
	
	
	match path.get_extension() :
		'wav' :
			var what = QmapbspWAVLoader.load_from_file(loadrsc_f)
			if what is StringName : return what
			rsc = what
			#what.save_to_wav("_c/" + path.get_file())
		'wad' :
			var wad = QmapbspWadFile.load_from_file(loadrsc_f)
			if wad is StringName : return wad
			wad.pal = global_pal
			rsc = wad
		'lmp' :
			var res : Array
			var ret := QmapbspLmpFile.load_from_file(path, loadrsc_f, res)
			match ret :
				&'pal' : global_pal.append_array(res[0]) # DO NOT SET IT INSTANTLY
				&'map' : global_map.append_array(res[0]) # DO NOT SET IT INSTANTLY
				&'pic' :
					convert_indexes.append(loadrsc_index)
					convert_entries.append([&'lmp_pic', res[0]])
		_ :
			rsc = QmapbspRawFile.new()
			var mpath := "user://packcache/".path_join(path)
			var f := FileAccess.open(mpath, FileAccess.WRITE)
			if f :
				f.store_buffer(loadrsc_f.get_buffer(datasize))
			rsc.raw_path = mpath
	
	if rsc :
		_save_entry(loadrsc_index, rsc)
	loadrsc_index += 1
	if loadrsc_index >= loaded_entries.size() :
		loadrsc_status = LoadingStatus.CONVERTING
		loadrsc_index = 0
	return StringName()
	
static func _make_image(
	entrydata : Array,
	pal : PackedColorArray,
	transparent : int = 255
) -> Image :
	var size : Vector2i = entrydata[0]
	var data : PackedByteArray = entrydata[1]
	var im := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var TRANSPARENT := Color(Color(), 0.0)
	for i in data.size() :
		var pali := data[i]
		im.set_pixelv(Vector2i(
			i % size.x, i / size.x
		), TRANSPARENT if pali == transparent else pal[pali])
	return im
	
func _poll_converting() -> StringName :
	var idx := convert_indexes[loadrsc_index]
	var entry : Array = convert_entries[loadrsc_index]
	var entrydata : Array = entry[1]
	match entry[0] :
		&'lmp_pic' :
			_save_entry(idx, _make_image(entrydata, global_pal))
	loadrsc_index += 1
				
	if loadrsc_index >= convert_entries.size() :
		#_save_to_pck()
		#var d := DirAccess.open("user://pak_imported_cache")
		#d.remove("")
		
		return &'DONE'
	return StringName()
	
func _save_entry(entry_index : int, resource : Resource) :
#	var path := loadrsc_pathlist[entry_index]
#	match path.get_extension() :
#		'wad' :
#			pass
#		'lmp' : # usually for pictures
#			path += ".png"
#	path = "user://pak_imported_cache/" + path
#	resource.set_meta(&'pakpath', path)
	loaded_entries[entry_index] = resource

#func _save_to_pck() :
#	var pck := PCKPacker.new()
#	pck.pck_start("user://pak_imported/%s.pck" % filename)
#
#	for i in loadrsc_pathlist.size() :
#		var rsc : Resource = loaded_entries[i]
#		if rsc.has_meta(&'pakpath') : continue
#
#
#
#		pck.add_file("res://_QUAKEPCK/%s" % (
#
#		), _get_path_from_entry_index(i))
#		pck.flush()
