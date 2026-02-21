extends CharacterBody3D

@onready var animationPlayer = $AnimationPlayer

func play_stalk_anim(stalk_anim: String):
	animationPlayer.play(stalk_anim)

func play_stalk(stalk_left: bool):
	if (stalk_left):
		animationPlayer.play("stalking_left")
	else:
		animationPlayer.play("stalking_right")
