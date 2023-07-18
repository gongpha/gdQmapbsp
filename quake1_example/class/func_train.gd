extends QmapbspQuakeFunctionBrush
class_name QmapbspQuakeFunctionTrain

# Properties defaults:
const SPEED : int = 100 # Speed (units per second)
const DMG : int = 2 # Damage on block
const SOUND : int = 1

const SOUND_LOOP_IDX : int = 0
const SOUND_IMP_IDX : int = 1 # impulse / non-loop

# 0: "Silent"
# 1: "Ratchet Metal"
const audio_paths := [
	['misc/null.wav', 'misc/null.wav'],
	['plats/train1.wav', 'plats/train2.wav']
]

var tween : Tween
var curve : Curve3D
var corner : Vector3
var player : AudioStreamPlayer3D
var streams : Array


func _map_ready() :
	_gen_aabb()
	_calc_corner()
	_after_map_ready.call_deferred()


func _calc_corner() :
	# path is aligned with brush corner
	corner = aabb.size / 2.0
#	corner.x = -corner.x


func _after_map_ready() :
	if not props.has('target') : 
		printerr('Platform missing target!')
		return

	var path : Node = get_tree().get_first_node_in_group(
		'T_' + props.get('target')
	)
	
	if path is QmapbspQuakePathCorner :
		curve = path.curve
		if curve and curve.point_count > 0 :
			position = curve.get_point_position(0) + corner


func _trigger(b : Node3D) :
	if curve == null : return
	_start(curve)


func _start(c : Curve3D) :
	if tween : return
	
	tween = create_tween()
	tween.tween_callback(_play_snd.bind(SOUND_IMP_IDX))
	
	var s : float = get_meta(&'scale', 32.0)
	var target_pos := position # initial position
	for i in c.point_count :
		if i == 0 : continue
		
		var next_pos := c.get_point_position(i)
		var speed : float = _prop('speed', SPEED) / s
		var dura : float = target_pos.distance_to(next_pos) / speed
		tween.tween_callback(_play_snd.bind(SOUND_LOOP_IDX))
		tween.tween_property(self, ^'position', next_pos + corner, dura)
		target_pos = next_pos # set next position
	
	tween.tween_callback(_play_snd.bind(SOUND_IMP_IDX))


func _get_sounds() :
	var sounds : int = _prop('sounds', SOUND)
	streams = audio_paths[sounds]
	

func _make_player() :
	player = AudioStreamPlayer3D.new()
	add_child(player)


func _play_snd(path : String) :
	if not player : _make_player()
	player.stop()
	player.stream = get_meta(&'viewer').hub.load_audio(path)
	player.play()
