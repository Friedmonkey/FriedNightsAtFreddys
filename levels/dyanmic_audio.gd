extends Node

@onready var player: Node3D = $"../../Player"

@onready var sound_forest1: AudioStreamPlayer = $ForrestAmbiance
@onready var sound_river: AudioStreamPlayer = $WaterAmbiance
@onready var sound_wind: AudioStreamPlayer = $WindAmbiance

# Structure:
# {
#     "start_z": float,
#     "end_z": float,
#     "base_volume": float (in dB),
#     "falloff": float,
#     "player": AudioStreamPlayer
# }

var audio_z_mapping = []


func _ready():
	# Make sure sounds are playing so we only control volume
	#for sound in [sound_river, sound_forest1, sound_forest2]:
		#sound.play()
#		#we have autoplay i think ons

	audio_z_mapping = [
		{
			"start_z": 60.0,
			"end_z": -50.0,
			"base_volume": -3.334,
			"falloff": 40.0,
			"player": sound_forest1
		},	
		{
			"start_z": -50.0,
			"end_z": -61.0,
			"base_volume": 0.0,
			"falloff": 30.0,
			"player": sound_river
		},
		{
			"start_z": -60.0,
			"end_z": -171.0,
			"base_volume": -11.0,
			"falloff": 40.0,
			"player": sound_wind
		}
	]


func _process(_delta: float) -> void:
	var player_z = player.global_transform.origin.z

	for zone in audio_z_mapping:
		var volume_db = calculate_zone_volume(
			player_z,
			zone.start_z,
			zone.end_z,
			zone.base_volume,
			zone.falloff
		)

		zone.player.volume_db = volume_db


func calculate_zone_volume(player_z: float, start_z: float, end_z: float, base_volume: float, falloff: float) -> float:
	
	# --- Normalize the zone ---
	var min_z = min(start_z, end_z)
	var max_z = max(start_z, end_z)
	
	# Inside the zone → full base volume
	if player_z >= min_z and player_z <= max_z:
		return base_volume
	
	# Outside the zone → calculate distance to nearest edge
	var distance: float
	
	if player_z < min_z:
		distance = min_z - player_z
	else:
		distance = player_z - max_z
	
	# Outside falloff range → silent
	if distance >= falloff:
		return -80.0  # effectively muted
	
	# Fade proportionally (only outside the zone)
	var t = distance / falloff  # 0 → 1
	return lerp(base_volume, -80.0, t)
