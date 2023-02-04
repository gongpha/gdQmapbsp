extends QmapbspQuakeFunctionBrush
class_name QmapbspQuakeFunctionTrain

var tween : Tween
var curve : Curve3D
var corner : Vector3

var player : AudioStreamPlayer3D
var player_end := false

func _make_player() :
	if !player :
		player = AudioStreamPlayer3D.new()
		player.finished.connect(_audf)
		add_child(player)
		
func _audf() :
	if player_end :
		player.queue_free()
		player = null
	else :
		_make_player()
		player.play()
		
func _play_snd(path : String) :
	_make_player()
	player.stream = get_meta(&'viewer').hub.load_audio(path)
	player.play()

func _map_ready() :
	_after_map_ready.call_deferred()
	
func _after_map_ready() :
	var path : Node = get_tree().get_first_node_in_group(
		'T_' + props.get('target')
	)
	
	if path is QmapbspQuakePathCorner :
		curve = path.curve
		_gen_aabb()
		if curve and curve.point_count > 0 :
			corner = aabb.size / 2.0
			corner.x = -corner.x
			position = curve.get_point_position(0) + corner

func _trigger(b : Node3D) :
	if curve == null : return
	_start(curve)
		
func _start(c : Curve3D) :
	if tween : return
	var s : float = get_meta(&'scale', 32.0)
	tween = create_tween()
	tween.finished.connect(_f)
	var poscursor := position
	for i in c.point_count :
		if i == 0 : continue
		
		var nextpos := c.get_point_position(i)
		var dura : float = (
			poscursor.distance_to(nextpos)
		) / (props.get('speed', '64').to_int() / s)
		poscursor = nextpos
		tween.tween_property(self, ^'position',
			nextpos + corner,
			dura
		)
	player_end = false
	_play_snd('plats/train1.wav')

func _f() :
	player_end = true
	_play_snd('plats/train2.wav')
