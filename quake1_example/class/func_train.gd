extends QmapbspQuakeFunctionBrush
class_name QmapbspQuakeFunctionTrain

# Properties defaults:
const SPEED : int = 100 # Speed (units per second)
const DMG : int = 2 # Damage on block
const SOUND : int = 1 # Default sound streams
const SOUND_IMP_IDX : int = 1 # impulse / non-loop
const SOUND_LOOP_IDX : int = 0

# 0: "Silent"
# 1: "Ratchet Metal"
const audio_paths := [
	['misc/null.wav', 'misc/null.wav'],
	['plats/train1.wav', 'plats/train2.wav']
]

var tween : Tween
var paths : Array
var corner : Vector3
var player : AudioStreamPlayer3D
var streams : Array
var viewer : QmapbspQuakeViewer


func _map_ready() :
	viewer = get_meta(&'viewer')
	_gen_aabb()
	_calc_corner()
	_get_sounds()
	_after_map_ready.call_deferred()


func _calc_corner() :
	# path is aligned with brush corner
	corner = aabb.size / 2.0
	corner.x = -corner.x


func _after_map_ready() :
	if not props.has('target') : 
		printerr('Platform missing target!')
		return

	var path : Node = get_tree().get_first_node_in_group(
		'T_' + props.get('target')
	)
	
	if path is QmapbspQuakePathCorner :
		if path.linked and path.linked.size() > 0 :
			paths = path.linked
			var path_corner : QmapbspQuakePathCorner = path.linked[0]
			position = path_corner.position + corner


func _trigger(b : Node3D) :
	if paths == null : return
	_start()


func _start() :
	if tween : return
	
	tween = create_tween()
	
	var s : float = get_meta(&'scale', 32.0)
	var target_pos := position # initial position
	for i in paths.size() :
		if i == 0 : continue # skip first index (already got first position)
		
		var path_corner = paths[i]
		var next_pos : Vector3 = path_corner.position + corner
		var speed : float = _prop('speed', SPEED) / s
		var dura : float = target_pos.distance_to(next_pos) / speed
		tween.tween_callback(_play_snd.bind(SOUND_LOOP_IDX))
		tween.tween_property(self, ^'position', next_pos, dura)
		# set wait time for each path corner
		if path_corner.props.has('wait') : 
			var wait = path_corner.props.get('wait', '0').to_int()
			tween.tween_callback(_play_snd.bind(SOUND_IMP_IDX))
			if wait == -1 : 
				tween.tween_callback(_tween_clear)
			else :
				tween.tween_interval(wait)
				tween.tween_callback(_play_snd.bind(SOUND_LOOP_IDX))
		target_pos = next_pos # set next position
	
	tween.tween_callback(_play_snd.bind(SOUND_IMP_IDX))


func _tween_clear() :
	tween.kill()
	tween = null


func _get_sounds() :
	var sounds : int = _prop('sounds', SOUND)
	streams = audio_paths[sounds]
	

func _make_player() :
	player = AudioStreamPlayer3D.new()
	add_child(player)


func _play_snd(idx : int) :
	if not player : _make_player()
	player.stop()
	var s : String = streams[idx]
	if s.is_empty() : return
	player.stream = viewer.hub.load_audio(s)
	player.play()
