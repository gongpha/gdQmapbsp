extends QmapbspQuakeFunctionBrush
class_name QmapbspQuakeFunctionPlat

# Spawnflags:
# 1 = Low trigger volume
const PLAT_LOW_TRIGGER : int = 1;
# Properties defaults
const SPEED : int = 150
const HEIGHT : int = 0 # Travel altitude (can be negative)
const WAIT : int = 3
const LIP : int = -8
const ANGLE : int = -1 # not used, hardcoded to go up and down
const TRIGGER_PADDING : Vector3 = Vector3(-0.75, 0, -0.75)
const SOUND : int = 2
const SOUND_LOOP_IDX : int = 0
const SOUND_IMP_IDX : int = 1

# 0: "None"
# 1: "Base fast"
# 2: "Chain Slow"
const audio_paths := [
	['misc/null.wav', 'misc/null.wav'],
	['plats/plat1.wav', 'plats/plat2.wav'],
	['plats/medplat1.wav', 'plats/medplat2.wav']
]

var tween : Tween
var height_add : Vector3
var dura : float
var wait : int
var streams : Array
var viewer : QmapbspQuakeViewer
var open : bool = false
var open_pos : Vector3
var close_pos : Vector3
var init_pos : Vector3

var player : AudioStreamPlayer3D
var links : Array[QmapbspQuakeFunctionDoor]
var trigger : QmapbspQuakeTrigger
var low_trigger_height : float = 0.25

signal emit_message_once(m : String)


func _map_ready() :
	viewer = get_meta(&'viewer')
	wait = _prop('wait', WAIT)
	init_pos = position
	add_to_group(&'plat')
	_gen_aabb()
	_calc_add()
	_calc_dura()
	_get_sounds()
	if !props.has('targetname') : 
		_create_trigger()
		_start_open()
	_calc_anim_pos()


func _get_scale() -> float :
	return get_meta(&'scale', 32.0)
	

func _get_lip() -> float :
	return _prop('lip', LIP) / _get_scale()


func _get_height() -> float :
	var height : float
	if props.has('height') : 
		height = _prop('height', HEIGHT) / _get_scale()
	else :
		height = aabb.size.y + _get_lip()
	return height


func _calc_add() :
	height_add = Vector3(0.0, _get_height(), 0.0)


func _calc_dura() :
	dura = height_add.length() / (_prop('speed', SPEED) / _get_scale())


func _create_trigger() :
	if trigger : return
	
	# self setup
	if not props.has('targetname') : props['targetname'] = name
	add_to_group('T_' + props['targetname'])
	# create trigger
	trigger = QmapbspQuakeTriggerMultiple.new()
	trigger.name = &'trigger_%s' % name
	trigger.set_meta(&'viewer', viewer)
	trigger.set_meta(&'scale', get_meta("scale"))
	trigger._get_properties({ "target": props['targetname'] })
	# add trigger to scene
	get_parent().add_child(trigger)
	# create trigger collision shape
	var col = CollisionShape3D.new()
	col.name = &'col_shape'
	col.shape = BoxShape3D.new()
	var t_pad = TRIGGER_PADDING
	var t_pos : Vector3 = aabb.position - t_pad
	var t_end : Vector3 = aabb.end + t_pad
	col.shape.size = (t_end - t_pos).abs()
	if _flag(PLAT_LOW_TRIGGER) :
		col.shape.size.y = low_trigger_height
	_set_trigger_position(col, aabb)
	# add collision shape to trigger
	trigger.add_child(col)


func _set_trigger_position(col : CollisionShape3D, aabb: AABB) :
	col.set_position(aabb.get_center())
	if _flag(PLAT_LOW_TRIGGER) :
		col.position.y -= height_add.y - aabb.size.y/2 - low_trigger_height/2
	else :
		col.position.y -= height_add.y - aabb.size.y


func _is_blocked() -> bool :
	# check if player has not exited the trigger area
	if trigger and trigger.blocked : return true
	else :
		for l in links :
			if l.trigger and l.trigger.blocked : return true
	return false


func _start_open() :
	position -= height_add
	init_pos = position
	open = true
	

func _calc_anim_pos() :
	open_pos = init_pos - height_add
	close_pos = init_pos


func _move_up() :
	if tween : return
	if not open : return
	
	tween = create_tween()
	tween.tween_callback(_play_snd.bind(SOUND_LOOP_IDX, true))
	tween.tween_property(self, ^'position', close_pos, dura)
	tween.tween_callback(_play_snd.bind(SOUND_IMP_IDX, true))
	tween.finished.connect(_move_end)
	
	open = false
	
	
func _move_down() :
	if tween : return
	if open : return
	
	tween = create_tween()
	if wait > 0 : tween.tween_interval(wait) # pause before going down
	tween.tween_callback(_play_snd.bind(SOUND_LOOP_IDX, true))
	tween.tween_property(self, ^'position', open_pos, dura)
	tween.tween_callback(_play_snd.bind(SOUND_IMP_IDX, true))
	tween.finished.connect(_move_end)
	
	open = true


func _move_end() :
	if tween :
		tween.kill()
		tween = null
	
	if wait == -1 : return # stay open
	
	if not _is_blocked() and not open : _move_down()


func _move_toggle() :
	if open : _move_up()
	else : _move_down()


func _trigger(b : Node3D) :
	if not trigger : _create_trigger()
	_move_toggle()


func _trigger_exit(b : Node3D) :
	_move_down()


func _player_touch(p : QmapbspQuakePlayer, pos : Vector3, nor : Vector3) :
	# if sides of plat were touched, trigger
	if not open and _touch_vertical(nor) : _trigger(p)


func _get_sounds() :
	var sounds : int = _prop('sounds', SOUND)
	streams = audio_paths[sounds]


func _make_player() :
	player = AudioStreamPlayer3D.new()
	add_child(player)


func _play_snd(idx : int, interrupt : bool = false) :
	if not player : _make_player()
	if player.is_playing() and not interrupt : return
	var s : String = streams[idx]
	if s.is_empty() : return
	player.stream = viewer.hub.load_audio(s)
	player.play()
