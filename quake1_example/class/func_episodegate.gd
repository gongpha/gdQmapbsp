extends QmapbspQuakeFunctionBrush
class_name QmapbspQuakeFunctionEpisodegate

# Spawnflags:
# 1 : "Episode 1" : 1 
# 2 : "Episode 2" : 0 
# 4 : "Episode 3" : 0 
# 8 : "Episode 4" : 0 
const EP_1 : int = 1
const EP_2 : int = 2
const EP_3 : int = 4
const EP_4 : int = 8

func _ready() :
	# TODO: implement
	# this is used in start map to block completed episodes, after rune has been aquired
	queue_free()
