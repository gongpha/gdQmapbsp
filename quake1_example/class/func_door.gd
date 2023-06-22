extends QmapbspQuakeFunctionBrush
class_name QmapbspQuakeFunctionDoor

# this is written from scratch. No QuakeC code was applied here
# maybe not accurate to the original approach

const GOLD_KEY_MESSAGE = 'You require the Gold Key!'
const SILVER_KEY_MESSAGE = 'You require the Silver Key!'

var tween : Tween
var add : Vector3
var add_reveal : Vector3
var dura : float
var wait : int
var calc_ : bool = false
var streams : Array
var viewer : QmapbspQuakeViewer
var open : bool = false

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

func _can_create_trigger() -> bool : return true
func _get_trigger_padding() -> Vector3 : return Vector3(1.8, 0.25, 1.8)

func _map_ready() :
	add_to_group(&'doors')
	_calc_add()
	_starts_open()
	
func _entities_ready() : 
	_set_primary()

func _doors_ready() :
	if is_in_group(&'primary_doors') : _create_primary_trigger()

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
				if n._no_linking() :
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
			add_reveal = Vector3.RIGHT.rotated(Vector3.UP, -rot) * -(Vector3(
				aabb.size.x, 0.0, aabb.size.z
			))
		dura = add.length() / (props.get('speed', _def_speed()).to_int() / s)
		
		var sounds : int = clampi(props.get('sounds', '0').to_int(), 0, 5)
		_get_sounds(sounds)
		
func _set_primary() :
	if !_can_create_trigger() : return
	if has_meta(&'primary') : return
	if props.has(&'targetname') : return
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
	if !_can_create_trigger() : return
	if _requires_key() : return
	if props.has(&'targetname') : return
	if trigger : return
	# self setup
	props["targetname"] = name
	props["message"] = name
	add_to_group('T_' + props['targetname'])
	# create trigger
	trigger = QmapbspQuakeTriggerMultiple.new()
	trigger.name = &'trigger_%s' % name
	trigger.set_meta(&'viewer', viewer)
	trigger.set_meta(&'scale', get_meta("scale"))
	trigger._get_properties({ "target": name })
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
	col.set_position(position)
	# add collision shape to trigger
	trigger.add_child(col)
	for l in links :
		_update_trigger_shape(l, trigger)
		
		
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
			viewer.worldspawn.props.get("worldtype", ['', '']) % 3
		]
	else :
		streams = audio_paths[sounds]
		
func _trigger(b : Node3D) :
	if _requires_gold_key() :
		emit_message_once.emit(GOLD_KEY_MESSAGE)
	elif _requires_silver_key() :
		emit_message_once.emit(SILVER_KEY_MESSAGE)
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
		
func _get_sound_index_loop() -> int : return 0
func _get_sound_index_motion_end() -> int : return 1

func _motion_f(destroy_tween : bool = false) :
	player_end = true
	_play_snd(_get_sound_index_motion_end())
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

func _move_pre(tween : Tween) -> Vector3 : return position

func _move() :
	tween = create_tween()
	
	var basepos := _move_pre(tween)
	
	if open :
		tween.tween_property(self, ^'position',
			basepos - add, dura
		).finished.connect(_motion_f.bind(true))
	else :
		tween.tween_property(self, ^'position',
			basepos + add, dura
		).finished.connect(_motion_f)
	open = !open
	_play_snd(_get_sound_index_loop())
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

func _requires_key() -> bool :
	if (_requires_silver_key() or _requires_gold_key()) : 
		return true
	else:
		return false

func _requires_silver_key() -> bool:
	if (props.get('spawnflags', 0) & 0b10000) : 
		return true
	else:
		return false

func _requires_gold_key() -> bool:
	if (props.get('spawnflags', 0) & 0b1000) : 
		return true
	else:
		return false
