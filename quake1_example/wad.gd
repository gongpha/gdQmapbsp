extends Resource
class_name QmapbspWadFile

var pics : Dictionary # <name : [size, pba]...>

var cache : Dictionary # <name : ImageTexture>
	
var pal : PackedColorArray
	
func load_pic(name : String) -> ImageTexture :
	var itex : ImageTexture = cache.get(name)
	if itex : return itex
	if pal.size() != 256 : return null
	
	# load image
	var im := QmapbspPakFile._make_image(pics.get(name, [Vector2i(), PackedByteArray()]), pal,
		0 if name == "CONCHARS" else 255
	)
	itex = ImageTexture.create_from_image(im)
	cache[name] = itex
	return itex

static func load_from_file(f : FileAccess) :
	# HEADER
	var begin := f.get_position()
	if f.get_32() != 0x32444157 : return &"WAD_INVALID_MAGIC"
	var numentries := f.get_32()
	var diroffset := f.get_32()
	
	var wad := QmapbspWadFile.new()
	var pics := wad.pics
	
	for i in numentries :
		f.seek(begin + diroffset + (32 * i)) # 32 is the size of wadentry_t
		var offset := f.get_32()
		var dsize := f.get_32()
		var size := f.get_32()
		var type := f.get_8()
		var cmprs := f.get_8()
		f.get_16()
		var name := f.get_buffer(16).get_string_from_ascii()
		
		f.seek(begin + offset)
		
		match type :
			0x40 : # @
				#Es.append(f.get_buffer(256))
				pass
			0x42 : # B
				var psize := Vector2i(f.get_32(), f.get_32())
				pics[name] = [
					psize,
					f.get_buffer(psize.x * psize.y)
				]
			0x43 : # C
				pass
			0x44 : # D
				var psize := Vector2i(128, 128)
				pics[name] = [
					psize,
					f.get_buffer(psize.x * psize.y)
				]
			0x45 : # E
#				Es.append([
#					f.get_buffer(200 * 320),
#					f.get_buffer(128 * 128)
#				])
				pass
		pass
	
	return wad
