extends StaticBody3D
class_name QmapbspQuakeWorldspawn

@onready var music := $music
@onready var wenv : WorldEnvironment = $wenv

var props : Dictionary
func _get_properties(dict : Dictionary) : props = dict

var surface : ShaderMaterial
var bsp_textures : Array
var bsp_textures_fullbright : Array
var frame_textures : Array[Texture2D]
var frame_textures_fullbright : Array[Texture2D]

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
		surface = viewer.world_surface
		bsp_textures = viewer.bsp_textures
		bsp_textures_fullbright = viewer.bsp_textures_fullbright
		frame_textures.resize(bsp_textures.size())
		frame_textures_fullbright.resize(bsp_textures.size())
		_update_texs(0)
		
		music.stream = viewer.get_music(props.get('sounds', 0))
		music.play()
		
		water.stream = viewer.hub.load_audio("ambience/water1.wav", true)
		sky.stream = viewer.hub.load_audio("ambience/wind2.wav", true)
		# the other 2 amb sounds are unknown
		
		ambplayers.append(water)
		ambplayers.append(sky)
		ambplayers.append(slime)
		ambplayers.append(lava)
		
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
	
var update_tex_delay : int = 0

#####################################################################
# ambient sounds
@onready var water : AudioStreamPlayer = $water
@onready var sky : AudioStreamPlayer = $sky
@onready var slime : AudioStreamPlayer = $slime
@onready var lava : AudioStreamPlayer = $lava
var amb : Vector4
var ambtarget : Vector4
var ambplayers : Array[AudioStreamPlayer]

func _process(delta : float) :
	if !surface : return # ?
	
	var frame := Engine.get_frames_drawn() / 10
	for i in MAX_LIGHTSTYLE :
		var pf32a := lightstyles[i]
		lightstyles_f[i] = pf32a[frame % pf32a.size()]
		
	surface.set_shader_parameter(&'lightstyles', lightstyles_f)
	
	# animate textures
	if update_tex_delay <= 0 :
		_update_texs(Engine.get_frames_drawn() / 20)
		update_tex_delay = 20
	else :
		update_tex_delay -= 1

	for i in 4 :
		if amb[i] < ambtarget[i] :
			amb[i] = min(amb[i] + delta, ambtarget[i])
		else :
			amb[i] = max(amb[i] - delta, ambtarget[i])
		var ambp := ambplayers[i]
		if amb[i] <= 0 :
			ambp.stop()
			continue
		elif !ambp.playing :
			ambp.play()
		ambplayers[i].volume_db = linear_to_db(amb[i])
	
func _update_texs(frame : int) -> void :
	for i in frame_textures.size() :
		var e = bsp_textures[i]
		var e2 = bsp_textures_fullbright[i]
		if e is Array :
			frame_textures[i] = e[frame % e.size()]
			frame_textures_fullbright[i] = e2[frame % e.size()]
		else :
			frame_textures[i] = e
			frame_textures_fullbright[i] = e2
	surface.set_shader_parameter(&'texs', frame_textures)
	surface.set_shader_parameter(&'texfs', frame_textures_fullbright)

func set_lightstyle(style : int, light : String) -> void :
	var lightraw : PackedFloat32Array
	lightraw.resize(light.length())
	for i in light.length() :
		lightraw[i] = (light.unicode_at(i) - 0x61) / ZA
	
	lightstyles[style] = lightraw

# ambient sounds
# 0 = water
# 1 = sky
# 2 = slime
# 3 = lava
var amb_activator : Object
func set_ambsnds(activator : Object, amb : Vector4) -> void :
	if amb.x < 0.0 :
		if amb_activator == activator :
			ambtarget = Vector4()
		return
		
	ambtarget = amb * 0.125 # too loud when used 1.0
	amb_activator = activator
