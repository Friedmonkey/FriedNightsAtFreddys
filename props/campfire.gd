extends Node3D

@onready var fire := $Fire
@onready var fire_zone := $fire_zone

var current_intensity: int = 0

func _ready() -> void:
	add_to_group("interactable")

func InteractGetName(): return "campfire"

func InteractGetAction(player: CharacterBody3D, obj: Node3D, name: String) -> InteractionActionResult:
	if obj == null:
		return InteractionActionResult.new(false, "add planks to increase the fire.")

	if name == "plank":
		return InteractionActionResult.new(true, "put plank on the fire")

	return InteractionActionResult.new(false, "only planks can be burned")

static var FireWhoosh := preload("res://audio/interaction/short_fire_whoosh.mp3")
func Interact(player: CharacterBody3D, obj: Node3D, name: String) -> InteractionResult:
	set_intensity(current_intensity + 1)
	return InteractionResult.new(true, FireWhoosh)
	
#debug stuff
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fire_intensity_up"):
		set_intensity(current_intensity + 1)

	if event.is_action_pressed("fire_intensity_down"):
		set_intensity(current_intensity - 1)

func set_intensity(intensity: int):
	current_intensity = clamp(intensity, 0, 5)
	fire_zone.monitoring = (current_intensity != 0)
	fire.set_intensity(current_intensity)

func _on_fire_zone_body_entered(body: Node3D) -> void:
	if (body.has_method("set_ablaze")):
		body.set_ablaze(current_intensity)
		set_intensity(current_intensity - 1)
