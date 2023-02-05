# Qmapbsp Trenchbroom Loading Example
First, Get the Quake tools (qbsp, vis, light, ...). If you have no idea where are these, You can obtain `ericw-tools` [here](https://github.com/ericwa/ericw-tools/releases/).

1. Open the `usercfg.tres` resource
2. Click on `QmapbspCompilationWorkflow` resource in `Compilation Workflow` field inside the `usercfg.tres` to expand its values
3. Enter your absolute `qbsp.exe` (or `qbsp` on Linux) in `Qbsp path`
4. Click on `map1.map` file in the FileSystem and open `Import` tab. Then click `Reimport`

![image](https://user-images.githubusercontent.com/13400398/216836079-c8306dba-3823-41b4-9ec1-1b1ef775b7a8.png)

## Use my own game configurations
Create a new `QmapbspTrenchbroomGameConfigResource` resource then put your configurations here. And don't forget to insert `QmapbspUserConfig` with the information in it.

Then hit `Export configs to Trenchbroom` button to export configurations to Trenchbroom.

## Importing entities
For now, Qmapbsp exports a plain FGD file to Trenchbroom to avoid errors. You will have to write entity properties manually in Trenchbroom. And extend the `_entity_node_directory_path` method in `QmapbspWorldImporterTrenchbroom` script file with your entity script directory path. [(See the Quake example)](https://github.com/gongpha/gdQmapbsp/tree/master/quake1_example/class) Then put in the `custom_trenchbroom_world_importer` field

To get properties on each entity script file. Create a new method named `_ent_props` with the first argument being `Directory` to receive a property dictionary on import.

## Wait, Where's the compiled BSP file ???
It was stored at `res://.godot/qmapbsp/artifact`. So the BSP file shouldn't include in the version control like Git.
