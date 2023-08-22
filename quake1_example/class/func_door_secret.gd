extends QmapbspQuakeFunctionBrush
class_name QmapbspQuakeFunctionDoorSecret

# Spawnflags:
# 1 = Open once
# 2 = Move left first
# 4 = Move down first
# 8 = Not shootable # TODO
# 16 = Always shootable # TODO
const OPEN_ONCE : int = 1; # stays open
const MOVE_LEFT_FIRST : int = 2; # 1st move is left of arrow
const MOVE_DOWN_FIRST : int = 4; # 1st move is down from arrow
const NO_SHOOT : int = 8; # only opened by trigger
const ALWAYS_SHOOT : int = 16; # shootable even if targeted
# Props defaults:
const LIP : int = 0 
const WAIT : int = 5 # Wait before close
const SPEED : int = 50 # hardcoded, not from props
const DMG : int = 2 # Damage when blocked
const ANGLE : int = 0 # Direction of second move
#const T_WIDTH value from aabb # First move length
#const T_LENGTH value from aabb # Second move length
const MESSAGE : String = '' # handled by parent class
const SOUNDS : int = 3 # Default sound set

# 0: "Silent"
# 1: "Medieval"
# 2: "Metal"
# 3: "Base"
const audio_paths := [
	['misc/null.wav', 'misc/null.wav'],
	['doors/latch2.wav', 'doors/winch2.wav', 'doors/drclos4.wav'],
	['doors/airdoor2.wav', 'doors/airdoor1.wav', 'doors/airdoor2.wav'],
	['doors/basesec2.wav', 'doors/basesec1.wav', 'doors/basesec2.wav'],
]
const SOUND_START_IDX : int = 0
const SOUND_LOOP_IDX : int =  1
const SOUND_END_IDX : int = 2

var tween : Tween
var add : Vector3
var add_reveal : Vector3
var dura : float
var wait : int
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


func _map_ready() :
	init_pos = position
	add_to_group(&'secret_doors')
	_gen_aabb()
	_calc_add()
	_get_sounds()
	_calc_anim_pos()
	if _flag(OPEN_ONCE) : wait = -1


func _target_pos() -> Vector3 :
	if open : return close_pos
	else : return open_pos


func _move() :
	if tween : return
	if wait == -1 and open : return

	tween = create_tween()
	if open :
		# anim step 1
		tween.tween_callback(_play_snd.bind(SOUND_START_IDX, true))
		tween.tween_property(self, ^'position',
			close_pos + add_reveal, dura
		)
		tween.tween_interval(1) # approx
		# anim step 2
		tween.tween_callback(_play_snd.bind(SOUND_LOOP_IDX, true))
		tween.tween_property(self, ^'position',
			_target_pos(), 0.5 # approx
		)
		tween.tween_callback(_play_snd.bind(SOUND_END_IDX, true))
		if wait > 0 : tween.tween_interval(wait)
		tween.finished.connect(_move_end)
	else :
		# anim step 1
		tween.tween_callback(_play_snd.bind(SOUND_START_IDX, true))
		tween.tween_property(self, ^'position',
			close_pos + add_reveal, 0.5 # approx
		)
		tween.tween_interval(1) # approx
		# anim step 2
		tween.tween_callback(_play_snd.bind(SOUND_LOOP_IDX, true))
		tween.tween_property(self, ^'position',
			_target_pos() + add_reveal, dura
		)
		tween.tween_callback(_play_snd.bind(SOUND_END_IDX, true))
		if wait > 0 : tween.tween_interval(wait)
		tween.finished.connect(_move_end)
	
	open = !open
	

func _move_end() :
	tween.kill()
	tween = null
	
	if wait == -1 : return # stay open
	
	if open : _move()
	
	
func _calc_add() :
	viewer = get_meta(&'viewer')
	var angle : int = _prop('angle', ANGLE)
	var s : float = get_meta(&'scale', 32.0)
	wait = _prop('wait', WAIT)
	var lip : float = _prop('lip', LIP) / s
	var rot := (angle / 180.0) * PI
	var dir := Vector3(aabb.size.x, 0.0, aabb.size.z)
	var lip_v := Vector3(lip, 0.0, lip)
	add = Vector3.BACK.rotated(Vector3.UP, rot) * (-dir + lip_v)
	add_reveal = Vector3.RIGHT.rotated(Vector3.UP, rot) * dir
	if _flag(MOVE_LEFT_FIRST) :
		add_reveal = Vector3.LEFT.rotated(Vector3.UP, rot) * dir
	if _flag(MOVE_DOWN_FIRST) :
		add_reveal = Vector3.DOWN.rotated(Vector3.UP, rot) * dir
	dura = add_reveal.length() * (SPEED/s)


func _calc_anim_pos() :
	open_pos = position + add
	close_pos = position 
		
		
func _player_touch(p : QmapbspQuakePlayer, pos : Vector3, nor : Vector3) :
	if props.has(&'targetname') : return
	if not open : _trigger(p)
	
	
func _trigger(b : Node3D) :
	if tween : return
	_move()


func _get_sounds() :
	var sounds : int = _prop('sounds', SOUNDS)
	streams = audio_paths[sounds]


func _make_player() :
	player = AudioStreamPlayer3D.new()
	add_child(player)


func _play_snd(idx : int, interrupt : bool = false) :
	if !player : _make_player()
	if player.is_playing() and not interrupt : return
	var s : String = streams[idx]
	if s.is_empty() : return
	player.stream = viewer.hub.load_audio(s)
	player.play()
