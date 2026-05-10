extends CharacterBody3D

var player = null

const SPEED = 6.0

@export var player_path: NodePath

@onready var nav_agent = $NavigationAgent3D as NavigationAgent3D

@onready var chase: AudioStreamPlayer3D = $Chase
@onready var sceam: AudioStreamPlayer3D = $Sceam
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

var currentlyActive: bool

func set_active(active: bool):
	visible = active
	chase.stream_paused = !active
	sceam.stream_paused = !active
	collision_shape_3d.disabled = !active
	currentlyActive = active

func _ready() -> void:
	set_active(false)
	player = get_node(player_path)

func _physics_process(_delta: float) -> void:
	if !currentlyActive:
		return
	
	velocity = Vector3.ZERO
	#nav_agent.settarget
	nav_agent.set_target_position(player.global_position)
	var next_point = nav_agent.get_next_path_position()
	velocity = (next_point - global_position).normalized() * SPEED
	
	var pos = Vector3(player.global_position.x, global_position.y, player.global_position.z)
	look_at(pos, Vector3.UP)
	
	move_and_slide()
