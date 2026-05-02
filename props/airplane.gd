extends Node3D

@export var player : Node3D

@onready var right_door: MeshInstance3D = $scaled/model/right_door
@onready var left_door: MeshInstance3D = $scaled/model/left_door
@onready var trauma_causer: Area3D = $Calamity/TraumaCauser
@onready var turbulance: AudioStreamPlayer3D = $Calamity/Turbulance
@onready var calamity: Node3D = $Calamity
@onready var dingle: AudioStreamPlayer3D = $Dingle


@export var startingState := "standing"

func _ready() -> void:
	setState(startingState)
	pass

#debug stuff
var states := ["standing", "flying", "crashing"]
var currentState := 1
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fire_intensity_up"):
		currentState += 1
	elif event.is_action_pressed("fire_intensity_down"):
		currentState -= 1
	else:
		return
	currentState = clamp(currentState, 0, 2)
	setState(states[currentState])
	
#TODO: add like a seatbelt on sign or sum stuff

func setState(state: String):
	#I LOVE MAGIC NUMBERSSS!!!!!!!
	if state == "standing":
		open_doors()
		trauma_causer.set_trauma_amount(0)
		player.set_shake_intensity(0)
		turbulance.volume_db = -80.0
		calamity.set_calamity(false)
		dingle.play()
		pass
	elif state == "flying":
		close_doors()
		trauma_causer.set_trauma_amount(0.1)
		player.set_shake_intensity(0.08)
		turbulance.volume_db = -25.0
		calamity.set_calamity(false)
		dingle.play()
		pass
	elif state == "crashing":
		close_doors()
		trauma_causer.set_trauma_amount(0.1)
		player.set_shake_intensity(1.0)
		turbulance.volume_db = -3.0
		calamity.set_calamity(true)
		pass

func open_doors():
	#magic numbers hmmmm yummers
	right_door.rotation_degrees.y = 165
	left_door.rotation_degrees.y = 30

func close_doors():
	left_door.rotation_degrees.y = 180
	right_door.rotation_degrees.y = 0
