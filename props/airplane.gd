extends Node3D

@export var player : Node3D
@export var startingState := "standing"

@export_group("Crash Rotation")

@export var enable_crash_rotation := true

@export var rotation_duration := 12.0

@export var max_pitch := -35.0
@export var max_roll := 15.0

@export var pitch_curve: Curve
@export var roll_curve: Curve

@export_group("Crash Movement")

@export var fall_duration := 12.0
@export var crash_drop_distance := 25.0
@export var height_curve: Curve


@onready var right_door: MeshInstance3D = $scaled/model/right_door
@onready var left_door: MeshInstance3D = $scaled/model/left_door
@onready var trauma_causer: Area3D = $Calamity/TraumaCauser
@onready var turbulance: AudioStreamPlayer3D = $Calamity/Turbulance
@onready var calamity: Node3D = $Calamity
@onready var dingle: AudioStreamPlayer3D = $Dingle

signal onPlayerSeatChanged(sit_left: bool, is_sitting: bool)

var crash_rotation_time := 0.0
var crash_fall_time := 0.0
var rotating_plane := false

var original_position := Vector3.ZERO

func _ready() -> void:
	original_position = position
	setState(startingState)

func _process(delta: float) -> void:
	if rotating_plane:
		update_crash_rotation(delta)

func onSeatChangedLeft(is_stting: bool):
	onPlayerSeatChanged.emit(true, is_stting)

func onSeatChangedRight(is_stting: bool):
	onPlayerSeatChanged.emit(false, is_stting)


#debug stuff
var states := ["standing", "flying", "crashing"]
var currentState := 0
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
	currentState = states.find(state)
	#I LOVE MAGIC NUMBERSSS!!!!!!!
	if state == "standing":
		open_doors()
		trauma_causer.set_trauma_amount(0)
		player.set_shake_intensity(0)
		turbulance.volume_db = -80.0
		calamity.set_calamity(false)
		dingle.play()
		rotating_plane = false
		rotation_degrees = Vector3.ZERO
		position = original_position
		pass
	elif state == "flying":
		close_doors()
		trauma_causer.set_trauma_amount(0.1)
		player.set_shake_intensity(0.08)
		turbulance.volume_db = -20.0
		calamity.set_calamity(false)
		dingle.play()
		rotating_plane = false
		rotation_degrees = Vector3.ZERO
		position = original_position
		pass
	elif state == "crashing":
		close_doors()
		trauma_causer.set_trauma_amount(0.1)
		player.set_shake_intensity(1.0)
		turbulance.volume_db = -3.0
		calamity.set_calamity(true)
		crash_rotation_time = 0.0
		crash_fall_time = 0.0
		rotating_plane = enable_crash_rotation
		pass

func update_crash_rotation(delta: float):
	crash_rotation_time += delta
	crash_fall_time += delta
	
	var rt: float = clamp(crash_rotation_time / rotation_duration, 0.0, 1.0)
	var ft: float = clamp(crash_fall_time / fall_duration, 0.0, 1.0)
	
	var pitch_t := rt
	var roll_t := rt
	var height_t := ft
	
	if pitch_curve:
		pitch_t = pitch_curve.sample(rt)
	
	if roll_curve:
		roll_t = roll_curve.sample(rt)
		
	if height_curve:
		height_t = height_curve.sample(ft)
	
	rotation_degrees.x = lerp(0.0, max_pitch, pitch_t)
	rotation_degrees.z = lerp(0.0, max_roll, roll_t)
	
	position.y = original_position.y - (height_t * crash_drop_distance)


func open_doors():
	#magic numbers hmmmm yummers
	right_door.rotation_degrees.y = 165
	left_door.rotation_degrees.y = 30

func close_doors():
	left_door.rotation_degrees.y = 180
	right_door.rotation_degrees.y = 0
