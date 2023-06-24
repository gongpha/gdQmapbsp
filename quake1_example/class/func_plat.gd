extends QmapbspQuakeFunctionDoor
class_name QmapbspQuakeFunctionPlat
# FIXME: platforms need to automatically return to previous position after move end, not toggle or wait -1

func _def_speed() -> String : return '150'
func _def_lip() -> String : return '-8' # >O_O<
func _no_linking() -> bool : return false
func _get_angle() -> int : return -1
func _can_create_trigger() -> bool : return true
func _get_trigger_padding() -> Vector3 : return Vector3(-0.75, -0.5, -0.75)


func _gen_aabb() :
	var height : int = props.get('height', '0').to_int()
	if height == 0 : super()
	else : aabb.size.y = height
	aabb.size.y *= -1
	
	
func _set_primary_trigger_position(col : CollisionShape3D, aabb: AABB) :
	super(col, aabb)
	col.position.y -= aabb.size.y
	
	
func _player_touch(p : QmapbspQuakePlayer, pos : Vector3, nor : Vector3) :
	if not open and _touch_horizontal(nor) :
		_trigger(p)


func _trigger(b : Node3D) :
	if is_in_group(&'primary_doors') : _create_primary_trigger()
	super(b)


func _move_end(destroy_tween : bool = false) :
	super(true)

		
func _starts_open() :
	_open_direct()

	




