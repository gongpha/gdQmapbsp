extends StaticBody3D
class_name QmapbspQuakeWorldspawn

@onready var music := $music
@onready var wenv : WorldEnvironment = $wenv

var props : Dictionary
func _get_properties(dict : Dictionary) : props = dict

var surface : ShaderMaterial

func _map_ready() :
	var viewer : QmapbspQuakeViewer = get_meta(&'viewer', null)
	if viewer :
		music.stream = viewer.get_music(props.get('sounds', '0').to_int())
		music.play()
		
		var env : Environment = wenv.environment
		var rendering : int = viewer.rendering
		if rendering != 0 :
#			var skysky : Sky = load("res://quake1_example/sky_sky.tres")
#			var skymat : ShaderMaterial = skysky.sky_material
#			skymat.set_shader_parameter(&'skytex', viewer.skytex)
#			env.sky = skysky
#			env.background_mode = Environment.BG_SKY
#			env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
#			env.ambient_light_energy = 16.0
			if rendering == 1 :
				env.sdfgi_enabled = true
				env.sdfgi_max_distance = 512.0
				env.sdfgi_cascades = 2
				env.sdfgi_read_sky_light = false
				env.sdfgi_energy = 4.0
			else :
				var aabb : AABB = props.get("__qmapbsp_aabb", AABB())
				if aabb.get_volume() > 0.0 :
					var voxelgi := VoxelGI.new()
					voxelgi.size = aabb.size
					voxelgi.position = aabb.get_center()
					voxelgi.name = "VOXELGI"
					add_child(voxelgi)
					voxelgi.bake()
					pass
				
		else :
			env.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED

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
