extends QmapbspQuakeTriggerOnce
class_name QmapbspQuakeTriggerSecret

# Spawnflags:
# 1: "Not touchable" : 0
# ... see parent class


func _trigger_now(b : Node3D) :
	super(b)
	get_meta(&'viewer').found_secret()


func _show_message_end() : return
