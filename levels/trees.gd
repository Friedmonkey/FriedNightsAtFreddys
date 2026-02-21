extends Node3D

@onready var player := $"../../Player"
@onready var friedy := $"../../friedy_mastermind/stalking_friedy"
@onready var twigSnapSound := $"../../friedy_mastermind/TwigSnap"
@onready var ristleSound := $"../../friedy_mastermind/Ristle"

var trees: Array = []
var current_tree: Node3D = null
var current_peek_left: bool = false
var follow_timer: Timer
var tree_timer: Timer
var target_position: Vector3
var is_teleporting: bool = false
var jump_in_progress: bool = false

const max_spotted_count: int = 32
var spotted_count: int = 0

func _ready() -> void:
	trees = get_children()
	
	tree_timer = Timer.new()
	tree_timer.wait_time = 60.0
	tree_timer.autostart = true
	tree_timer.one_shot = false
	add_child(tree_timer)
	tree_timer.timeout.connect(_on_tree_timer_timeout)
	
	follow_timer = Timer.new()
	follow_timer.wait_time = 0.5
	follow_timer.autostart = true
	follow_timer.one_shot = false
	add_child(follow_timer)
	follow_timer.timeout.connect(_on_follow_timer_timeout)
	
	move_to_new_tree()

func move_to_new_tree():
	if trees.is_empty():
		return
	if jump_in_progress:
		return  # Prevent overlapping teleports/jumps
	jump_in_progress = true
	friedy.visible = true
	
	if current_tree != null:
		await update_friedy(player.global_position, current_tree.global_position, current_peek_left, true)
		await get_tree().create_timer(0.2).timeout
		#current_tree.scale = Vector3.ONE
	
	current_tree = trees.pick_random()
	if player.global_position.distance_to(current_tree.global_position) >= 60:
		current_tree = trees.pick_random()
	current_peek_left = (randi() % 2 == 1)
	friedy.play_stalk(current_peek_left)
	#current_tree.scale = Vector3(1, 5, 1)
	
	update_friedy(player.global_position, current_tree.global_position, current_peek_left, true)
	is_teleporting = true
	jump_in_progress = false  # release lock
	#reset timer
	tree_timer.stop()
	tree_timer.start()

func move_around_tree():
	if current_tree == null:
		return
	
	#friedy.visible = true
	update_friedy(player.global_position, current_tree.global_position, current_peek_left)
	
	var distance = player.global_position.distance_to(current_tree.global_position)
	if should_move_to_new_tree(distance):
		playSound(ristleSound)
		move_to_new_tree()
	else: if distance >= 60 and (randi() % 4 == 1): #if to far for too long high chance of swapping tree
		move_to_new_tree()
		playSound(twigSnapSound)
	
	var min_wait = 0.05
	var max_wait = 0.6
	var max_distance = 40.0
	var t = clamp(distance / max_distance, 0.0, 1.0)
	follow_timer.wait_time = lerp(min_wait, max_wait, t)

func _process(delta: float) -> void:
	if is_teleporting:
		friedy.global_position = target_position
		is_teleporting = false
	else:
		friedy.global_position = friedy.global_position.lerp(target_position, delta * 6.0)
		
	friedy.look_at(player.global_position, Vector3.UP)

func _on_tree_timer_timeout():
	await move_to_new_tree()
	playSound(twigSnapSound)

func _on_follow_timer_timeout():
	move_around_tree()
	
func playSound(sound : AudioStreamPlayer3D):
	sound.global_position = current_tree.global_position
	if (randi() % 3 == 2):
		sound.play()
		
func update_friedy(player_pos: Vector3, tree_pos: Vector3, peek_left: bool, jump: bool = false):
	var dir = (tree_pos - player_pos).normalized()
	var hide_distance = 1.2
	var base_position = tree_pos + dir * hide_distance
	
	var player_right = player.global_transform.basis.x
	player_right.y = 0
	player_right = player_right.normalized()
	
	# Dynamic offset: closer = smaller peek, farther = bigger peek
	var distance = player_pos.distance_to(tree_pos)
	var min_offset = 0.4   # minimum peek when close
	var max_offset = 1.2   # maximum peek when far
	var max_distance = 40.0
	var peek_amount = lerp(min_offset, max_offset, clamp(distance / max_distance, 0.0, 1.0))
	if (peek_left):
		peek_amount = -peek_amount
		
	var offset = 0.0 if jump else peek_amount
	var peek_offset = player_right * offset
	var target_pos = (base_position + peek_offset)
	
	target_position = target_pos

func should_move_to_new_tree(distance: float) -> bool:
	if distance <= 10.0: #player too close
		return true
	
	var look_amount = player_looking_at_friedy_amount()
	
	if (distance <= 50.0 and look_amount > 0):
		spotted_count += look_amount
		if (spotted_count >= max_spotted_count):
			spotted_count = 0
			return true
		
	return false

func can_player_see_friedy() -> bool:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		player.global_position,
		friedy.global_position
	)
	query.exclude = [player]
	
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		return false
		
	return result.collider == friedy


func player_looking_at_friedy_amount() -> int:
	var to_friedy = (friedy.global_position - player.global_position).normalized()
	
	# Player forward direction (-Z is forward in Godot)
	var player_forward = -player.global_transform.basis.z
	player_forward = player_forward.normalized()
	
	var dot = player_forward.dot(to_friedy)
	
	var look_amount = 0
	if dot > 0.85:
		look_amount = 1
	if dot > 0.90:
		look_amount = 3
	if dot > 0.94:
		look_amount = 4
	if dot > 0.98:
		look_amount = 5
	return look_amount
