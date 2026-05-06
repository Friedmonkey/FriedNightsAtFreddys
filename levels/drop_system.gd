extends Node

var world_items: Node3D #= get_tree().current_scene.get_node("WorldItems")

func set_world_items(new: Node3D):
	world_items = new

func can_drop(pos: Vector3, size: Vector3) -> bool:
	return ray_to_floor(pos, size) != Vector3.INF

func drop(obj: Node3D, pos: Vector3, size: Vector3) -> bool:
	if !can_drop(pos, size):
		return false
	
	var hit = ray_to_floor(pos, size)
	if obj.get_parent():
		obj.get_parent().remove_child(obj)
	
	world_items.add_child(obj)
	obj.global_position = hit  # + Vector3.UP * 0.05
	
	return true

func ray_to_floor(pos: Vector3, size: Vector3) -> Vector3:
	var space = get_tree().current_scene.get_world_3d().direct_space_state
	
	var from = pos + Vector3.UP * 50
	var to = pos + Vector3.DOWN * 200
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space.intersect_ray(query)
	
	if result and is_item_floor(result.collider):
		var hit_pos = result.position
		
		# optional: prevent clipping into walls using size check
		if is_area_free(hit_pos, size):
			return hit_pos
	
	return Vector3.INF

func is_area_free(pos: Vector3, size: Vector3) -> bool:
	var space = get_tree().current_scene.get_world_3d().direct_space_state
	
	var shape = SphereShape3D.new()
	shape.radius = max(size.x, size.y, size.z) * 0.5
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), pos + Vector3.UP * size.y)
	query.collision_mask = 1
	
	var result = space.intersect_shape(query)
	
	return result.is_empty()

func is_item_floor(obj: Node) -> bool:
	while obj != null:
		if obj.is_in_group("item_floor"):
			return true
		obj = obj.get_parent()
	return false
