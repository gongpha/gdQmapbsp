# Qmapbsp Trenchbroom Importing

## Running the example
To make the importer works. First, Get the Quake tools (qbsp, vis, light, ...). If you have no idea where these are, You can obtain `ericw-tools` [here](https://github.com/ericwa/ericw-tools/releases/).

1. Open the `usercfg.tres` resource
2. Click on `QmapbspCompilationWorkflow` resource in `Compilation Workflow` field inside the `usercfg.tres` to expand its values
3. Enter your absolute `qbsp.exe` (or `qbsp` on Linux) in `Qbsp path`
4. Click on `map1.map` file in the FileSystem and open the `Import` tab. Then click `Reimport`

![image](https://user-images.githubusercontent.com/13400398/216836079-c8306dba-3823-41b4-9ec1-1b1ef775b7a8.png)

## Using my own game configurations
Create a new `QmapbspTrenchbroomGameConfigResource` resource then put your configurations here. And don't forget to insert `QmapbspUserConfig` with the information.

Then hit `Export configs to Trenchbroom` button to export configurations to Trenchbroom.

To make MAP files know your game configuration. Go to `Project Settings → Import Defaults → Qmapbsp Trenchbroom → Game Config Path` then put your game configuration resource file path here.

## Customing entities
Qmapbsp supports custom entities by scanning all entity scripts inside the chosen folder (`ent_entity_script_directory`) when clicking the `Export configs to Trenchbroom` button. It will read the info by calling the `_qmapbsp_get_fgd_info` method on each script file that has to return a `Dictionary` value with these keyvalues:
```gdscript
{
	property_name1 : [property_description, property_default_value],
	property_name2 : [property_description, property_default_value],
	property_name3 : [property_description, property_default_value],
	. . .
}
```
```gdscript
func _qmapbsp_get_fgd_info() -> Dictionary :
	return {
		"my_prop1" : ["My integer property", 0],
		"my_prop2" : ["My string property", "Hello"]
	}
```
Once all entities have been scanned. The game configuration resource will convert to an FGD class format and export to an FGD file.

To import properties, Create a new method in a script named below with the first argument being `Dictionary`

 - `_qmapbsp_ent_props_pre` : Calls **before** an entity node enters the root node.
 - `_qmapbsp_ent_props_post` : Calls **after** an entity node enters the root node. Use this method if you would like to access the parent node
 
```gdscript
func _qmapbsp_ent_props_post(props : Dictionary) -> void :
	var my_prop1 = props.get('my_prop1', 0) # returns int
	var my_prop2 = props.get('my_prop2', "Bye") # returns string
	# do something
```

## Dealing with transparent textures
Since the BSP compiler cannot know transparent textures like glasses or grilles, their faces will be clipped away because the compiler would think they were opaque textures. You could fix this issue by converting these brushes into a brush entity `func_detail_fence`. (You can read more about the entity class [here](http://ericwa.github.io/ericw-tools/doc/qbsp.html#DETAIL%20VARIANTS))

## Where's the compiled BSP file ?
It was stored at `res://.godot/qmapbsp/artifact`. So the BSP file shouldn't include in the version control like Git.
