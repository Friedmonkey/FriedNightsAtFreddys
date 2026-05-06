extends Node3D

enum State {
	STANDING = 0,
	FLYING = 1,
	CRASHING = 2,
	CRASHED = 3
}

@export var player : Node3D
@export var startingState := State.STANDING

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

@export_group("Crash Landing")

@export var crash_final_pitch := 0.0
@export var crash_final_roll := 0.0
@export var settle_duration := 0.5

@onready var right_door: MeshInstance3D = $scaled/model/right_door
@onready var left_door: MeshInstance3D = $scaled/model/left_door
@onready var trauma_causer: Area3D = $Calamity/TraumaCauser
@onready var turbulance: AudioStreamPlayer3D = $Calamity/Turbulance
@onready var calamity: Node3D = $Calamity
@onready var dingle: AudioStreamPlayer3D = $Dingle
@onready var crash: AudioStreamPlayer3D = $Crash

@onready var siren: AudioStreamPlayer3D = $Calamity/Siren
@onready var danger_alarm: AudioStreamPlayer3D = $Calamity/DangerAlarm

var current_state: State = State.STANDING


signal onPlayerSeatChanged(sit_left: bool, is_sitting: bool)
signal crash_finished

var crash_time := 0.0
var rotating_plane := false
var settling := false
var settle_time := 0.0

#var start_rot := Vector3.ZERO


var original_position := Vector3.ZERO

func _ready() -> void:
	original_position = position
	setState(startingState)

func _process(delta: float) -> void:
	if rotating_plane:
		update_crash_rotation(delta)
	
	if settling:
		update_settle(delta)

func onSeatChangedLeft(is_stting: bool):
	onPlayerSeatChanged.emit(true, is_stting)

func onSeatChangedRight(is_stting: bool):
	onPlayerSeatChanged.emit(false, is_stting)


#debug stuff
#var states := ["standing", "flying", "crashing", "crashed"]
#var currentState := 0
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fire_intensity_up"):
		current_state = wrap_state(current_state + 1)
	elif event.is_action_pressed("fire_intensity_down"):
		current_state = wrap_state(current_state - 1)
	else:
		return
	
	setState(current_state)

func wrap_state(value: int) -> State:
	return (value + State.size()) % State.size() as State
#TODO: add like a seatbelt on sign or sum stuff

func setState(newState: State):
	current_state = newState
	#I LOVE MAGIC NUMBERSSS!!!!!!!
	if newState == State.STANDING:
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
	elif newState == State.FLYING:
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
	elif newState == State.CRASHING:
		close_doors()
		trauma_causer.set_trauma_amount(0.1)
		player.set_shake_intensity(1.0)
		turbulance.volume_db = -3.0
		calamity.set_calamity(true)
		crash_time = 0.0
		rotating_plane = enable_crash_rotation
		pass
	elif newState == State.CRASHED:
		if !calamity.has_calamity:
			calamity.set_calamity(true)
		crash.play()
		
		#rotation_degrees.x = max_pitch * 0.9
		#rotation_degrees.z = max_roll * 0.9
		position.y = original_position.y - (height_curve.sample(0.9) * crash_drop_distance)
		
		settling = true
		settle_time = 0.0
		#start_rot = rotation_degrees
		
		player.set_shake_intensity(3)
		trauma_causer.set_trauma_amount(1.0)
		trauma_causer.cause_trauma()
		trauma_causer.set_trauma_amount(0)
		
		siren.stop()
		danger_alarm.stop()
		
		open_doors()
		turbulance.volume_db = -80.0
		
		rotating_plane = false
		#settling = false
		crash_time = 0.0
		crash_finished.emit()
		
		#player.set_shake_intensity(0)


func on_crash_impact():
	setState(State.CRASHED)


func update_crash_rotation(delta: float):
	crash_time += delta
	
	var rt: float = clamp(crash_time / rotation_duration, 0.0, 1.0)
	var ft: float = clamp(crash_time / fall_duration, 0.0, 1.0)
	
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
	
	if ft >= 0.90 && rotating_plane:
		on_crash_impact()

func update_settle(delta: float):
	settle_time += delta
	
	var t: float = clamp(settle_time / settle_duration, 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t) # smoothstep
	
	var target_rot := Vector3(
		crash_final_pitch,
		rotation_degrees.y,
		crash_final_roll
	)
	
	rotation_degrees = rotation_degrees.lerp(target_rot, t)
	
	if t >= 1.0:
		settling = false
		rotation_degrees = target_rot


func open_doors():
	#magic numbers hmmmm yummers
	right_door.rotation_degrees.y = 165
	left_door.rotation_degrees.y = 30

func close_doors():
	left_door.rotation_degrees.y = 180
	right_door.rotation_degrees.y = 0
