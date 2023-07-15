extends Control
class_name QmapbspQuakeViewer

@export var iterations : int = 64

var hub : QmapbspQuake1Hub
var parser : QmapbspWorldImporterQuake1
var map : QmapbspQuakeWorld
var player : QmapbspQuakePlayer
var worldspawn : QmapbspQuakeWorldspawn
@onready var console : QmapbspConsole = $console
@onready var menu : QmapbspMenu = $menu
@onready var message : QmapbspQuakeViewerMessage = $message
@onready var loading : TextureRect = $loading
@onready var hud : QmapbspQuakeHUD = $hud

var current_mapname : String
var pal : PackedColorArray
var bspdir : String
var mapdir : String
var map_upper : bool = false
var tracklist : Dictionary
var trackcaches : Dictionary # <sounds : AudioStreamMP3>
	
var world_surface : ShaderMaterial

var registered : bool = false
var occlusion_culling : bool = false
var skill : int = 1
var rendering : int = 0

var skytex : ImageTexture


func _ready() :
	get_viewport().use_occlusion_culling = occlusion_culling
	hud.setup(self)
	
	console.hub = hub
	console.setup(hub)
	set_process(false)
	
	menu.hub = hub
	menu.viewer = self
	menu.init()
	menu.menu_canvas.hub = hub
	menu.cursor.hub = hub
	
	message.hub = hub
	
	var t : ImageTexture = hub.load_as_texture("gfx/loading.lmp")
	$loading/loading.texture = t
	$loading/loading.pivot_offset = t.get_size() / 2
	loading.texture = hub.load_as_texture("gfx/conback.lmp")
	
	
func set_rendering(i : int) -> void :
	rendering = i
	if i == 1 :
		lightmap_boost = 8.0


func play_by_node() :
	hud.show()
	message.show()
	loading.hide()
	add_child(map)
	
	_update_wireframe_mode()
	
	for n in get_tree().get_nodes_in_group(&'entities') :
		if !n.has_method(&'_map_ready') : continue
		n._map_ready()
	
	for n in get_tree().get_nodes_in_group(&'entities') :
		if !n.has_method(&'_entities_ready') : continue
		n._entities_ready()
		
	for n in get_tree().get_nodes_in_group(&'primary_doors') :
		if !n.has_method(&'_doors_ready') : continue
		n._doors_ready()
	
	if console.showing :
		console.toggle()
	
	player = preload("res://quake1_example/scene/player.tscn").instantiate()
	player.viewer = self
	hud.player = player
	add_child(player)
	var pspawn : Node3D = get_tree().get_first_node_in_group(&'player_spawn')
	if pspawn :
		player.global_position = pspawn.global_position
		player.around.rotation = pspawn.rotation
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func play_by_mapname(mapname : String, no_console : bool = false) -> bool :
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	current_mapname = mapname
	menu.hide()
	hud.hide()
	message.clear()
	get_tree().paused = false
	
	if !no_console :
		console.down()
	
	if map :
		map.free()
		player.free()
	oldprog = 0
	
	parser = QmapbspWorldImporterQuake1.new()
	parser.viewer = self
	map = QmapbspQuakeWorld.new()
	map.name = &'map'
	console.printv("Loading %s" % mapname)
	console.printv("Loading a map %s times per frame." % iterations)
	if iterations <= 32 :
		console.printv("If you feel this was too slow,")
		console.printv("You could adjust \"iterations\" inside the code.")
		console.printv("This example performs at a low value,")
		console.printv("So you could read this message")
		console.printv("before it was pushed by percentage spam.")
	parser.pal = pal
	parser.root = map
	
	var mappath := mapdir.path_join((
		mapname.to_upper() + '.MAP' if map_upper else mapname + '.map'
	))
	if !FileAccess.file_exists(mappath) :
		return false
	
	var retc : Array
	var ret := parser.begin_load_absolute(
		mappath,
		bspdir.path_join('/maps/' + mapname + '.bsp'),
		retc
	)
	if ret != StringName() :
		console.printv("Cannot open BSP file : %s" % ret)
	set_process(true)
	return true


