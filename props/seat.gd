extends Node3D

@export var Name := "seat"
@export var seatedSound: AudioStream = preload("res://audio/interaction/sitSound.mp3")
@export var unseatSound: AudioStream = null
@export var SeatOffset := Vector3(0, 0.1, -0.1)
@export var ExitOffset := Vector3(0, 0, -0.8)

func _ready():
	add_to_group("interactable")

signal onSeatChanged(is_sitting: bool)

func InteractGetName() -> String:
	return Name

func InteractGetAction(player: CharacterBody3D, obj: Node3D, name: String) -> InteractionActionResult:
	if player.seated:
		if player.currentSeat == self:
			return InteractionActionResult.new(true, "get off the " + Name)
		else:
			return InteractionActionResult.new(false, "already seated.")
	else:
		return InteractionActionResult.new(true, "sit on the " + Name)

func SeatGetExitOffset():
	return ExitOffset

func Interact(player: CharacterBody3D, obj: Node3D, name: String) -> InteractionResult:
	if player.seated:
		player.stand()
		onSeatChanged.emit(false)
		return InteractionResult.new(false, unseatSound)
	else:
		player.sit(self, SeatOffset)
		onSeatChanged.emit(true)
		return InteractionResult.new(false, seatedSound)
