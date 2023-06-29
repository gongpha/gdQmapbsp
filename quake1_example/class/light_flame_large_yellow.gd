extends QmapbspQuakeLight
class_name QmapbspQuakeLightFlameLargeYellow

func _map_ready() -> void :
	var viewer : QmapbspQuakeViewer = get_meta(&'viewer')
	var mdl : QmapbspMDLFile = viewer.hub.load_model("progs/flame2.mdl")
	var mdli := QmapbspMDLInstance.new()
	mdli.mdl = mdl
	mdli.name = &"MODEL"
	add_child(mdli)
	
	var aud := AudioStreamPlayer3D.new()
	aud.stream = viewer.hub.load_audio("ambience/fire1.wav")
	aud.max_distance = 10.0
	aud.finished.connect(func() :
		aud.play()
		)
	add_child(aud)
	aud.play()
