extends Control
class_name QmapbspMenu

var hub : QmapbspQuake1Hub
var viewer : QmapbspQuakeViewer
var menu_canvas : QmapbspQuakeDraw
var cursor : Control
var cursor_frames : Array[Texture]
var menuui_player : AudioStreamPlayer

var menu_cursor : int = 0
var menu_cursor_is_options : bool = false
var menu_cursor_prev : int
var menu_items : Array
var menu_current : StringName
var menu_dict : Dictionary

var MENU := {
	'none' : {},
	'main' : {
		title = "gfx/ttl_main.lmp",
		back = "main",
		options = [
			["Toggle noclip (V)", func() :
				viewer.toggle_noclip()
				protect3()
				],
			["Restart", func() :
				hub.restart()
				],
			["Back to the hub", func() :
				hub.back()
				],
		]
	},
#	'single' : {
#		title = "gfx/ttl_sgl.lmp",
#		context = "gfx/sp_menu.lmp",
#		back = "main",
#		items = [
#			NewGame,
#			null,
#			null,
#		]
#	},
#	'options' : {
#
#	}
}

func ToggleMenu() :
	entersound()
	
	#if key_dest == key_menu :
	go_to(&'main')
	return
#	if key_dest == key_console :
#		Console.toggle()
#	else :
#		Menu_Main()
	
#func NewGame() :
	#Console.exec("map", ["start"])
	#hub.play_map("start")
	
func draw_general_menu(menu_dict : Dictionary) :
	if !menu_dict.has("title") : return
	menu_canvas.draw_texture(hub.load_as_texture("gfx/qplaque.lmp"), Vector2(16, 4))
	var p := hub.load_as_texture(menu_dict["title"])
	menu_canvas.draw_texture(p, Vector2(
		(320 - p.get_width()) / 2.0, 4
	))
	var context : String = menu_dict.get("context", "")
	if !context.is_empty() :
		menu_canvas.draw_texture(hub.load_as_texture(context), Vector2(72, 32))
	
	if menu_cursor_is_options :
		for i in menu_items.size() :
			var o = menu_items[i]
			var y : int = 32 + (i * 8)
			if o is Array :
				var s : String = o[0]
				menu_canvas.draw_quake_text(Vector2(16 + (22 - s.length()) * 8, y), s, 128)
				var v = o[1]
				var t = o[2] if o.size() >= 3 else null
				if t is Callable :
					menu_canvas.draw_slider(Vector2(220, y), t)

func Draw() :
	draw_general_menu(menu_dict)

################################################
var statedc : Callable

func go_to(to : StringName) :
	menu_cursor = 0
	menu_dict = MENU.get(to, {})
	if menu_dict.is_empty() :
		menu_items = []
		menu_canvas.queue_redraw()
		return
	menu_current = to
	entersound()
	menu_cursor_is_options = menu_dict.has("options")
	if menu_cursor_is_options :
		menu_items = menu_dict.get("options")
	else :
		menu_items = menu_dict.get("items", [])
	
	menu_canvas.queue_redraw()
	
func entersound() :
	if !visible : return
	menuui_player.stream = hub.load_audio("misc/menu2.wav")
	menuui_player.play()
	
func menu3() :
	if !visible : return
	menuui_player.stream = hub.load_audio("misc/menu3.wav")
	menuui_player.play()
	
func protect3() :
	if !visible : return
	menuui_player.stream = hub.load_audio("items/protect3.wav")
	menuui_player.play()
	
func _cursor_draw() :
	var f : int
	if menu_cursor_is_options :
		f = 12 + (int(Engine.get_frames_drawn() / 40.0) & 1)
		cursor.draw_quake_character(Vector2(200, 32 + menu_cursor * 8), f)
		return
	f = int(Engine.get_frames_drawn() / 10.0) % 6
	cursor.draw_texture(cursor_frames[f], Vector2(54, 32 + menu_cursor * 20.0))
	
func _process(delta : float) :
	if !visible : return
	cursor.queue_redraw()
	
func init() :
	menuui_player = AudioStreamPlayer.new()
	menuui_player.name = &"ENTERSOUND"
	add_child(menuui_player)
	
	menu_canvas = QmapbspQuakeDraw.new()
	menu_canvas.custom_minimum_size = Vector2(320, 200)
	menu_canvas.name = &'MENUCANVAS'
	menu_canvas.draw.connect(Draw)
	menu_canvas.scale = Vector2(3, 3)
	menu_canvas.pivot_offset = Vector2(160, 100)
	menu_canvas.grow_horizontal = Control.GROW_DIRECTION_BOTH
	menu_canvas.grow_vertical = Control.GROW_DIRECTION_BOTH
	menu_canvas.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(menu_canvas)
	
	cursor = QmapbspQuakeDraw.new()
	cursor.name = &'CURSOR'
	cursor.draw.connect(_cursor_draw)
	cursor_frames.resize(6)
	for i in 6 :
		var itex := hub.load_as_texture("gfx/menudot%d.lmp" % (i + 1))
		cursor_frames[i] = itex
	menu_canvas.add_child(cursor)

func _init() :
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hide()
	
#	Console.add_command("togglemenu", ToggleMenu)
#	Console.add_command("menu_main", go_to.bind(&'main'))
#	Console.add_command("menu_singleplayer", Menu_SinglePlayer)
#	Console.add_command("menu_load", Menu_Load)
#	Console.add_command("menu_save", Menu_Save)
#	Console.add_command("menu_multiplayer", Menu_MultiPlayer)
#	Console.add_command("menu_setup", Menu_Setup)
#	Console.add_command("menu_options", Menu_Options)
#	Console.add_command("menu_keys", Menu_Keys)
#	Console.add_command("menu_video", Menu_Video)
#	Console.add_command("help", Menu_Help)
#	Console.add_command("menu_quit", Menu_Quit)

func updownsound() :
	menuui_player.stream = hub.load_audio("misc/menu1.wav")
	menuui_player.play()

func _unhandled_input(event : InputEvent) :
	if visible :
		if event.is_action_pressed(&"ui_up") :
			updownsound()
			menu_cursor -= 1
			if menu_cursor < 0 : menu_cursor = menu_items.size() - 1
		elif event.is_action_pressed(&"ui_down") :
			updownsound()
			menu_cursor += 1
			if menu_cursor >= menu_items.size() : menu_cursor = 0
		elif event.is_action_pressed(&"ui_accept") :
			if menu_items.is_empty() :
				menu3()
				return
			var that = menu_items[menu_cursor]
			if that is String :
				menu_cursor_prev = menu_cursor
				go_to(that)
				return
			elif that is Callable :
				that.call()
				return
			elif that is Array :
				if that.size() == 3 :
					# slider
					return
				elif that.size() == 2 :
					# press
					var c : Callable = that[1]
					if c.is_valid() :
						c.call()
					return
			menu3()
	if event.is_action_pressed(&"ui_cancel") :
		if hub.viewer.console.visible : return
		
		visible = !visible
		if visible :
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else :
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		viewer.message.visible = !visible
		viewer.hud.visible = !visible
		get_tree().paused = !get_tree().paused
		
		var back : String = menu_dict.get('back', '')
		if !back.is_empty() :
			go_to(back)
			menu_cursor = menu_cursor_prev
		else :
			go_to(&'main')
		
