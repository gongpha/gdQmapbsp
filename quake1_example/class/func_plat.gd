extends QmapbspQuakeFunctionDoor
class_name QmapbspQuakeFunctionPlat

func _can_create_trigger() : return true

func _gen_aabb() :
	var height : int = props.get('height', '0').to_int()
	if height == 0 :
		super()
	else :
		aabb.size.y = height
	aabb.size.y *= -1
	
func _def_lip() -> String : return '-8' # >O_O<
func _no_linking() -> bool : return false
func _player_touch(p : QmapbspQuakePlayer, pos : Vector3, nor : Vector3) :
	if open and nor.y > 0.9 :
		_trigger(p)
		
func _motion_f(destroy_tween : bool = false) :
	super(true)
		
func _starts_open() :
	_open_direct()
	
func _get_angle() -> int :
	return -1
	
func _def_speed() -> String : return '150'
