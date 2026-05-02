extends Node3D

@onready var smoke_effect : MeshInstance3D = $Smoke
@onready var bridge_build : AudioStreamPlayer3D = $Build
@onready var wood_place : AudioStreamPlayer3D = $Wood
@onready var collision = $StaticBody3D/planks
@onready var plankStack = $plankStack
const MAX_PLANKS := 13
var planks: Array[MeshInstance3D] = []
var plank_level := 0
var bridge_built := false

func InteractGetName(): return "bridge"

func InteractGetAction(player: CharacterBody3D, obj: Node3D, name: String) -> InteractionActionResult:
	if bridge_built:
		return InteractionActionResult.new(false, "bridge already built")
	
	if plank_level >= MAX_PLANKS:
		if name == "hammer":
			return InteractionActionResult.new(true, "finish building the bridge")
		else:
			return InteractionActionResult.new(false, "requires hammer to build the bridge")
	
	if obj == null:
		return InteractionActionResult.new(
			false,
			"add planks to build the bridge %d/%d" % [plank_level, MAX_PLANKS]
		)
	
	if name == "plank":
		return InteractionActionResult.new(true, "store the plank near the bridge")
	elif name == "hammer":
		return InteractionActionResult.new(false, "place 13 planks first.")
	else:
		return InteractionActionResult.new(false, "only planks can be used")

static var WoodPlace := preload("res://audio/interaction/wood_place.mp3")

func Interact(player: CharacterBody3D, obj: Node3D, name: String) -> InteractionResult:
	set_plank_level(plank_level + 1)
	var consume: bool = (name != "hammer")
	return InteractionResult.new(consume, WoodPlace)

func _ready() -> void:
	add_to_group("interactable")
	setup_planks()
	hide_planks()
	bridge_build.finished.connect(bridge_complete)
	wood_place.finished.connect(func (): wood_place.pitch_scale = 1)

func build_bridge() -> void:
	if bridge_built or smoke_effect.visible:
		return
	bridge_built = true
	plankStack.set_level(0)
	bridge_build.play()
	smoke_effect.visible = true

func bridge_complete():
	wood_place.pitch_scale = 2
	wood_place.play()
	show_planks()
	smoke_effect.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fire_intensity_up"):
		set_plank_level(plank_level+1)
	
	if event.is_action_pressed("fire_intensity_down"):
		set_plank_level(plank_level-1)

func set_plank_level(new_level : int) -> void:
	plank_level = new_level
	plank_level = clamp(plank_level, 0, MAX_PLANKS+1)
	if (plank_level == 14):
		build_bridge()
	else:
		bridge_built = false
		plankStack.set_level(plank_level)
		wood_place.play()
		hide_planks()

func setup_planks() -> void:
	planks.clear()
	for node in get_children():
		if node is MeshInstance3D and node.is_in_group("bridge_plank"):
			planks.append(node)

func hide_planks() -> void:
	for plank in planks:
		plank.visible = false
	collision.disabled = true

func show_planks() -> void:
	for plank in planks:
		plank.visible = true
	collision.disabled = false
