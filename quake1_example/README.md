# Qmapbsp Quake1 Example

This folder contains a simple Quake1 BSP viewer, PAK/WAD explorers, a basic Quake movement character, and some entity implementation like `trigger_*` and `func_*`

This viewer requires PAK files and **MAP files of maps** inside the PAK to load.

![image](https://user-images.githubusercontent.com/13400398/216873785-c92ece5b-fbfc-440e-9aaf-6c1e87fe0651.png)

Tested on some ID Software's Quake shareware maps. Not all entities are implemented yet. And remember that you have to run this viewer on the full project. Because it contains bound keys for the player character.

## Usage
Run `hub.tscn` then enter your Mod and MAP paths. And hit `Load`. The tree will display a file structure inside PAK files. You can click on some resources to play (\*.bsp, \*.wav) or view (\*.wad, \*.lmp). MDL files are not supported yet
