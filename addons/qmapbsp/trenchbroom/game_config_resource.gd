@tool
extends Resource
class_name QmapbspTrenchbroomGameConfigResource

@export var usercfg : QmapbspUserConfig
@export var name : String
@export_file("*.png") var icon
@export_dir var textures_dir : String
@export var custom_trenchbroom_world_importer : Script

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
	fgd.store_string(FGD_TEMPLATE)
	fgd = null
		
	var gt := GAMECONFIG_TEMPLATE.duplicate(true)
	gt["name"] = name
	gt["textures"]["package"]["root"] = (
		textures_dir.replace("res://", "") # TODO : please fix
	)
	
	var cfg := FileAccess.open(dirpath.path_join("GameConfig.cfg"), FileAccess.WRITE)
	cfg.store_string(JSON.stringify(gt, "\t", false))
	cfg = null
	
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
		"contentflags" : []
	}
}

const FGD_TEMPLATE := """
@baseclass = Angle [ angle(integer) : "Angle" ]

@SolidClass = worldspawn : "World entity" []

@SolidClass = area : "Area" []

@PointClass size(-8 -8 -8, 8 8 8) base(Light, Target, Targetname) =
	light : "Invisible light source"
	[
		spawnflags(Flags) = [ 1 : "Start off" : 0 ]
	]
"""
