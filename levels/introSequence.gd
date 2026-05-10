extends Node2D
@onready var sequence_player: AnimationPlayer = $SequencePlayer

#var intro_scene := preload("res://levels/woods.scn")
const game_scene := preload("res://levels/woods.scn")
@onready var music: AudioStreamPlayer = $AudioStreamPlayer2D

const SYNC_OFFSET := 0.02
const SYNC_SPEED := 10.0

func _process(delta: float) -> void:
	if music.playing:
		var target_pos = music.get_playback_position() + SYNC_OFFSET

		# smooth correction
		var current_pos = sequence_player.current_animation_position
		var synced_pos = lerp(current_pos, target_pos, delta * SYNC_SPEED)

		sequence_player.seek(synced_pos, true)

func start(player: Node3D):
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	sequence_player.play("intro_2")
	music.play()
	await player.Transition("fade_out");
	#var gameplay = game_scene.instantiate()
	#get_tree().root.add_child(gameplay)
	get_tree().change_scene_to_packed(game_scene)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	await get_tree().process_frame
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#player.Transition("fade_in");
#	thje player has to get loaded first??? because player hasnt loaded its vars yet here?
	var new_scene = get_tree().current_scene
	var newPlayer = new_scene.find_child("Player")
	#newPlayer.Transition("fade_out");
	
	await get_tree().create_timer(10).timeout
	newPlayer.Transition("fade_in");
	
#	unload previous scene?
	
	await sequence_player.animation_finished
	
	newPlayer.Transition("fade_out");
	#load other scene?
	newPlayer.Transition("fade_in");
