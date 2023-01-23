@tool
extends EditorPlugin

const PATH := "res://addons/qmapbsp/"
const PLUGIN_PATHS := [
	"importer/bsp_importer.gd",
	"importer/map_importer.gd",
	"inspector/map_inspector.gd",
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
