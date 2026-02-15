extends Node3D

const MAX_PLANKS := 13
var planks: Array[Node3D] = []

func _ready() -> void:
	setup_planks()
	set_level(0) # start empty

func setup_planks() -> void:
	planks.clear()
	
	for i in range(1, MAX_PLANKS + 1):
		var plank := get_node_or_null("plank%d" % i)
		
		if plank == null:
			push_warning("Missing plank%d" % i)
			continue
		
		planks.append(plank)
		_set_plank(plank, true)

func set_level(level: int) -> void:
	level = clamp(level, 0, MAX_PLANKS)
	
	for i in range(planks.size()):
		var enabled = (i < level)
		_set_plank(planks[i], enabled)



func _set_plank(node: Node, enabled: bool) -> void:
	_set_collision(node, enabled)
	node.visible = enabled

func _set_collision(node: Node, enabled: bool) -> void:
	if node is CollisionShape3D:
		node.disabled = !enabled

	for child in node.get_children():
		_set_collision(child, enabled)
