extends QmapbspQuakeFunctionDoor
class_name QmapbspQuakeFunctionPlat
# FIXME: trigger volume needs to extend through the entire travel path of the plat

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
	
func _def_lip() -> String : return '-8' # >O_O<
func _no_linking() -> bool : return false
		
func _motion_f(destroy_tween : bool = false) :
	super(true)
		
func _starts_open() :
	_open_direct()
	
func _get_angle() -> int :
	return -1
	
func _def_speed() -> String : return '150'
