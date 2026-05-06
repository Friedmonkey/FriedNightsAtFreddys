extends Node3D

@onready var friedy_mind: Node = $friedy_mind
@onready var airplane: Node3D = $Airplane
@onready var player: CharacterBody3D = $Player
@onready var lightning: Node = $vibe/lightning

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.Transition("fade_in")
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_friedy_mind_friedy_spotted() -> void:
	#if player.seated && player.currentSeat != null:
		#player.stand()
	await get_tree().create_timer(2).timeout
	lightning.thunder()
	await get_tree().create_timer(2).timeout
	airplane.setState(airplane.State.CRASHING)
	lightning.night()
	

func _on_airplane_on_player_seat_changed(sit_left: bool, is_sitting: bool) -> void:
	if is_sitting:
		friedy_mind.spawn_friedy(sit_left)
	else:
		friedy_mind.hide_friedy()
		#if airplane.currentState == 2: #crashing
			#airplane.setState("flying")
	pass # Replace with function body.


func _on_airplane_crash_finished() -> void:
	await get_tree().create_timer(0.2).timeout
	IntroSequence.start(player)
	#player.Transition("fade_out")
	pass # Replace with function body.
