extends Node3D

@export var Name := "seat"
@export var seatedSound: AudioStream = preload("res://audio/interaction/wood_place.mp3")
@export var SeatOffset := Vector3(0, 0.1, -0.1)
@export var ExitOffset := Vector3(0, 0, -0.8)

func _ready():
	add_to_group("interactable")

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
		return InteractionResult.new(false, seatedSound)
	else:
		player.sit(self, SeatOffset)
		return InteractionResult.new(false, seatedSound)
