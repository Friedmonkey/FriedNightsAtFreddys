extends Node3D

var player : Node3D

@onready var fire1 := $AirplaneFire
@onready var fire2 := $AirplaneFire2

@onready var dangerAlarm := $DangerAlarm
@onready var beeping := $Beeping
@onready var turbulance := $Turbulance
@onready var siren := $Siren

@onready var lights := $lights

#var current_intensity: int = 0
func _ready() -> void:
	player = $"..".player
	if player == null:
		player.THE_PLAYER_IS_NULL("PLEASE ASSIGN A PLAYER IN THE EDITOR")

#debug stuff
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fire_intensity_up"):
		set_calamity(true)

	if event.is_action_pressed("fire_intensity_down"):
		set_calamity(false)

func set_calamity(enabled: bool):
	var intensity = 5 if enabled else 0
	fire1.set_intensity(intensity)
	fire2.set_intensity(intensity)
	
	#todo: add camera shake system
	#https://www.youtube.com/watch?v=1i5SB8Ct1y0
	#player.set_camera_shake(enabled)
	#maby also play an explosion sound when setting it to true?
	
	if (enabled):
		set_lights(Color.DARK_RED)
		dangerAlarm.play()
		beeping.play()
		turbulance.play()
		siren.play()
	else:
		set_lights(Color.WHITE)
		dangerAlarm.stop()
		beeping.stop()
		turbulance.stop()
		siren.stop()

func set_lights(color: Color, emmision: bool = true):
	var lamps = lights.get_children()
	for lamp in lamps:
		lamp.material_override.emission_energy_multiplier = 1.0 if emmision else 0.0
		var light = lamp.find_child("OmniLight3D")
		light.light_color = color
