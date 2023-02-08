@tool
extends Resource
class_name QmapbspUserConfig

## An individual user configuration.
## When worked on the team. This should be ignored via [code].gitignore[/code]

@export var compilation_workflow : QmapbspCompilationWorkflow
@export_group("Trenchbroom", "tb_")
@export_global_dir var tb_path : String

func _init() :
	resource_name = "USERCONFIG"
