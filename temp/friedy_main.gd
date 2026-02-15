extends CharacterBody3D

var player = null

const SPEED = 0#6.0

@export var player_path: NodePath

@onready var nav_agent = $NavigationAgent3D as NavigationAgent3D

func _ready() -> void:
	player = get_node(player_path)

func _physics_process(delta: float) -> void:
	velocity = Vector3.ZERO
	#nav_agent.settarget
	nav_agent.set_target_position(player.global_position)
	var next_point = nav_agent.get_next_path_position()
	velocity = (next_point - global_position).normalized() * SPEED
	
	var pos = Vector3(player.global_position.x, global_position.y, player.global_position.z)
	look_at(pos, Vector3.UP)
	
	move_and_slide()
