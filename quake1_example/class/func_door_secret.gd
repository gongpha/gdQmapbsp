extends QmapbspQuakeFunctionBrush
class_name QmapbspQuakeFunctionDoorSecret

# Spawnflags:
# 1 = Open once
# 2 = Move left first
# 4 = Move down first
# 8 = Not shootable
# 16 = Always shootable
const OPEN_ONCE : int = 1; # stays open
const MOVE_LEFT_FIRST : int = 2; # 1st move is left of arrow
const MOVE_DOWN_FIRST : int = 4; # 1st move is down from arrow
const NO_SHOOT : int = 8; # only opened by trigger
const ALWAYS_SHOOT : int = 16; # shootable even if targeted

var tween : Tween
var add : Vector3
var add_reveal : Vector3
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
		
const audio_paths_secret := [
	['doors/basesec2.wav', 'doors/basesec1.wav', 'doors/basesec2.wav'],
	['doors/latch2.wav', 'doors/winch2.wav', 'doors/drclos4.wav'],
	['doors/airdoor2.wav', 'doors/airdoor1.wav', 'doors/airdoor2.wav'],
	['doors/basesec2.wav', 'doors/basesec1.wav', 'doors/basesec2.wav'],
]

func _def_lip() -> String : return '0'
func _def_wait() -> String : return '3'
func _def_speed() -> String : return '100'

func _starts_open() -> bool : return false
func _get_sound_index_loop() -> int : return 1
func _get_sound_index_motion_end() -> int : return 2


func _map_ready() :
	init_pos = position
	add_to_group(&'secret_doors')
	_calc_add()
	_calc_anim_pos()
	if _flag(OPEN_ONCE) :
		wait = -1.0

func _get_sounds(sounds : int) :
	streams = audio_paths_secret[sounds]


func _move_pre(tween : Tween) -> Vector3 :
	if open : return close_pos
	else : return open_pos


func _get_angle() -> int :
	return props.get('angle', 0)


# TODO: fix sound
# TODO: fix cases where spawnflag is "move down" or "move left" first
func _move() :
	if tween : return

	tween = create_tween()
	var target_pos : Vector3 = _move_pre(tween)
	if open :
		# anim step 1
		tween.tween_property(self, ^'position',
			close_pos + add_reveal, dura
		)
		tween.tween_interval(1) # approx
		# anim step 2
		tween.tween_property(self, ^'position',
			target_pos, 0.5 # approx
		)
		if wait > 0 : tween.tween_interval(wait)
		tween.finished.connect(_move_end)
	else :
		# anim step 1
		tween.tween_property(self, ^'position',
			close_pos + add_reveal, 0.5 # approx
		)
		tween.tween_interval(1) # approx
		# anim step 2
		tween.tween_property(self, ^'position',
			target_pos + add_reveal, dura
		)
		if wait > 0 : tween.tween_interval(wait)
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
	
	
func _calc_add() :
	if !calc_ :
		calc_ = true
		
		_gen_aabb()
		
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
			var dir := Vector3(aabb.size.x, 0.0, aabb.size.z)
			var lip_v := Vector3(lip, 0.0, lip)
			add = Vector3.BACK.rotated(Vector3.UP, rot) * (-dir + lip_v)
			add_reveal = Vector3.RIGHT.rotated(Vector3.UP, rot) * dir
			if _flag(MOVE_LEFT_FIRST) :
				add_reveal = Vector3.LEFT.rotated(Vector3.UP, rot) * dir
			if _flag(MOVE_DOWN_FIRST) :
				# TODO: find example of where this is used to verify
				add_reveal = Vector3.DOWN.rotated(Vector3.UP, rot) * dir
		dura = add.length() / (props.get('speed', _def_speed()).to_int() / s)
		
		var sounds : int = clampi(props.get('sounds', '0').to_int(), 0, 5)
		_get_sounds(sounds)


func _calc_anim_pos() :
	if _starts_open() :
		open_pos = position + add
		close_pos = init_pos
	else :
		open_pos = position + add
		close_pos = position 


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


func _player_touch(p : QmapbspQuakePlayer, pos : Vector3, nor : Vector3) :
	if props.has(&'targetname') : return
	if not open : _trigger(p)
	
	
func _trigger(b : Node3D) :
	if tween : return
	_move()
