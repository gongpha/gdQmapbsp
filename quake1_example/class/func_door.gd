extends QmapbspQuakeFunctionBrush
class_name QmapbspQuakeFunctionDoor

# this is written from scratch. No QuakeC code was applied here
# maybe not accurate to the original approach

# Spawnflags:
# 1 = Starts Open
# 4 = Don't link
# 8 = Gold Key required
# 16 = Silver Key required
# 32 = Toggle
const START_OPEN : int = 1;
const DONT_LINK : int = 4;
const GOLD_KEY : int = 8;
const SILVER_KEY : int = 16;
const TOGGLE : int = 32;

const GOLD_KEY_MESSAGE = 'You require the Gold Key!'
const SILVER_KEY_MESSAGE = 'You require the Silver Key!'

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

# according to the QC file
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

func _def_lip() -> String : return '8'
func _def_wait() -> String : return '3'
func _def_speed() -> String : return '100'

func _get_trigger_padding() -> Vector3 : return Vector3(1.8, 0.25, 1.8)
func _get_sound_index_loop() -> int : return 0
func _get_sound_index_motion_end() -> int : return 1

func _map_ready() :
	init_pos = position
	add_to_group(&'doors')
	_calc_add()
	_calc_anim_pos()
	
	
func _entities_ready() : 
	_set_primary()


func _doors_ready() :
	if is_in_group(&'primary_doors') and not props.has(&'targetname') : 
		_create_primary_trigger()
	if _starts_open() : 
		_open_direct()


func _starts_open() -> bool :
	return _flag(START_OPEN)


func _add_link(n : QmapbspQuakeFunctionDoor) :
	if n == self : return
	if links.has(n) : return
	links.append(n)


func _no_linking() -> bool :
	return _flag(DONT_LINK)


func _get_angle() -> int :
	return props.get('angle', 0)


func _calc_add() :
	if !calc_ :
		calc_ = true
		
		_gen_aabb()
		
		if not _no_linking() :
			# find doors to try and link
			for n in get_tree().get_nodes_in_group(&'doors') :
				n._calc_add()
				if n._no_linking() : continue
				# check if doors are touching
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
	if _starts_open() :
		open_pos = init_pos + add
		close_pos = init_pos
	else :
		open_pos = init_pos + add
		close_pos = init_pos 
		
		
func _set_primary() :
	if has_meta(&'primary') : return
	if _requires_key() : return
	
	var make_primary : bool = true
	var l_targetname : String
	for l in links :
		if l.has_meta(&'primary') : make_primary = false
		if l.props.has(&'targetname') : make_primary = false
	if make_primary : 
		set_meta(&'primary', true)
		add_to_group(&'primary_doors')
		
		
func _create_primary_trigger() :
	if _requires_key() : return
	if trigger : return
	
	# self setup
	if not props.has(&'targetname') : props[&'targetname'] = name
	add_to_group('T_' + props['targetname'])
	# create trigger
	trigger = QmapbspQuakeTriggerMultiple.new()
	trigger.name = &'trigger_%s' % name
	trigger.set_meta(&'viewer', viewer)
	trigger.set_meta(&'scale', get_meta("scale"))
	trigger._get_properties({ 'target': props[&'targetname'] })
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
	_set_primary_trigger_position(col, aabb)
	# add collision shape to trigger
	trigger.add_child(col)
	for l in links :
		# copy message from linked door to primary door
		if !props.has(&'message') and l.props.has(&'message'): 
			props[&'message'] = l.props.get(&'message')
		# grow trigger shape around linked door
		_update_trigger_shape(l, trigger)


func _set_primary_trigger_position(col : CollisionShape3D, aabb: AABB) :
	col.set_position(aabb.get_center())
		
		
func _update_trigger_shape(
	new_door : QmapbspQuakeFunctionDoor, 
	trigger : QmapbspQuakeTriggerMultiple
) :
	# calc new size
	var m_aabb : AABB = aabb.merge(new_door.aabb)
	var t_pad = _get_trigger_padding()
	var t_pos : Vector3 = m_aabb.position - t_pad
	var t_end : Vector3 = m_aabb.end + t_pad
	# update shape size and position
	var col = trigger.get_node_or_null('col_shape')
	if col : 
		col.shape.size = (t_end - t_pos).abs()
		col.set_position(m_aabb.get_center())
		
		
func _get_sounds(sounds : int) :
	if sounds == 5 :
		streams = func_door[
			viewer.worldspawn.props.get('worldtype', ['', '']) % 3
		]
	else :
		streams = audio_paths[sounds]
		
		
func _trigger(b : Node3D) :
	if _requires_gold_key() : emit_message_once.emit(GOLD_KEY_MESSAGE)
	elif _requires_silver_key() : emit_message_once.emit(SILVER_KEY_MESSAGE)
	if _requires_key() : return # TODO: fetch key from player
	if tween : return
	_move()
	for l in links :
		l._trigger(b)
		
		
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


func _move_pre(tween : Tween) -> Vector3 : 
	if open : return close_pos
	else : return open_pos
	

# TODO: check if something is blocking the door before closing
# TODO: apply damage to player if blocking and trying to close door
func _move() :
	if tween : return

	tween = create_tween()
	var target_pos : Vector3 = _move_pre(tween) 
	tween.tween_property(self, ^'position',
		target_pos, dura
	)
	if wait > 0 : # add delay
		if not open and not _starts_open() :
			tween.tween_interval(wait)
		elif open and _starts_open() :
			tween.tween_interval(wait)
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
	
	if wait == -1 : return # permanently open
	
	# close
	# TODO: check if player is still inside the trigger
	if _starts_open() and not open :
		_move()
	elif not _starts_open() and open :
		_move()


func _open_direct() :
#	player_end = false
	position += add
	init_pos = position
	open = true


func _player_touch(p : QmapbspQuakePlayer, pos : Vector3, nor : Vector3) :
	var can_trigger : bool = true
	if props.has(&'targetname') : can_trigger = false
	if props.has('message') : 
		emit_message_once.emit(props['message'])
	
	for l in links :
		if l.props.has(&'targetname') : can_trigger = false
		if l.props.has('message') :
			l.emit_message_once.emit(l.props['message'])
	
	if can_trigger : _trigger(p)


func _requires_key() -> bool :
	return _requires_silver_key() or _requires_gold_key()


func _requires_silver_key() -> bool :
	return _flag(SILVER_KEY)


func _requires_gold_key() -> bool :
	return _flag(GOLD_KEY)
