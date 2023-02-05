extends Object
class_name QmapbspWAVLoader
# Ah yes . . . Yet Another WAV Loader in Godot
static func load_from_file(f : FileAccess) :
	# headers
	if f.get_32() != 0x46464952 : return &'WAV_INVALID_HEADER_RIFF'
	f.get_32() # who cares lmao
	if f.get_32() != 0x45564157 : return &'WAV_INVALID_HEADER_WAVE'
	if f.get_32() != 0x20746d66 : return &'WAV_INVALID_HEADER_FORMAT'
	var chunks := f.get_32()
	var fmttype := f.get_16()
	var channel := f.get_16()
	var samrate := f.get_32()
	f.get_32()
	f.get_16()
	var bitPsam := f.get_16()
	if bitPsam != 8 and bitPsam != 16 : return &'WAV_UNSUPPORTED_BIT_PER_SAMPLE'
	if chunks > 16 : f.seek(f.get_position() + chunks - 16)
	if f.get_32() != 0x61746164 : return &'WAV_INVALID_HEADER_DATA'
	var datsize := f.get_32()
	var a := AudioStreamWAV.new()
	var data := f.get_buffer(datsize)
	for i in data.size() : data[i] = data[i] - 128
	a.data = data
	a.format = 0 # force 8-bit (OO)???
	a.mix_rate = samrate
	a.stereo = channel == 2
	return a
