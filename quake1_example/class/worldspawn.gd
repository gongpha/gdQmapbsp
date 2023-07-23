extends StaticBody3D
class_name QmapbspQuakeWorldspawn

@onready var music := $music
@onready var wenv : WorldEnvironment = $wenv

var props : Dictionary
func _get_properties(dict : Dictionary) : props = dict

var world_shader : QmapbspQuake1StyleShader

func _init() -> void :
	lightstyles.resize(MAX_LIGHTSTYLE)
	#lightstyles_f.resize(MAX_LIGHTSTYLE)
	lightstyles.fill(PackedColorArray([
		Color(DEFAULT_LIGHT_M, 0.0, 0.0, 0.0)
	])) # normal light
	
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
	lightstyles_i = Image.create(64, 1, false, Image.FORMAT_RF)
	lightstyles_t = ImageTexture.create_from_image(lightstyles_i)
	
	RenderingServer.global_shader_parameter_set(
		&'lightstyle_tex',
		lightstyles_t
	)
	
	var viewer : QmapbspQuakeViewer = get_meta(&'viewer', null)
	if viewer :
		world_shader = viewer.world_shader
		
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
var lightstyles : Array[PackedColorArray]
#var lightstyles_f : PackedFloat32Array
var lightstyles_i : Image
var lightstyles_t : ImageTexture

const ZA : float = 0x7a - 0x61
const MAX_LIGHTSTYLE := 64
const SWITCHABLE_LIGHT_BEGIN := 32 # to 62

const DEFAULT_LIGHT_M := (0x6D - 0x61) / ZA # M light (0.48)
	
var update_tex_delay : int = 0
var update_ls_delay : int = 0
var ls_frame : int = 0

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
	#if !surface : return # ?
	
	if update_ls_delay <= 0 :
		_update_ls()
		update_ls_delay = 10
	else :
		update_ls_delay -= 1

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
		
func _update_ls() -> void :
	#var frame := Engine.get_frames_drawn() / 10
	for i in MAX_LIGHTSTYLE :
		var pf32a := lightstyles[i]
		#print(pf32a[ls_frame % pf32a.size()])
		lightstyles_i.set_pixel(i, 0, pf32a[ls_frame % pf32a.size()])
	lightstyles_t.update(lightstyles_i)
	ls_frame += 1

func set_lightstyle(style : int, light : String) -> void :
	var lightraw : PackedColorArray
	lightraw.resize(light.length())
	for i in light.length() :
		lightraw[i] = Color(
			(light.unicode_at(i) - 0x61) / ZA,
			0.0, 0.0, 0.0
		)
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

func set_filter_mode(filter : int) -> void :
	world_shader.texture_filter = filter
	world_shader.rebuild_shader()

func set_rendering_mode(ren_mode : int) -> void :
	world_shader.texture_mode = ren_mode
	world_shader.rebuild_shader()