var oldprog : int
func _process(delta) :
	for I in iterations :
		var reti := parser.poll()
		
		var prog : int = parser.get_progress() * 100.0
		if oldprog != prog :
			console.printv('-> %d%%' % prog)
			oldprog = prog
		
		if reti == &'END' :
			set_process(false)
			parser = null # free the mem
			play_by_node()
			break
		elif reti != StringName() :
			breakpoint


func toggle_noclip() :
	if !player : return
	player.toggle_noclip()


###################################################


func change_level(mapname : String) :
	loading.show()
	console.down()
	
	play_by_mapname.call_deferred(mapname, true)


func set_skill(s : int) :
	skill = s
	
	
func trigger_targets(targetname : String, activator : Node3D) :
	get_tree().call_group('T_' + targetname, &'_trigger', activator)


func trigger_targets_exit(targetname : String, activator : Node3D) :
	get_tree().call_group('T_' + targetname, &'_trigger_exit', activator)
	
	
func killtarget(targetname : String) :
	for n in get_tree().get_nodes_in_group('T_' + targetname) :
		n.queue_free()


func emit_message_state(msg : String, show : bool, from : Node) :
	if show :
		message.set_talk_sound(hub.load_audio("misc/talk.wav"))
	else :
		if message.current_emitter != from : return
	message.set_emitter(msg, show, from)


func emit_message_once(msg : String, from : Node) :
	message.set_talk_sound(hub.load_audio("misc/talk.wav"))
	message.set_emitter(msg, true, from)


func get_music(sounds : int) -> AudioStreamMP3 :
	var mp3 : AudioStreamMP3 = trackcaches.get(sounds)
	if mp3 : return mp3
	
	var path : String = tracklist.get(sounds, '')
	var f := FileAccess.open(path, FileAccess.READ)
	if !f : return null
	
	mp3 = AudioStreamMP3.new()
	mp3.data = f.get_buffer(f.get_length())
	trackcaches[sounds] = mp3
	return mp3
	
	
func found_secret() :
	message.set_talk_sound(hub.load_audio("misc/secret.wav"))
	message.set_emitter("You found a secret area!", true, null)


var mode : int = 0
func switch_render_mode() :
	if mode == 3 :
		mode = 0
	else :
		mode += 1
	world_surface.set_shader_parameter(&'mode', mode)


var lightmap_boost : float = 4.0
var lightmap_boost_min : float = 0.0
var lightmap_boost_max : float = 32.0
func add_lightmap_boost(add : int) :
	lightmap_boost = clampf(
		lightmap_boost + add * 2.0,
		lightmap_boost_min, lightmap_boost_max
	)
	world_surface.set_shader_parameter(&'lmboost', lightmap_boost)


func get_lightmap_boost_val() -> float :
	return inverse_lerp(lightmap_boost_min, lightmap_boost_max, lightmap_boost)


var region_highlighting : bool = false
func toggle_region_highlighting() -> void :
	region_highlighting = !region_highlighting
	world_surface.set_shader_parameter(&'regionhl', region_highlighting)


var wireframe_enabled : bool = false
func toggle_wireframe_mode() -> void :
	wireframe_enabled = !wireframe_enabled
	_update_wireframe_mode()
	
	
func _update_wireframe_mode() -> void :
	get_viewport().debug_draw = (
		Viewport.DEBUG_DRAW_WIREFRAME
		if wireframe_enabled else
		Viewport.DEBUG_DRAW_DISABLED
	)
	worldspawn.wenv.environment.background_color = (
		Color.WHITE
		if wireframe_enabled else
		Color.BLACK
	)


# according to QC builtin functions
func qc_lightstyle(style : int, light : String) -> void :
	worldspawn.set_lightstyle(style, light)
