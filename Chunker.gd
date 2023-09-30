@tool
extends Node

@export var chunk_size = 8 #do not change this after any chunks have been saved
@export var chunk_range = 1 #can change this whenever
var camera_position_current = Vector3.ZERO
var camera_chunk_current = Vector3i.ZERO
var camera :Camera3D
var scene_name
var chunk_scene_path

var chunks_loaded = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	scene_name = get_tree().get_edited_scene_root().scene_file_path.get_file()
	chunk_scene_path = "res://chunks/"+scene_name+"/"
	DirAccess.make_dir_absolute("res://chunks/"+scene_name)
	camera = get_tree().root.find_child("*Camera*", true, false)
	var children = self.get_children()
	if children:
		for child in children:
			child.get_parent().remove_child(child)
			child.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if camera:
		if camera.transform.origin != camera_position_current:
			camera_position_current = camera.transform.origin
			var camera_chunk_current_temp:Vector3i = get_chunk_position(camera_position_current)
			if camera_chunk_current_temp != camera_chunk_current:
				camera_chunk_current = camera_chunk_current_temp
				reassign_nodes_to_chunks()
				load_nearby_chunks(camera_chunk_current)
				unload_distant_chunks(camera_chunk_current)

func get_chunk_position(position: Vector3) -> Vector3:
	var chunk_position = Vector3i()
	chunk_position.x = floor(position.x / chunk_size)
	chunk_position.y = floor(position.y / chunk_size)
	chunk_position.z = floor(position.z / chunk_size)
	return chunk_position

func load_nearby_chunks(chunk_position):
	for x in range(-chunk_range, chunk_range+1):
		for y in range(-chunk_range, chunk_range+1):
			for z in range(-chunk_range, chunk_range+1):
				var new_chunk_position = chunk_position + Vector3i(x, y, z)
				var new_chunk_str = str(new_chunk_position)
				if new_chunk_str not in chunks_loaded:
					load_chunk(new_chunk_position)
					chunks_loaded[new_chunk_str] = new_chunk_position

func unload_distant_chunks(chunk_position:Vector3):
	var chunks_to_unload = []
	for chunk_str in chunks_loaded:
		var chunk:Vector3 = chunks_loaded[chunk_str]
		var diff = chunk_position - chunk
		if abs(diff.x) > chunk_range or abs(diff.y) > chunk_range or abs(diff.z) > chunk_range:
			unload_chunk(chunk)
			chunks_to_unload.append(chunk_str)
	for chunk_str in chunks_to_unload:
		chunks_loaded.erase(chunk_str)

	
func load_chunk(chunk_position, force = false):
	#print('Loading chunk', chunk_position)
	var chunk_name = str(chunk_position)+'.tscn'
	if FileAccess.file_exists(chunk_scene_path+chunk_name):
		var chunk_scene = load(chunk_scene_path+chunk_name)
		var node_new :Node3D = chunk_scene.instantiate()
		self.add_child(node_new)
		node_new.name = str(chunk_position)
		node_new.owner = get_tree().get_edited_scene_root()
		recursive_set_owner(node_new)
		node_new.owner.set_editable_instance(node_new, true)
		node_new.scene_file_path = ''
		node_new.position = chunk_position * chunk_size
		node_new.set_meta("chunk_node", true)
	else:
		if force:
			var node_new = Node3D.new()
			node_new.name = str(chunk_position)
			self.add_child(node_new)
			node_new.owner = get_tree().get_edited_scene_root()
			node_new.position = chunk_position * chunk_size
			node_new.set_meta("chunk_node", true)

func unload_chunk(chunk_position):
	var chunk_name = str(chunk_position)+'.tscn'
	if FileAccess.file_exists(chunk_scene_path+chunk_name):
		DirAccess.remove_absolute(chunk_scene_path+chunk_name)
	var expired_chunk = self.find_child(str(chunk_position))
	if expired_chunk:
		if expired_chunk.get_child_count() > 0:
			var chunk_scene = PackedScene.new()
			recursive_set_owner(expired_chunk, expired_chunk)
			var result = chunk_scene.pack(expired_chunk)
			if result == OK:
				ResourceSaver.save(chunk_scene, chunk_scene_path+chunk_name)
		expired_chunk.get_parent().remove_child(expired_chunk)
		expired_chunk.queue_free()
		
func recursive_set_owner(node, owner = get_tree().get_edited_scene_root()):
	for child in node.get_children():
		child.owner = owner
		if child.get_child_count() > 0:
			recursive_set_owner(child,owner)
		
func reassign_nodes_to_chunks():
	var all_chunks = self.get_children(true)
	for chunk in all_chunks:
		if chunk.has_meta("chunk_node"):
			var all_nodes = chunk.get_children(true)
			for node in all_nodes:
				reassign_node_to_closest_chunk(node)
		else:
			reassign_node_to_closest_chunk(chunk)

#TODO it would be much quicker to call this automatically on any node which is move or placed
func reassign_node_to_closest_chunk(node):
	var node_chunk_position = get_chunk_position(node.global_transform.origin)
	var node_parent :Node= node.get_parent()
	var rechunk = false
	if !node_parent.has_meta("chunk_node"):
		rechunk = true
	else:
		var node_parent_chunk_position = get_chunk_position( (node_parent as Node3D).global_transform.origin)
		if node_chunk_position != node_parent_chunk_position:
			rechunk = true
		
	if rechunk:
		var new_parent = self.find_child(str(node_chunk_position))
		if !new_parent:
			load_chunk(node_chunk_position, true)
			chunks_loaded[str(node_chunk_position)] = node_chunk_position
			new_parent = self.find_child(str(node_chunk_position))
		node.reparent(new_parent, true)
		node.owner = get_tree().get_edited_scene_root()
