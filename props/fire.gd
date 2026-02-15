extends Node3D

@onready var anim_player: AnimationPlayer = $intensity

# Animation positions for each intensity level
const INTENSITY_TIMES := [
	0.0, # 0 - doused
	0.25, # 1
	0.45, # 2
	0.65, # 3
	0.85, # 4
	1.0   # 5 - max
]

func _ready() -> void:
	set_intensity(0)

func set_intensity(value: int) -> void:
	value = clamp(value, 0, INTENSITY_TIMES.size() - 1)

	if not anim_player.has_animation("intensity"):
		push_error("Campfire missing 'intensity' animation")
		return

	anim_player.play("intensity")
	anim_player.seek(INTENSITY_TIMES[value], true)
	anim_player.pause()
