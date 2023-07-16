extends QmapbspQuakeFunctionBrush
class_name QmapbspQuakeFunctionButton

# Properties default:
const SPEED : int = 40
const LIP : int = 4
const WAIT : int = 1
const ANGLE : int = 0

# 0 : "Steam metal"
# 1 : "Wooden clunk"
# 2 : "Metallic clink"
# 3 : "In-out"
const audio_paths := [
	"buttons/airbut1.wav",
	"buttons/switch21.wav",
	"buttons/switch02.wav",
	"buttons/switch04.wav"
]

var tween : Tween
var add : Vector3
var dura : float
var wait : int
var noise : String
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
	add_to_group(&'buttons')
	_gen_aabb()
	_calc_add()
	_calc_anim_pos()
	_get_sounds()


func _calc_add() :
	viewer = get_meta(&'viewer')
	wait = _prop(&'wait', WAIT)
	var s : float = get_meta(&'scale', 32.0)
	var angle : int = _prop(&'angle', ANGLE)
	var speed : int = _prop(&'speed', SPEED) / s
	var lip : float = _prop(&'lip', LIP) / s
	if angle == -1 :
		add = Vector3(0.0, aabb.size.y - lip, 0.0)
	elif angle == -2 :
		add = Vector3(0.0, -aabb.size.y + lip, 0.0)
	else :
		var rot := (angle / 180.0) * PI
		var lip_v := Vector3(lip, lip, lip)
		add = Vector3.BACK.rotated(Vector3.UP, rot) * (aabb.size - (aabb.size + lip_v))
	dura = add.length() / speed


func _calc_anim_pos() :
	open_pos = position + add
	close_pos = position 


func _target_pos() -> Vector3 : 
	if open : return close_pos
	else : return open_pos
	

func _move() :
	if tween : return

	tween = create_tween()
	if not open : tween.tween_callback(_play_snd)
	tween.tween_property(self, ^'position', _target_pos(), dura)
	tween.finished.connect(_move_end)
	if wait > 0 and not open : tween.tween_interval(wait)
	
	open = !open


func _move_end() :
	tween.kill()
	tween = null
	
	if wait == -1 : return # stay open
	
	if open : _move() # close


func _player_touch(p : QmapbspQuakePlayer, pos : Vector3, nor : Vector3) :
	_trigger(p)


func _trigger(b : Node3D) :
	if open and wait == -1 : return
	if tween : return
	
	_move()
	
	var delay : float = _prop(&'delay', 0.0)
	if delay > 0 :
		get_tree().create_timer(delay, false).timeout.connect(
			_trigger_now.bind(b)
		)
	else :
		_trigger_now(b)


func _trigger_now(b: Node3D) :
	if not props.has(&'target') : return
	
	for t in get_tree().get_nodes_in_group(
		'T_' + _prop(&'target', '')
	) :
		if !t : continue
		if !t.has_method(&'_trigger') : continue
		t._trigger(self)


func _get_sounds() :
	noise = audio_paths[_prop(&'sounds', 0)]


func _make_player() :
	player = AudioStreamPlayer3D.new()
	add_child(player)


func _play_snd() :
	if !player : _make_player()
	player.stop()
	if noise.is_empty() : return
	player.stream = viewer.hub.load_audio(noise)
	player.play()
	
