extends Node3D

@onready var ray := $RayCast
@onready var hand := $Hand
@onready var player: CharacterBody3D = $"../.."


# go up twice: INTERACTION -> Head -> Player
@onready var ui_label := $"../../CanvasLayer/InteractLabel"
@onready var status_label := $"../../CanvasLayer/StatusLabel"

@onready var interaction_result_player: AudioStreamPlayer2D = $InteractionResultPlayer

var current: Node3D = null
var hovered: Node3D = null

# ===== Interface wrappers =====

func canPickup(obj: Node3D) -> bool:
	return obj.has_method("InteractCanPickup") and obj.InteractCanPickup()

func getName(obj: Node3D) -> String:
	if obj == null:
		return "" 
	
	if obj.has_method("InteractGetName"):
		return obj.InteractGetName()
	return ""
	
func getCaption(obj: Node3D) -> String:
	if obj == null:
		return "" 
	
	if obj.has_method("InteractGetCaption"):
		return obj.InteractGetCaption()
	return getName(obj)

func canInteract(obj: Node3D) -> bool:
	return obj.has_method("Interact")

func getInteractionAction(obj: Node3D) -> InteractionActionResult:
	if obj.has_method("InteractGetAction"):
		return obj.InteractGetAction(player, current, getName(current))
	return null

func interact(obj: Node3D) -> InteractionResult:
	if obj and obj.has_method("Interact"):
		var result := getInteractionAction(obj)
		if result == null || result.can_interact:
			var res: InteractionResult = obj.Interact(player, current, getName(current))
			if res != null:
				return res
	return InteractionResult.new(false, null)

func getSize(obj: Node3D) -> Vector3:
	if obj == null:
		return Vector3(0.5, 0.5, 0.5)

	if obj.has_method("InteractGetSize"):
		var s = obj.InteractGetSize()
		if s is Vector3:
			return s

	return Vector3(0.5, 0.5, 0.5)

# ===== Core loop =====

func _process(delta):
	update_raycast()
	update_ui()
	
	if Input.is_action_just_pressed("interact"):
		if hovered:
			handleInteraction()
	
	if Input.is_action_just_pressed("drop"):
		drop_current()

func handleInteraction():
	#var name = getName(hovered)
	
	# ===== PICKUP =====
	if canPickup(hovered):
		if current != null:
			show_status("Hands are full")
			return
	
		pickup(hovered)
		return
	
	# ===== INTERACT =====
	var actionResult := interact(hovered)
	if actionResult.sound:
		interaction_result_player.stop()
		interaction_result_player.stream = actionResult.sound
		interaction_result_player.play()
		pass
	if actionResult.consume_current and current:
		current.queue_free()
		current = null

# ===== Raycast =====

func update_raycast():
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var obj = ray.get_collider()
		obj = get_interactable(obj)
		if obj is Node3D:
			var name: String = getName(obj)
			if name != "":
				hovered = obj
				return
	
	hovered = null

func get_interactable(obj):
	while obj:
		if obj.is_in_group("interactable"):
			return obj
		obj = obj.get_parent()
	return null

# ===== UI =====

func update_ui():
	if hovered == null:
		ui_label.text = ""
		return
	
	var caption = getCaption(hovered)
	var key = get_action_key("interact")
	
	if canPickup(hovered):
		if current == null:
			ui_label.text = "Press " + key + " to pickup " + caption
		else:
			ui_label.text = "Hands full"
	elif canInteract(hovered):
		var result := getInteractionAction(hovered)
		if result == null:
			ui_label.text = "Press " + key + " to interact with " + caption
		else:
			if result.can_interact:
				ui_label.text = "Press " + key + " to " + result.text
			else:
				ui_label.text = result.text
	else:
		ui_label.text = caption

func get_action_key(action: String) -> String:
	var events = InputMap.action_get_events(action)

	if events.size() > 0:
		var e = events[0]

		if e is InputEventKey:
			return OS.get_keycode_string(e.physical_keycode)

	return "?"

# ===== Pickup =====

func pickup(obj: Node3D):
	if obj == current:
		return
	
	if current != null:
		show_status("Hands are full")
		return
	
	set_held(obj)
	current = obj
	
	if obj.has_signal("Interact_picked_up"):
		obj.emit_signal("Interact_picked_up")
	
	if obj.get_parent() != null and obj.get_parent() != hand:
		obj.get_parent().remove_child(obj)
	
	hand.add_child(obj)
	
	obj.transform = Transform3D.IDENTITY

# ===== Drop =====

func set_held(obj: Node3D):
	for child in obj.find_children("*", "CollisionShape3D", true):
		child.disabled = true

func set_world(obj: Node3D):
	for child in obj.find_children("*", "CollisionShape3D", true):
		child.disabled = false


func drop_current():
	if current == null:
		show_status("Nothing to drop")
		return
	
	var obj = current
	
	ray.force_raycast_update()
	
	var drop_pos: Vector3
	
	if ray.is_colliding():
		drop_pos = ray.get_collision_point()
	else:
		drop_pos = ray.global_position + -ray.global_transform.basis.z * 3.5
	
	var size = getSize(obj)
	if DropSystem.can_drop(drop_pos, size):
		current = null
		set_world(obj)
		DropSystem.drop(obj, drop_pos, size)
		if obj.has_signal("Interact_placed_down"):
			obj.emit_signal("Interact_placed_down")
	else:
		show_status("Can't drop here")

# ===== Status =====

func show_status(text: String):
	status_label.text = text
	status_label.show()
	
	await get_tree().create_timer(2.0).timeout
	
	status_label.hide()
