@tool
extends Resource
class_name QmapbspTrenchbroomMapConfig

## If [code]false[/code], the importer will omit internal lightmap loading.
## and unwraps UV2.
@export var use_bsp_lightmap : bool = false
@export var lightmap_texel : float = 1.0
@export var inverse_scale_factor : float = 32.0
## When using occlusion culling, A lower value is much better
@export var mesh_splitting_size : float = 32.0 # godot unit
@export var default_material : Material
## Bakes occluders from the worldspawn entity
@export var bake_occluders : bool = false
