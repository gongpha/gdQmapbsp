extends StaticBody3D
class_name QmapbspQuakeWorldspawn

@onready var music := $music

var props : Dictionary
func _get_properties(dict : Dictionary) : props = dict

var surface : ShaderMaterial

func _map_ready() :
	var viewer : QmapbspQuakeViewer = get_meta(&'viewer', null)
	if viewer :
		music.stream = viewer.get_music(props.get('sounds', '0').to_int())
		music.play()

# progs/world.qc
# i can't invest the time to make a VM for these languages
const LIGHTSTYLES : PackedStringArray = [
	'm',
	'mmnmmommommnonmmonqnmmo',
	'abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba',
	'mmmmmaaaaammmmmaaaaaabcdefgabcdefg',
	'mamamamamama',
	'jklmnopqrstuvwxyzyxwvutsrqponmlkj',
	'nmonqnmomnmomomno',
	'mmmaaaabcdefgmmmmaaaammmaamm',
	'mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa',
	'aaaaaaaazzzzzzzz',
	'mmamammmmammamamaaamammma',
	'abcdefghijklmnopqrrqponmlkjihgfedcba'
]

const ZA : float = 0x7a - 0x61

func _process(delta : float) :
	if !surface : return # ?
	
	var s : PackedFloat32Array
	s.resize(12)
	for i in LIGHTSTYLES.size() : # 12
		var str := LIGHTSTYLES[i]
		var currlight : int = (Engine.get_frames_drawn() / 10) % str.length()
		s[i] = (str.unicode_at(currlight) - 0x61) / ZA;
		
		
	surface.set_shader_parameter(&'lightstyles', s)
