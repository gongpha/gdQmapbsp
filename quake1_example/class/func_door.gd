extends QmapbspQuakeFunctionBrush
class_name QmapbspQuakeFunctionDoor

# this is written from scratch. No QuakeC code was applied here
# maybe not accurate to the original approach

var tween : Tween
var add : Vector3
var dura : float
var wait : int
var calc_ : bool = false
var streams : Array
var viewer : QmapbspQuakeViewer
var open : bool = false

var player : AudioStreamPlayer3D
var player_end : bool = false
var links : Array[QmapbspQuakeFunctionDoor]

signal emit_message_once(m : String)

# according to the QC file
var audio_paths := [
	['misc/null.wav', ''],
	['doors/drclos4.wav', 'doors/doormv1.wav'],
	['doors/hydro1.wav', 'doors/hydro2.wav'],
	['doors/stndr1.wav', 'doors/stndr2.wav'],
	['doors/ddoor1.wav', 'doors/ddoor2.wav'],
	['misc/null.wav', ''],
]

var func_door := [
	['doors/medtry.wav', 'doors/meduse.wav'],
	['doors/runetry.wav', 'doors/runeuse.wav'],
	['doors/basetry.wav', 'doors/baseuse.wav'],
]



func _map_ready() :
	add_to_group(&'doors')
	_calc_add()
	_starts_open()
	
func _starts_open() :
	if props.get('spawnflags', 0) & 0b01 :
		_open_direct()
			
func _add_link(n : QmapbspQuakeFunctionDoor) :
	if n == self : return
	if links.has(n) : return
	links.append(n)
	
func _def_lip() -> String : return '8'
func _def_wait() -> String : return '-1'
func _def_speed() -> String : return '100'

func _no_linking() -> bool :
	return props.get('spawnflags', 0) & 0b100
	
func _get_angle() -> int :
	return props.get('angle', 0)

func _calc_add() :
	if !calc_ :
		calc_ = true
		
		_gen_aabb()
		
		if !(props.get('spawnflags', 0) & 0b100) :
			for n in get_tree().get_nodes_in_group(&'doors') :
				#if n.calc_ : continue
				n._calc_add()
				if _no_linking() :
					continue
					
				if (
					aabb.size.x >= 0 and aabb.size.y >= 0 and
					n.aabb.size.x >= 0 and n.aabb.size.y >= 0
				) :
					if aabb.grow(0.01).intersects(n.aabb) :
						_add_link(n)
						n._add_link(self)
		
		viewer = get_meta(&'viewer')
		var angle : int = _get_angle()
		var s : float = get_meta(&'scale', 32.0)
		wait = props.get('wait', _def_wait()).to_int()
		var lip : float = props.get('lip', _def_lip()).to_int() / s
		
		if angle == -1 :
			add = Vector3(0.0, aabb.size.y - lip, 0.0)
		elif angle == -2 :
			add = Vector3(0.0, -aabb.size.y + lip, 0.0)
		else :
			var rot := (angle / 180.0) * PI
			var dir := -(Vector3(
				aabb.size.x, 0.0, aabb.size.z
			)) + Vector3(lip, 0.0, lip)
			add = Vector3.BACK.rotated(Vector3.UP, rot) * dir
		dura = add.length() / (props.get('speed', _def_speed()).to_int() / s)
		
		var sounds : int = clamp(props.get('sounds', '0').to_int(), 0, 5)
		_get_sounds(sounds)
		
func _get_sounds(sounds : int) :
	if sounds == 5 :
		streams = func_door[
			viewer.worldspawn.props.get("worldtype", ['', '']) % 3
		]
	else :
		streams = audio_paths[sounds]
		
func _trigger(b : Node3D) :
	if tween : return
	_move()
	for l in links :
		l._trigger(b)
		
func _make_player() :
	if !player :
		player = AudioStreamPlayer3D.new()
		player.finished.connect(_audf)
		add_child(player)

func _motion_f(destroy_tween : bool = false) :
	player_end = true
	_play_snd(1)
	if destroy_tween :
		tween.kill()
		tween = null
		
func _play_snd(idx : int) :
	_make_player()
	var s : String = streams[idx]
	if s.is_empty() : return
	player.stream = viewer.hub.load_audio(s)
	player.play()
	
func _audf() :
	if player_end :
		player.queue_free()
		player = null
	else :
		_make_player()
		player.play()

func _move() :
	if open :
		tween = create_tween()
		tween.tween_property(self, ^'position',
			position - add, dura
		).finished.connect(_motion_f.bind(true))
	else :
		tween = create_tween()
		tween.tween_property(self, ^'position',
			position + add, dura
		).finished.connect(_motion_f)
	open = !open
	_play_snd(0)
	player_end = false
	
	if wait != -1 :
		tween.tween_interval(wait)
		tween.finished.connect(_move)

func _open_direct() :
	player_end = false
	position += add
	open = true
	
func _player_touch(p : QmapbspQuakePlayer, pos : Vector3, nor : Vector3) :
	if props.has("targetname") :
		if props.has("message") :
			emit_message_once.emit(props["message"])
		return
	for l in links :
		if l.props.has("targetname") :
			if l.props.has("message") :
				l.emit_message_once.emit(l.props["message"])
			return
	_trigger(p)
