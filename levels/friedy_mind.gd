extends Node


# =========================
# Node References
# =========================
@onready var player := $"../Player"
@onready var friedy := $"stalking_friedy"
@onready var right_wing: Node3D = $right_wing
@onready var left_wing: Node3D = $left_wing

const MAX_SPOTTED_COUNT := 32
var spotted_count := 0
var friedy_timer: Timer

signal friedySpotted

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	friedy_timer = Timer.new()
	friedy_timer.wait_time = 0.1
	friedy_timer.autostart = true
	add_child(friedy_timer)
	friedy_timer.timeout.connect(friedy_update)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	friedy.look_at(player.global_position, Vector3.UP)

func friedy_update():
	if !friedy.visible:
		return
	var distance = player.global_position.distance_to(friedy.global_position)
	if has_been_spotted(distance):
		hide_friedy()
		friedySpotted.emit()

func hide_friedy():
	friedy.visible = false

func spawn_friedy(spawn_left: bool):
	var location = left_wing.global_position if spawn_left else right_wing.global_position
	friedy.global_position = location
	friedy.visible = true

func has_been_spotted(distance: float) -> bool:
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
