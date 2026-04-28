extends Node3D

@onready var player := $Player
@onready var campfire := $NavMap/Island1/campfire/fire
@onready var airplane: Node3D = $NavMap/Island0/Airplane
@onready var bridge := $NavMap/bridge
@onready var time_controller: AnimationPlayer = $vibe/lighing/TimeController
@onready var player_respawn: Node3D = $player_respawn
@onready var intro_player_spawn: Node3D = $NavMap/Island0/player_spawn
@onready var woods_player_spawn: Node3D = $NavMap/Island1/player_spawn


enum GameState {
	NONE,
	INTRO,
	FALLING,
	EXPLOSION,
	WOODS,
	DEAD
}

var state: GameState = GameState.NONE


func _ready() -> void:
	SimpleGrass.set_interactive(true)
	
	player.player_moved.connect(_on_player_moved)
	player.on_player_died.connect(player_died)
	
	set_state(GameState.INTRO)


# -------------------------
# STATE SYSTEM
# -------------------------

func set_state(new_state: GameState) -> void:
	if state == new_state:
		return
	
	state = new_state
	_enter_state(state)


func _enter_state(s: GameState) -> void:
	match s:
		GameState.INTRO:
			player_respawn.transform = intro_player_spawn.transform
			time_controller.play("daytime")
			time_controller.seek(4.9, true) # instant snap to start of day
			
			bridge.set_plank_level(0)
			campfire.set_intensity(0)
		
		GameState.FALLING:
			await get_tree().create_timer(2.0).timeout
			set_state(GameState.EXPLOSION)
		
		GameState.EXPLOSION:
			await get_tree().create_timer(1.5).timeout
			set_state(GameState.WOODS)
		
		GameState.WOODS:
			player_respawn.transform = woods_player_spawn.transform
			time_controller.play("nighttime")
			#time_controller.seek(0.0, true)
		
		GameState.DEAD:
			bridge.set_plank_level(0)
			campfire.set_intensity(0)
			airplane.find_child("Calamity").set_calamity(false)


func player_died() -> void:
	set_state(GameState.DEAD)


func _on_player_moved(new_pos: Vector3) -> void:
	SimpleGrass.set_player_position(new_pos)
	
	# INTRO → FALLING trigger
	if state == GameState.INTRO and new_pos.y < 8.0:
		set_state(GameState.FALLING)
