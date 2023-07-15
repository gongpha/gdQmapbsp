extends Area3D
class_name QmapbspQuakeClipProxyArea

func set_area(a : Area3D) -> void :
	area_entered.connect(func(b) : a.area_entered.emit(b))
	area_exited.connect(func(b) : a.area_exited.emit(b))
	area_shape_entered.connect(func(b,c,d,e) : a.area_shape_entered.emit(b,c,d,e))
	area_shape_exited.connect(func(b,c,d,e) : a.area_shape_exited.emit(b,c,d,e))
	
	body_entered.connect(func(b) : a.body_entered.emit(b))
	body_exited.connect(func(b) : a.body_exited.emit(b))
	body_shape_entered.connect(func(b,c,d,e) : a.body_shape_entered.emit(b,c,d,e))
	body_shape_exited.connect(func(b,c,d,e) : a.body_shape_exited.emit(b,c,d,e))
