extends Node3D

#@onready var grass := $NavMap/floor/StaticBody3D/SimpleGrassTextured
@onready var player := $Player

@onready var campfire := $NavMap/campfire
@onready var bridge := $NavMap/bridge

func _ready() -> void:
	player.player_moved.connect(_on_player_moved)
	player.on_player_died.connect(player_died)
	#grass.interactive = true
	SimpleGrass.set_interactive(true)

func player_died():
	bridge.set_plank_level(0)
	campfire.set_intensity(0)
	pass

func _on_player_moved(new_pos:Vector3):
	SimpleGrass.set_player_position(new_pos) 
