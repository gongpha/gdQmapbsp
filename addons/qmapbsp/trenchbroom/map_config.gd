@tool
extends Resource
class_name QmapbspTrenchbroomMapConfig

## If [code]false[/code], the importer will omit internal lightmap loading.
## and unwraps UV2.
@export var use_bsp_lightmap : bool = false
## The texel size used for baking UV2.
## A lower value gives high-resolution lightmaps.
## But also leads to bigger lightmap size and more baking time.
@export var lightmap_texel : float = 1.0
## The ratio of Quake 1 unit per Godot unit.
@export var inverse_scale_factor : float = 32.0
## The threshold for splitting meshes apart.
## When using occlusion culling, A lower value is much better.
@export var mesh_splitting_size : float = 32.0 # godot unit
## The placeholder material. This applies to faces that can't load any textures.
@export var default_material : Material
## Bakes navigation meshes based on this [NavigationMesh].
## The operation will skip if it's empty.
@export var navmesh_template : NavigationMesh
## If [code]true[/code], collision shape construction would get ignored.
@export var ignore_collision : bool = false
## Loads point file as [Path3D] if it exists.
## Useful for interior maps. This can help you to locate leaks in your map. And gives an extra face clipping.
@export var load_point_file : bool = false
## Removes unnecessary points in the point file.
## But still can lead you to the leak properly.
@export var simplify_point_files : bool = true

@export_group("Occluders", "occ_")
## Bakes occluders from the worldspawn entity.
@export var occ_bake_occluders : bool = false
## The amount for shrinking occluders.
## This method will reduce an over-occlusion that could make an inaccurate rasterizing.
## Must not be lesser than the grid size (like in Trenchbroom) divided with the inverse scale factor.
## Otherwise, it will shrink through to the opposite side and make it grow rather than shrinking.
@export var occ_shrink_amount : float = 0.5 # grid 16
