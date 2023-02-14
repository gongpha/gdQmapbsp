extends QmapbspQuakeDraw
class_name QmapbspQuakeHUD

var nums : Array[ImageTexture]
var anums : Array[ImageTexture]
var faces : Array[ImageTexture]

var player : QmapbspQuakePlayer

const MARGIN : float = 32.0
const SCALE := Vector2(3, 3)

var health := 100

func _process(delta : float) :
	queue_redraw()

func _draw() :
	draw_quake_text(
		Vector2(16, 16),
		"fps : %s\ndraw calls : %s\nprimitives : %s\nvelocity : %d" % [
			Performance.get_monitor(Performance.TIME_FPS),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			player.velocity.length() * 32.0 if is_instance_valid(player) else "N/A"
		], 0, Vector2(3, 3)
	)
	draw_line(Vector2(16, 128), Vector2(16 + (player.velocity.length() / 15.0 * 128.0), 128), Color.TOMATO, 4.0)
	
	
	
	
	return
	var t : ImageTexture
	var ts : Vector2
	t = faces[0]
	ts = t.get_size() * SCALE
	draw_texture_rect(t, Rect2(
		Vector2(MARGIN, size.y - ts.y - MARGIN),
		ts
	), false)
	
	# HEALTH
	var hs := str(health)
	if hs.length() >= 3 :
		t = nums[int(hs[0])]
		ts = t.get_size() * SCALE
		draw_texture_rect(t, Rect2(
			Vector2(MARGIN + ts.x + 16.0,
			size.y - ts.y - MARGIN),
			ts
		), false)
		
	if hs.length() >= 2 :
		t = nums[int(hs[hs.length() - 2])]
		ts = t.get_size() * SCALE
		draw_texture_rect(t, Rect2(
			Vector2(MARGIN + ts.x + 16.0 + (24.0 * 3),
			size.y - ts.y - MARGIN),
			ts
		), false)
		
	t = nums[int(hs[hs.length() - 1])]
	ts = t.get_size() * SCALE
	draw_texture_rect(t, Rect2(
		Vector2(MARGIN + ts.x + 16.0 + (24.0 * 2 * 3),
		size.y - ts.y - MARGIN),
		ts
	), false)

func setup(viewer : QmapbspQuakeViewer) :
	var C := viewer.hub.load_as_texture
	hub = viewer.hub
	nums = [
		C.call("gfx.wad:NUM_0"),
		C.call("gfx.wad:NUM_1"),
		C.call("gfx.wad:NUM_2"),
		C.call("gfx.wad:NUM_3"),
		C.call("gfx.wad:NUM_4"),
		C.call("gfx.wad:NUM_5"),
		C.call("gfx.wad:NUM_6"),
		C.call("gfx.wad:NUM_7"),
		C.call("gfx.wad:NUM_8"),
		C.call("gfx.wad:NUM_9")
	]
	anums = [
		C.call("gfx.wad:ANUM_0"),
		C.call("gfx.wad:ANUM_1"),
		C.call("gfx.wad:ANUM_2"),
		C.call("gfx.wad:ANUM_3"),
		C.call("gfx.wad:ANUM_4"),
		C.call("gfx.wad:ANUM_5"),
		C.call("gfx.wad:ANUM_6"),
		C.call("gfx.wad:ANUM_7"),
		C.call("gfx.wad:ANUM_8"),
		C.call("gfx.wad:ANUM_9")
	]
	faces = [
		C.call("gfx.wad:FACE1"),
		C.call("gfx.wad:FACE2"),
		C.call("gfx.wad:FACE3"),
		C.call("gfx.wad:FACE4"),
		C.call("gfx.wad:FACE5")
	]
