# Qmapbsp
An interactive Quake's MAP/BSP loader for Godot 4. It loads MAP and BSP together into the Godot 4 scene.

### This is a very experimental plugin and needs more work.

## Usage
> For loading MAP files with Trenchbroom configuration. [See this example folder](https://github.com/gongpha/gdQmapbsp/tree/master/trenchbroom_example)
>
> For playing with Quake maps. [See this example folder](https://github.com/gongpha/gdQmapbsp/tree/master/quake1_example)

This plugin has more quite complex than the existed plugins like [Qodot](https://github.com/QodotPlugin/qodot-plugin) and [Trenchbroom Loader](https://github.com/codecat/godot-tbloader).
In this plugin, you are able to customize the importer workflow by extending the importer script [`QmapbspWorldImporter`](https://github.com/gongpha/gdQmapbsp/blob/master/addons/qmapbsp/importer/world_importer.gd).

For example, Initially, the plugin doesn't create a node for you at first. But it will feed you the information.
```gdscript
func _entity_your_mesh(ent_id : int, brush_id : int, mesh : ArrayMesh, origin : Vector3, ...) -> void :
  # do something
func _entity_your_shape(ent_id : int, brush_id : int, shape : Shape3D, origin : Vector3, ...) -> void :
  # do something
```
Also, the [`QmapbspWorldImporterScene`](https://github.com/gongpha/gdQmapbsp/blob/master/addons/qmapbsp/importer/impext/scene.gd) does the most job of building the node hierarchy. You can also extend this for your work too.

To process importing progress. call `poll()` method to poll the progress, Once it returned StringName `"END"` that means the importing progress is completed, Or if an empty StringName was returned, that means you still need to keep polling. Otherwise, it's an error message. You have to abort the work by not calling `poll()` anymore.

While the importing is progressing, You can get the progression percentage by calling `get_progress()`. This returns a float number that has only 0 to 1.

## Is it needed both MAP and BSP ?
In general, yes. The MAP data will get imported as the collision shapes and texture name references (in case of using custom textures i.e. via Trenchbroom), and the BSP data will get imported as geometries, entities, and more (lightmaps, visleaves).

But fortunately, on import time, you can provide a MAP file alone. the plugin will compile them into a BSP on the import time by [`QmapbspCompilationWorkflowQuake1`](https://github.com/gongpha/gdQmapbsp/blob/master/addons/qmapbsp/importer/cmplwf/quake1.gd). (and yes, this requires external compilers like QBSP)
