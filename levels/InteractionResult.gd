class_name InteractionResult

var can_interact: bool = false
var text: String = "unable to interact, missing implemtation"

func _init(c: bool = false, t: String = ""):
	can_interact = c
	text = t
