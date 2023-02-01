extends QmapbspQuakeFunctionDoor
class_name QmapbspQuakeFunctionButton

func _motion_f(destroy_tween : bool = false) :
	super(destroy_tween)
	for t in get_tree().get_nodes_in_group(
		'T_' + props.get('target')
	) :
		if !t : continue
		t._trigger(self)

func _def_lip() -> String : return '4'
func _def_wait() -> String : return '1'
func _no_linking() -> bool : return true

func _play_snd(idx : int) :
	if open : super(idx)

func _get_sounds(sounds : int) :
	if sounds == 0 :
		streams = [
			'buttons/airbut1.wav', 'buttons/null.wav'
		]
	else :
		super(sounds)

func _player_touch(p : QmapbspQuakePlayer, pos : Vector3, nor : Vector3) :
	_trigger(p)
