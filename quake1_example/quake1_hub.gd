extends Control
class_name QmapbspQuake1Hub

@onready var tabs : TabContainer = $tabs
@onready var dialog : FileDialog = $dialog
@onready var pathshow : LineEdit = $"tabs/PAK Viewer/vbox/hbox/path"
@onready var prog : ProgressBar = $"tabs/PAK Viewer/vbox/prog"
@onready var status : Label = $"tabs/PAK Viewer/vbox/status"
@onready var tree : Tree = $"tabs/PAK Viewer/vbox/hbox3/tree"
@onready var load : Button = $"tabs/PAK Viewer/vbox/hbox2/load"
@onready var bsponly : CheckButton = $"tabs/PAK Viewer/vbox/hbox2/bsponly"
@onready var wavplay : AudioStreamPlayer = $"wavplay"
@onready var texview_root : Control = $"tabs/PAK Viewer/vbox/hbox3/texview"
@onready var texview : TextureRect = $"tabs/PAK Viewer/vbox/hbox3/texview/tex"
@onready var texinfo : Label = $"tabs/PAK Viewer/vbox/hbox3/texview/info"

var viewer : QmapbspViewer

func _ready() :
	set_process(false)

func _on_browse_pressed() :
	dialog.popup_centered(Vector2i(800, 400))


func _on_dialog_dir_selected(dir : String) :
	pathshow.text = dir


func _on_load_pressed() :
	find_pak()


#####################################################

var globaldirs : Dictionary # <path : rsc>
var c_textures : Dictionary # <path : ImageTexture>
var c_raw : Dictionary

var global_pal : PackedColorArray

var load_pak_list : Array[QmapbspPakFile]

func find_pak() -> StringName :
	var paknam : int = 0
	
	globaldirs.clear()
	c_textures.clear()
	c_raw.clear()
	global_pal.clear()
	load_pak_list.clear()
	
	while true :
		var path : String = pathshow.text.path_join('pak%d.pak' % paknam)
		var ret : Array
		var pak = QmapbspPakFile.begin(path, ret)
		if pak is QmapbspPakFile :
			load_pak_list.append(pak)
			paknam += 1
		else :
			break
	if load_pak_list.is_empty() :
		return &'NO_PAK_FILES'
	prog.show()
	load.disabled = true
	set_process(true)
	pakidx = 0
	return StringName()
	
func load_paks() :
	set_process(true)
			
var pakidx : int
func _process(delta : float) :
	for I in 16 :
		var pak : QmapbspPakFile = load_pak_list[pakidx]
		var r := pak.poll()
		if r == &'DONE' :
			if !pak.global_pal.is_empty() :
				global_pal = pak.global_pal
					
			var P : PackedStringArray = pak.loadrsc_pathlist
			var E : Array[Resource] = pak.loaded_entries
			for i in P.size() :
				globaldirs[P[i]] = E[i]
			pakidx += 1
			if pakidx == load_pak_list.size() :
				prog.hide()
				set_process(false)
				load.disabled = false
				status.text = 'Double-click on files to play'
				_show_tree(bsponly.button_pressed)
				return
			
		elif r != StringName() :
			status.text = "[%s] %s" % [pak.filename, r]
			prog.hide()
			set_process(false)
			load.disabled = false
			return
			
		prog.value = pak.get_progress()
		status.text = 'Loading %s . . .' % pak.filename
		
