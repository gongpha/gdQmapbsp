@tool
extends EditorPlugin

const PATH := "res://addons/qmapbsp/"
const PLUGIN_PATHS := [
	#"inspector/map_inspector.gd",
	"trenchbroom/game_config_inspector.gd",
	"trenchbroom/map_importer.gd",
]

var plugins : Array[RefCounted] # []

func _enter_tree() :
	for p in PLUGIN_PATHS :
		var plugin : RefCounted = load(PATH + p).new()
		plugins.append(plugin)
		if plugin is EditorImportPlugin :
			add_import_plugin(plugin)
		elif plugin is EditorInspectorPlugin :
			add_inspector_plugin(plugin)

func _exit_tree() :
	for i in plugins :
		if i is EditorImportPlugin :
			remove_import_plugin(i)
		elif i is EditorInspectorPlugin :
			remove_inspector_plugin(i)
	plugins.clear()
