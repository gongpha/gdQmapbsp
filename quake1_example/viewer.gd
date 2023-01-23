extends Control
class_name QmapbspViewer

@export var iterations : int = 32

var hub : QmapbspQuake1Hub
var parser : QmapbspBSPParser
var map : Node3D
var player : QmapbspPlayer
@onready var console : QmapbspConsole = $console

func _ready() :
	console.hub = hub
	console.setup(hub)
	set_process(false)

func play_by_node() :
	add_child(map)
	console.toggle()
	
	player = preload("res://quake1_example/scene/player.tscn").instantiate()
	add_child(player)
	var pspawn : Node3D = get_tree().get_first_node_in_group(&'player_spawn')
	if pspawn :
		player.global_position = pspawn.global_position

func play_by_path(path : String, pal : PackedColorArray) -> void :
	parser = QmapbspBSPParser.new()
	var ext := QmapbspImporterExtensionQuake1.new()
	map = Node3D.new()
	console.printv("Loading %s" % path)
	console.printv("Loading a map %s times per frame." % iterations)
	console.printv("If you feel this was too slow,")
	console.printv("You could adjust \"iterations\" inside the code.")
	console.printv("This example performs at a low value,")
	console.printv("So you could read this message")
	console.printv("before it was pushed by percentage spam.")
	ext.pal = pal
	ext.root = map
	
	var f := FileAccess.open(path, FileAccess.READ)
	if FileAccess.get_open_error() != OK :
		console.printv("Cannot open BSP file")
	
	var ret := parser.begin_read_file(f, ext)
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
		
		if reti == ERR_FILE_EOF :
			set_process(false)
			play_by_node()
			break
