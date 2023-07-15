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
# Properties defaults:
const LIP : int = 8
const WAIT : int = 3
const SPEED : int = 100
const DMG : int = 2

const TRIGGER_PADDING : Vector3 = Vector3(1.8, 0.25, 1.8)

# 0: "Silent"
# 1: "Stone"
# 2: "Machine"
# 3: "Stone Chain"
# 4: "Screechy Metal"
const audio_paths := [
	['misc/null.wav', 'misc/null.wav'],
	['doors/drclos4.wav', 'doors/doormv1.wav'],
	['doors/hydro1.wav', 'doors/hydro2.wav'],
	['doors/stndr1.wav', 'doors/stndr2.wav'],
	['doors/ddoor1.wav', 'doors/ddoor2.wav']
]

const keys_audio_paths := [
	['doors/medtry.wav', 'doors/meduse.wav'],
	['doors/runetry.wav', 'doors/runeuse.wav'],
	['doors/basetry.wav', 'doors/baseuse.wav'],
]

# 0 : "Medieval"
# 1 : "Metal (runic)"
# 2 : "Base"
const gold_keys_message = [
	"You need the gold key",
	"You need the gold runekey",
	"You need the gold keycard"
]
const silver_key_message = [
	"You need the silver key",
	"You need the silver runekey",
	"You need the silver keycard"
]

var tween : Tween
var add : Vector3
var dura : float
var wait : int
var calc_ : bool = false
var noise_door : Array
var noise_key : Array
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


func _map_ready() :
	init_pos = position
	add_to_group(&'doors')
	_gen_aabb()
	_calc_add()
	_get_sounds()
	_calc_anim_pos()
	
	
func _entities_ready() : 
	_set_primary()


func _doors_ready() :
	if is_in_group(&'primary_doors') and not props.has(&'targetname') : 
		_create_primary_trigger()
	if _flag(START_OPEN) : _open_direct()


func _add_link(n : QmapbspQuakeFunctionDoor) :
	if n == self : return
	if links.has(n) : return
	
	links.append(n)


func _calc_add() :
	if !calc_ :
		calc_ = true
		
		if not _flag(DONT_LINK) :
			# find doors to try and link
			for n in get_tree().get_nodes_in_group(&'doors') :
				n._calc_add()
				if n._flag(DONT_LINK) : continue
				# check if doors are touching
				if (
					aabb.size.x >= 0 and aabb.size.y >= 0 and
					n.aabb.size.x >= 0 and n.aabb.size.y >= 0
				) :
					if aabb.grow(0.01).intersects(n.aabb) :
						_add_link(n)
						n._add_link(self)
		
		viewer = get_meta(&'viewer')
		var angle : int = _prop(&'angle', 0)
		var s : float = get_meta(&'scale', 32.0)
		wait = _prop(&'wait', WAIT)
		var lip : float = _prop(&'lip', LIP) / s
		if angle == -1 :
			add = Vector3(0.0, aabb.size.y - lip, 0.0)
		elif angle == -2 :
			add = Vector3(0.0, -aabb.size.y + lip, 0.0)
		else :
			var rot := (angle / 180.0) * PI
			var dir := Vector3(aabb.size.x, 0.0, aabb.size.z)
			var lip_v := Vector3(lip, 0.0, lip)
			add = Vector3.BACK.rotated(Vector3.UP, rot) * (-dir + lip_v)
		dura = add.length() / (_prop(&'speed', SPEED) / s)


func _calc_anim_pos() :
	if _flag(START_OPEN) :
		open_pos = init_pos + add
		close_pos = init_pos
	else :
		open_pos = init_pos + add
		close_pos = init_pos 
		
		
func _set_primary() :
	if has_meta(&'primary') : return
	if _requires_key() : return
	
	var make_primary : bool = true
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
	var t_pad = TRIGGER_PADDING
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
	var t_pad = TRIGGER_PADDING
	var t_pos : Vector3 = m_aabb.position - t_pad
	var t_end : Vector3 = m_aabb.end + t_pad
	# update shape size and position
	var col = trigger.get_node_or_null('col_shape')
	if col : 
		col.shape.size = (t_end - t_pos).abs()
		col.set_position(m_aabb.get_center())
		
		
