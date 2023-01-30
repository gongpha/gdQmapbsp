extends QmapbspQuakeFunctionBrush
class_name QmapbspQuakeFunctionDoor

var tween : Tween
var aabb : AABB
var add : Vector3
var dura : float
var wait : int
var calc_ : bool = false
var streams : Array
var viewer : QmapbspQuakeViewer

var player : AudioStreamPlayer3D
var player_end : bool = false

# according to the QC file
var audio_paths := [
	['misc/null.wav', 'misc/null.wav'],
	['doors/drclos4.wav', 'doors/doormv1.wav'],
	['doors/hydro1.wav', 'doors/hydro2.wav'],
	['doors/stndr1.wav', 'doors/stndr2.wav'],
	['doors/ddoor1.wav', 'doors/ddoor2.wav'],
	['misc/null.wav', 'misc/null.wav'],
]

var func_door := [
	['doors/medtry.wav', 'doors/meduse.wav'],
	['doors/runetry.wav', 'doors/runeuse.wav'],
	['doors/basetry.wav', 'doors/baseuse.wav'],
]

func _calc_add() :
	if !calc_ :
		for m in get_children() :
			if m is GeometryInstance3D :
				aabb = aabb.merge(m.get_aabb())
		
		viewer = get_meta(&'viewer')
		var angle : int = props.get('angle', 0)
		var s : float = get_meta(&'scale', 32.0)
		wait = props.get('wait', '-1').to_int()
		var lip : float = props.get('lip', '8').to_int() / s
		
		if angle == -1 :
			add = Vector3(0.0, aabb.size.y - lip, 0.0)
		elif angle == -2 :
			add = Vector3(0.0, -aabb.size.y + lip, 0.0)
		else :
			add = Vector3(-aabb.size.z + lip, 0.0, 0.0).rotated(
				Vector3.UP, (angle / 180.0) * PI
			)
		dura = add.length() / (props.get('speed', '64').to_int() / s)
		
		var sounds : int = clamp(props.get('sounds', '0').to_int(), 0, 5)
		if sounds == 5 :
			streams = func_door[
				viewer.worldspawn.props.get("worldtype", ['', '']) % 3
			]
		else :
			streams = audio_paths[sounds]
		
		calc_ = true
		
func _trigger(b : Node3D) :
	if tween : return
	
	_calc_add()
	player_end = false
	tween = create_tween()
	tween.tween_property(self, ^'position',
		position + add, dura
	).finished.connect(_motion_f)
	
	if !player :
		player = AudioStreamPlayer3D.new()
		player.finished.connect(_audf)
		add_child(player)
		
	player.stream = viewer.hub.load_audio(streams[0])
	player.play()
	
	if wait != -1 :
		tween.tween_interval(wait)
		tween.finished.connect(_close)

func _motion_f() :
	player_end = true
	player.stream = viewer.hub.load_audio(streams[1])
	player.play()
	
func _audf() :
	if player_end :
		player.queue_free()
	else :
		player.play()

func _close() :
	_calc_add()
	player_end = false
	tween = create_tween()
	tween.tween_property(self, ^'position',
		position - add, dura
	)
