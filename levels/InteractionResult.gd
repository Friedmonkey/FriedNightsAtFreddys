class_name InteractionResult

var consume_current: bool = false
var sound: AudioStream = null

func _init(c: bool = false, s: AudioStream = null):
	consume_current = c
	sound = s
