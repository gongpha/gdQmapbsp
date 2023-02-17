@tool
extends Resource
class_name QmapbspTrenchbroomMapConfig

## If [code]false[/code], the importer will omit internal lightmap loading.
## and unwraps UV2.
@export var use_bsp_lightmap : bool = false
## The texel size used for baking UV2
@export var lightmap_texel : float = 1.0
## The ratio of Quake 1 unit per Godot unit
@export var inverse_scale_factor : float = 32.0
## The threshold for splitting meshes apart.
## When using occlusion culling, A lower value is much better
@export var mesh_splitting_size : float = 32.0 # godot unit
## The material used for faces that can't load any textures into
@export var default_material : Material
## Bakes occluders from the worldspawn entity
@export var bake_occluders : bool = false
## The amount for shrinking occluders.
## This method will reduce an over-occlusion that could make an inaccurate rasterizing.
@export var occluder_shrink_amount : float = 1.0
