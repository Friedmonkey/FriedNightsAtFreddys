extends Node3D

@onready var fire := $fire/Fire
@onready var fire_zone := $fire/fire_zone

var current_intensity: int = 0

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