func _show_tree(only_bsp : bool = true) :
	tree.clear()
	var root := tree.create_item()
	root.set_text(0, pathshow.text.get_file())
	var paths : Array = globaldirs.keys()
	if only_bsp :
		for p in paths :
			if !p.begins_with('maps/') : continue
			var currroot := tree.create_item(root)
			currroot.collapsed = true
			currroot.set_custom_color(0, Color.DARK_ORANGE)
			currroot.set_text(0, p.get_file())
			currroot.set_meta(&'open', [&'bsp', p])
	else :
		var treedir : Dictionary
		for p in paths :
			var currdir : Dictionary = treedir
			var currroot : TreeItem = root
			var ss : PackedStringArray = p.split('/')
			for i in ss.size() :
				var s : String = ss[i]
				if currdir.has(s) :
					currroot = currdir[s][0]
					currdir = currdir[s][1]
				else :
					currroot = tree.create_item(currroot)
					currroot.collapsed = true
					currroot.set_text(0, s)
					if s == 'maps' :
						currroot.set_custom_color(0, Color.DARK_GOLDENROD)
						
					elif p.begins_with('maps/') :
						currroot.set_custom_color(0, Color.DARK_ORANGE)
						currroot.set_meta(&'open', [&'bsp', p])
					elif p.ends_with('.wad') :
						currroot.set_custom_color(0, Color.DARK_MAGENTA)
						var wad : QmapbspWadFile = globaldirs[p]
						for k in wad.pics :
							var waditem := tree.create_item(currroot)
							waditem.set_text(0, k)
							waditem.set_custom_color(0, Color.DARK_VIOLET)
							waditem.set_meta(&'open', [&'wad', p, k])
					elif ss[-1].ends_with('.lmp') and i >= ss.size() - 1 :
						currroot.set_custom_color(0, Color.DARK_OLIVE_GREEN)
						currroot.set_meta(&'open', [&'lmp', p])
					elif ss[-1].ends_with('.wav') and i >= ss.size() - 1 :
						currroot.set_custom_color(0, Color.RED)
						currroot.set_meta(&'open', [&'wav', p])
					var newdir := {}
					currdir[s] = [currroot, newdir]
					currdir = newdir
		
func load_audio(pakpath : String) -> AudioStream :
	return load_resource("sound/" + pakpath)
	
func load_resource(pakpath : String) -> Resource :
	return globaldirs.get(pakpath, null)
	
func load_as_texture(pakpath : String) -> ImageTexture :
	var split := pakpath.split(':')
	var path := split[0]
	var subsrc := split[1] if split.size() >= 2 else ""
	var itex : ImageTexture = c_textures.get(path)
	if itex : return itex
	var rsc = load_resource(path)
	if rsc is QmapbspWadFile :
		itex = rsc.load_pic(subsrc)
		c_textures[pakpath] = itex
	if rsc is Image :
		itex = ImageTexture.create_from_image(rsc)
		c_textures[pakpath] = itex
	return itex

func export_raw_file(pakpath : String, to : String) -> StringName :
	var path := to.path_join(pakpath)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if !f :
		pass
	var rf = load_resource(pakpath)
	if rf is QmapbspRawFile :
		f.store_buffer(rf.raw)
		return StringName()
	return &'NOT_A_RAW_FILE'
	


func _on_bsponly_toggled(yes : bool) :
	texview_root.visible = !yes
	_show_tree(yes)

func _on_tree_item_activated():
	var that := tree.get_selected()
	if !that.has_meta(&'open') : return
	var arr : Array = that.get_meta(&'open')
	match arr[0] :
		&'wav' :
			wavplay.stream = globaldirs[arr[1]]
			wavplay.play()
		&'bsp' :
			_play_bsp(arr[1])


func _on_tree_item_selected():
	var that := tree.get_selected()
	if !that.has_meta(&'open') : return
	var arr : Array = that.get_meta(&'open')
	match arr[0] :
		&'lmp' :
			var item := load_as_texture(arr[1])
			if item :
				_show_tex(item)
		&'wad' :
			var wad : QmapbspWadFile = globaldirs[arr[1]]
			_show_tex(wad.load_pic(arr[2]))

func _show_tex(tex : Texture2D) :
	texview.texture = tex
	texinfo.text = "(%d, %d)" % [tex.get_width(), tex.get_height()]

func _play_bsp(pakpath : String) :
	export_raw_file(pakpath, "user://packcache/")
	
	viewer = preload("res://quake1_example/viewer.tscn").instantiate()
	viewer.hub = self
	add_child(viewer)
	tabs.hide()
	viewer.play_by_path.call_deferred(
		"user://packcache/".path_join(pakpath), global_pal
	)


func _on_path_text_submitted(new_text) :
	find_pak()
