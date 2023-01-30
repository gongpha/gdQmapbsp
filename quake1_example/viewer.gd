extends Control
class_name QmapbspQuakeViewer

@export var iterations : int = 2048

var hub : QmapbspQuake1Hub
var parser : QmapbspWorldImporterQuake1
var map : QmapbspQuakeWorld
var player : QmapbspPlayer
@onready var console : QmapbspConsole = $console
@onready var menu : QmapbspMenu = $menu
@onready var message : QmapbspQuakeViewerMessage = $message
@onready var loading : TextureRect = $loading

var pal : PackedColorArray
var bspdir : String
var mapdir : String
var map_upper : bool = false

var registered : bool = false

func _ready() :
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
	loading.texture = t
	loading.pivot_offset = t.get_size() / 2

func play_by_node() :
	loading.hide()
	add_child(map)
	if console.showing :
		console.toggle()
	
	player = preload("res://quake1_example/scene/player.tscn").instantiate()
	add_child(player)
	var pspawn : Node3D = get_tree().get_first_node_in_group(&'player_spawn')
	if pspawn :
		player.global_position = pspawn.global_position
		player.around.rotation = pspawn.rotation
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func play_by_mapname(mapname : String, no_console : bool = false) -> bool :
	menu.hide()
	message.clear()
	
	if !no_console :
		console.down()
	
	if map :
		map.free()
		player.free()
	oldprog = 0
	
	parser = QmapbspWorldImporterQuake1.new()
	parser.viewer = self
	map = QmapbspQuakeWorld.new()
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
	
	play_by_mapname.call_deferred(mapname, true)

func set_skill(s : int) :
	print(s)
	
func killtarget(targetname : String) :
	for n in get_tree().get_nodes_in_group('T_' + targetname) :
		n.queue_free()

func _emit_message_state(msg : String, show : bool, from : Node) :
	message.set_emitter(msg, show, from)
