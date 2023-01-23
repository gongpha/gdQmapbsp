extends Control
class_name QmapbspConsole

var hub : QmapbspQuake1Hub

const ENGINE_TEXT := "Qmapbsp by gongpha"

var cmds : Dictionary
var control : QmapbspQuakeDraw
var regex : RegEx
var tween : Tween
var showing : bool = true

var text_visible : bool = true
var text : PackedStringArray
var cvars : Dictionary

func setup(hub_ : QmapbspQuake1Hub) :
	hub = hub_
	control.hub = hub

func var_set(cvar : String, v) -> void :
	cvars[cvar] = v
	
func var_get(cvar : String) :
	return cvars.get(cvar, 0)
	
func exec(cmd : StringName, args : Array) :
	var call = cmds.get(cmd)
	if call is Callable :
		last_call_v = args
		call.call()

func exec_line(line : String) :
	var r := regex.search_all(line)
	pass
	
func add_command(n : StringName, call : Callable) :
	cmds[n] = call
	
func toggle() :
	showing = !showing
	tween = create_tween()
	tween.set_parallel()
	if showing :
		anchor_top = -1.0
		anchor_bottom = 0.0
		show()
		tween.tween_property(self, ^'anchor_bottom', 1.0, 1.0)
		tween.tween_property(self, ^'anchor_top', 0.0, 1.0)
	else :
		anchor_top = 0.0
		anchor_bottom = 1.0
		tween.tween_property(self, ^'anchor_top', -1.0, 1.0)
		tween.tween_property(self, ^'anchor_bottom', 0.0, 1.0)
	tween.finished.connect(_tf)
	control.queue_redraw()
	
func _tf() :
	if !showing : hide()
	
func make_visible(yes : bool) :
	control.visible = yes
	
func printv(s : String) :
	text.push_back(s)
	while (text.size() + 2) * 8 * 3 > size.y :
		text.remove_at(0)
	control.queue_redraw()
	
func _ready() :
	control = QmapbspQuakeDraw.new()
	control.name = &'CONSOLECONTROL'
	control.draw.connect(_console_draw)
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(control)
	
	regex = RegEx.new()
	regex.compile("[^\\s\"']+|\"([^\"]*)\"|'([^']*)'")
	
var begin_line := 0
	
func _console_draw() :
	if !hub : return
	var texture := hub.load_as_texture("gfx/conback.lmp")
	control.draw_texture_rect(texture, Rect2(
		Vector2(), size
	), false)
	
	if text_visible :
		var y : float = 8.0 * 3
		for i in text.size() :
			var t := text[i]
			control.draw_quake_text(Vector2(
				8 * 3, y + (begin_line * 8 * 3)
			), t, 0, Vector2(3, 3))
			y += 8 * 3
		
		control.draw_quake_text(
			Vector2(size.x - (ENGINE_TEXT.length() * 8 * 3), size.y - 8 * 3),
			ENGINE_TEXT, 0, Vector2(3, 3)
		)

func scroll(add : int) :
	begin_line += add
	control.queue_redraw()

#func _unhandled_input(event : InputEvent) :
#	if !text_visible :
#		Menu.unhandled_input(event)
#		return
#	if event is InputEventMouseButton :
#		if !event.pressed : return
#		if event.button_index == MOUSE_BUTTON_WHEEL_UP :
#			scroll(1)
#		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN :
#			scroll(-1)
#	elif event.is_action_pressed(&"ui_cancel") :
#		text_visible = false
#		Menu.show()
#		control.queue_redraw()

########################
var last_call_v : Array
var last_call_cmd : StringName

func argv() -> Array :
	return [last_call_cmd] + last_call_v
