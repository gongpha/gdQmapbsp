extends QmapbspQuakeFunctionBrush
class_name QmapbspQuakeFunctionButton

var tween : Tween
var add : Vector3
var dura : float
var wait : int
var calc_ : bool = false
var streams : Array
var viewer : QmapbspQuakeViewer
var open : bool = false
var open_pos : Vector3
var close_pos : Vector3
var init_pos : Vector3

var player : AudioStreamPlayer3D
var player_end : bool = false
var links : Array[QmapbspQuakeFunctionDoor]
var trigger : QmapbspQuakeTrigger

signal emit_message_once(m : String)

# TODO: update for button sounds
const audio_paths := [
	['', ''],
	['doors/drclos4.wav', 'doors/doormv1.wav'],
	['doors/hydro1.wav', 'doors/hydro2.wav'],
	['doors/stndr1.wav', 'doors/stndr2.wav'],
	['doors/ddoor1.wav', 'doors/ddoor2.wav'],
	['', ''],
]

var func_door := [
	['doors/medtry.wav', 'doors/meduse.wav'],
	['doors/runetry.wav', 'doors/runeuse.wav'],
	['doors/basetry.wav', 'doors/baseuse.wav'],
]

func _def_lip() -> String : return '4'
func _def_wait() -> String : return '1'
func _def_speed() -> String : return '100'

func _get_trigger_padding() -> Vector3 : return Vector3(1.8, 0.25, 1.8)
func _get_sound_index_loop() -> int : return 0
func _get_sound_index_motion_end() -> int : return 1

func _get_angle() -> int : return props.get('angle', 0)

func _map_ready() :
	init_pos = position
	add_to_group(&'buttons')
	_calc_add()
	_calc_anim_pos()


func _calc_add() :
	if !calc_ :
		calc_ = true
		
		_gen_aabb()
		
		viewer = get_meta(&'viewer')
		var angle : int = _get_angle()
		var s : float = get_meta(&'scale', 32.0)
		wait = props.get(&'wait', _def_wait()).to_int()
		var lip : float = props.get(&'lip', _def_lip()).to_int() / s
		if angle == -1 :
			add = Vector3(0.0, aabb.size.y - lip, 0.0)
		elif angle == -2 :
			add = Vector3(0.0, -aabb.size.y + lip, 0.0)
		else :
			var rot := (angle / 180.0) * PI
			var dir := Vector3(aabb.size.x, 0.0, aabb.size.z)
			var lip_v := Vector3(lip, 0.0, lip)
			add = Vector3.BACK.rotated(Vector3.UP, rot) * (-dir + lip_v)
		dura = add.length() / (props.get(&'speed', _def_speed()).to_int() / s)
		
		var sounds : int = clampi(props.get(&'sounds', '0').to_int(), 0, 5)
		_get_sounds(sounds)


func _calc_anim_pos() :
	open_pos = position + add
	close_pos = position 


func _move_pre(tween : Tween) -> Vector3 : 
	if open : return close_pos
	else : return open_pos
	

func _move() :
	if tween : return

	tween = create_tween()
	var target_pos : Vector3 = _move_pre(tween) 
	tween.tween_property(self, ^'position',
		target_pos, dura
	)
	if wait > 0 and not open : tween.tween_interval(wait)
	tween.finished.connect(_move_end)
	
	open = !open
	
	_play_snd(_get_sound_index_loop())
	player_end = true


func _move_end() :
	tween.kill()
	tween = null
	
	# sound
	player_end = true
	_play_snd(_get_sound_index_motion_end())
	
	if wait == -1 : return # stay open
	
	if open : _move() # close


func _player_touch(p : QmapbspQuakePlayer, pos : Vector3, nor : Vector3) :
	_trigger(p)


func _trigger(b : Node3D) :
	if open and wait == -1 : return
	if tween : return
	
	_move()
		
	for t in get_tree().get_nodes_in_group(
		'T_' + props.get('target')
	) :
		if !t : continue
		if !t.has_method(&'_trigger') : continue
		t._trigger(self)
		
		
func _make_player() :
	if !player :
		player = AudioStreamPlayer3D.new()
		player.finished.connect(_audf)
		add_child(player)


func _audf() :
	if player_end :
		player.queue_free()
		player = null
	else :
		_make_player()
		player.play()


func _play_snd(idx : int) :
	if open : 
		_make_player()
		var s : String = streams[idx]
		if s.is_empty() : return
		player.stream = viewer.hub.load_audio(s)
		player.play()
	

func _get_sounds(sounds : int) :
	if sounds == 0 :
		streams = [
			'buttons/airbut1.wav', ''
		]
	else :
		if sounds == 5 :
			streams = func_door[
				viewer.worldspawn.props.get('worldtype', ['', '']) % 3
			]
		else :
			streams = audio_paths[sounds]

