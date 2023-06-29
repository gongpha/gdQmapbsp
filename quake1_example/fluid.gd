extends Area3D
class_name QmapbspQuakeFluidVolume

func damage() -> int : return 1
func liquid_type() -> StringName : return &'water'
func duration() -> float : return 0 # damage effect lasts in seconds

func _ready() :
	set_collision_layer_value(1, false)
	set_collision_layer_value(3, true)
	body_entered.connect(_bo_en)
	body_exited.connect(_bo_ex)
	
func _bo_en(b : Node3D) :
	if b.has_method(&'_fluid_enter') :
		b._fluid_enter(self)
		
func _bo_ex(b : Node3D) :
	if b.has_method(&'_fluid_exit') :
		b._fluid_exit(self)
