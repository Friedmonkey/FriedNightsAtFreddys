extends Node3D

#var player : Node3D

@onready var fire1 := $AirplaneFire
@onready var fire2 := $AirplaneFire2

@onready var left_bang := $LeftBang
@onready var right_bang := $RightBang
@onready var explosionTrauma := $ExplosionTrauma

@onready var traumaCauser := $TraumaCauser
@onready var smoke1: MeshInstance3D = $Smoke1
@onready var smoke2: MeshInstance3D = $Smoke2

@onready var dangerAlarm := $DangerAlarm
@onready var beeping := $Beeping
#@onready var turbulance := $Turbulance
@onready var siren := $Siren

@onready var lights := $lights

@export var smoke1_start_time := 0.0
@export var smoke2_start_time := 5.0

@export var smoke1_fill_time := 6.0
@export var smoke2_fill_time := 6.0

@export_range(0.0, 1.0) var smoke1_max_alpha := 1.0
@export_range(0.0, 1.0) var smoke2_max_alpha := 1.0

var smoke_time := 0.0
var smoke_active := false

#var smoke_timer: Timer

#func _ready() -> void:
	#smoke_timer = Timer.new()
	#smoke_timer.wait_time = 5
	##smoke_timer.autostart = true
	#add_child(smoke_timer)
	#smoke_timer.timeout.connect(smoke_update)

var has_calamity := false

#var current_intensity: int = 0
#func _ready() -> void:
	#player = $"..".player
	#if player == null:
		#player.THE_PLAYER_IS_NULL("PLEASE ASSIGN A PLAYER IN THE EDITOR")

func _process(delta: float) -> void:
	traumaCauser.cause_trauma()
	
	if smoke_active:
		smoke_time += delta
		update_smoke()

func set_calamity(enabled: bool):
	has_calamity = enabled
	#perhaps next up
	#make some sort of chair dance where you have to pick an seat where friedy isnt outside the window
	#one a timer is over all friedies that are on a chair move inside
	# if you were on  a seat and friedy was outside your window, you die!
	# if you're not seated by the time when friedy move in, you die
	#now how on earth do i explain these rules to the player without just outright telling them?
	# also do this minigame before or after the calamity kicks in?
	
	if (enabled):
		fire1.activate_smooth(6.0)
		fire2.activate_smooth(6.0)
		left_bang.play()
		right_bang.play()
		explosionTrauma.cause_trauma()
		smoke_time = 0.0
		smoke_active = true
		
		set_lights(Color.DARK_RED)
		dangerAlarm.play()
		beeping.play()
		#turbulance.play()
		siren.play()
	else:
		fire1.set_intensity(0)
		fire2.set_intensity(0)
		smoke_active = false
		smoke_time = 0.0
		smoke1.visible = false
		smoke2.visible = false
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

func set_smoke_transparency(smoke: Node3D, transparency: float):
	var mat := smoke.material_override as ShaderMaterial
	if mat == null:
		return

	var col: Color = mat.get_shader_parameter("smoke_color")
	col.a = transparency
	mat.set_shader_parameter("smoke_color", col)

func update_smoke() -> void:
	# Smoke 1 progress
	var t1: float = clamp(
		(smoke_time - smoke1_start_time) / smoke1_fill_time,
		0.0,
		1.0
	)
	
	# Smoke 2 progress
	var t2: float = clamp(
		(smoke_time - smoke2_start_time) / smoke2_fill_time,
		0.0,
		1.0
	)
	
	# Smoke 1
	if t1 > 0.0:
		smoke1.visible = true
		set_smoke_transparency(smoke1, t1 * smoke1_max_alpha)
	else:
		smoke1.visible = false
	
	# Smoke 2
	if t2 > 0.0:
		smoke2.visible = true
		set_smoke_transparency(smoke2, t2 * smoke2_max_alpha)
	else:
		smoke2.visible = false
