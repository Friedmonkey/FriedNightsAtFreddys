extends Node3D

@export var spawn_platform: Node3D
@export var spawn_items: Array[PackedScene] = []
@export var spawn_interval := 60.0 # seconds

@export var max_attempts := 10

func _ready():
	for i in 10:
		spawn_one()
	spawn_loop()

func spawn_loop():
	while true:
		await get_tree().create_timer(spawn_interval).timeout
		spawn_one()

func spawn_one():
	if spawn_platform == null or spawn_items.is_empty():
		return
	
	for i in max_attempts:
		var pos = get_random_point_on_platform()
		
		var scene: PackedScene = spawn_items.pick_random()
		var obj: Node3D = scene.instantiate()
		var size = get_size(obj)
		
		if DropSystem.can_drop(pos, size):
			DropSystem.drop(obj, pos, size)
			obj.rotation.y = randf() * TAU
			return
		else:
			obj.queue_free() # cleanup failed attempt
			
func get_random_point_on_platform() -> Vector3:
	var mesh_instance := spawn_platform as MeshInstance3D
	
	if mesh_instance == null or mesh_instance.mesh == null:
		return spawn_platform.global_position
	
	var aabb = mesh_instance.mesh.get_aabb()
	
	var x = randf_range(aabb.position.x, aabb.position.x + aabb.size.x)
	var z = randf_range(aabb.position.z, aabb.position.z + aabb.size.z)
	
	var local_point = Vector3(x, 0, z)
	return mesh_instance.to_global(local_point)
	
func get_size(obj: Node3D) -> Vector3:
	if obj.has_method("InteractGetSize"):
		return obj.InteractGetSize()
	return Vector3(0.5, 0.5, 0.5)
