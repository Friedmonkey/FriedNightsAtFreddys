extends Node

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var thunderSound: AudioStreamPlayer = $Thunder

var thunder_active := false
var thunder_cooldown := 0.0

func _ready() -> void:
	night()
	
func thunder():
	if thunder_active:
		return
	
	thunder_active = true

	day()

	await get_tree().create_timer(0.2).timeout
	thunderSound.pitch_scale = randf_range(0.8, 1.2)
	thunderSound.play()

	await get_tree().create_timer(0.1).timeout
	night()

	# cooldown so it can't instantly retrigger
	await get_tree().create_timer(5.0).timeout

	thunder_active = false


func reset():
	world_environment.environment.sky.sky_material.energy_multiplier = 0.45

func night():
	world_environment.environment.sky.sky_material.energy_multiplier = 0

func day():
	world_environment.environment.sky.sky_material.energy_multiplier = 20


func _process(delta: float) -> void:
	thunder_cooldown -= delta
	
	# chance system but with time-based control
	if thunder_cooldown <= 0.0:
		if randf() < 0.002:  # cleaner than randi()%500
			thunder()
			thunder_cooldown = 10.0
