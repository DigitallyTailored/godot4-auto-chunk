# Godot 4 Chunk handling Tool Script

This is a tool script for Godot 4 that manages chunk loading and unloading based on the camera's position. It is useful for games with large open worlds, where loading the entire map at once is not feasible. The script runs from the editor to dynamically update chunk scenes with placed and moved nodes while loading and unloding chunks of the game world around the camera to maintain performance both in game and while editing.

![image](https://github.com/DigitallyTailored/godot4-auto-chunk/assets/13086157/57ce58f6-ce36-401a-bc25-8c9545768c7d)

https://github.com/DigitallyTailored/godot4-auto-chunk/assets/13086157/de8e03b4-6dc7-435b-9ed9-3544c253db7b

## How it Works

The script divides the game world into chunks of a specified size and keeps track of the current chunk that the camera is in. When the camera moves to a new chunk, the script unloads chunks that are now out of range and loads new chunks that have come into range. You can place or move around any nodes that extend Node3D and if they are under the primary node that this script is attached to then they will be automatically saved to the correct chunk scene when the chunks refresh. Any chunks that are empty are not saved.

## Key Variables

- `chunk_size`: The size of each chunk. Do not change this after any chunks have been saved.
- `chunk_range`: The range of chunks around the camera that should be loaded. Can be changed at any time.

## Usage

1. Attach the script to a Node in your scene.
2. Set the `chunk_size` and `chunk_range` variables to suit your game.
3. Add Node3D type nodes under this node such as MeshInstance3D or StaticBody3D.
4. The script will automatically start managing chunks in the editor and when the game runs.

## Functions

The script includes several functions for managing chunks:

- `_ready()`: Called when the node enters the scene tree for the first time. Initializes the scene and camera variables and clears any existing children of the node.
- `_process(delta)`: Called every frame. Checks if the camera has moved and updates chunks as necessary.
- `get_chunk_position(position)`: Returns the chunk that contains the given position.
- `load_nearby_chunks(chunk_position)`: Loads all chunks within the `chunk_range` of the given chunk.
- `unload_distant_chunks(chunk_position)`: Unloads all chunks that are outside the `chunk_range` of the given chunk.
- `load_chunk(chunk_position)`: Loads the chunk at the given position.
- `unload_chunk(chunk_position)`: Unloads the chunk at the given position.
- `recursive_set_owner(node, owner)`: Recursively sets the owner of a node and all its descendants.
- `reassign_nodes_to_chunks()`: Reassigns all nodes to their correct chunks based on their current position.
- `reassign_node_to_closest_chunk(node)`: Reassigns a node to its closest chunk based on its current position.

## Notes

This script requires Godot 4.0 or later. It assumes that the camera is a child of the root node and that its name contains "Camera". It also assumes that chunks are saved as `.tscn` files in a `chunks` directory under the root of the project.

## Todo

- Move loading and unloading on chunks to a thread to prevent noticeable stutter
- chunk scene file names should include the path
- Hook into Node3D transform update to call chunk placement logic on only required node. We currently do this for all nodes every time we save
- Create a small demo
- The way we get the camera is a little hacky
