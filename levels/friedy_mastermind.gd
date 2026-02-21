extends Node

const DEBUGGING: bool = false;

# =========================
# Node References
# =========================
@onready var player := $"../Player"
@onready var friedy := $"stalking_friedy"
@onready var twigSnapSound := $"TwigSnap"
@onready var ristleSound := $"Ristle"
@onready var treesFolder := $"../NavMap/trees"

# =========================
# Enums
# =========================
enum PeekState {
	LEFT,
	RIGHT,
	UP
}

# =========================
# Config
# =========================
const MAX_SPOTTED_COUNT := 32
const TELEPORT_HIDE_DISTANCE := 1.2
const MAX_DISTANCE_FOR_PEEK := 40.0

const MIN_PEEK_OFFSET := 0.4
const MAX_PEEK_OFFSET := 1.2
const UP_HEIGHT_OFFSET := 8.25
#HEIGHT offset when preparing to jump away 
const UP_HEIGHT_OFFSET_JUMP := UP_HEIGHT_OFFSET-1.25

# =========================
# Runtime
# =========================
var trees: Array = []
var current_tree: Node3D = null
var current_state: PeekState = PeekState.LEFT

var target_position: Vector3
var spotted_count := 0

var is_teleporting := false
var jump_lock := false

var follow_timer: Timer
var tree_timer: Timer


# ============================================================
# Ready
# ============================================================
func _ready() -> void:
	trees = treesFolder.get_children()
	
	setup_timers()
	move_to_new_tree()


func setup_timers():
	tree_timer = Timer.new()
	tree_timer.wait_time = 60.0
	tree_timer.autostart = true
	add_child(tree_timer)
	tree_timer.timeout.connect(_on_tree_timer_timeout)
	
	follow_timer = Timer.new()
	follow_timer.wait_time = 0.5
	follow_timer.autostart = true
	add_child(follow_timer)
	follow_timer.timeout.connect(_on_follow_timer_timeout)


# ============================================================
# Tree Movement
# ============================================================
func move_to_new_tree():
	if trees.is_empty():
		return
	if jump_lock:
		return
	
	jump_lock = true
	friedy.visible = true
	
	if current_tree != null:
		await update_target_position(true)
		await get_tree().create_timer(0.2).timeout
	
	_DEBUG_TREE(false)
	current_tree = pick_valid_tree()
	_DEBUG_TREE(true)
	current_state = random_state()
	
	play_state_animation()
	
	update_target_position(true)
	
	is_teleporting = true
	jump_lock = false
	
	tree_timer.stop()
	tree_timer.start()


func pick_valid_tree() -> Node3D:
	var tree = trees.pick_random()
	if player.global_position.distance_to(tree.global_position) >= 60.0:
		tree = trees.pick_random()
	return tree


func random_state() -> PeekState:
	var r = randi() % 3
	return PeekState.values()[r]


# ============================================================
# State Handling
# ============================================================
func play_state_animation():
	match current_state:
		PeekState.LEFT:
			friedy.play_stalk_anim("stalking_left")
		PeekState.RIGHT:
			friedy.play_stalk_anim("stalking_right")
		PeekState.UP:
			friedy.play_stalk_anim("stalking_up")


# ============================================================
# Follow Logic
# ============================================================
func _on_follow_timer_timeout():
	move_around_tree()


func move_around_tree():
	if current_tree == null:
		return
	
	update_target_position()
	
	var distance = player.global_position.distance_to(current_tree.global_position)
	
	if should_move_to_new_tree(distance):
		playSound(ristleSound)
		move_to_new_tree()
	elif distance >= 60.0 and randi() % 4 == 1:
		playSound(twigSnapSound)
		move_to_new_tree()
	
	update_follow_speed(distance)


func update_follow_speed(distance: float):
	var min_wait := 0.05
	var max_wait := 0.6
	var t = clamp(distance / MAX_DISTANCE_FOR_PEEK, 0.0, 1.0)
	follow_timer.wait_time = lerp(min_wait, max_wait, t)


# ============================================================
# Positioning
# ============================================================
func update_target_position(jump: bool = false):
	if current_tree == null:
		return
	
	var player_pos = player.global_position
	var tree_pos = current_tree.global_position
	
	var dir = (tree_pos - player_pos).normalized()
	var base_position = tree_pos + dir * TELEPORT_HIDE_DISTANCE
	
	var final_position = base_position
	
	match current_state:
		PeekState.LEFT, PeekState.RIGHT:
			final_position += calculate_side_offset(player_pos, tree_pos, jump)
		
		PeekState.UP:
			final_position += calculate_up_offset(jump)
	
	target_position = final_position


func calculate_side_offset(player_pos: Vector3, tree_pos: Vector3, jump: bool) -> Vector3:
	if jump:
		return Vector3.ZERO
	
	var distance = player_pos.distance_to(tree_pos)
	var peek_amount = lerp(
		MIN_PEEK_OFFSET,
		MAX_PEEK_OFFSET,
		clamp(distance / MAX_DISTANCE_FOR_PEEK, 0.0, 1.0)
	)
	
	if current_state == PeekState.LEFT:
		peek_amount *= -1.0
	
	var player_right = player.global_transform.basis.x
	player_right.y = 0
	player_right = player_right.normalized()
	
	return player_right * peek_amount


func calculate_up_offset(jump: bool = false) -> Vector3:
	return Vector3.UP * (UP_HEIGHT_OFFSET_JUMP if jump else UP_HEIGHT_OFFSET)


# ============================================================
# Process
# ============================================================
func _process(delta: float) -> void:
	if is_teleporting:
		friedy.global_position = target_position
		is_teleporting = false
	else:
		friedy.global_position = friedy.global_position.lerp(target_position, delta * 6.0)
	
	friedy.look_at(player.global_position, Vector3.UP)


# ============================================================
# Detection Logic
# ============================================================
func should_move_to_new_tree(distance: float) -> bool:
	if distance <= 10.0:
		return true
	
	var look_amount = player_looking_at_friedy_amount()
	
	if distance <= 50.0 and look_amount > 0:
		spotted_count += look_amount
		if spotted_count >= MAX_SPOTTED_COUNT:
			spotted_count = 0
			return true
	
	return false


func player_looking_at_friedy_amount() -> int:
	var to_friedy = (friedy.global_position - player.global_position).normalized()
	var player_forward = -player.global_transform.basis.z
	player_forward = player_forward.normalized()
	
	var dot = player_forward.dot(to_friedy)
	
	if dot > 0.98:
		return 5
	if dot > 0.94:
		return 4
	if dot > 0.90:
		return 3
	if dot > 0.85:
		return 1
	
	return 0


# ============================================================
# Sounds
# ============================================================
func playSound(sound: AudioStreamPlayer3D):
	if current_tree == null:
		return
	
	sound.global_position = current_tree.global_position
	if randi() % 3 == 2:
		sound.play()


# ============================================================
# Tree Timer
# ============================================================
func _on_tree_timer_timeout():
	await move_to_new_tree()
	playSound(twigSnapSound)
	
# ============================================================
# DEBUG Tree
# ============================================================
func _DEBUG_TREE(enabled: bool):
	if !DEBUGGING or current_tree == null:
		return
	
	var layer = current_tree.find_child("second")
	layer.scale.x = 5 if enabled else 1
	#if enabled:
	#var stuffs = current_tree.get_children()
	#for stuff in stuffs:
		#if stuff.name == "trunk":
			#continue
		#stuff.visible = !enabled
