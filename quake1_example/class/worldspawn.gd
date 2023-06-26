extends StaticBody3D
class_name QmapbspQuakeWorldspawn

@onready var music := $music
@onready var wenv : WorldEnvironment = $wenv

var props : Dictionary
func _get_properties(dict : Dictionary) : props = dict

var surface : ShaderMaterial

func _init() -> void :
	lightstyles.resize(MAX_LIGHTSTYLE)
	lightstyles_f.resize(MAX_LIGHTSTYLE)
	lightstyles.fill(PackedFloat32Array([DEFAULT_LIGHT_M])) # normal light
	
	# stock lightstyles (world.qc)
	set_lightstyle(1, 'mmnmmommommnonmmonqnmmo')
	set_lightstyle(2, 'abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba')
	set_lightstyle(3, 'mmmmmaaaaammmmmaaaaaabcdefgabcdefg')
	set_lightstyle(4, 'mamamamamama')
	set_lightstyle(5, 'jklmnopqrstuvwxyzyxwvutsrqponmlkj')
	set_lightstyle(6, 'nmonqnmomnmomomno')
	set_lightstyle(7, 'mmmaaaabcdefgmmmmaaaammmaamm')
	set_lightstyle(8, 'mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa')
	set_lightstyle(9, 'aaaaaaaazzzzzzzz')
	set_lightstyle(10, 'mmamammmmammamamaaamammma')
	set_lightstyle(11, 'abcdefghijklmnopqrrqponmlkjihgfedcba')

func _map_ready() :
	var viewer : QmapbspQuakeViewer = get_meta(&'viewer', null)
	if viewer :
		music.stream = viewer.get_music(props.get('sounds', 0))
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

#####################################################################
# lightstyles
var lightstyles : Array[PackedFloat32Array]
var lightstyles_f : PackedFloat32Array

const ZA : float = 0x7a - 0x61
const MAX_LIGHTSTYLE := 64
const SWITCHABLE_LIGHT_BEGIN := 32 # to 62

const DEFAULT_LIGHT_M := (0x6D - 0x61) / ZA # M light (0.48)

func _process(delta : float) :
	if !surface : return # ?
	
	var frame := Engine.get_frames_drawn() / 10
	for i in MAX_LIGHTSTYLE :
		var pf32a := lightstyles[i]
		lightstyles_f[i] = pf32a[frame % pf32a.size()]
		
	surface.set_shader_parameter(&'lightstyles', lightstyles_f)

func set_lightstyle(style : int, light : String) -> void :
	var lightraw : PackedFloat32Array
	lightraw.resize(light.length())
	for i in light.length() :
		lightraw[i] = (light.unicode_at(i) - 0x61) / ZA
	
	lightstyles[style] = lightraw
