extends Node3D

func _ready():
	add_to_group("interactable")

func InteractGetName() -> String:
	return "chair"

func InteractGetAction(player: CharacterBody3D, obj: Node3D, name: String) -> InteractionActionResult:
	if player.seated:
		return InteractionActionResult.new(true, "get off the chair")
	else:
		return InteractionActionResult.new(true, "sit on the chair")


static var SeatedSound := preload("res://audio/interaction/wood_place.mp3")

func Interact(player: CharacterBody3D, obj: Node3D, name: String) -> InteractionResult:
	if player.seated:
		player.seated = false
		player.global_position = self.global_position + Vector3(0, 0, -0.8)
		return InteractionResult.new(false, SeatedSound)
	else:
		player.seated = true
		player.global_position = self.global_position + Vector3(0, 0.1, -0.1)
		return InteractionResult.new(false, SeatedSound)
