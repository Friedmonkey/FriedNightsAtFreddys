extends Node3D

#var player : Node3D

@onready var fire1 := $AirplaneFire
@onready var fire2 := $AirplaneFire2

@onready var left_bang := $LeftBang
@onready var right_bang := $RightBang
@onready var explosionTrauma := $ExplosionTrauma

@onready var traumaCauser := $TraumaCauser
@onready var smoke: MeshInstance3D = $Smoke

@onready var dangerAlarm := $DangerAlarm
@onready var beeping := $Beeping
#@onready var turbulance := $Turbulance
@onready var siren := $Siren

@onready var lights := $lights
#var has_calamity := false

#var current_intensity: int = 0
#func _ready() -> void:
	#player = $"..".player
	#if player == null:
		#player.THE_PLAYER_IS_NULL("PLEASE ASSIGN A PLAYER IN THE EDITOR")

func _process(_delta: float) -> void:
	traumaCauser.cause_trauma()

func set_calamity(enabled: bool):
	#has_calamity = enabled
	var intensity = 5 if enabled else 0
	fire1.set_intensity(intensity)
	fire2.set_intensity(intensity)
	smoke.visible = enabled
	
	#perhaps next up
	#make some sort of chair dance where you have to pick an seat where friedy isnt outside the window
	#one a timer is over all friedies that are on a chair move inside
	# if you were on  a seat and friedy was outside your window, you die!
	# if you're not seated by the time when friedy move in, you die
	#now how on earth do i explain these rules to the player without just outright telling them?
	# also do this minigame before or after the calamity kicks in?
	
	if (enabled):
		left_bang.play()
		right_bang.play()
		explosionTrauma.cause_trauma()
		
		set_lights(Color.DARK_RED)
		dangerAlarm.play()
		beeping.play()
		#turbulance.play()
		siren.play()
	else:
		set_lights(Color.WHITE)
		dangerAlarm.stop()
		beeping.stop()
		#turbulance.stop()
		siren.stop()

func set_lights(color: Color, emmision: bool = true):
	var lamps = lights.get_children()
	for lamp in lamps:
		lamp.material_override.emission_energy_multiplier = 1.0 if emmision else 0.0
		var light = lamp.find_child("OmniLight3D")
		light.light_color = color
