extends QmapbspQuakeFunctionBrush
class_name QmapbspQuakeFunctionPlat

# Spawnflags:
# 1 = Low trigger volume
const PLAT_LOW_TRIGGER : int = 1;

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

func _def_wait() -> String : return '3'
func _def_speed() -> String : return '150'
func _def_lip() -> String : return '-8' # >O_O<

func _get_angle() -> int : return -1
func _get_trigger_padding() -> Vector3 : return Vector3(-0.75, 0, -0.75)
func _get_sound_index_loop() -> int : return 0
func _get_sound_index_motion_end() -> int : return 1


func _map_ready() :
	viewer = get_meta(&'viewer')
	wait = props.get(&'wait', _def_wait()).to_int()
	init_pos = position
	add_to_group(&'plat')
	_gen_aabb()
	_calc_add()
	_calc_dura()
	_create_trigger()
	_starts_open()
	_calc_anim_pos()
	# TODO: make sounds less worse
	var sounds : int = clampi(props.get(&'sounds', '0').to_int(), 0, 5)
	_get_sounds(sounds)


func _get_scale() -> float :
	return get_meta(&'scale', 32.0)
	

func _get_lip() -> float :
	return props.get(&'lip', _def_lip()).to_int() / _get_scale()


func _get_height() -> float :
	var height : float
	if props.has(&'height') : 
		height = props.get(&'height', '0').to_int() / _get_scale()
	else :
		height = aabb.size.y + _get_lip()
	return height


func _calc_add() :
	add = Vector3(0.0, _get_height(), 0.0)


func _calc_dura() :
	dura = add.length() / (props.get(&'speed', _def_speed()).to_int() / _get_scale())


# TODO: for targeted plats only create trigger after target has been activated
func _create_trigger() :
	if trigger : return
	
	# self setup
	if not props.has(&'targetname') : props[&'targetname'] = name
	add_to_group('T_' + props['targetname'])
	# create trigger
	trigger = QmapbspQuakeTriggerMultiple.new()
	trigger.name = &'trigger_%s' % name
	trigger.set_meta(&'viewer', viewer)
	trigger.set_meta(&'scale', get_meta("scale"))
	trigger._get_properties({ "target": props[&'targetname'] })
	# add trigger to scene
	get_parent().add_child(trigger)
	# create trigger collision shape
	var col = CollisionShape3D.new()
	col.name = &'col_shape'
	col.shape = BoxShape3D.new()
	var t_pad = _get_trigger_padding()
	var t_pos : Vector3 = aabb.position - t_pad
	var t_end : Vector3 = aabb.end + t_pad
	col.shape.size = (t_end - t_pos).abs()
	_set_trigger_position(col, aabb)
	# add collision shape to trigger
	trigger.add_child(col)


func _set_trigger_position(col : CollisionShape3D, aabb: AABB) :
	col.set_position(aabb.get_center())
	if props.has(&'height') :
		col.position.y -= add.y - aabb.size.y
	else :
		col.position.y -= _get_lip()


func _starts_open() :
	# TODO: if targetname set, it should start at top (extended)
	# otherwise start at bottom
	_open_direct()


func _open_direct() :
	position -= add
	init_pos = position
	open = true
	

func _calc_anim_pos() :
	open_pos = init_pos - add
	close_pos = init_pos


func _target_pos() -> Vector3 : 
	if open : return close_pos
	else : return open_pos


func _move() :
	if tween : return
	
	tween = create_tween()
	var target_pos : Vector3 = _target_pos() 
	tween.tween_property(self, ^'position',
		target_pos, dura
	)
	if open : tween.tween_interval(wait)
	tween.finished.connect(_move_end)
	
	# sound
	player_end = true
	_play_snd(_get_sound_index_loop())
	
	open = !open


func _move_end() :
	tween.kill()
	tween = null
	
	# sound
	# TODO: change sound played based on tob or bottom position
	player_end = true
	_play_snd(_get_sound_index_motion_end())
	
	if wait == -1 : return # permanently open
	
	# close
	# TODO: check if player is still inside the trigger
	if not open : _move()


func _player_touch(p : QmapbspQuakePlayer, pos : Vector3, nor : Vector3) :
	_trigger(p)


func _get_sounds(sounds : int) :
	if sounds == 5 :
		streams = func_door[
			viewer.worldspawn.props.get(&'worldtype', ['', '']) % 3
		]
	else :
		streams = audio_paths[sounds]


func _trigger(b : Node3D) :
	_create_trigger()
	if not tween : _move()


func _trigger_off(b : Node3D) :
	# TODO: connect this to area that will trigger it when trigger is exited
	# use to set `player_on = false`
	pass


func _make_player() :
	if !player :
		player = AudioStreamPlayer3D.new()
		player.finished.connect(_audf)
		add_child(player)


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



