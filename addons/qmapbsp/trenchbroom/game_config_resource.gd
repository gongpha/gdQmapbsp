@tool
extends Resource
class_name QmapbspTrenchbroomGameConfigResource

@export var usercfg : QmapbspUserConfig
@export var name : String
@export_file("*.png") var icon
@export_dir var textures_directory : String
@export var global_map_config : QmapbspTrenchbroomMapConfig
@export_group("Entities", "ent_")
@export_dir var ent_entity_script_directory : String
@export var ent_export_to_fgd_file : bool = true

@export_group("Default values", "def_")
@export var def_face_offset := Vector2(0, 0)
@export var def_face_scale := Vector2(1, 1)

@export_group("Advanced configurations")
@export var custom_trenchbroom_world_importer : Script
@export_multiline var additional_fgd : String = ""

@export_group("Generated", "_")
@export var _entity_properties_def : Dictionary

func export_cfg() :
	if !usercfg :
		printerr("No User config")
		return
	var tpath : String = usercfg.tb_path
	if !usercfg :
		printerr("No Trenchbroom path")
		return
		
	var dirpath := tpath.path_join(
		"games".path_join(
			name
		)
	)
	DirAccess.make_dir_absolute(dirpath)
	var dir := DirAccess.open(dirpath)
	if !dir :
		printerr("Cannot open the game directory")
		return
		
	dir.copy(icon, dirpath.path_join("icon.png"))
		
	var fgd := FileAccess.open(dirpath.path_join("qmapbsp.fgd"), FileAccess.WRITE)
	fgd.store_string(
		FGD_TEMPLATE % [name] +
		additional_fgd
	)
	if ent_export_to_fgd_file :
		fgd.store_string(_scan_fgd_classes())
	fgd = null
		
	var texture_dir := textures_directory.replace("res://", "") # TODO : please fix
	if texture_dir.is_empty() : texture_dir = '.'
		
	var gt := GAMECONFIG_TEMPLATE.duplicate(true)
	gt["name"] = name
	gt["textures"]["package"]["root"] = texture_dir
	gt["faceattribs"]["defaults"]["scale"] = [
		def_face_scale.x, def_face_scale.y
	]
	gt["faceattribs"]["defaults"]["offset"] = [
		def_face_offset.x, def_face_offset.y
	]
	
	
	var cfg := FileAccess.open(dirpath.path_join("GameConfig.cfg"), FileAccess.WRITE)
	cfg.store_string(JSON.stringify(gt, "\t", false))
	cfg = null
	
func _scan_fgd_classes() -> String :
	var dir := DirAccess.open(ent_entity_script_directory)
	if !dir : return ""
	dir.list_dir_begin()
	var file := dir.get_next()
	
	var fgdsrc := ""
	
	while file != "" :
		if !dir.current_is_dir() :
			var classname := file.get_file().trim_suffix('.gd')
			var rsc = load(ent_entity_script_directory.path_join(file))
			if rsc is GDScript :
				var object : Object = rsc.new()
				fgdsrc += _write_object_fgd(classname, object) + '\n'
				object.free()
		file = dir.get_next()
	return fgdsrc
		
func _write_object_fgd(classname : String, object : Object) -> String :
	#if !object.has_method(&'_qmapbsp_get_fgd_info') : return ""
	var dict : Dictionary = object._qmapbsp_get_fgd_info()
	var s : String
	var bases : PackedStringArray
	if object is Node3D :
		bases.append("Node3D")
		
	return _write_fgd_class(
		classname, "PointClass", "", bases, dict
	)
		
func _write_fgd_class(
	classname : String,
	type : String, # SolidClass, PointClass, baseclass
	desc : String,
	
	bases : PackedStringArray,
	#size : PackedVector3Array,
	properties : Dictionary,
	color = null
) -> String :
	var props : String = ""
	#var ths : PackedStringArray
	var eprop : Dictionary = {}
	_entity_properties_def[classname] = eprop
	for k in properties :
		var arr : Array = properties[k]
		var def = arr[1]
		
		var v := QmapbspTypeProp.var_to_prop(def)
		var typev : String = v[1]
		var vv : String = v[0]
		props += (
			"\t%s(%s) : \"%s\" : \"%s\" : \"%s\"\n" % [
				k,
				typev,
				k.capitalize(),
				vv,
				arr[0] if arr[0] else ""
			]
		)
		eprop[k] = def
		#ths.append(k + ":" + str(typeof(def)))
	#props += "\t\t_qmapbsp_typehints(string) : \"Qmapbsp Typehints\" : \"" + ','.join(ths) + "\""
	var color_ : String
	if color is Color :
		color_ = "color(%d %d %d) " % [
			color.r * 255,
			color.g * 255,
			color.b * 255,
		]
	var size_ : String = "-4 -4 -4, 4 4 4"
	if !desc.is_empty() :
		desc = " : " + desc
	notify_property_list_changed()
	return """
@""" + type + """ base(""" + ', '.join(bases) + """) size(""" + size_ + """) """ + color_ + """= """ + classname + desc + """ [
""" + props + """
]
		"""
	
const GAMECONFIG_TEMPLATE := {
	"version" : 4,
	"name" : "Qmapbsp Game",
	"icon" : "icon.png",
	"fileformats" : [
		{
			"format" : "Standard",
			"initialmap" : "initial_standard.map"
		}
	],
	"filesystem" : {
		"searchpath" : ".",
		"packageformat" : { "extension" : "pak", "format" : "idpak" }
	},
	"textures" : {
		"package" : { "type" : "directory", "root" : "textures" },
		"format" : {
			"extensions" : [
				"png",
				"tga",
				"jpg",
				"jpeg",
				"webp",
			], "format" : "image"
		},
		"attribute" : "_tb_textures"
	},
	"entities" : {
		"definitions" : [ "qmapbsp.fgd" ],
		"defaultcolor" : "0.6 0.6 0.6 1.0",
		"modelformats" : [ "bsp, mdl, md2" ]
	},
	"tags" : {
		"brush" : [],
		"brushface" : []
	},
	"faceattribs" : {
		"surfaceflags" : [],
		"contentflags" : [],
		"defaults" : {
			"scale" : [1, 1]
		}
	}
}

const FGD_TEMPLATE := """
// Generated by Qmapbsp for %s

@SolidClass = worldspawn : "Worldspawn Entity" []

@baseclass = Angle [ angle(integer) : "Angle" : 0 ]
@baseclass base(Angle) size(-8 -8 -8, 8 8 8) color(255 128 128) = Node3D [
	visible(boolean) : "Visible" : 1 : "The node's visibility"
]

@SolidClass = func_detail_fence []

////////////////////////////

@SolidClass = func_occluder []

////////////////////////////

"""


