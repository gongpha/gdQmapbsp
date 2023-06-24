extends QmapbspQuakeFunctionDoor
class_name QmapbspQuakeFunctionDoorSecret

func _can_create_trigger() : return false

func _starts_open() :
	return
	
func _map_ready() :
	super()
	if props.get('spawnflags', 0) & 0b01 :
		wait = -1.0
		
const audio_paths_secret := [
	['doors/basesec2.wav', 'doors/basesec1.wav', 'doors/basesec2.wav'],
	['doors/latch2.wav', 'doors/winch2.wav', 'doors/drclos4.wav'],
	['doors/airdoor2.wav', 'doors/airdoor1.wav', 'doors/airdoor2.wav'],
	['doors/basesec2.wav', 'doors/basesec1.wav', 'doors/basesec2.wav'],
]

func _reveal() -> bool : return true
func _def_wait() -> String : return '-1'

func _get_sounds(sounds : int) :
	streams = audio_paths_secret[sounds]
	
func _move_pre(tween : Tween) -> Vector3 :
	_play_snd(0)
	tween.tween_property(self, ^'position',
		position + add_reveal, 0.5 # approx
	)
	tween.tween_interval(1) # approx
	return position + add_reveal
	
func _no_linking() -> bool : return true
	
func _get_sound_index_loop() -> int : return 1
func _get_sound_index_motion_end() -> int : return 2

func _player_touch(p : QmapbspQuakePlayer, pos : Vector3, nor : Vector3) :
	if not open : _trigger(p)
