@tool
extends Node

var chunk_size = 8
var chunk_range = 3
var camera_position_current = Vector3.ZERO
var camera_chunk_current = Vector3i.ZERO
var camera :Camera3D
var scene_name
var chunk_scene_path
# Called when the node enters the scene tree for the first time.
func _ready():
	print(get_tree().get_edited_scene_root().scene_file_path.get_file())
	scene_name = get_tree().get_edited_scene_root().scene_file_path.get_file()
	chunk_scene_path = "res://chunks/"+scene_name+"/"
	print(chunk_scene_path)
	#make chunk scene folder
	DirAccess.make_dir_absolute("res://chunks/"+scene_name)
	camera = get_tree().root.find_child("*Camera*", true, false)
	
	#var chunk_scene :Node = load(chunk_scene_path+"(-1,0,0).tscn").instantiate()
	#$"../Chunks".add_child(chunk_scene)
	#chunk_scene.owner = get_tree().get_edited_scene_root()
	#chunk_scene.get_parent().set_editable_instance(chunk_scene, true);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if camera:
		if camera.transform.origin != camera_position_current:
			camera_position_current = camera.transform.origin
			var camera_chunk_current_temp:Vector3i = get_chunk_position(camera_position_current)
			if camera_chunk_current_temp != camera_chunk_current:
				camera_chunk_current = camera_chunk_current_temp
				print('camera chunk: ', camera_chunk_current)
				
				#chunk has changed, unload distant chunks, load in new chunks
				

func get_chunk_position(position: Vector3) -> Vector3:
	var chunk_position = Vector3i()
	chunk_position.x = floor(position.x / chunk_size)
	chunk_position.y = floor(position.y / chunk_size)
	chunk_position.z = floor(position.z / chunk_size)
	return chunk_position

func _on_child_entered_tree(node):
	if node.get_parent().name != "Chunker":
		return
		
	print("Node added:")
	print(node)
	var chunk_position = get_chunk_position(node.position)
	var chunk_scene_position_path = chunk_scene_path+str(chunk_position)+".tscn"
	print(chunk_scene_position_path)
	var chunk_scene: PackedScene
	
	#create packed scene for new chunk
	if !FileAccess.file_exists(chunk_scene_position_path):
		chunk_scene = PackedScene.new()
		var node_new = Node3D.new()
		node_new.name = str(chunk_position)
		chunk_scene.pack(node_new)
		ResourceSaver.save(chunk_scene, chunk_scene_position_path)
		
	#load packed scene chunk
	chunk_scene = load(chunk_scene_position_path)
	var chunk_root :Node = chunk_scene.instantiate()
	$"../Chunks".add_child(chunk_root)
	chunk_root.name = str(chunk_position)
	chunk_root.owner = get_tree().get_edited_scene_root()
	chunk_root.get_parent().set_editable_instance(chunk_root, true);
	
	
	#remove new node from current scene and add to new chunk-specific root
	remove_child(node)
	chunk_root.add_child(node)
	node.owner = chunk_root
	
	#replace old chunk with new updated one
	DirAccess.remove_absolute(chunk_scene_position_path)
	var result = chunk_scene.pack(chunk_root)
	ResourceSaver.save(chunk_scene, chunk_scene_position_path)
	
	
#todo, update/add scenes on child node being moved around.
#save scenes on change
#camera load/unload chunk scenes based on position
