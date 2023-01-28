extends Control
class_name QmapbspViewer

@export var iterations : int = 2048

var hub : QmapbspQuake1Hub
var parser : QmapbspWorldImporterQuake1
var map : Node3D
var player : QmapbspPlayer
@onready var console : QmapbspConsole = $console
@onready var menu : QmapbspMenu = $menu

func _ready() :
	console.hub = hub
	console.setup(hub)
	set_process(false)
	
	menu.hub = hub
	menu.viewer = self
	menu.init()
	menu.menu_canvas.hub = hub
	menu.cursor.hub = hub

func play_by_node() :
	add_child(map)
	console.toggle()
	
	player = preload("res://quake1_example/scene/player.tscn").instantiate()
	add_child(player)
	var pspawn : Node3D = get_tree().get_first_node_in_group(&'player_spawn')
	if pspawn :
		player.global_position = pspawn.global_position
		player.around.rotation = pspawn.rotation
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func play_by_path(
	path : String,
	mappath : String,
	pal : PackedColorArray
) -> void :
	menu.hide()
	
	parser = QmapbspWorldImporterQuake1.new()
	map = Node3D.new()
	console.printv("Loading %s" % path)
	console.printv("Loading a map %s times per frame." % iterations)
	if iterations <= 32 :
		console.printv("If you feel this was too slow,")
		console.printv("You could adjust \"iterations\" inside the code.")
		console.printv("This example performs at a low value,")
		console.printv("So you could read this message")
		console.printv("before it was pushed by percentage spam.")
	parser.pal = pal
	parser.root = map
	
	var f := FileAccess.open(path, FileAccess.READ)
	if FileAccess.get_open_error() != OK :
		console.printv("Cannot open BSP file")
	var retc : Array
	var ret := parser.begin_load_absolute(
		path, mappath, retc
	)
	if ret != StringName() :
		console.printv("Cannot open BSP file : %s" % ret)
	set_process(true)

var oldprog : int = 0

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
