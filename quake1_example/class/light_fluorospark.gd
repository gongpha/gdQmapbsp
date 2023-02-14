extends QmapbspQuakeLight
class_name QmapbspQuakeLightFluorospark

func _map_ready() :
	var viewer : QmapbspQuakeViewer = get_meta(&'viewer')
	var aud := AudioStreamPlayer3D.new()
	aud.stream = viewer.hub.load_audio("ambience/buzz1.wav")
	aud.max_distance = 10.0
	aud.finished.connect(func() :
		aud.play()
		)
	add_child(aud)
	aud.play()
