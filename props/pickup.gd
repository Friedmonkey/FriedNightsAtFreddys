extends Node3D

signal Interact_picked_up
signal Interact_placed_down

@export var Name := "object"
@export var Size := Vector3(0.5, 0.5, 0.5)

@export var pickup_sound: AudioStream = preload("res://audio/interaction/generic_pickup.mp3")
@export var place_sound: AudioStream = preload("res://audio/interaction/generic_place.mp3")

@onready var audio_player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()

func _ready():
	add_child(audio_player)
	add_to_group("interactable")

	Interact_picked_up.connect(OnPickup)
	Interact_placed_down.connect(OnPlace)

func OnPickup():
	if pickup_sound == null:
		return
	
	audio_player.stream = pickup_sound
	audio_player.play()

func OnPlace():
	if place_sound == null:
		return
	
	audio_player.stream = place_sound
	audio_player.play()

func InteractGetName() -> String:
	return Name

func InteractCanPickup() -> bool:
	return true
