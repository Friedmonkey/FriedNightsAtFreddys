extends Node2D
@onready var sequence_player: AnimationPlayer = $SequencePlayer

#var intro_scene := preload("res://levels/woods.scn")
const game_scene := preload("res://levels/woods.scn")

func start(player: Node3D):
	sequence_player.play("intro_2")
	await player.Transition("fade_out");
	#var gameplay = game_scene.instantiate()
	#get_tree().root.add_child(gameplay)
	get_tree().change_scene_to_packed(game_scene)
	
	await get_tree().process_frame
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
