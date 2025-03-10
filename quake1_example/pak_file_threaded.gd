extends RefCounted
class_name QmapbspPakFileThreaded

var pak : QmapbspPakFile
var thread : Thread

var mutex : Mutex
var progress : float

signal completed
signal failed(reason : StringName)

static func begin(p : String, ret : Array = []) -> QmapbspPakFileThreaded :
	var pak := QmapbspPakFile.begin(p, ret)
	if !pak :
		return null
		
	var pakthread := QmapbspPakFileThreaded.new()
	pakthread.pak = pak
	pakthread.mutex = Mutex.new()
	
	return pakthread
	
func start() -> void :
	if thread :
		return
	thread = Thread.new()
	
	thread.start(_load)
	
func _complete() -> void :
	thread.wait_to_finish()
	thread = null
	completed.emit()
	
func _fail(reason : StringName) -> void :
	thread.wait_to_finish()
	thread = null
	failed.emit(reason)
	
func _load() -> void :
	while 1 :
		var r := pak.poll()
		if r == &'DONE' :
			_complete.call_deferred()
			return
			
		elif r != StringName() :
			_fail.call_deferred(r)
			return
			
		mutex.lock()
		progress = get_progress()
		mutex.unlock()

func get_progress() -> float :
	mutex.lock()
	var p := pak.get_progress()
	mutex.unlock()
	return p