func _is_blocked() -> bool :
	# check if player has not exited the trigger area
	if trigger and trigger.blocked : return true
	else :
		for l in links :
			if l.trigger and l.trigger.blocked : return true
	return false
		
		
func _trigger(b : Node3D) :
	if tween : return
	
	# TODO: check player for key
	if _requires_key() :
		# doors that require keys, stay open
		if open : return
		else :
			_play_snd(&'key_try')
			_show_key_message()
		return
	
	_move_toggle()
	for l in links : l._trigger(b)
		
		
func _trigger_exit(b : Node3D) :
	if tween : return
	if _requires_key() : return
	
	if not _flag(TOGGLE) and wait > 0 :
		_move_close()
		for l in links : l._trigger_exit(b)
	
	
func _move_open() :
	if tween : return
	if open : return
	
	tween = create_tween()
	tween.tween_callback(_play_snd.bind(&'door_loop'))
	tween.tween_property(self, ^'position', open_pos, dura)
	tween.tween_callback(_play_snd.bind(&'door_impulse'))
	if not _flag(START_OPEN) : tween.tween_interval(wait) # wait after animation
	tween.finished.connect(_move_end)
	
	open = true


func _move_close() :
	if tween : return
	if not open : return
	if _is_blocked() : return
	if not _flag(START_OPEN) and wait == -1 : return # stay open

	tween = create_tween()
	tween.tween_callback(_play_snd.bind(&'door_loop'))
	tween.tween_property(self, ^'position', close_pos, dura)
	tween.tween_callback(_play_snd.bind(&'door_impulse'))
	if _flag(START_OPEN) : tween.tween_interval(wait) # wait after animation
	tween.finished.connect(_move_end)
	
	open = false


func _move_toggle() :
	if open : _move_close()
	else : _move_open()


func _move_end() :
	tween.kill()
	tween = null
	
	if wait == -1 : return # stay open
	if _is_blocked() : return
	if _flag(TOGGLE) : return
	
	if _flag(START_OPEN) : 
		if not open : _move_open()
	elif open : _move_close()


func _open_direct() :
	position += add
	init_pos = position
	open = true


func _player_touch(p : QmapbspQuakePlayer, pos : Vector3, nor : Vector3) :
	var can_trigger : bool = true
	if props.has(&'targetname') : can_trigger = false
	if props.has(&'message') : 
		if not _prop(&'message', '').is_empty(): 
			emit_message_once.emit(_prop(&'message', ''))
	
	for l in links :
		if l.props.has(&'targetname') : can_trigger = false
		if l.props.has(&'message') :
			if not _prop(&'message', '').is_empty(): 
				l.emit_message_once.emit(l._prop(&'message', ''))
	
	if can_trigger : _trigger(p)


func _requires_key() -> bool :
	return _requires_silver_key() or _requires_gold_key()


func _requires_silver_key() -> bool :
	return _flag(SILVER_KEY)


func _requires_gold_key() -> bool :
	return _flag(GOLD_KEY)


func _show_key_message() -> void :
	var world_idx : int = viewer.worldspawn.props.get(&'worldtype', 0)
	if _requires_gold_key() : 
		emit_message_once.emit(gold_keys_message[world_idx])
	elif _requires_silver_key() : 
		emit_message_once.emit(silver_key_message[world_idx])


func _get_sounds() :
	var world_idx : int = viewer.worldspawn.props.get(&'worldtype', 0)
	var noise_idx : int = _prop(&'sounds', 0)

	noise_key = keys_audio_paths[world_idx]
	noise_door = audio_paths[noise_idx]


func _make_player() :
	player = AudioStreamPlayer3D.new()
	add_child(player)


func _play_snd(sname : StringName) :
	if !player : _make_player()
	player.stop()
	var audio_path : String
	match sname :
		&'door_impulse' : audio_path = noise_door[1]
		&'door_loop' : audio_path = noise_door[0]
		&'key_try' : audio_path = noise_key[0]
		&'key_use' : audio_path = noise_key[1]
	player.stream = viewer.hub.load_audio(audio_path)
	player.play()
