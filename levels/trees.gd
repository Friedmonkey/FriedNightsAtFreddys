extends Node3D

@onready var player := $"../../Player"
@onready var friedy := $"../../stalking/stalking_friedy"
@onready var twigSnapSound := $"../../stalking/TwigSnap"
@onready var ristleSound := $"../../stalking/Ristle"

var trees: Array = []
var current_tree: Node3D = null
var follow_timer: Timer
var tree_timer: Timer
var target_position: Vector3
var is_teleporting: bool = false
var jump_in_progress: bool = false


func _ready() -> void:
	trees = get_children()
	
	tree_timer = Timer.new()
	tree_timer.wait_time = 10.0
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
		await update_friedy(player.global_position, current_tree.global_position, true)
		await get_tree().create_timer(0.2).timeout
		#current_tree.scale = Vector3.ONE
	
	current_tree = trees.pick_random()
	#current_tree.scale = Vector3(1, 1.5, 1)
	update_friedy(player.global_position, current_tree.global_position, true)
	is_teleporting = true
	jump_in_progress = false  # release lock

func move_around_tree():
	if current_tree == null:
		return
	
	#friedy.visible = true
	update_friedy(player.global_position, current_tree.global_position)
	
	var distance = player.global_position.distance_to(current_tree.global_position)
	if distance <= 10.0:
		ristleSound.global_position = current_tree.global_position
		ristleSound.play()
		move_to_new_tree()
	
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
	twigSnapSound.global_position = current_tree.global_position
	twigSnapSound.play()

func _on_follow_timer_timeout():
	move_around_tree()

func update_friedy(player_pos: Vector3, tree_pos: Vector3, jump: bool = false):
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
	
	var offset = 0.0 if jump else peek_amount
	var peek_offset = player_right * offset
	var target_pos = base_position + peek_offset
	
	target_position = target_pos
